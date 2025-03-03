// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, sort_child_properties_last

import 'package:vreceipt_customer/screen/view_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vreceipt_customer/widgets/hamburger_menu.dart';
import 'dart:io';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  _StoreProfileScreenState createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<bool> _isSaveButtonEnabled = ValueNotifier(false);
  String? _userId;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
    _nameController.addListener(_checkNameField);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkNameField);
    _nameController.dispose();
    _isSaveButtonEnabled.dispose();
    super.dispose();
  }

  void _checkNameField() {
    _isSaveButtonEnabled.value = _nameController.text.isNotEmpty;
  }

  Future<void> _fetchCustomerData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(user.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        _nameController.text = userDoc['name'] ?? '';
        _userId = userDoc['uid']?.toString() ?? '';
        _profileImageUrl = userDoc['imageURL'] ?? '';
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String fileName = user.email!;
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('Customer Picture')
            .child(fileName);

        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('Customer')
            .doc(user.email)
            .update({
          'imageURL': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Navigator.pop(context);
    await FirebaseFirestore.instance
        .collection('Customer')
        .doc(user.email)
        .update({
      'name': _nameController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully')),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String fileName = user.email!;
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('Customer Picture')
            .child(fileName);

        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('Customer')
            .doc(user.email)
            .update({
          'imageURL': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .update({
        'imageURL': '',
      });

      setState(() {
        _profileImageUrl = '';
      });
    }
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? [
                    ListTile(
                      leading: const Icon(Icons.visibility),
                      title: const Text('View Image'),
                      onTap: () {
                        Navigator.pop(context);
                        if (_profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewImageScreen(imageUrl: _profileImageUrl),
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Update Image'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Remove Image'),
                      onTap: () {
                        Navigator.pop(context);
                        _removeImage();
                      },
                    ),
                  ]
                : [
                    ListTile(
                      leading: const Icon(Icons.photo),
                      title: const Text('Upload from Gallery'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take a Photo'),
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                    ),
                  ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: const Text('Customer Profile'),
        centerTitle: true,
      ),
      drawer: const HamburgerMenu(), // Use the HamburgerMenu widget
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showProfileImageOptions,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[800],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'User ID: ${_userId ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              _buildTextField(
                label: 'Name:',
                controller: _nameController,
              ),
              const SizedBox(height: 32),
              ValueListenableBuilder<bool>(
                valueListenable: _isSaveButtonEnabled,
                builder: (context, isEnabled, child) {
                  return ElevatedButton(
                    onPressed: isEnabled ? _saveChanges : null,
                    child: const Text('SAVE CHANGES'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                          double.infinity, 48), // Make the button full width
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          controller: controller,
          obscureText: obscureText,
        ),
      ],
    );
  }
}
