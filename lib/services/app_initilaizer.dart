import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppInitialization {
  static Future<void> initialize() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // Sync events with Firebase
    await _syncEventsWithFirebase();
  }

  static Future<void> _scheduleNotification(
      String event, DateTime dateTime, String transactionId) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: dateTime
              .hashCode, // Ensure to use a unique ID for each notification
          channelKey: 'warranty_channel', // Use the existing warranty channel
          title: 'Warranty Notification',
          body: event,
          notificationLayout: NotificationLayout.Default,
          payload: {'transactionId': transactionId},
          icon: 'resource://mipmap/ic_launcher'),
      schedule: NotificationCalendar.fromDate(
        date: tz.TZDateTime.from(dateTime, tz.local),
      ),
    );
  }

  static Future<void> _syncEventsWithFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final userEmail = user.email!;
    final snapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(userEmail)
        .collection('Events')
        .get();

    final Map<DateTime, List<Map<String, String>>> firebaseEvents = {};
    for (var doc in snapshot.docs) {
      final dateTimeString = doc['time'] as String;
      final dateTime = DateTime.parse(dateTimeString);
      final event = doc['event'] as String;
      final transactionId = doc['transactionId'];
      firebaseEvents.update(
          dateTime,
          (events) => [
                ...events,
                {'event': event, 'transactionId': transactionId}
              ],
          ifAbsent: () => [
                {'event': event, 'transactionId': transactionId}
              ]);
    }

    // Clear local events
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('events');

    // Save new events to local storage
    final Map<String, dynamic> eventsMap = firebaseEvents
        .map((key, value) => MapEntry(key.toIso8601String(), value));
    final String eventsString = jsonEncode(eventsMap);
    await prefs.setString('events', eventsString);

    // Schedule notifications for all events
    for (var entry in firebaseEvents.entries) {
      for (var event in entry.value) {
        await _scheduleNotification(
            event['event']!, entry.key, event['transactionId']!);

        // Schedule notification 7 days before the event
        final DateTime dateTime = entry.key;
        final DateTime sevenDaysBefore =
            dateTime.subtract(const Duration(days: 7));
        await _scheduleNotification('Reminder: ${event['event']} is in 1 week!',
            sevenDaysBefore, event['transactionId']!);
      }
    }
  }
}
