// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    if (await Permission.photos.isGranted) {
      return true;
    }

    if (await Permission.photos.request().isGranted) {
      return true;
    } else {
      if (await Permission.photos.isPermanentlyDenied) {
        _showPermissionDialog(context, 'Gallery Permission Required',
            'This app needs gallery access to select photos. Please grant permission from settings.');
      }
      return false;
    }
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (await Permission.camera.isGranted) {
      return true;
    }

    if (await Permission.camera.request().isGranted) {
      return true;
    } else {
      if (await Permission.camera.isPermanentlyDenied) {
        _showPermissionDialog(context, 'Camera Permission Required',
            'This app needs camera access to take photos. Please grant permission from settings.');
      }
      return false;
    }
  }

  static void _showPermissionDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
