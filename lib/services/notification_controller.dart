import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vreceipt_customer/main.dart';
import 'package:flutter/material.dart';

class NotificationController {
  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    String? transactionId = receivedAction.payload!['transactionId'];

    // Add debug information
    debugPrint('Received action with transactionId: $transactionId');
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/notification-page',
      (route) => (route.settings.name != '/notification-page') || route.isFirst,
      arguments: transactionId,
    );
  }
}
