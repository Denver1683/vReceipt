// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_stock.dart';

class ManageStockScreen extends StatefulWidget {
  const ManageStockScreen({super.key});

  @override
  _ManageStockScreenState createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<DocumentSnapshot> _allStockItems = [];
  final ValueNotifier<List<DocumentSnapshot>> _filteredStockItemsNotifier =
      ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStockItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStockItems);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filteredStockItemsNotifier.dispose();
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

  Future<void> _deleteItem(String userEmail, String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(userEmail)
          .collection('Stock')
          .doc(id)
          .delete();

      _allStockItems.removeWhere((item) => item.id == id);
      _filteredStockItemsNotifier.value = List.from(_allStockItems);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }

  Future<void> _updateQuantity(
      String userEmail, String id, int newQuantity) async {
    try {
      await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(userEmail)
          .collection('Stock')
          .doc(id)
          .update({'qty': newQuantity});

      _allStockItems = _allStockItems.map((item) {
        if (item.id == id) {
          final data = item.data() as Map<String, dynamic>;
          data['qty'] = newQuantity;
          return item;
        }
        return item;
      }).toList();

      _filteredStockItemsNotifier.value = List.from(_allStockItems);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity: $e')),
      );
    }
  }

  void _editStockItem(BuildContext context, String id) {
    final item = _allStockItems.firstWhere((item) => item.id == id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStockScreen(
          isEdit: true,
          productId: id,
          name: item['name'],
          price: item['price'].toString(),
          qty: item['qty'].toString(),
          warranty: item['warranty'],
          category: item['category'],
        ),
      ),
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
            Navigator.pop(context);
          },
        ),
        title: const Text('Manage Stock'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
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
                      if (stockSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (stockSnapshot.hasError) {
                        return const Center(
                            child: Text('Error fetching stock items.'));
                      }

                      if (!stockSnapshot.hasData ||
                          stockSnapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No stock items found.'));
                      }

                      _allStockItems = stockSnapshot.data!.docs;
                      _filterStockItems();

                      return ValueListenableBuilder<List<DocumentSnapshot>>(
                        valueListenable: _filteredStockItemsNotifier,
                        builder: (context, filteredStockItems, child) {
                          return ListView.builder(
                            itemCount: filteredStockItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredStockItems[index];
                              return GestureDetector(
                                onTap: () => _editStockItem(context, item.id),
                                child: Dismissible(
                                  key: Key(item.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    _deleteItem(userEmail, item.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('${item['name']} deleted')),
                                    );
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  child: _buildStockItem(
                                    context,
                                    userEmail: userEmail!,
                                    title: item['name'],
                                    price: 'RM ${item['price']}',
                                    quantity: item['qty'],
                                    id: item.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockItem(
    BuildContext context, {
    required String userEmail,
    required String title,
    required String price,
    required int quantity,
    required String id,
  }) {
    final TextEditingController _quantityController =
        TextEditingController(text: quantity.toString());

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
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 0
                          ? () {
                              int newQuantity =
                                  int.parse(_quantityController.text) - 1;
                              _updateQuantity(userEmail, id, newQuantity);
                              _quantityController.text = newQuantity.toString();
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 50,
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // Remove the border
                        ),
                        onFieldSubmitted: (value) {
                          int newQuantity = int.parse(value);
                          if (newQuantity >= 0) {
                            _updateQuantity(userEmail, id, newQuantity);
                            _quantityController.text = newQuantity.toString();
                          } else {
                            _quantityController.text = quantity.toString();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        int newQuantity =
                            int.parse(_quantityController.text) + 1;
                        _updateQuantity(userEmail, id, newQuantity);
                        _quantityController.text = newQuantity.toString();
                      },
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'ID: $id',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100.0),
        ), // Keep the border
        contentPadding: const EdgeInsets.all(8.0),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildSearchBar()),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'add_item_fab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStockScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
