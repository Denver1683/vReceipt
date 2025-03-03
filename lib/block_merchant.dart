import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'merchant_details.dart';

class BlockMerchantScreen extends StatefulWidget {
  const BlockMerchantScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BlockMerchantScreenState createState() => _BlockMerchantScreenState();
}

class _BlockMerchantScreenState extends State<BlockMerchantScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchants'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Merchant')
                  .where('blocked', isEqualTo: false)
                  .where('verified', isEqualTo: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = data['storename']?.toString().toLowerCase() ?? '';
                  var storeId = data['storeid']?.toString().toLowerCase() ?? '';
                  var email = doc.id.toString().toLowerCase();
                  return name.contains(searchQuery) ||
                      storeId.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No merchant is blocked.'));
                }

                return ListView(
                  children: filteredDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['storename']),
                      subtitle: Text(doc.id),
                      trailing: IconButton(
                        icon: const Icon(Icons.block),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('Merchant')
                              .doc(doc.id)
                              .update({'blocked': true});
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MerchantDetailScreen(merchantId: doc.id),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, store ID, or email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
