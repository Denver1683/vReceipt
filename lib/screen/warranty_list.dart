// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'receipt_details.dart';

class WarrantyListScreen extends StatefulWidget {
  const WarrantyListScreen({super.key});

  @override
  _WarrantyListScreenState createState() => _WarrantyListScreenState();
}

class _WarrantyListScreenState extends State<WarrantyListScreen> {
  final Map<DateTime, List<Map<String, String>>> _events = {};
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _loadEvents();
    tz.initializeTimeZones();
    _syncEventsWithFirebase();
  }

  Future<void> _scheduleNotification(
      String event, DateTime dateTime, String transactionId) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: dateTime.hashCode,
          channelKey: 'warranty_channel',
          title: 'Event Reminder',
          body: event,
          notificationLayout: NotificationLayout.Default,
          payload: {'transactionId': transactionId},
          icon: 'resource://mipmap/ic_launcher'),
      schedule: NotificationCalendar.fromDate(
        date: tz.TZDateTime.from(dateTime, tz.local),
      ),
    );
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsString = prefs.getString('events');
    if (eventsString != null) {
      final Map<String, dynamic> eventsMap = jsonDecode(eventsString);
      final Map<DateTime, List<Map<String, String>>> loadedEvents = {};
      eventsMap.forEach((key, value) {
        final date = DateTime.parse(key);
        final eventsList = List<Map<String, dynamic>>.from(value).map((item) {
          return item
              .map((key, value) => MapEntry(key.toString(), value.toString()));
        }).toList();
        loadedEvents[date] = eventsList;
      });

      setState(() {
        _events.addAll(loadedEvents);
      });
    }
  }

  Future<void> _syncEventsWithFirebase() async {
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
      final transactionId = doc['transactionId'] as String;
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

    setState(() {
      _events.clear();
      _events.addAll(firebaseEvents);
    });

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> eventsMap =
        _events.map((key, value) => MapEntry(key.toIso8601String(), value));
    final String eventsString = jsonEncode(eventsMap);
    await prefs.setString('events', eventsString);

    for (var entry in _events.entries) {
      for (var event in entry.value) {
        await _scheduleNotification(
            event['event']!, entry.key, event['transactionId']!);

        final DateTime dateTime = entry.key;
        final DateTime sevenDaysBefore =
            dateTime.subtract(const Duration(days: 7));
        await _scheduleNotification('Reminder: ${event['event']} is in 1 week!',
            sevenDaysBefore, event['transactionId']!);
      }
    }
  }

  List<Widget> _buildEventList(
      Map<DateTime, List<Map<String, String>>> events, bool isUpcoming) {
    final filteredEvents = events.entries.where((entry) {
      return isUpcoming
          ? entry.key.isAfter(_today) || entry.key.isAtSameMomentAs(_today)
          : entry.key.isBefore(_today);
    }).toList();

    filteredEvents.sort((a, b) => a.key.compareTo(b.key));

    if (filteredEvents.isEmpty) {
      return [
        Center(
          child: Text(
            'No data available',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: isUpcoming ? Colors.blue[100] : Colors.red[100],
            ),
          ),
        )
      ];
    }

    return filteredEvents
        .map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isUpcoming ? Colors.blue[900] : Colors.red[900],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key.day}\n${_monthToString(entry.key.month)}\n${entry.key.year}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entry.value
                            .map((event) => GestureDetector(
                                  onTap: () async {
                                    final result =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReceiptDetailsPage(
                                          transactionId:
                                              event['transactionId']!,
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      _syncEventsWithFirebase();
                                    }
                                  },
                                  child: Text(
                                    event['event']!,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  String _monthToString(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final upcomingEvents = _buildEventList(_events, true);
    final expiredEvents = _buildEventList(_events, false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventSection('Upcoming', upcomingEvents, Colors.blue[500]!,
                Colors.blue[100]!),
            const SizedBox(height: 16.0),
            _buildEventSection(
                'Expired', expiredEvents, Colors.red[400]!, Colors.red[100]!),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSection(String title, List<Widget> events,
      Color backgroundColor, Color tileColor) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: tileColor,
            ),
          ),
          const SizedBox(height: 16.0),
          ...events,
        ],
      ),
    );
  }
}
