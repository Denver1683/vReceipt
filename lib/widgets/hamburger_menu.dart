import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vreceipt_merchant/screen/login_screen.dart';
import 'package:vreceipt_merchant/screen/manage_stock.dart';
import 'package:vreceipt_merchant/screen/profile.dart';
import 'package:vreceipt_merchant/screen/statistics.dart';
import 'package:vreceipt_merchant/screen/settings.dart'; // Import the SettingsScreen

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({super.key});

  Stream<DocumentSnapshot> fetchStoreDataStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    // Get the user document stream
    return FirebaseFirestore.instance
        .collection('Merchant')
        .doc(user.email)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          StreamBuilder<DocumentSnapshot>(
            stream: fetchStoreDataStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data == null) {
                return const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Center(
                    child: Text('No data available'),
                  ),
                );
              } else {
                Map<String, dynamic> storeData =
                    snapshot.data!.data() as Map<String, dynamic>;
                return DrawerHeader(
                  padding: const EdgeInsets.fromLTRB(15, 5, 0, 0),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoreProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: storeData['imageURL'] != null &&
                                  storeData['imageURL'].isNotEmpty
                              ? NetworkImage(storeData['imageURL'])
                              : null,
                          child: storeData['imageURL'] == null ||
                                  storeData['imageURL'].isEmpty
                              ? const Icon(
                                  Icons.store,
                                  size: 40,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 30, // Adjust the height as needed
                        child: Text(
                          storeData['storename'] ?? 'No Store Name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Manage Stock'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageStockScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics'), // New Statistics menu item
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StatisticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'), // New Settings menu item
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(), // Adding a Divider before the logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
