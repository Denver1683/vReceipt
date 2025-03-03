import 'package:vreceipt_customer/screen/home.dart';
import 'package:vreceipt_customer/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:vreceipt_customer/services/warranty_notifications.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  _AddReceiptScreenState createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  BarcodeCapture? result;
  MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;
  String RcustomerName = '';
  int RcustomerUid = 0;
  late encrypt.Key _key;
  late encrypt.IV _iv;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    tz.initializeTimeZones();
    _checkUserBlockedStatus(); // Check if user is blocked
    _fetchCustomerData();
    _fetchEncryptionKeys();
  }

  Future<void> _requestPermissions() async {
    final statusCamera = await Permission.camera.request();

    if (statusCamera.isDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
              "Please grant camera permissions to use this feature."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkUserBlockedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data?['blocked'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sorry your account is suspended. Please contact customer service via email at admin@vreceipt.com.'),
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 1));
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Customer')
          .doc(user.email)
          .get();
      final data = doc.data() as Map<String, dynamic>?;

      setState(() {
        RcustomerName = data?['name'] ?? 'Customer';
        RcustomerUid = data?['uid'] ?? 0;
      });
    }
  }

  Future<void> _fetchEncryptionKeys() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Key')
          .doc('Encryption')
          .get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null &&
          data.containsKey('32bit') &&
          data.containsKey('16bit')) {
        setState(() {
          _key = encrypt.Key.fromUtf8(data['32bit']);
          _iv = encrypt.IV.fromUtf8(data['16bit']);
          _isLoading = false;
        });
      } else {
        _navigateBackToHomeWithError('Encryption keys not found.');
      }
    } catch (e) {
      _navigateBackToHomeWithError('Failed to fetch encryption keys.');
    }
  }

  void _navigateBackToHomeWithError(String errorMessage) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TransactionScreen()),
      );
    }
  }

  Future<void> _processData(String data) async {
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
    });

    try {
      final decryptedData = _decryptData(data);

      if (!decryptedData.startsWith('app:vReceiptApp|')) {
        _showIncompatibleDataDialog();
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final parts = decryptedData.split('|');
      if (parts.length != 3) {
        _showIncompatibleDataDialog();
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final transactionId = parts[1];
      final userEmail = parts[2];

      final isAlreadyScanned =
          await _updateMerchantScannedStatus(transactionId, userEmail);
      if (isAlreadyScanned) {
        _showReceiptOwnedDialog();
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final transactionData =
          await _fetchTransactionFromMerchant(userEmail, transactionId);
      if (transactionData == null) {
        _showIncompatibleDataDialog();
        setState(() {
          isProcessing = false;
        });
        return;
      }

      await _addReceiptToFirebase(transactionData, transactionId);

      if (mounted) {
        Navigator.pop(context);
      }

      // Add warranty to Firebase in the background
      _scheduleWarrantyNotificationsInBackground(
          transactionData, transactionId);
    } catch (e) {
      print('Failed to process data: $e');
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransactionScreen()),
        );
        setState(() {
          isProcessing = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: const Text(
                  "Failed to process data, please recheck internet connection and ensure you're scanning correct QR code"),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  String _decryptData(String encryptedData) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final decrypted = encrypter.decrypt64(encryptedData, iv: _iv);
    return decrypted;
  }

  Future<void> _scheduleWarrantyNotificationsInBackground(
      Map<String, dynamic> transactionData, String transactionId) async {
    try {
      // Ensure the transaction data contains the required warranty information
      if (transactionData['prodwarranty'] != null &&
          transactionData['prodname'] != null) {
        // Schedule notifications
        final warrantyNotifications = WarrantyNotifications();
        await warrantyNotifications.scheduleWarrantyNotifications(
            transactionData, transactionData['trdate'], transactionId);
      } else {
        print(
            'No warranty information found, skipping warranty notifications.');
      }
    } catch (e) {
      print('Error scheduling warranty notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to schedule warranty notifications')),
        );
      }
    }
  }

  void _showIncompatibleDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Incompatible Data"),
          content: const Text("Incompatible QR data, please recheck input."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReceiptOwnedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Receipt Owned"),
          content: const Text(
              "Receipt is owned by another customer. Contact merchant if you think this is an issue."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addReceiptToFirebase(
      Map<String, dynamic> transactionData, String transactionId) async {
    final String userEmail = FirebaseAuth.instance.currentUser!.email!;

    final DocumentSnapshot customerSnapshot = await FirebaseFirestore.instance
        .collection('Customer')
        .doc(userEmail)
        .get();
    final customerData = customerSnapshot.data() as Map<String, dynamic>?;

    final String customerName = customerData?['name'] ?? "Customer";
    final int customerUid = customerData?['uid'] ?? 0;

    final CollectionReference transactionsCollection = FirebaseFirestore
        .instance
        .collection('Customer')
        .doc(userEmail)
        .collection('Transactions');

    final newTransactionData = {
      'category': transactionData['category'],
      'custname': customerName,
      'isFavorite': false, // Assuming this is a default value
      'price': transactionData['prodprice'],
      'product': transactionData['prodname'],
      'qty': transactionData['qty'],
      'storeaddress': transactionData['storeadd'],
      'storeid': transactionData['storeid'],
      'storename': transactionData['storename'],
      'total': transactionData['total'],
      'trdate': transactionData['trdate'],
      'trid': transactionId,
      'uid': customerUid,
      'warranty': transactionData['prodwarranty'],
      'pretaxtotal': transactionData['pretaxtotal'],
      'totalTax': transactionData['totalTax'],
      'taxPercentage': transactionData['taxPercentage'],
      'totalServiceCharge': transactionData['totalServiceCharge'],
      'serviceChargePercentage': transactionData['serviceChargePercentage'],
      'deleted': false,
      'payBy': transactionData['payBy']
    };

    await transactionsCollection.doc(transactionId).set(newTransactionData);
  }

  Future<Map<String, dynamic>?> _fetchTransactionFromMerchant(
      String userEmail, String transactionId) async {
    final DocumentSnapshot transactionSnapshot = await FirebaseFirestore
        .instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('TrHistory')
        .doc(transactionId)
        .get();

    if (!transactionSnapshot.exists) {
      return null;
    }

    return transactionSnapshot.data() as Map<String, dynamic>?;
  }

  Future<bool> _updateMerchantScannedStatus(
      String transactionId, String userEmail) async {
    final DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(userEmail)
        .collection('TrHistory')
        .doc(transactionId)
        .get();

    if (transactionDoc.exists) {
      final transactionData = transactionDoc.data() as Map<String, dynamic>?;
      final bool isScanned = transactionData?['scanned'] ?? false;
      if (isScanned) {
        return true;
      }

      await transactionDoc.reference.update({
        'scanned': true,
        'custname': RcustomerName,
        'uid': RcustomerUid, // Update UID in merchant's data
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction not found')),
        );
      }
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Shopping Receipt'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: MobileScanner(
                    controller: controller,
                    onDetect: (barcode) {
                      if (result == null && barcode.barcodes.isNotEmpty) {
                        setState(() {
                          result = barcode;
                        });
                        _processData(result!.barcodes.first.rawValue!);
                      }
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: result != null
                        ? const Text('Processing scanned data, please wait...')
                        : const Text(
                            'Scan a code, your transaction is protected with encryption.'),
                  ),
                ),
              ],
            ),
    );
  }
}
