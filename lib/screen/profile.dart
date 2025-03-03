// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vreceipt_merchant/widgets/hamburger_menu.dart';
import 'view_image_screen.dart';
import 'dart:io';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  _StoreProfileScreenState createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _serviceChargeController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ValueNotifier<bool> _isSaveButtonEnabled = ValueNotifier(false);
  String? _storeId;
  String? _profileImageUrl;
  String? _icImageUrl;
  String? _icSelfieImageUrl;
  String? _locationCoordinates;
  String? _icNumber;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  final List<bool> _workingDays = List<bool>.generate(7, (index) => false);
  final List<TimeOfDay?> _startTimes =
      List<TimeOfDay?>.generate(7, (index) => null);
  final List<TimeOfDay?> _endTimes =
      List<TimeOfDay?>.generate(7, (index) => null);

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
    _getCurrentLocation();
    _nameController.addListener(_checkFields);
    _addressController.addListener(_checkFields);
    _phoneNumberController.addListener(_checkFields);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkFields);
    _addressController.removeListener(_checkFields);
    _phoneNumberController.removeListener(_checkFields);
    _nameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _noteController.dispose();
    _taxController.dispose();
    _serviceChargeController.dispose();
    _locationController.dispose();
    _isSaveButtonEnabled.dispose();
    super.dispose();
  }

  void _checkFields() {
    _isSaveButtonEnabled.value = _nameController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _phoneNumberController.text.isNotEmpty;
  }

  Future<void> _fetchStoreData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(user.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        _nameController.text = userDoc['storename'] ?? '';
        _addressController.text = userDoc['storeadd'] ?? '';
        _phoneNumberController.text = userDoc['phoneNumber'] ?? '';
        _noteController.text = userDoc['note'] ?? '';
        _storeId = userDoc['storeid']?.toString() ?? '';
        _profileImageUrl = userDoc['imageURL'] ?? '';
        _icImageUrl = userDoc['icImageURL'] ?? '';
        _icSelfieImageUrl = userDoc['icSelfieImageURL'] ?? '';
        _taxController.text = userDoc['tax'] ?? '';
        _serviceChargeController.text = userDoc['serviceCharge'] ?? '';
        _locationCoordinates = userDoc['locationCoordinates'] ?? '';
        _icNumber = userDoc['icnumber'] ?? '';

        _locationController.text = _locationCoordinates ?? '';

        // Fetch working hours
        List<dynamic> startTimes = userDoc['startTimes'];
        List<dynamic> endTimes = userDoc['endTimes'];
        List<dynamic> workingDays = userDoc['workingDays'];
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
          List<String> coords = _locationCoordinates!.split(',');
          if (coords.length == 2) {
            _currentLatitude = double.parse(coords[0]);
            _currentLongitude = double.parse(coords[1]);

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
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();

    setState(() {
      _currentLatitude = locationData.latitude!;
      _currentLongitude = locationData.longitude!;
    });
  }

  Future<void> _saveChanges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(user.email)
        .update({
      'storename': _nameController.text,
      'storeadd': _addressController.text,
      'phoneNumber': _phoneNumberController.text,
      'workingDays': _workingDays,
      'startTimes': _startTimes.map((time) => _formatTimeOfDay(time)).toList(),
      'endTimes': _endTimes.map((time) => _formatTimeOfDay(time)).toList(),
      'note': _noteController.text,
      'tax': _taxController.text,
      'serviceCharge': _serviceChargeController.text,
      'locationCoordinates': _locationCoordinates,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully')),
    );

    Navigator.pop(context);
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '00:00';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String fileName = user.email!;
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('User Picture')
            .child(fileName);

        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('Merchant')
            .doc(user.email)
            .update({
          'imageURL': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(user.email)
          .update({
        'imageURL': '',
      });

      setState(() {
        _profileImageUrl = '';
      });
    }
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Image'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewImageScreen(imageUrl: _profileImageUrl),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Update Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setCurrentLocation() async {
    Location location = Location();
    LocationData locationData;

    try {
      locationData = await location.getLocation();
      setState(() {
        _currentLatitude = locationData.latitude!;
        _currentLongitude = locationData.longitude!;
        _locationCoordinates = '$_currentLatitude, $_currentLongitude';
        _locationController.text = _locationCoordinates!;

        // Clear any existing markers and add a new marker at the current location
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('current-location'),
            position: LatLng(_currentLatitude, _currentLongitude),
          ),
        );

        // Update the map's camera position to the current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentLatitude, _currentLongitude),
          ),
        );
      });
    } catch (e) {
      _showSnackBar('Could not fetch location. Please try again.');
    }
  }

  void _pickTime(BuildContext context, Function(TimeOfDay) onPicked) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: const Text('Store Profile'),
        centerTitle: true,
      ),
      drawer: const HamburgerMenu(), // Use the HamburgerMenu widget
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showProfileImageOptions,
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
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Address:',
                controller: _addressController,
              ),
              const SizedBox(height: 16),
              _buildLocationTagging(), // Location Tagging Section
              const SizedBox(height: 32),
              _buildTextField(
                label: 'Phone Number:',
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Billing Information'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tax (%):',
                controller: _taxController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Service Charge (%):',
                controller: _serviceChargeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              ValueListenableBuilder<bool>(
                valueListenable: _isSaveButtonEnabled,
                builder: (context, isEnabled, child) {
                  return ElevatedButton(
                    onPressed: isEnabled ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                          double.infinity, 48), // Make the button full width
                    ),
                    child: const Text('SAVE CHANGES'),
                  );
                },
              ),
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
    bool obscureText = false,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
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
                onChanged: (value) {
                  setState(() {
                    _workingDays[i] = value ?? false;
                    if (_workingDays[i]) {
                      _startTimes[i] =
                          _startTimes[i] ?? const TimeOfDay(hour: 0, minute: 0);
                      _endTimes[i] =
                          _endTimes[i] ?? const TimeOfDay(hour: 0, minute: 0);
                    }
                  });
                },
              ),
              Expanded(child: Text(_getDayLabel(i))),
              _workingDays[i]
                  ? Row(
                      children: [
                        _buildTimePicker(
                          context,
                          label: 'Start',
                          selectedTime: _startTimes[i],
                          onSelected: (time) {
                            setState(() {
                              _startTimes[i] = time;
                            });
                          },
                        ),
                        const Text(' - '),
                        _buildTimePicker(
                          context,
                          label: 'End',
                          selectedTime: _endTimes[i],
                          onSelected: (time) {
                            setState(() {
                              _endTimes[i] = time;
                            });
                          },
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
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onSelected,
  }) {
    final textColor =
        Theme.of(context).textTheme.bodyText1?.color ?? Colors.black;

    return GestureDetector(
      onTap: () => _pickTime(context, onSelected),
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
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _setCurrentLocation,
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
            onTap: (LatLng latLng) {
              setState(() {
                _locationCoordinates =
                    '${latLng.latitude}, ${latLng.longitude}';
                _locationController.text = _locationCoordinates!;

                // Add a marker at the tapped location
                _markers.clear(); // Clear existing markers
                _markers.add(
                  Marker(
                    markerId: const MarkerId('selected-location'),
                    position: latLng,
                  ),
                );

                // Update the map's camera to center on the tapped location
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(latLng),
                );
              });
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
}
