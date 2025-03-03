import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vreceipt_merchant/screen/add_receipt.dart';
import 'package:vreceipt_merchant/screen/transaction_confirmation.dart';
import '../models/product_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TransactionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;

  const TransactionScreen({Key? key, required this.selectedItems})
      : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late List<Map<String, dynamic>> selectedItems;
  late String storeName;
  late String storeId;
  late String storeAddress;
  late String transactionId;
  late String transactionDate;
  double taxPercentage = 0.0;
  double serviceChargePercentage = 0.0;
  int totalTransactions = 0;
  bool _scanning = false;
  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  @override
  void initState() {
    super.initState();
    selectedItems = List<Map<String, dynamic>>.from(widget.selectedItems);
    _fetchStoreDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuantities();
    });
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshSelectedItems();
  }

  void _refreshSelectedItems() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          initialSelectedItems: selectedItems,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selectedItems = List<Map<String, dynamic>>.from(result);
        final productProvider = context.read<ProductProvider>();
        for (var item in selectedItems) {
          productProvider.setQuantity(item['id'], item['quantity']);
        }
      });
    }
  }

  void _initializeQuantities() {
    final productProvider = context.read<ProductProvider>();
    for (var item in selectedItems) {
      productProvider.setQuantity(item['id'], item['quantity']);
    }
  }

  Future<void> _fetchStoreDetails() async {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return;
    }

    final DocumentSnapshot storeSnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .get();

    if (!mounted) return;
    setState(() {
      storeName = storeSnapshot['storename'];
      storeAddress = storeSnapshot['storeadd'];
      storeId = storeSnapshot['storeid'].toString();
      taxPercentage = double.tryParse(storeSnapshot['tax'] ?? '0') ?? 0.0;
      serviceChargePercentage =
          double.tryParse(storeSnapshot['serviceCharge'] ?? '0') ?? 0.0;
    });

    await _fetchTransactionId();
  }

  Future<void> _fetchTransactionId() async {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return;
    }

    bool isUnique = false;

    while (!isUnique) {
      final String newTransactionId = const Uuid().v4();
      final QuerySnapshot trHistorySnapshot = await FirebaseFirestore.instance
          .collectionGroup('TrHistory')
          .where('transactionId', isEqualTo: newTransactionId)
          .get();

      if (trHistorySnapshot.docs.isEmpty) {
        setState(() {
          transactionId = newTransactionId;
          transactionDate = DateTime.now().toString();
          isUnique = true;
        });
      }
    }

    // Counting total transactions for the current merchant, excluding voided transactions
    final CollectionReference trHistoryCollection = FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('TrHistory');

    final QuerySnapshot currentMerchantTransactions =
        await trHistoryCollection.get();

    if (!mounted) return;
    setState(() {
      totalTransactions = currentMerchantTransactions.docs.where((doc) {
        final data =
            doc.data() as Map<String, dynamic>?; // Ensure data is a Map
        return data?['void'] != true; // Exclude transactions where void is true
      }).length;
    });
  }

  void _updateQuantity(int index, int change) async {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return;
    }

    final DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('Stock')
        .doc(selectedItems[index]['id'])
        .get();

    final int availableQuantity = itemSnapshot['qty'];

    if (!mounted) return;
    setState(() {
      int newQuantity = selectedItems[index]['quantity'] + change;
      if (newQuantity >= 1 && newQuantity <= availableQuantity) {
        selectedItems[index]['quantity'] = newQuantity;
        context
            .read<ProductProvider>()
            .setQuantity(selectedItems[index]['id'], newQuantity);
      } else if (newQuantity == 0) {
        _deleteItem(index);
      }
    });
  }

  void _deleteItem(int index) {
    if (!mounted) return;
    setState(() {
      String itemId = selectedItems[index]['id'];
      selectedItems.removeAt(index);
      context.read<ProductProvider>().setQuantity(itemId, 0);
    });
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (!_scanning && barcodeCapture.barcodes.isNotEmpty) {
      _mobileScannerController.stop();
      setState(() {
        _scanning = true;
      });
      _handleBarcodeScan(barcodeCapture.barcodes.first.rawValue!).then((_) {
        setState(() {
          _scanning = false;
        });
        _mobileScannerController.start();
      });
    }
  }

  Future<void> _handleBarcodeScan(String barcode) async {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return;
    }

    final DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('Stock')
        .doc(barcode)
        .get();

    if (productSnapshot.exists) {
      final productData = productSnapshot.data() as Map<String, dynamic>;
      setState(() {
        final existingIndex =
            selectedItems.indexWhere((item) => item['id'] == barcode);
        if (existingIndex != -1) {
          selectedItems[existingIndex]['quantity'] += 1;
        } else {
          selectedItems.add({
            'id': barcode,
            'title': productData['name'],
            'price': double.parse(productData['price'].toString()),
            'quantity': 1,
            'warranty': productData['warranty'],
            'category': productData['category'],
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found')),
      );
    }
  }

  void _navigateAndAddProducts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          initialSelectedItems: selectedItems,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selectedItems = List<Map<String, dynamic>>.from(result);
        final productProvider = context.read<ProductProvider>();
        for (var item in selectedItems) {
          productProvider.setQuantity(item['id'], item['quantity']);
        }
      });
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
            final productProvider = context.read<ProductProvider>();
            productProvider.clearQuantities();
            setState(() {
              selectedItems.clear();
            });
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        title: Text('Total Transactions: $totalTransactions'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black12,
              child: MobileScanner(
                controller: _mobileScannerController,
                onDetect: _onBarcodeDetect,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                final item = selectedItems[index];
                return Dismissible(
                  key: Key(item['id']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteItem(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['title']} deleted')),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: _buildTransactionItem(
                    context,
                    title: item['title'],
                    price: 'RM ${item['price'].toStringAsFixed(2)}',
                    quantity: item['quantity'],
                    id: item['id'],
                    note: '',
                    index: index,
                    warranty: item['warranty'],
                    category: item['category'],
                  ),
                );
              },
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 5, 80),
        child: FloatingActionButton(
          onPressed: _navigateAndAddProducts,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required String title,
    required String price,
    required int quantity,
    required String id,
    required String note,
    required int index,
    required String warranty,
    required String category,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
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
                'Warranty: $warranty | Category: $category',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$price x $quantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1
                            ? () {
                                _updateQuantity(index, -1);
                              }
                            : null,
                      ),
                      Text('$quantity'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _updateQuantity(index, 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (note.isNotEmpty)
                Text(
                  'Note: $note',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    double subtotal = selectedItems.fold(
      0.0,
      (sum, item) =>
          sum + (double.parse(item['price'].toString()) * item['quantity']),
    );

    double totalTax = subtotal * (taxPercentage / 100);
    double totalServiceCharge = subtotal * (serviceChargePercentage / 100);
    double totalPrice = subtotal + totalTax + totalServiceCharge;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculating subtotal array (price * quantity for each item)
    List<String> subtotalArray = selectedItems
        .map((item) =>
            (double.parse(item['price'].toString()) * item['quantity'])
                .toStringAsFixed(2))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (taxPercentage > 0 || serviceChargePercentage > 0)
            Text(
              'Subtotal: RM ${subtotal.toStringAsFixed(2)}',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
              ),
            ),
          if (taxPercentage > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Tax ($taxPercentage%): RM ${totalTax.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                ),
              ),
            ),
          if (serviceChargePercentage > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Service Charge ($serviceChargePercentage%): RM ${totalServiceCharge.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: RM ${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                ),
              ),
              ElevatedButton(
                onPressed: selectedItems.isEmpty
                    ? null
                    : () async {
                        final transactionInfo = {
                          'trdate': transactionDate,
                          'storeadd': storeAddress,
                          'storename': storeName,
                          'storeid': storeId,
                          'total': totalPrice.toString(),
                          'pretaxtotal': subtotal.toString(),
                          'totalTax': totalTax.toString(),
                          'totalServiceCharge': totalServiceCharge.toString(),
                          'taxPercentage': taxPercentage.toString(),
                          'serviceChargePercentage':
                              serviceChargePercentage.toString(),
                          'category': selectedItems
                              .map((item) => item['category'].toString())
                              .toList(),
                          'prodname': selectedItems
                              .map((item) => item['title'].toString())
                              .toList(),
                          'prodprice': selectedItems
                              .map((item) => item['price'].toStringAsFixed(2))
                              .toList(),
                          'prodwarranty': selectedItems
                              .map((item) => item['warranty'].toString())
                              .toList(),
                          'qty': selectedItems
                              .map((item) => item['quantity'])
                              .toList(),
                          'subtotal': subtotalArray,
                          'scanned': false,
                          'transactionId': transactionId,
                          'payBy': 'Cash'
                        };

                        // Deduct stock for each item
                        final String? userEmail =
                            FirebaseAuth.instance.currentUser?.email;
                        if (userEmail != null) {
                          for (var item in selectedItems) {
                            final DocumentReference productRef =
                                FirebaseFirestore.instance
                                    .collection('Merchant')
                                    .doc(userEmail)
                                    .collection('Stock')
                                    .doc(item['id']);

                            await FirebaseFirestore.instance
                                .runTransaction((transaction) async {
                              DocumentSnapshot snapshot =
                                  await transaction.get(productRef);
                              if (snapshot.exists) {
                                int currentStock = snapshot['qty'];
                                num newStock = currentStock - item['quantity'];
                                transaction
                                    .update(productRef, {'qty': newStock});
                              }
                            });
                          }
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionConfirmationScreen(
                                transactionInfo: transactionInfo),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.lightBlue : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Checkout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
