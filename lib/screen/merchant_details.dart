// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MerchantDetailScreen extends StatefulWidget {
  final String merchantId;

  const MerchantDetailScreen({super.key, required this.merchantId});

  @override
  _MerchantDetailScreenState createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  String storeName = '';
  String storeAddress = '';
  String phoneNumber = '';
  String email = '';
  String profileImageUrl = '';
  List<bool> workingDays = [];
  List<String> startTimes = [];
  List<String> endTimes = [];
  String note = '';
  LatLng? _merchantLocation;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    _fetchMerchantDetails();
  }

  Future<void> _fetchMerchantDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(widget.merchantId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final coordinates = data['locationCoordinates']?.split(',') ?? ['', ''];
      final latitude = double.tryParse(coordinates[0]) ?? 0.0;
      final longitude = double.tryParse(coordinates[1]) ?? 0.0;

      setState(() {
        storeName = data['storename'] ?? '';
        storeAddress = data['storeadd'] ?? '';
        phoneNumber = data['phoneNumber'] ?? '';
        email = doc.id;
        profileImageUrl = data['imageURL'] ?? '';
        workingDays = List<bool>.from(data['workingDays'] ?? []);
        startTimes = List<String>.from(data['startTimes'] ?? []);
        endTimes = List<String>.from(data['endTimes'] ?? []);
        note = data['note'] ?? '';
        _merchantLocation = LatLng(latitude, longitude);

        // Move the camera to the merchant's location
        mapController?.animateCamera(
          CameraUpdate.newLatLng(_merchantLocation!),
        );
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          "subject=Customer Request&body=Hello, I'm contacting you from the vReceipt App",
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl.isEmpty
                    ? Icon(Icons.store, size: 60, color: Colors.grey[800])
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                storeName,
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 8),
              Text(
                storeAddress,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 16),
              const Text(
                'Working Days:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...List.generate(7, (index) {
                return workingDays.isNotEmpty &&
                        startTimes.isNotEmpty &&
                        endTimes.isNotEmpty &&
                        workingDays[index]
                    ? Text(
                        '${[
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday'
                        ][index]}: ${startTimes[index]} - ${endTimes[index]}',
                      )
                    : Container();
              }),
              const SizedBox(height: 10),
              const Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(note),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phoneNumber),
                onTap: () => _makePhoneCall(phoneNumber),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(email),
                onTap: () => _sendEmail(email),
              ),
              const SizedBox(height: 16),
              const Text(
                'Location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _merchantLocation ?? const LatLng(0.0, 0.0),
                    zoom: 14,
                  ),
                  markers: _merchantLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId(widget.merchantId),
                            position: _merchantLocation!,
                          ),
                        }
                      : {},
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    if (_merchantLocation != null) {
                      mapController?.animateCamera(
                        CameraUpdate.newLatLng(_merchantLocation!),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
