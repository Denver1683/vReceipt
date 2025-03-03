// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:vreceipt_merchant/models/category.dart';
import 'barcode_scanner.dart';

class AddStockScreen extends StatefulWidget {
  final bool isEdit;
  final String? productId;
  final String? name;
  final String? price;
  final String? qty;
  final String? warranty;
  final String? category;

  const AddStockScreen({
    super.key,
    this.isEdit = false,
    this.productId,
    this.name,
    this.price,
    this.qty,
    this.warranty,
    this.category,
  });

  @override
  _AddStockScreenState createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _productIdController;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _warrantyController;
  String _warrantyUnit = 'year(s)';
  String _selectedCategory = 'Electronics';

  @override
  void initState() {
    super.initState();

    _productIdController = TextEditingController(text: widget.productId ?? '');
    _nameController = TextEditingController(text: widget.name ?? '');
    _priceController = TextEditingController(text: widget.price ?? '');
    _stockController = TextEditingController(text: widget.qty ?? '');

    if (widget.isEdit) {
      _selectedCategory = widget.category ?? 'Electronics';
      _parseWarranty(widget.warranty ?? '');
    } else {
      _warrantyController = TextEditingController();
      _fetchDefaultCategory();
      _generateProductId();
    }
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  void _parseWarranty(String warranty) {
    final warrantyParts = warranty.split(' ');
    if (warrantyParts.length == 2) {
      _warrantyController =
          TextEditingController(text: warrantyParts[0]); // Numeric part
      _warrantyUnit = warrantyParts[1]; // Unit part (e.g., year(s))
    } else {
      _warrantyController = TextEditingController();
    }
  }

  Future<void> _fetchDefaultCategory() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentSnapshot merchantDoc = await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(user.email)
          .get();

      if (merchantDoc.exists) {
        setState(() {
          _selectedCategory = merchantDoc['storeCategory'] ?? 'Electronics';
        });
      }
    }
  }

  Future<void> _addOrEditStock() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final stockCollection = FirebaseFirestore.instance
              .collection('Merchant')
              .doc(user.email)
              .collection('Stock');

          // Check if a product with the same name already exists
          final existingNameSnapshot = await stockCollection
              .where('name', isEqualTo: _nameController.text.trim())
              .get();

          if (existingNameSnapshot.docs.isNotEmpty && !widget.isEdit) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Product name already exists in stock')),
            );
            return;
          }

          if (widget.isEdit) {
            // Editing mode
            await stockCollection.doc(widget.productId).update({
              'name': _nameController.text.trim(),
              'category': _selectedCategory,
              'price': _priceController.text.trim(),
              'qty': int.parse(_stockController.text.trim()),
              'warranty': '${_warrantyController.text.trim()} $_warrantyUnit',
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock updated successfully')),
            );
          } else {
            // Adding new stock
            final existingDoc = await stockCollection
                .doc(_productIdController.text.trim())
                .get();
            if (existingDoc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Product ID already exists in stock')),
              );
              return;
            }

            await stockCollection.doc(_productIdController.text.trim()).set({
              'name': _nameController.text.trim(),
              'category': _selectedCategory,
              'price': _priceController.text.trim(),
              'qty': int.parse(_stockController.text.trim()),
              'warranty': '${_warrantyController.text.trim()} $_warrantyUnit',
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stock added successfully')),
            );
          }

          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add/edit stock: $e')),
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    final scannedProductId = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (scannedProductId != null && !widget.isEdit) {
      _productIdController.text = scannedProductId;
    }
  }

  Future<void> _generateProductId() async {
    var uuid = const Uuid();
    final generatedId = uuid.v4();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final stockCollection = FirebaseFirestore.instance
          .collection('Merchant')
          .doc(user.email)
          .collection('Stock');
      final existingDoc = await stockCollection.doc(generatedId).get();
      if (existingDoc.exists) {
        await _generateProductId(); // Recursively generate until unique
      } else {
        _productIdController.text = generatedId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.isEdit ? 'Edit Stock' : 'Add Stock'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildTextField(
                      controller: _productIdController,
                      label: 'Product ID:',
                      suffixIcon: widget.isEdit
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner),
                                  onPressed: _scanBarcode,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.auto_fix_high),
                                  onPressed: _generateProductId,
                                ),
                              ],
                            ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the product ID';
                        }
                        return null;
                      },
                      enabled: !widget.isEdit,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name:',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      controller: _priceController,
                      label: 'Price: RM',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the price';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) < 0) {
                          return 'Price must be a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      controller: _stockController,
                      label: 'Stock:',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the stock quantity';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'Stock must be a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildWarrantyField(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addOrEditStock,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(
                      double.infinity, 48), // Make the button full width
                ),
                child: Text(widget.isEdit ? 'UPDATE STOCK' : 'ADD TO STOCK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              enabled: enabled,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: validator,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            child: Text(
              'Category:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            child: Text(
              'Warranty:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _warrantyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the warranty duration';
                }
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'Warranty must be a positive number';
                }
                return null;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _warrantyUnit,
            onChanged: (String? newValue) {
              setState(() {
                _warrantyUnit = newValue!;
              });
            },
            items: <String>['day(s)', 'month(s)', 'year(s)']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
