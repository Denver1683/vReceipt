// ignore_for_file: library_private_types_in_public_api, unused_local_variable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:vreceipt_merchant/widgets/hamburger_menu.dart';
import 'package:vreceipt_merchant/widgets/shopping_receipt.dart';
import 'package:vreceipt_merchant/widgets/sort_filters.dart';
import 'package:vreceipt_merchant/screen/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  String searchQuery = '';
  double totalPriceMin = 0.00;
  double totalPriceMax = 99999999999.00;
  double productPriceMin = 0.00;
  double productPriceMax = 999999999999.00;
  String category = '';
  DateTime? startDate;
  DateTime? endDate;
  String sortBy = 'Date of purchase';
  bool ascending = false;
  bool showVoidTransactions = false; // Toggle for showing void transactions

  ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
    _pageController.addListener(() {
      currentPageNotifier.value = _pageController.page?.round() ?? 0;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    currentPageNotifier.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('Merchant')
        .doc(user.email)
        .collection('TrHistory')
        .orderBy('trdate', descending: true)
        .snapshots();
  }

  Future<void> _shareAsPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final products = List<String>.from(data['prodname'] ?? []);
    final quantities = List<int>.from(data['qty'] ?? []);
    final prices = List<String>.from(data['prodprice'] ?? []);
    final doublePrices = prices.map((price) => double.parse(price)).toList();
    final subtotals =
        List<double>.from(doublePrices.asMap().entries.map((entry) {
      final index = entry.key;
      return entry.value * quantities[index];
    }));

    final subtotal = data['subtotal'] != null
        ? (data['subtotal'] as List<dynamic>)
            .map((s) => double.tryParse(s.toString()) ?? 0.0)
            .reduce((a, b) => a + b)
        : null;
    final tax = data['totalTax'] != null
        ? double.tryParse(data['totalTax'].toString()) ?? 0.0
        : null;
    final serviceCharge = data['totalServiceCharge'] != null
        ? double.tryParse(data['totalServiceCharge'].toString()) ?? 0.0
        : null;
    final taxPercentage = data['taxPercentage'] != null
        ? double.tryParse(data['taxPercentage'].toString()) ?? 0.0
        : null;
    final serviceChargePercentage = data['serviceChargePercentage'] != null
        ? double.tryParse(data['serviceChargePercentage'].toString()) ?? 0.0
        : null;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  data['storename'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  data['storeadd'] ?? '',
                  style: const pw.TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      child: pw.Text('Product Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      child: pw.Text('Quantity',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      child: pw.Text('Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      child: pw.Text('Subtotal',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...products.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(product)),
                    pw.Expanded(child: pw.Text(quantities[index].toString())),
                    pw.Expanded(child: pw.Text('RM ${doublePrices[index]}')),
                    pw.Expanded(child: pw.Text('RM ${subtotals[index]}')),
                  ],
                );
              }).toList(),
              if (tax! > 0 || serviceCharge! > 0) pw.Divider(thickness: 2),
              if (tax > 0 || serviceCharge! > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('RM ${subtotal!.toStringAsFixed(2)}'),
                  ],
                ),
              if (tax > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax (${taxPercentage!.toStringAsFixed(2)}%)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('RM ${tax.toStringAsFixed(2)}'),
                  ],
                ),
              if (serviceCharge != null && serviceCharge > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Service Charge (${serviceChargePercentage!.toStringAsFixed(2)}%)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('RM ${serviceCharge.toStringAsFixed(2)}'),
                  ],
                ),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('RM ${data['total']}'),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Transaction ID: ${data['transactionId']}'),
              pw.Text('Transaction Date: ${data['trdate']}'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file =
        File('${output.path}/transaction_${data['transactionId']}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareFiles([file.path], text: 'Here is my transaction');
  }

  void _showFilterSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SortFilterMenu(
          totalPriceMin: totalPriceMin,
          totalPriceMax: totalPriceMax,
          productPriceMin: productPriceMin,
          productPriceMax: productPriceMax,
          category: category,
          startDate: startDate,
          endDate: endDate,
          sortBy: sortBy,
          ascending: ascending,
          onApply: (
            double newTotalPriceMin,
            double newTotalPriceMax,
            double newProductPriceMin,
            double newProductPriceMax,
            String newCategory,
            DateTime? newStartDate,
            DateTime? newEndDate,
            String newSortBy,
            bool newAscending,
          ) {
            if (mounted) {
              setState(() {
                totalPriceMin = newTotalPriceMin;
                totalPriceMax = newTotalPriceMax;
                productPriceMin = newProductPriceMin;
                productPriceMax = newProductPriceMax;
                category = newCategory;
                startDate = newStartDate;
                endDate = newEndDate;
                sortBy = newSortBy;
                ascending = newAscending;
              });

              // Reset the page view and current page notifier to the first page
              _pageController.jumpToPage(0);
              currentPageNotifier.value = 0;
            }
          },
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
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text('Transaction History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const TransactionScreen(selectedItems: [])),
              );
            },
          ),
        ],
      ),
      drawer: const HamburgerMenu(),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Transaction History'),
              Switch(
                value: showVoidTransactions,
                onChanged: (bool value) {
                  setState(() {
                    showVoidTransactions = value;
                  });

                  // Reset the page view and current page notifier to the first page
                  //_pageController.jumpToPage(0);
                  currentPageNotifier.value = 0;
                },
              ),
              const Text('Voided Transactions'),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTransactionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error fetching transactions.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }

                final transactions = snapshot.data!.docs.where((doc) {
                  final storeName =
                      (doc['storename'] ?? '').toString().toLowerCase();
                  final products = List<String>.from(doc['prodname'] ?? [])
                      .map((product) => product.toLowerCase())
                      .toList();
                  final productPrices =
                      List<String>.from(doc['prodprice'] ?? []);
                  final searchLower = searchQuery.toLowerCase();
                  final transactionId = doc.id.toLowerCase();
                  final customerName =
                      (doc['custname'] ?? '').toString().toLowerCase();
                  final total = double.tryParse(doc['total'].toString()) ?? 0;
                  final date = DateTime.parse(doc['trdate']);
                  final categories = List<String>.from(doc['category'] ?? []);
                  final voidStatus = doc['void'] ?? false;

                  final matchesFilters = total >= totalPriceMin &&
                      total <= totalPriceMax &&
                      productPrices.any((price) {
                        final parsedPrice =
                            double.tryParse(price.toString()) ?? 0;
                        return parsedPrice >= productPriceMin &&
                            parsedPrice <= productPriceMax;
                      }) &&
                      (category.isEmpty ||
                          categories.any((cat) => cat
                              .toLowerCase()
                              .contains(category.toLowerCase()))) &&
                      (startDate == null || date.isAfter(startDate!)) &&
                      (endDate == null || date.isBefore(endDate!)) &&
                      voidStatus == showVoidTransactions;

                  final matchesSearch = storeName.contains(searchLower) ||
                      products
                          .any((product) => product.contains(searchLower)) ||
                      transactionId.contains(searchLower) ||
                      customerName.contains(searchLower) ||
                      total.toString().contains(searchLower) ||
                      date.toString().contains(searchLower) ||
                      productPrices.any(
                          (price) => price.toString().contains(searchLower));

                  return matchesFilters && matchesSearch;
                }).toList();

                if (transactions.isEmpty) {
                  return const Center(child: Text('No data found.'));
                }

                transactions.sort((a, b) {
                  if (sortBy == 'Date of purchase') {
                    return ascending
                        ? DateTime.parse(a['trdate'])
                            .compareTo(DateTime.parse(b['trdate']))
                        : DateTime.parse(b['trdate'])
                            .compareTo(DateTime.parse(a['trdate']));
                  } else if (sortBy == 'Name of Customer') {
                    return ascending
                        ? a['custname'].compareTo(b['custname'])
                        : b['custname'].compareTo(a['custname']);
                  } else if (sortBy == 'Name of product') {
                    return ascending
                        ? a['prodname'][0].compareTo(b['prodname'][0])
                        : b['prodname'][0].compareTo(a['prodname'][0]);
                  }
                  return 0;
                });

                // Reset to first page if the transactions list has changed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients &&
                      currentPageNotifier.value != 0) {
                    _pageController.jumpToPage(0);
                    currentPageNotifier.value = 0;
                  }
                });

                return Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final products =
                              List<String>.from(transaction['prodname']);
                          final quantities = List<int>.from(transaction['qty']);
                          final prices =
                              List<String>.from(transaction['prodprice']);
                          final warranties =
                              List<String>.from(transaction['prodwarranty']);
                          final categories =
                              List<String>.from(transaction['category']);
                          final payBy = transaction['payBy'];

                          final subtotalList =
                              List<String>.from(transaction['subtotal']);

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: ShoppingReceipt(
                                    title: transaction['custname'] ?? '',
                                    products: products,
                                    quantities: quantities,
                                    prices: prices
                                        .map((p) => double.tryParse(p) ?? 0)
                                        .toList(),
                                    storeAddress: transaction['storeadd'] ?? '',
                                    storeName: transaction['storename'] ?? '',
                                    total: double.parse(
                                        transaction['total'].toString()),
                                    trDate: transaction['trdate'] ?? '',
                                    warranties: warranties,
                                    id: transaction.id,
                                    custName: transaction['custname'] ?? '',
                                    custId: transaction['uid'].toString(),
                                    categories: categories,
                                    isVoid: transaction['void'] ?? false,
                                    subtotal: transaction['subtotal'] != null
                                        ? (transaction['subtotal']
                                                as List<dynamic>)
                                            .map((s) =>
                                                double.tryParse(s.toString()) ??
                                                0.0)
                                            .reduce((a, b) => a + b)
                                        : null,
                                    tax: double.tryParse(
                                        transaction['totalTax'].toString()),
                                    serviceCharge: double.tryParse(
                                        transaction['totalServiceCharge']
                                            .toString()),
                                    taxPercentage: double.tryParse(
                                        transaction['taxPercentage']
                                            .toString()),
                                    serviceChargePercentage: double.tryParse(
                                        transaction['serviceChargePercentage']
                                            .toString()),
                                    payBy: payBy,
                                  ),
                                ),
                                if (!(transaction['void'] ?? false))
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        _shareAsPdf(transaction.data()
                                            as Map<String, dynamic>);
                                      },
                                      icon: const Icon(Icons.share),
                                    ),
                                  ),
                                if (transaction['custname'] == 'Customer' &&
                                    showVoidTransactions == false)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        _confirmVoidTransaction(transaction.id);
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                  ),
                                FutureBuilder<DocumentSnapshot>(
                                  future:
                                      _checkCustomerTransaction(transaction.id),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<DocumentSnapshot>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox.shrink();
                                    }
                                    if (snapshot.hasError) {
                                      return const SizedBox.shrink();
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      final customerTransaction =
                                          snapshot.data!;
                                      final isDeleted =
                                          customerTransaction['deleted'] ==
                                              true;
                                      if (isDeleted) {
                                        return Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: IconButton(
                                            onPressed: () {
                                              _confirmVoidTransaction(
                                                  transaction.id);
                                            },
                                            icon: const Icon(Icons.close),
                                          ),
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (transactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ValueListenableBuilder<int>(
                          valueListenable: currentPageNotifier,
                          builder: (context, currentPage, child) {
                            return Text(
                              '${currentPage + 1} out of ${transactions.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _showFilterSortMenu,
            child: const Text('Filter | Sort'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText:
                    'Search by Customer Name, Date, Product, Total, Price, or Transaction ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }

  Future<void> _confirmVoidTransaction(String transactionId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Void'),
          content: const Text(
              'Are you sure you want to void this transaction? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Void'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _voidTransaction(transactionId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<DocumentSnapshot<Object?>> _checkCustomerTransaction(
      String transactionId) async {
    final customerQuerySnapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .where('Transactions.$transactionId', isNotEqualTo: null)
        .limit(1)
        .get();

    if (customerQuerySnapshot.docs.isNotEmpty) {
      final customerEmail = customerQuerySnapshot.docs.first.id;

      final customerTransactionRef = FirebaseFirestore.instance
          .collection('Customer')
          .doc(customerEmail)
          .collection('Transactions')
          .doc(transactionId);

      final customerTransactionSnapshot = await customerTransactionRef.get();

      if (customerTransactionSnapshot.exists) {
        return customerTransactionSnapshot;
      } else {
        throw Exception("Transaction not found in customer records");
      }
    } else {
      throw Exception("Customer transaction not found");
    }
  }

  Future<void> _voidTransaction(String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final transactionRef = FirebaseFirestore.instance
        .collection('Merchant')
        .doc(user.email)
        .collection('TrHistory')
        .doc(transactionId);

    final transactionSnapshot = await transactionRef.get();
    if (!transactionSnapshot.exists) {
      throw Exception("Transaction not found in merchant records");
    }

    try {
      final customerUid = transactionSnapshot['uid'];

      if (customerUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Customer')
            .where('uid', isEqualTo: customerUid)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          final customerEmail = userDoc.docs.first.id;

          final customerTransactionRef = FirebaseFirestore.instance
              .collection('Customer')
              .doc(customerEmail)
              .collection('Transactions')
              .doc(transactionId);

          final customerTransactionSnapshot =
              await customerTransactionRef.get();

          if (customerTransactionSnapshot.exists &&
              customerTransactionSnapshot['deleted'] == true) {
            await customerTransactionRef.delete();

            await transactionRef.update({'void': true});
          } else {
            throw Exception(
                "Cannot void the transaction as it's not deleted in customer records.");
          }
        } else {
          throw Exception("Customer email not found for the given UID.");
        }
      } else {
        throw Exception("Customer UID is not available in the transaction.");
      }
    } catch (e) {
      await transactionRef.update({'void': true});
    }
  }
}
