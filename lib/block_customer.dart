import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_details.dart';

class BlockCustomerScreen extends StatefulWidget {
  const BlockCustomerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BlockCustomerScreenState createState() => _BlockCustomerScreenState();
}

class _BlockCustomerScreenState extends State<BlockCustomerScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Customer')
                  .where('blocked', isEqualTo: false)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var name = data['name']?.toString().toLowerCase() ?? '';
                  var uid = data['uid']?.toString().toLowerCase() ?? '';
                  var email = doc.id.toString().toLowerCase();
                  return name.contains(searchQuery) ||
                      uid.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No customer is blocked.'));
                }

                return ListView(
                  children: filteredDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? 'No Name'),
                      subtitle: Text(doc.id),
                      trailing: IconButton(
                        icon: const Icon(Icons.block),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('Customer')
                              .doc(doc.id)
                              .update({'blocked': true});
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerDetailsScreen(
                              customerId: doc.id,
                            ),
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
                hintText: 'Search by name, UID, or email',
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
