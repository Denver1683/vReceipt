// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

class WarrantyNotifications {
  int i = 0;
  Future<void> scheduleWarrantyNotifications(
      Map<String, dynamic> transactionData,
      String transactionDate,
      String transactionId) async {
    try {
      // Ensure prodwarranty and prodname are lists
      final List<dynamic> warranties = transactionData['prodwarranty'];
      final List<dynamic> products = transactionData['prodname'];

      for (i < products.length;;) {
        String warranty = warranties[i];
        String product = products[i];
        DateTime purchaseDateTime = DateTime.parse(transactionDate);
        DateTime expiryDate;

        // Calculate the expiry date based on the warranty period
        if (warranty.contains('year(s)')) {
          int years = int.parse(warranty.split(' ')[0]);
          expiryDate = DateTime(
            purchaseDateTime.year + years,
            purchaseDateTime.month,
            purchaseDateTime.day,
            purchaseDateTime.hour,
            purchaseDateTime.minute,
            purchaseDateTime.second,
          );
        } else if (warranty.contains('month(s)')) {
          int months = int.parse(warranty.split(' ')[0]);
          expiryDate = DateTime(
            purchaseDateTime.year,
            purchaseDateTime.month + months,
            purchaseDateTime.day,
            purchaseDateTime.hour,
            purchaseDateTime.minute,
            purchaseDateTime.second,
          );
        } else {
          int days = int.parse(warranty.split(' ')[0]);
          expiryDate = purchaseDateTime.add(Duration(days: days));
        }

        // Schedule notifications
        await _scheduleNotification(
            'Warranty for $product ends today, if anything occurs, please contact seller soon.',
            expiryDate,
            transactionId);
        await _scheduleNotification(
            'Your $product warranty is expiring in 1 week, please check your item.',
            expiryDate.subtract(const Duration(days: 7)),
            transactionId);

        // Add event to Firebase
        await _addEventToFirebase(
            'Warranty end for $product', expiryDate, transactionId);

        i++;
      }
    } catch (e) {}
  }

  static Future<void> _scheduleNotification(
      String event, DateTime dateTime, String transactionId) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: dateTime.hashCode,
          channelKey: 'warranty_channel',
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

  Future<void> _addEventToFirebase(
      String event, DateTime dateTime, String transactionId) async {
    final userEmail = FirebaseAuth.instance.currentUser!.email!;
    final eventCollection = FirebaseFirestore.instance
        .collection('Customer')
        .doc(userEmail)
        .collection('Events');

    await eventCollection.doc(event + transactionId).set({
      'event': event,
      //To ensure time is always unique
      'time': dateTime.add(Duration(seconds: i)).toIso8601String() + 'Z',
      'transactionId': transactionId,
    });

    print('Event added to Firebase: $event on $dateTime');
  }
}
