import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vreceipt_admin/view_image.dart';

class MerchantDetailScreen extends StatefulWidget {
  final String merchantId;

  const MerchantDetailScreen({super.key, required this.merchantId});

  @override
  _MerchantDetailScreenState createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _serviceChargeController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _storeId;
  String? _profileImageUrl;
  String? _icImageUrl;
  String? _icSelfieImageUrl;
  String? _locationCoordinates;
  String? _icNumber;
  bool _verified = false;
  bool _blocked = false;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  List<bool> _workingDays = List<bool>.generate(7, (index) => false);
  List<TimeOfDay?> _startTimes = List<TimeOfDay?>.generate(7, (index) => null);
  List<TimeOfDay?> _endTimes = List<TimeOfDay?>.generate(7, (index) => null);

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
        _nameController.text = data['storename'] ?? '';
        _addressController.text = data['storeadd'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        _noteController.text = data['note'] ?? '';
        _storeId = data['storeid']?.toString() ?? '';
        _profileImageUrl = data['imageURL'] ?? '';
        _icImageUrl = data['icImageURL'] ?? '';
        _icSelfieImageUrl = data['icSelfieImageURL'] ?? '';
        _taxController.text = data['tax'] ?? '';
        _serviceChargeController.text = data['serviceCharge'] ?? '';
        _locationCoordinates = data['locationCoordinates'] ?? '';
        _icNumber = data['icnumber'] ?? '';
        _verified = data['verified'] ?? false;
        _blocked = data['blocked'] ?? false;

        _locationController.text = _locationCoordinates ?? '';

        _currentLatitude = latitude;
        _currentLongitude = longitude;

        // Fetch working hours
        List<dynamic> startTimes = data['startTimes'] ?? [];
        List<dynamic> endTimes = data['endTimes'] ?? [];
        List<dynamic> workingDays = data['workingDays'] ?? [];
        for (int i = 0; i < 7; i++) {
          _workingDays[i] = workingDays[i];
          _startTimes[i] = TimeOfDay(
              hour: int.parse(startTimes[i].split(':')[0]),
              minute: int.parse(startTimes[i].split(':')[1]));
          _endTimes[i] = TimeOfDay(
              hour: int.parse(endTimes[i].split(':')[0]),
              minute: int.parse(endTimes[i].split(':')[1]));
        }

        // Set marker and update camera position on the map based on fetched coordinates
        if (_locationCoordinates != null && _locationCoordinates!.isNotEmpty) {
          _markers.add(
            Marker(
              markerId: const MarkerId('fetched-location'),
              position: LatLng(_currentLatitude, _currentLongitude),
            ),
          );

          // Move the camera to the fetched coordinates
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentLatitude, _currentLongitude),
            ),
          );
        }
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
      queryParameters: {
        'subject': 'Inquiry',
        'body': 'Hello, I would like to know more about your store.',
      },
    );
    await launchUrl(launchUri);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateMerchantStatus(bool verified, bool blocked) async {
    await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(widget.merchantId)
        .update({
      'blocked': blocked,
    });

    setState(() {
      _verified = verified;
      _blocked = blocked;
    });

    _showSnackBar('Merchant status updated successfully.');
  }

  Future<void> _rejectMerchant() async {
    await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(widget.merchantId)
        .delete();
    _showSnackBar('Merchant rejected successfully.');
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
            children: [
              GestureDetector(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? Icon(
                          Icons.store,
                          size: 60,
                          color: Colors.grey[800],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Store ID: ${_storeId ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Store Details'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Name:',
                controller: _nameController,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Address:',
                controller: _addressController,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildLocationTagging(), // Location Tagging Section
              const SizedBox(height: 32),
              _buildTextField(
                label: 'Phone Number:',
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Billing Information'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tax (%):',
                controller: _taxController,
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Service Charge (%):',
                controller: _serviceChargeController,
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Working Hours'),
              const SizedBox(height: 16),
              _buildWorkingHoursSection(),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  if (_icImageUrl != null && _icImageUrl!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ViewImageScreen(imageUrl: _icImageUrl),
                      ),
                    );
                  } else {
                    _showSnackBar('No image available to view.');
                  }
                },
                child: _buildImageBox('IC/Passport Image', _icImageUrl),
              ),
              GestureDetector(
                onTap: () {
                  if (_icSelfieImageUrl != null &&
                      _icSelfieImageUrl!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ViewImageScreen(imageUrl: _icSelfieImageUrl),
                      ),
                    );
                  } else {
                    _showSnackBar('No image available to view.');
                  }
                },
                child: _buildImageBox(
                    'Selfie with IC/Passport', _icSelfieImageUrl),
              ),
              Text(
                'IC/Passport No.: ${_icNumber ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final textColor =
        Theme.of(context).textTheme.bodyText1?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintStyle: TextStyle(color: textColor),
          ),
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          readOnly: readOnly,
        ),
      ],
    );
  }

  Widget _buildImageBox(String label, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : const Center(
                  child: Text(
                    'No image available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    final textColor =
        Theme.of(context).textTheme.bodyText1?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 7; i++)
          Row(
            children: [
              Checkbox(
                value: _workingDays[i],
                onChanged: null, // Admin cannot edit the working days
              ),
              Expanded(child: Text(_getDayLabel(i))),
              _workingDays[i]
                  ? Row(
                      children: [
                        _buildTimePicker(
                          context,
                          label: 'Start',
                          selectedTime: _startTimes[i],
                          onSelected: null, // Admin cannot edit the start time
                        ),
                        const Text(' - '),
                        _buildTimePicker(
                          context,
                          label: 'End',
                          selectedTime: _endTimes[i],
                          onSelected: null, // Admin cannot edit the end time
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        const SizedBox(height: 16),
        const Text(
          'Note: (example break hours, close during public holiday, etc.)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintStyle: TextStyle(color: textColor),
          ),
          style: TextStyle(color: textColor),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay)? onSelected,
  }) {
    final textColor =
        Theme.of(context).textTheme.bodyText1?.color ?? Colors.black;

    return GestureDetector(
      child: Container(
        width: 60,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          selectedTime != null ? selectedTime.format(context) : label,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _buildLocationTagging() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Tagging',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Coordinates',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentLatitude,
                  _currentLongitude), // Updated to use fetched coordinates
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              // Move the camera if the coordinates are already fetched
              if (_locationCoordinates != null &&
                  _locationCoordinates!.isNotEmpty) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentLatitude, _currentLongitude),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  String _getDayLabel(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return '';
    }
  }

  Widget _buildActionButtons() {
    if (!_verified) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _updateMerchantStatus(true, false); // Verify merchant
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Verify',
                style:
                    TextStyle(color: Colors.white), // Font color set to white
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _rejectMerchant(); // Reject merchant
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Reject',
                style:
                    TextStyle(color: Colors.white), // Font color set to white
              ),
            ),
          ),
        ],
      );
    } else if (_verified && !_blocked) {
      return ElevatedButton(
        onPressed: () {
          _updateMerchantStatus(true, true); // Block merchant
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text(
          'Block',
          style: TextStyle(color: Colors.white), // Font color set to white
        ),
      );
    } else if (_verified && _blocked) {
      return ElevatedButton(
        onPressed: () {
          _updateMerchantStatus(true, false); // Unblock merchant
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text(
          'Unblock',
          style: TextStyle(color: Colors.white), // Font color set to white
        ),
      );
    }
    return Container();
  }
}
