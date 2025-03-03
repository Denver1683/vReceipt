// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:vreceipt_customer/widgets/shopping_receipt.dart';
import 'package:vreceipt_customer/widgets/hamburger_menu.dart';
import 'package:vreceipt_customer/screen/add_receipt.dart';
import 'package:vreceipt_customer/widgets/sort_filters.dart';
import 'package:vreceipt_customer/widgets/capsule.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String customerName = '';
  ValueNotifier<Map<String, dynamic>> merchantDetailsNotifier =
      ValueNotifier<Map<String, dynamic>>({});
  ValueNotifier<bool> isExpandedNotifier = ValueNotifier<bool>(false);
  String searchQuery = ''; // Add search query
  double totalPriceMin = 0;
  double totalPriceMax = 99999999999;
  double productPriceMin = 0;
  double productPriceMax = 999999999999;
  String category = '';
  DateTime? startDate;
  DateTime? endDate;
  String sortBy = 'Date of purchase';
  bool ascending = false;
  bool showDeletedTransactions = false;
  final PageController _pageController = PageController();
  ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _fetchCustomerName();
    _pageController.addListener(() {
      currentPageNotifier.value = _pageController.page?.round() ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    isExpandedNotifier.dispose();
    merchantDetailsNotifier.dispose();
    currentPageNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .get();
      if (mounted) {
        setState(() {
          customerName = doc.data()?['name'] ?? 'Customer';
        });
      }
    }
  }

  Future<void> _fetchMerchantDetails(String storeId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('storeid', isEqualTo: storeId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      merchantDetailsNotifier.value = {
        ...data,
        'email': doc.id,
      };
    } else {
      merchantDetailsNotifier.value = {};
    }
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('Customer')
        .doc(user.email)
        .collection('Transactions')
        .snapshots();
  }

  Future<void> _toggleFavorite(String docId, bool currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .collection('Transactions')
          .doc(docId)
          .update({'isFavorite': !currentStatus});
      setState(() {});

      _pageController.jumpToPage(0);
      currentPageNotifier.value = 0;
    }
  }

  Future<void> _shareAsPdf(Map<String, dynamic> data, String docId) async {
    final pdf = pw.Document();

    final products = List<String>.from(data['product'] ?? []);
    final quantities = List<int>.from(data['qty'] ?? []);
    final prices = List<String>.from(data['price'] ?? []);
    final doublePrices = prices.map((price) => double.parse(price)).toList();
    final subtotals =
        List<double>.from(doublePrices.asMap().entries.map((entry) {
      final index = entry.key;
      return entry.value * quantities[index];
    }));

    final subtotal = data['pretaxtotal'] != null
        ? double.tryParse(data['pretaxtotal'].toString()) ?? 0.0
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
                  data['storeaddress'] ?? '',
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
              pw.Text('Transaction ID: ${data['trid']}'),
              pw.Text('Transaction Date: ${data['trdate']}'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/transaction_${data['trid']}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareFiles([file.path], text: 'Here is my transaction');
  }

  Future<void> _deleteTransaction(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .collection('Transactions')
          .doc(docId)
          .update({'deleted': true});

      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .collection('Events')
          .where('transactionId', isEqualTo: docId)
          .get();

      for (var doc in eventsSnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction marked as deleted')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String storeId) async {
    final storeDetails = await fetchStoreDetails(storeId);
    final phoneNumber = storeDetails['phoneNumber'];
    if (phoneNumber!.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      await launchUrl(launchUri);
    }
  }

  Future<Map<String, String>> fetchStoreDetails(String storeId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('storeid', isEqualTo: storeId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      return {
        'email': doc.id,
        'phoneNumber': data['phoneNumber'] ?? '',
      };
    } else {
      return {
        'email': '',
        'phoneNumber': '',
      };
    }
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

  Future<void> _showDeleteConfirmationDialog(String docId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Deleting this receipt will void your warranty and the action cannot be undone.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTransaction(docId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text('Hi, $customerName'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.history,
              color:
                  showDeletedTransactions ? Colors.red : Colors.lightBlueAccent,
            ),
            onPressed: () {
              setState(() {
                showDeletedTransactions = !showDeletedTransactions;
              });
            },
          ),
        ],
      ),
      drawer: const HamburgerMenu(),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _getTransactionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                // Clear the merchant details when no data is found
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  merchantDetailsNotifier.value = {};
                });

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 550,
                      child: Center(
                        child: Text(
                          'No transactions found.',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showFilterSortMenu,
                      child: const Text('Sort | Filter'),
                    ),
                  ],
                );
              }

              final transactions = snapshot.data!.docs.where((doc) {
                final storeName =
                    (doc['storename'] ?? '').toString().toLowerCase();
                final products = List<String>.from(doc['product'] ?? [])
                    .map((product) => product.toLowerCase());
                final productPrices = List<String>.from(doc['price'] ?? []);
                final categories = List<String>.from(doc['category'] ?? []);
                final searchLower = searchQuery.toLowerCase();
                final transactionId = doc.id.toLowerCase();
                final customerName =
                    (doc['custname'] ?? '').toString().toLowerCase();
                final total = doc['total'] ?? 0.0;
                final date = DateTime.parse(doc['trdate']);
                final deleted = doc['deleted'] ?? false;

                final matchesFilters =
                    double.parse(doc['total']) >= totalPriceMin &&
                        double.parse(doc['total']) <= totalPriceMax &&
                        productPrices.any((price) =>
                            double.tryParse(price)! >= productPriceMin &&
                            double.tryParse(price)! <= productPriceMax) &&
                        (category.isEmpty ||
                            categories.any((cat) => cat
                                .toLowerCase()
                                .contains(category.toLowerCase()))) &&
                        (startDate == null || date.isAfter(startDate!)) &&
                        (endDate == null || date.isBefore(endDate!)) &&
                        deleted == showDeletedTransactions;

                final matchesSearch = storeName.contains(searchLower) ||
                    products.any((product) => product.contains(searchLower)) ||
                    transactionId.contains(searchLower) ||
                    customerName.contains(searchLower) ||
                    total.toString().contains(searchLower) ||
                    date.toString().contains(searchLower) ||
                    productPrices
                        .any((price) => price.toString().contains(searchLower));

                return matchesFilters && matchesSearch;
              }).toList();

              if (transactions.isEmpty) {
                // Clear the merchant details when no matching data is found
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  merchantDetailsNotifier.value = {};
                });

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 550,
                      child: Center(
                        child: Text(
                          'No data found.',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showFilterSortMenu,
                      child: const Text('Sort | Filter'),
                    ),
                  ],
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (merchantDetailsNotifier.value.isEmpty) {
                  _fetchMerchantDetails(transactions[0]['storeid']);
                }
              });

              transactions.sort((a, b) {
                if (a['isFavorite'] != b['isFavorite']) {
                  return a['isFavorite'] ? -1 : 1;
                }
                if (sortBy == 'Date of purchase') {
                  return ascending
                      ? DateTime.parse(a['trdate'])
                          .compareTo(DateTime.parse(b['trdate']))
                      : DateTime.parse(b['trdate'])
                          .compareTo(DateTime.parse(a['trdate']));
                } else if (sortBy == 'Name of Shop') {
                  return ascending
                      ? a['storename'].compareTo(b['storename'])
                      : b['storename'].compareTo(a['storename']);
                } else if (sortBy == 'Name of product') {
                  return ascending
                      ? a['product'][0].compareTo(b['product'][0])
                      : b['product'][0].compareTo(a['product'][0]);
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
                  const SizedBox(height: 80),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: transactions.length,
                      onPageChanged: (index) {
                        final transaction = transactions[index];
                        _fetchMerchantDetails(transaction['storeid']);
                      },
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final products =
                            List<String>.from(transaction['product'] ?? []);
                        final quantities =
                            List<int>.from(transaction['qty'] ?? []);
                        final prices =
                            List<String>.from(transaction['price'] ?? []);
                        final doublePrices =
                            prices.map((price) => double.parse(price)).toList();
                        final warranties =
                            List<String>.from(transaction['warranty'] ?? []);
                        final isFavorite = transaction['isFavorite'] ?? false;
                        final categories =
                            List<String>.from(transaction['category']);

                        final subtotal = transaction['pretaxtotal'] != null
                            ? double.tryParse(transaction['pretaxtotal'])
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 550,
                                child: ReceiptWidget(
                                  name: transaction['custname'] ?? '',
                                  id: transaction.id,
                                  products: products,
                                  quantities: quantities,
                                  prices: doublePrices,
                                  storeAddress:
                                      transaction['storeaddress'] ?? '',
                                  storeName: transaction['storename'] ?? '',
                                  storeId: transaction['storeid'] ?? '',
                                  total:
                                      double.parse(transaction['total'] ?? '0'),
                                  trDate: transaction['trdate'] ?? '',
                                  warranties: warranties,
                                  trid: transaction['trid'].toString(),
                                  categories: categories,
                                  onFavoriteToggle: () {
                                    _toggleFavorite(transaction.id, isFavorite);
                                  },
                                  onDelete: () {
                                    _showDeleteConfirmationDialog(
                                        transaction.id);
                                  },
                                  onShare: () {
                                    _shareAsPdf(
                                        transaction.data()
                                            as Map<String, dynamic>,
                                        transaction.id);
                                  },
                                  fetchStoreDetails: fetchStoreDetails,
                                  subtotal: subtotal,
                                  tax: transaction['totalTax'] != null
                                      ? double.tryParse(transaction['totalTax'])
                                      : null,
                                  serviceCharge:
                                      transaction['totalServiceCharge'] != null
                                          ? double.tryParse(
                                              transaction['totalServiceCharge'])
                                          : null,
                                  taxPercentage:
                                      transaction['taxPercentage'] != null
                                          ? double.tryParse(
                                              transaction['taxPercentage'])
                                          : null,
                                  serviceChargePercentage:
                                      transaction['serviceChargePercentage'] !=
                                              null
                                          ? double.tryParse(transaction[
                                              'serviceChargePercentage'])
                                          : null,
                                  payBy: transaction['payBy'],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Visibility(
                                  visible: !showDeletedTransactions,
                                  child: IconButton(
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: isFavorite
                                          ? Colors.yellow
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _toggleFavorite(
                                          transaction.id, isFavorite);
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    if (!showDeletedTransactions) ...[
                                      IconButton(
                                        icon: const Icon(Icons.picture_as_pdf),
                                        onPressed: () => _shareAsPdf(
                                            transaction.data()
                                                as Map<String, dynamic>,
                                            transaction.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _showDeleteConfirmationDialog(
                                                transaction.id),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Row(
                                  children: [
                                    if (!showDeletedTransactions)
                                      IconButton(
                                        icon: const Icon(Icons.phone),
                                        onPressed: () async {
                                          await _makePhoneCall(
                                              transaction['storeid']);
                                        },
                                      ),
                                  ],
                                ),
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
                  ElevatedButton(
                    onPressed: _showFilterSortMenu,
                    child: const Text('Sort | Filter'),
                  ),
                  const SizedBox(height: 90),
                ],
              );
            },
          ),
          ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: merchantDetailsNotifier,
            builder: (context, merchantDetails, child) {
              if (merchantDetails.isEmpty) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Capsule(
                  storeName: merchantDetails['storename'] ?? '',
                  storeAddress: merchantDetails['storeadd'] ?? '',
                  phoneNumber: merchantDetails['phoneNumber'] ?? '',
                  email: merchantDetails['email'] ?? '',
                  profileImageUrl: merchantDetails['imageURL'] ?? '',
                  workingDays: merchantDetails['workingDays'] != null
                      ? List<bool>.from(merchantDetails['workingDays'])
                      : [],
                  startTimes: merchantDetails['startTimes'] != null
                      ? List<String>.from(merchantDetails['startTimes'])
                      : [],
                  endTimes: merchantDetails['endTimes'] != null
                      ? List<String>.from(merchantDetails['endTimes'])
                      : [],
                  note: merchantDetails['note'] ?? '',
                  isExpandedNotifier: isExpandedNotifier,
                  storeId: merchantDetails['storeid'] ?? '',
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SearchBar(
              onSearch: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 75),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddReceiptScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const SearchBar({super.key, required this.onSearch});

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText:
              'Search by Store Name, Date, Product, Total, Price, or Transaction ID',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
          suffixIcon: const Icon(Icons.search),
        ),
        onChanged: widget.onSearch,
      ),
    );
  }
}
