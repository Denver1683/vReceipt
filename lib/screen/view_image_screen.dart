import 'package:flutter/material.dart';

class ViewImageScreen extends StatelessWidget {
  final String? imageUrl;

  const ViewImageScreen({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Image'),
        centerTitle: true,
      ),
      body: Center(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!)
            : Icon(
                Icons.store,
                size: 200,
                color: Colors.grey[800],
              ),
      ),
    );
  }
}
