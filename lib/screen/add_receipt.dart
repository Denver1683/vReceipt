// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelectedItems;

  const AddProductScreen({super.key, required this.initialSelectedItems});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<DocumentSnapshot> _allStockItems = [];
  final ValueNotifier<List<DocumentSnapshot>> _filteredStockItemsNotifier =
      ValueNotifier([]);
  late List<Map<String, dynamic>> selectedItems;
  final Map<String, ValueNotifier<int>> _quantityNotifiers = {};

  @override
  void initState() {
    super.initState();
    selectedItems =
        List<Map<String, dynamic>>.from(widget.initialSelectedItems);
    _searchController.addListener(_filterStockItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStockItems);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterStockItems() {
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      _filteredStockItemsNotifier.value = _allStockItems.where((item) {
        final title = item['name'].toString().toLowerCase();
        return title.contains(query);
      }).toList();
    } else {
      _filteredStockItemsNotifier.value = _allStockItems;
    }
  }

  void _updateQuantity(String id, int change) async {
    final String userEmail = FirebaseAuth.instance.currentUser!.email!;
    final DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('Stock')
        .doc(id)
        .get();

    final int availableQuantity = itemSnapshot['qty'];

    final productProvider = context.read<ProductProvider>();
    final currentQuantity = productProvider.getQuantity(id);
    int newQuantity = currentQuantity + change;

    if (newQuantity >= 0 && newQuantity <= availableQuantity) {
      productProvider.setQuantity(id, newQuantity);

      final existingIndex =
          selectedItems.indexWhere((item) => item['id'] == id);
      if (newQuantity == 0) {
        if (existingIndex != -1) {
          selectedItems.removeAt(existingIndex);
        }
      } else {
        if (existingIndex != -1) {
          selectedItems[existingIndex]['quantity'] = newQuantity;
        } else {
          selectedItems.add({
            'title': itemSnapshot['name'],
            'price': double.parse(itemSnapshot['price'].toString()),
            'quantity': newQuantity,
            'id': id,
            'warranty': itemSnapshot['warranty'],
            'category': itemSnapshot['category'],
          });
        }
      }

      _quantityNotifiers[id] ??= ValueNotifier<int>(newQuantity);
      _quantityNotifiers[id]!.value = newQuantity;
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
            // Filter out items with quantity 0 before returning
            selectedItems.removeWhere((item) => item['quantity'] == 0);
            Navigator.pop(context, selectedItems);
          },
        ),
        title: const Text('Add Product'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text('No user is currently logged in.'));
            }

            final userEmail = snapshot.data!.email;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Merchant')
                  .doc(userEmail)
                  .collection('Stock')
                  .snapshots(),
              builder: (context, stockSnapshot) {
                if (stockSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!stockSnapshot.hasData ||
                    stockSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No stock items found.'));
                }

                _allStockItems = stockSnapshot.data!.docs;
                _filteredStockItemsNotifier.value =
                    _searchController.text.isEmpty
                        ? _allStockItems
                        : _filteredStockItemsNotifier.value;

                return Column(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<List<DocumentSnapshot>>(
                        valueListenable: _filteredStockItemsNotifier,
                        builder: (context, filteredStockItems, child) {
                          return ListView.builder(
                            itemCount: filteredStockItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredStockItems[index];
                              final itemId = item.id;
                              final availableQuantity = item['qty'] ?? 0;
                              final warranty =
                                  item['warranty'] ?? 'No warranty';
                              final category = item['category'];
                              final itemQuantity = context
                                  .watch<ProductProvider>()
                                  .getQuantity(itemId);

                              return _buildProductItem(
                                context,
                                title: item['name'],
                                price: double.parse(item['price'].toString()),
                                quantity: itemQuantity,
                                warranty: warranty,
                                category: category,
                                availableQuantity: availableQuantity,
                                id: itemId,
                                index: index,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(100.0),
                                ),
                                contentPadding: const EdgeInsets.all(8.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context, {
    required String title,
    required double price,
    required int quantity,
    required String warranty,
    required String category,
    required int availableQuantity,
    required String id,
    required int index,
  }) {
    _quantityNotifiers[id] ??= ValueNotifier<int>(quantity);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '$warranty | $category',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM ${price.toStringAsFixed(2)} x $quantity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 0
                          ? () {
                              _updateQuantity(id, -1);
                            }
                          : null,
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: _quantityNotifiers[id]!,
                      builder: (context, value, child) {
                        return Text('$value');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: quantity < availableQuantity
                          ? () {
                              _updateQuantity(id, 1);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'ID: $id',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Available: $availableQuantity',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
