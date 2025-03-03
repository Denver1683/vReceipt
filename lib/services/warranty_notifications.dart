// ignore_for_file: prefer_interpolation_to_compose_strings, empty_catches
import 'package:cloud_firestore/cloud_firestore.dart';

class WarrantyNotifications {
  int i = 0;
  Future<void> scheduleWarrantyNotifications(
      Map<String, dynamic> transactionData,
      String transactionDate,
      String transactionId,
      String customerEmail) async {
    try {
      // Ensure prodwarranty and prodname are lists
      final List<dynamic> warranties = transactionData['warranty'];
      final List<dynamic> products = transactionData['product'];

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

        // Add event to Firebase
        await _addEventToFirebase('Warranty end for $product', expiryDate,
            transactionId, customerEmail);

        i++;
      }
    } catch (e) {}
  }

  Future<void> _addEventToFirebase(String event, DateTime dateTime,
      String transactionId, String customerEmail) async {
    final eventCollection = FirebaseFirestore.instance
        .collection('Customer')
        .doc(customerEmail)
        .collection('Events');

    await eventCollection.doc(event + transactionId).set({
      'event': event,
      'time': dateTime.add(Duration(seconds: i)).toIso8601String() + 'Z',
      'transactionId': transactionId,
    });
  }
}
