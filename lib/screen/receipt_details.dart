// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, unnecessary_to_list_in_spreads, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vreceipt_customer/widgets/shopping_receipt.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ReceiptDetailsPage extends StatefulWidget {
  final String transactionId;

  const ReceiptDetailsPage({super.key, required this.transactionId});

  @override
  _ReceiptDetailsPageState createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  bool isFavorite = false;

  Future<Map<String, String>> fetchStoreDetails(String storeId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('storeid', isEqualTo: storeId)
        .limit(1)
        .get();
    final docId = querySnapshot.docs.first.id;
    if (querySnapshot.docs.isEmpty) {
      return {'email': '', 'phoneNumber': ''};
    }

    final data = querySnapshot.docs.first.data();
    return {
      'email': docId,
      'phoneNumber': data['phoneNumber'] ?? '',
    };
  }

  Future<void> _toggleFavorite(BuildContext context, String email, String docId,
      bool currentStatus) async {
    setState(() {
      isFavorite = !currentStatus;
    });
    await FirebaseFirestore.instance
        .collection('Customer')
        .doc(email)
        .collection('Transactions')
        .doc(docId)
        .update({'isFavorite': !currentStatus});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              currentStatus ? 'Removed from favorites' : 'Added to favorites')),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String email, String docId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must type 'void' to enable delete
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
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await _deleteTransaction(
                    context, email, docId); // Proceed with delete
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(
      BuildContext context, String email, String docId) async {
    await FirebaseFirestore.instance
        .collection('Customer')
        .doc(email)
        .collection('Transactions')
        .doc(docId)
        .update({'deleted': true});

    // Delete corresponding events
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(email)
        .collection('Events')
        .where('transactionId', isEqualTo: docId)
        .get();

    for (var doc in eventsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Close the screen after deletion
    if (mounted) {
      Navigator.of(context).pop(); // Close the screen after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction marked as deleted')),
      );
    }
  }

  Future<void> _shareAsPdf(
      BuildContext context, Map<String, dynamic> data, String docId) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final products = List<String>.from(data['product'] ?? []);
          final quantities = List<int>.from(data['qty'] ?? []);
          final prices = List<String>.from(data['price'] ?? []);
          final doublePrices =
              prices.map((price) => double.parse(price)).toList();
          final subtotals =
              List<double>.from(doublePrices.asMap().entries.map((entry) {
            final index = entry.key;
            return entry.value * quantities[index];
          }));

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  data['storename'] ?? '',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  data['storeaddress'] ?? '',
                  textAlign: pw.TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Receipt Details'),
        ),
        body: const Center(child: Text('No user is logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Customer')
            .doc(user.email)
            .collection('Transactions')
            .doc(widget.transactionId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text('Receipt not found. ${widget.transactionId}'));
          }

          final receiptData = snapshot.data!.data() as Map<String, dynamic>;
          final products = List<String>.from(receiptData['product'] ?? []);
          final quantities = List<int>.from(receiptData['qty'] ?? []);
          final prices = List<String>.from(receiptData['price'] ?? []);
          final doublePrices =
              prices.map((price) => double.parse(price)).toList();
          final warranties = List<String>.from(receiptData['warranty'] ?? []);
          final categories = List<String>.from(receiptData['category'] ?? []);
          isFavorite = receiptData['isFavorite'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                SizedBox(
                  height: 600,
                  child: ReceiptWidget(
                    name: receiptData['custname'],
                    id: widget.transactionId,
                    products: products,
                    quantities: quantities,
                    prices: doublePrices,
                    storeAddress: receiptData['storeaddress'],
                    storeName: receiptData['storename'],
                    storeId: receiptData['storeid'].toString(),
                    total: double.parse(receiptData['total']),
                    trDate: receiptData['trdate'],
                    warranties: warranties,
                    trid: receiptData['trid'].toString(),
                    categories: categories,
                    onFavoriteToggle: () {
                      _toggleFavorite(context, user.email!,
                          widget.transactionId, isFavorite);
                    },
                    onDelete: () {
                      _showDeleteConfirmationDialog(
                          context, user.email!, widget.transactionId);
                    },
                    onShare: () {
                      _shareAsPdf(context, receiptData, widget.transactionId);
                    },
                    fetchStoreDetails: fetchStoreDetails,
                    // Adding the new fields
                    subtotal: receiptData['pretaxtotal'] != null
                        ? double.tryParse(receiptData['pretaxtotal'])
                        : null,
                    tax: receiptData['totalTax'] != null
                        ? double.tryParse(receiptData['totalTax'])
                        : null,
                    serviceCharge: receiptData['totalServiceCharge'] != null
                        ? double.tryParse(receiptData['totalServiceCharge'])
                        : null,
                    taxPercentage: receiptData['taxPercentage'] != null
                        ? double.tryParse(receiptData['taxPercentage'])
                        : null,
                    serviceChargePercentage:
                        receiptData['serviceChargePercentage'] != null
                            ? double.tryParse(
                                receiptData['serviceChargePercentage'])
                            : null,
                    payBy: receiptData['payBy'],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.yellow : Colors.grey,
                    ),
                    onPressed: () {
                      _toggleFavorite(context, user.email!,
                          widget.transactionId, isFavorite);
                    },
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => _shareAsPdf(
                            context, receiptData, widget.transactionId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteConfirmationDialog(
                            context, user.email!, widget.transactionId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
