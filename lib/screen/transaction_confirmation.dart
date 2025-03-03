// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vreceipt_merchant/models/product_provider.dart';
import 'checkout.dart'; // Ensure this is the correct path to your checkout.dart file
import 'package:vreceipt_merchant/widgets/shopping_receipt.dart'; // Ensure this is the correct path to your shopping_receipt.dart file
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> transactionInfo;

  const TransactionConfirmationScreen({
    Key? key,
    required this.transactionInfo,
  }) : super(key: key);

  @override
  _TransactionConfirmationScreenState createState() =>
      _TransactionConfirmationScreenState();
}

class _TransactionConfirmationScreenState
    extends State<TransactionConfirmationScreen> {
  String _selectedPaymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    // Initialize the selected payment method to the existing value in transactionInfo or default to 'Cash'
    _selectedPaymentMethod = widget.transactionInfo['payBy'] ?? 'Cash';
  }

  @override
  Widget build(BuildContext context) {
    final productNames = List<String>.from(
        widget.transactionInfo['prodname'].map((item) => item.toString()));
    final quantities = List<int>.from(widget.transactionInfo['qty']
        .map((item) => int.parse(item.toString())));
    final prices = List<double>.from(widget.transactionInfo['prodprice']
        .map((item) => double.parse(item.toString())));
    final warranties = List<String>.from(
        widget.transactionInfo['prodwarranty'].map((item) => item.toString()));
    final categories = List<String>.from(
        widget.transactionInfo['category'].map((item) => item.toString()));

    final subtotalList = List<double>.from(
      prices.asMap().entries.map((entry) {
        final index = entry.key;
        final price = entry.value;
        final quantity = quantities[index];
        return price * quantity;
      }),
    );

    final subtotal = subtotalList.reduce((a, b) => a + b);
    final pretaxtotal =
        double.parse(widget.transactionInfo['pretaxtotal'].toString());
    final tax = double.parse(widget.transactionInfo['totalTax'].toString());
    final serviceCharge =
        double.parse(widget.transactionInfo['totalServiceCharge'].toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transaction'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Revert stock logic (same as before)
            final String? userEmail = FirebaseAuth.instance.currentUser?.email;
            if (userEmail != null) {
              for (var item
                  in widget.transactionInfo['prodname'].asMap().entries) {
                String productId = widget.transactionInfo['prodname'][item.key];
                int quantity = widget.transactionInfo['qty'][item.key];

                final DocumentReference productRef = FirebaseFirestore.instance
                    .collection('Merchant')
                    .doc(userEmail)
                    .collection('Stock')
                    .doc(productId);

                await FirebaseFirestore.instance
                    .runTransaction((transaction) async {
                  DocumentSnapshot snapshot = await transaction.get(productRef);
                  if (snapshot.exists) {
                    int currentStock = snapshot['qty'];
                    int newStock = currentStock + quantity;
                    transaction.update(productRef, {'qty': newStock});
                  }
                });
              }
            }

            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ShoppingReceipt(
                title: 'Receipt',
                products: productNames,
                quantities: quantities,
                prices: prices,
                storeAddress: widget.transactionInfo['storeadd'],
                storeName: widget.transactionInfo['storename'],
                total: double.parse(widget.transactionInfo['total']),
                trDate: widget.transactionInfo['trdate'],
                warranties: warranties,
                id: widget.transactionInfo['transactionId'],
                custName: 'Customer',
                custId: '0',
                categories: categories,
                isVoid: false,
                subtotal: subtotal,
                tax: tax,
                serviceCharge: serviceCharge,
                taxPercentage:
                    double.parse(widget.transactionInfo['taxPercentage']),
                serviceChargePercentage: double.parse(
                    widget.transactionInfo['serviceChargePercentage']),
                payBy:
                    _selectedPaymentMethod, // Use the selected payment method
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Payment Method:  '),
                DropdownButton<String>(
                  value: _selectedPaymentMethod,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue!;
                      widget.transactionInfo['payBy'] =
                          newValue; // Update the transactionInfo
                    });
                  },
                  items: <String>['Cash', 'Card', 'e-Wallet']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                widget.transactionInfo['custname'] = 'Customer';
                widget.transactionInfo['uid'] = 0;
                widget.transactionInfo['scanned'] = false;
                widget.transactionInfo['void'] = false;

                widget.transactionInfo['subtotal'] =
                    subtotalList.map((s) => s.toStringAsFixed(2)).toList();
                widget.transactionInfo['pretaxtotal'] =
                    pretaxtotal.toStringAsFixed(2);

                // Clear product in cart
                final productProvider = context.read<ProductProvider>();
                productProvider.clearQuantities();

                // Pass the transactionInfo to the CheckoutScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CheckoutScreen(transactionInfo: widget.transactionInfo),
                  ),
                );
              },
              child: const Text('Confirm Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
