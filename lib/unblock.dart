import 'package:flutter/material.dart';
import 'unblock_customer.dart';
import 'unblock_merchant.dart';

class UnblockScreen extends StatefulWidget {
  const UnblockScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UnblockScreenState createState() => _UnblockScreenState();
}

class _UnblockScreenState extends State<UnblockScreen> {
  bool showCustomers = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unblock Merchants'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        showCustomers ? Colors.blue : Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      showCustomers = true;
                    });
                  },
                  child: const Text(
                    'Customer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        showCustomers ? Colors.grey[400] : Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      showCustomers = false;
                    });
                  },
                  child: const Text(
                    'Merchant',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: showCustomers
                ? const UnblockCustomerScreen()
                : const UnblockMerchantScreen(),
          ),
        ],
      ),
    );
  }
}
