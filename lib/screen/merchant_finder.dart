// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vreceipt_customer/screen/merchant_details.dart';

class MerchantFinderScreen extends StatefulWidget {
  const MerchantFinderScreen({super.key});

  @override
  _MerchantFinderScreenState createState() => _MerchantFinderScreenState();
}

class _MerchantFinderScreenState extends State<MerchantFinderScreen> {
  List<Map<String, dynamic>> merchants = [];
  List<Map<String, dynamic>> filteredMerchants = [];
  String searchQuery = '';
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  LatLng _initialPosition =
      const LatLng(3.1390, 101.6869); // Default: Kuala Lumpur
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _fetchMerchants();
  }

  Future<void> _fetchUserLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return; // If service is not enabled, use fallback location
        }
      }

      // Check for location permission
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return; // If permission is denied, use fallback location
        }
      }

      // Fetch current location
      LocationData locationData = await _location.getLocation();

      setState(() {
        _initialPosition =
            LatLng(locationData.latitude!, locationData.longitude!);
      });

      // Animate the camera to the user's location
      if (mapController != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLng(_initialPosition),
        );
      }
    } catch (e) {
      // In case of an error, use the default location (Kuala Lumpur)
    }
  }

  Future<void> _fetchMerchants() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('verified', isEqualTo: true)
        .get();

    final List<Map<String, dynamic>> merchantList =
        querySnapshot.docs.map((doc) {
      final data = doc.data();
      final coordinates = data['locationCoordinates']?.split(',') ?? ['', ''];
      final latitude = double.tryParse(coordinates[0]) ?? 0.0;
      final longitude = double.tryParse(coordinates[1]) ?? 0.0;

      final merchant = {
        'id': doc.id,
        'storename': data['storename'] ?? '',
        'storeadd': data['storeadd'] ?? '',
        'imageURL': data['imageURL'] ?? '',
        'location': LatLng(latitude, longitude),
      };

      return merchant;
    }).toList();

    setState(() {
      merchants = merchantList;
      filteredMerchants = merchantList;
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};
    for (var merchant in filteredMerchants) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(merchant['id']),
          position: merchant['location'],
          infoWindow: InfoWindow(
            title: merchant['storename'],
            snippet: merchant['storeadd'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MerchantDetailScreen(merchantId: merchant['id']),
                ),
              );
            },
          ),
        ),
      );
    }
    setState(() {
      _markers = newMarkers;
      if (filteredMerchants.isNotEmpty) {
        // Move the camera to the first merchant's location
        mapController?.animateCamera(
          CameraUpdate.newLatLng(filteredMerchants.first['location']),
        );
      }
    });
  }

  void _filterMerchants(String query) {
    final filtered = merchants.where((merchant) {
      final storeName = merchant['storename'].toLowerCase();
      final storeAddress = merchant['storeadd'].toLowerCase();
      final storeId = merchant['id'].toLowerCase();
      final searchLower = query.toLowerCase();

      return storeName.contains(searchLower) ||
          storeAddress.contains(searchLower) ||
          storeId.contains(searchLower);
    }).toList();

    setState(() {
      searchQuery = query;
      filteredMerchants = filtered;
      _updateMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Finder'),
      ),
      body: Column(
        children: [
          // Top half: Google Map
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: _markers,
            ),
          ),
          // Bottom half: Merchant List and Search Bar
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by store name, address, or ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _filterMerchants,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMerchants.length,
                    itemBuilder: (context, index) {
                      final merchant = filteredMerchants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: merchant['imageURL'].isNotEmpty
                              ? NetworkImage(merchant['imageURL'])
                              : null,
                          backgroundColor: Colors.grey[200],
                          child: merchant['imageURL'].isEmpty
                              ? Icon(Icons.store, color: Colors.grey[800])
                              : null,
                        ),
                        title: Text(merchant['storename']),
                        subtitle: Text(merchant['storeadd']),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MerchantDetailScreen(
                                merchantId: merchant['id'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
