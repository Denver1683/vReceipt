import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vreceipt_admin/view_image.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  _CustomerDetailsScreenState createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _profileImageUrl;
  String? _userId;
  String? _email;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomerData();
  }

  Future<void> _fetchCustomerData() async {
    DocumentSnapshot customerDoc = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(widget.customerId)
        .get();

    if (customerDoc.exists) {
      setState(() {
        _nameController.text = customerDoc['name'] ?? '';
        _userId = customerDoc['uid']?.toString() ?? '';
        _profileImageUrl = customerDoc['imageURL'] ?? '';
        _email = customerDoc.id;
        _blocked = customerDoc['blocked'] ?? false;
      });
    }
  }

  Future<void> _updateCustomerStatus(bool blocked) async {
    await FirebaseFirestore.instance
        .collection('Customer')
        .doc(widget.customerId)
        .update({
      'blocked': blocked,
    });

    setState(() {
      _blocked = blocked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(blocked
            ? 'Customer blocked successfully.'
            : 'Customer unblocked successfully.'),
      ),
    );
  }

  void _showProfileImageOptions() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewImageScreen(imageUrl: _profileImageUrl),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image available to view.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Customer Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showProfileImageOptions,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.surface,
                  backgroundImage:
                      _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: colorScheme.onSurface,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'User ID: ${_userId ?? ''}',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                label: 'Name:',
                controller: _nameController,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Email:',
                controller: TextEditingController(text: _email),
                readOnly: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _updateCustomerStatus(!_blocked);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: _blocked ? Colors.green : Colors.red,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(
                  _blocked ? 'UNBLOCK' : 'BLOCK',
                ),
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
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
