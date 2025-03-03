// ignore_for_file: library_private_types_in_public_api, unused_local_variable, use_build_context_synchronously, unnecessary_cast, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vreceipt_merchant/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:vreceipt_merchant/services/warranty_notifications.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> transactionInfo;

  const CheckoutScreen({
    Key? key,
    required this.transactionInfo,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _encryptedQrData;
  late encrypt.Key _key;
  late encrypt.IV _iv;
  bool _isLoading = true;
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _checkUserBlockedStatus();
    _fetchEncryptionKeys();
    _addTransactionToFirebase();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkUserBlockedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(user.email)
          .get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data?['blocked'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sorry, your account is suspended. Please contact customer service via email at admin@vreceipt.com.'),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await FirebaseAuth.instance.signOut();
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  Future<void> _fetchEncryptionKeys() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Key')
          .doc('Encryption')
          .get();

      if (mounted) {
        setState(() {
          _key = encrypt.Key.fromUtf8(doc.data()?['32bit']);
          _iv = encrypt.IV.fromUtf8(doc.data()?['16bit']);
          _encryptedQrData = _encryptData(
              widget.transactionInfo['transactionId'],
              FirebaseAuth.instance.currentUser?.email ?? '');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Failed to fetch encryption keys: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch encryption keys')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTransactionToFirebase() async {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('TrHistory')
        .doc(widget.transactionInfo['transactionId'])
        .set({
      ...widget.transactionInfo,
      'payBy': widget.transactionInfo['payBy'], // Include the payBy field
      'scanned': false, // Initially set scanned to false
    });
  }

  String _encryptData(String transactionId, String userEmail) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final data = 'app:vReceiptApp|$transactionId|$userEmail';
    print('Here is the transactionID and email $transactionId $userEmail');
    final encrypted = encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  void _showSendManuallyDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Receipt to Customer'),
          content: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Enter customer email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;
                setState(() {
                  _isSending = true;
                });

                bool success = await _sendReceiptToCustomer();

                if (mounted) {
                  setState(() {
                    _isSending = false;
                  });
                }
              },
              child: const Text('Send Receipt'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _sendReceiptToCustomer() async {
    try {
      final customerEmail = _emailController.text.trim();
      if (customerEmail.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid email address')),
          );
        }
        return false;
      }

      final customerDoc = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(customerEmail)
          .get();

      if (!customerDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer email does not exist')),
          );
        }
        return false;
      }

      final customerData = customerDoc.data();
      final String customerName = customerData?['name'] ?? "Customer";
      final int customerUid = customerData?['uid'] ?? 0;

      // Prepare the transaction data with the correct format
      final transactionData = {
        'category': widget.transactionInfo['category'],
        'custname': customerName,
        'isFavorite': false,
        'price': widget.transactionInfo['prodprice'],
        'product': widget.transactionInfo['prodname'],
        'qty': widget.transactionInfo['qty'],
        'storeaddress': widget.transactionInfo['storeadd'],
        'storeid': widget.transactionInfo['storeid'],
        'storename': widget.transactionInfo['storename'],
        'total': widget.transactionInfo['total'],
        'trdate': widget.transactionInfo['trdate'],
        'trid': widget.transactionInfo['transactionId'],
        'uid': customerUid,
        'warranty': widget.transactionInfo['prodwarranty'],
        'pretaxtotal': widget.transactionInfo['pretaxtotal'],
        'totalTax': widget.transactionInfo['totalTax'],
        'taxPercentage': widget.transactionInfo['taxPercentage'],
        'totalServiceCharge': widget.transactionInfo['totalServiceCharge'],
        'serviceChargePercentage':
            widget.transactionInfo['serviceChargePercentage'],
        'payBy': widget.transactionInfo['payBy'], // Include the payBy field
        'deleted': false
      };

      await FirebaseFirestore.instance
          .collection('Customer')
          .doc(customerEmail)
          .collection('Transactions')
          .doc(widget.transactionInfo['transactionId'])
          .set(transactionData);
      final warrantyNotifications = WarrantyNotifications();
      await warrantyNotifications.scheduleWarrantyNotifications(
          transactionData,
          widget.transactionInfo['trdate'],
          widget.transactionInfo['transactionId'],
          customerEmail);

      final String? userEmail = FirebaseAuth.instance.currentUser?.email;
      final transactionId = widget.transactionInfo['transactionId'];

      if (userEmail != null && mounted) {
        await FirebaseFirestore.instance
            .collection('Merchant')
            .doc(userEmail)
            .collection('TrHistory')
            .doc(transactionId)
            .update({
          'custname': customerName,
          'uid': customerUid,
          'scanned': true,
        });
      }

      return true;
    } catch (e) {
      print('Error sending receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occurred while sending the receipt')),
        );
      }
      return false;
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
            if (mounted) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
        ),
        title:
            Text('Transaction ID: ${widget.transactionInfo['transactionId']}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Merchant')
                  .doc(FirebaseAuth.instance.currentUser?.email)
                  .collection('TrHistory')
                  .doc(widget.transactionInfo['transactionId'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Center(child: Text('Error loading data'));
                }

                if (snapshot.data?.get('scanned') == true) {
                  Future.delayed(Duration.zero, () {
                    if (mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Receipt sent to customer successfully'),
                      ));
                    }
                  });
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Total: RM ${widget.transactionInfo['total']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            alignment: Alignment.center,
                            width: 400,
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.black54, width: 2),
                            ),
                            child: _encryptedQrData == null
                                ? const Center(
                                    child: Text('Error generating QR code'))
                                : QrImageView(
                                    data: _encryptedQrData!,
                                    version: QrVersions.auto,
                                    size: 400.0,
                                    backgroundColor: Colors.white,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _showSendManuallyDialog,
                          child: const Text('Send Manually'),
                        ),
                        if (_isSending)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                );
              },
            ),
      resizeToAvoidBottomInset: true,
    );
  }
}
