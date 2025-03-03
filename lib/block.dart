import 'package:flutter/material.dart';
import 'block_customer.dart';
import 'block_merchant.dart';

class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BlockScreenState createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  bool showCustomers = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Merchants'),
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
                ? const BlockCustomerScreen()
                : const BlockMerchantScreen(),
          ),
        ],
      ),
    );
  }
}
