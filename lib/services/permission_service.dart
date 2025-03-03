import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PermissionService {
  static Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    bool isAllowedToSendNotification =
        await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowedToSendNotification) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }

    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelGroupKey: "warranty_channel_group",
        channelKey: "warranty_channel",
        channelName: "Warranty Reminder",
        channelDescription: "Warranty Notification Channel",
        importance: NotificationImportance.High,
      ),
    ], channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: "warranty_channel_group",
        channelGroupName: "Warranty Group",
      ),
    ]);
  }

  static Future<void> requestCameraPermission(BuildContext context) async {
    final statusCamera = await Permission.camera.request();

    if (statusCamera.isDenied || statusCamera.isPermanentlyDenied) {
      _showCameraPermissionDialog(context);
    }
  }

  static Future<bool> requestGalleryPermission(BuildContext context) async {
    PermissionStatus status;

    if (await Permission.photos.isGranted) {
      return true;
    }

    if (await Permission.photos.request().isGranted) {
      return true;
    } else {
      if (await Permission.photos.isPermanentlyDenied) {
        _showGalleryPermissionDialog(context);
      }
      return false;
    }
  }

  static Future<void> requestLocationPermission(BuildContext context) async {
    final statusLocation = await Permission.location.request();

    if (statusLocation.isDenied || statusLocation.isPermanentlyDenied) {
      _showLocationPermissionDialog(context);
    }
  }

  static void _showCameraPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
              'This app needs camera access to scan QR codes. Please grant permission from settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void _showGalleryPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gallery Permission Required'),
          content: const Text(
              'This app needs gallery access to select photos. Please grant permission from settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void _showLocationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'This app needs location access to show the location of merchants. Please grant permission from settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
