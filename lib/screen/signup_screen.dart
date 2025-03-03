// ignore_for_file: prefer_final_fields, library_private_types_in_public_api, unrelated_type_equality_checks

import 'package:vreceipt_merchant/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:location/location.dart'; // Import for getting user location
import 'package:vreceipt_merchant/models/category.dart'; // Import the category.dart file

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _serviceChargeController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? _profileImageFile;
  File? _icImageFile;
  File? _icSelfieImageFile;
  String? _profileImageUrl;
  String? _icImageUrl;
  String? _icSelfieImageUrl;
  String? _selectedCategory;
  List<bool> _workingDays = List<bool>.filled(7, false);
  List<TimeOfDay?> _startTimes = List<TimeOfDay?>.filled(7, null);
  List<TimeOfDay?> _endTimes = List<TimeOfDay?>.filled(7, null);
  String? _locationCoordinates;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();

    setState(() {
      _currentLatitude = locationData.latitude!;
      _currentLongitude = locationData.longitude!;
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String storeName = _storeNameController.text.trim();
    String storeAddress = _storeAddressController.text.trim();
    String phoneNumber = _phoneNumberController.text.trim();
    String tax = _taxController.text.trim();
    String serviceCharge = _serviceChargeController.text.trim();
    String icNumber = _icNumberController.text.trim();

    if (_icImageFile == null || _icSelfieImageFile == null) {
      _showSnackBar('Please upload all required images.');
      return;
    }

    if (!_workingDays.contains(true) ||
        !_startTimes.any((time) => time != null) ||
        !_endTimes.any((time) => time != null)) {
      _showSnackBar('Please select working hours.');
      return;
    }

    if (await _doesICNumberExist(icNumber)) {
      _showSnackBar(
          'User with the same identity exists. Please log in or contact admin at admin@vreceipt.com');
      try {
        await _auth.signOut();
      } catch (e) {}
      _navigateToLogin();
      return;
    }

    try {
      if (await _doesUserExist(email)) {
        _showSnackBar('Account already exists.');
      } else {
        bool proceedSignup = await _registerUser(email, password, storeName,
            storeAddress, phoneNumber, tax, serviceCharge, icNumber);
        if (proceedSignup == true) {
          if (_profileImageFile != null) {
            await _uploadImage(
                email, _profileImageFile!, 'User Picture', 'imageURL');
          }
          if (_icImageFile != null) {
            await _uploadImage(email, _icImageFile!, 'ic', 'icImageURL');
          }
          if (_icSelfieImageFile != null) {
            await _uploadImage(
                email, _icSelfieImageFile!, 'icselfie', 'icSelfieImageURL');
          }
          _showSnackBar(
              'Details have been successfully updated. Please inform admin at admin@vreceipt.com');
          await _auth.signOut();
          _navigateToLogin();
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  Future<bool> _doesUserExist(String email) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Merchant')
        .doc(email)
        .get();
    return userDoc.exists;
  }

  Future<bool> _doesICNumberExist(String icNumber) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('icnumber', isEqualTo: icNumber)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> _registerUser(
      String email,
      String password,
      String storeName,
      String storeAddress,
      String phoneNumber,
      String tax,
      String serviceCharge,
      String icNumber) async {
    // ignore: unused_local_variable
    UserCredential userCredential;
    try {
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      } catch (e) {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      }
      int storeId = await _generateStoreId();
      await FirebaseFirestore.instance.collection('Merchant').doc(email).set({
        'storename': storeName,
        'storeadd': storeAddress,
        'storeid': storeId.toString(),
        'imageURL': '',
        'icImageURL': '',
        'icSelfieImageURL': '',
        'phoneNumber': phoneNumber,
        'storeCategory': _selectedCategory,
        'verified': false,
        'blocked': false,
        'workingDays': _workingDays,
        'startTimes':
            _startTimes.map((time) => _formatTimeOfDay(time)).toList(),
        'endTimes': _endTimes.map((time) => _formatTimeOfDay(time)).toList(),
        'note': _noteController.text.trim(),
        'tax': tax,
        'serviceCharge': serviceCharge,
        'locationCoordinates': _locationCoordinates,
        'icnumber': icNumber,
      });
      return true;
    } catch (e) {
      _showSnackBar(
          'Please sign up with the same username and password if you signed up before. You will use your initial credentials to sign in later.');
      return false;
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '00:00';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _uploadImage(
      String email, File imageFile, String folder, String field) async {
    String fileName = email;
    Reference storageRef =
        FirebaseStorage.instance.ref().child(folder).child(fileName);

    try {
      await storageRef.putFile(imageFile);
      String imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('Merchant')
          .doc(email)
          .update({field: imageUrl});
    } catch (e) {
      _showSnackBar('Failed to upload image: $e');
    }
  }

  Future<int> _generateStoreId() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Merchant').get();
    return snapshot.docs.length + 1;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;
    if (e.code == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      message = 'The account already exists for that email.';
    } else {
      message = 'An error occurred. Please try again.';
    }
    _showSnackBar(message);
  }

  void _navigateToLogin() {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _pickImage(ImageSource source,
      {required Function(File) onPicked}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        onPicked(File(pickedFile.path));
      });
    }
  }

  void _showProfileImageOptions({required Function(File) onPicked}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onPicked: onPicked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onPicked: onPicked);
                },
              ),
              if (onPicked == _profileImageFile ||
                  onPicked == _icImageFile ||
                  onPicked == _icSelfieImageFile)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      if (onPicked == _profileImageFile) {
                        _profileImageFile = null;
                      } else if (onPicked == _icImageFile) {
                        _icImageFile = null;
                      } else if (onPicked == _icSelfieImageFile) {
                        _icSelfieImageFile = null;
                      }
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime(
      BuildContext context, Function(TimeOfDay) onTimePicked) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onTimePicked(pickedTime);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildSectionHeader('I. Credentials'),
              _buildTextField(
                  _emailController, 'Email', 'Please enter your email'),
              _buildTextField(
                  _passwordController, 'Password', 'Please enter your password',
                  obscureText: true),
              const SizedBox(height: 16),
              _buildSectionHeader('II. Store Information'),
              GestureDetector(
                onTap: () => _showProfileImageOptions(onPicked: (file) {
                  setState(() {
                    _profileImageFile = file;
                  });
                }),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _profileImageFile != null
                      ? FileImage(_profileImageFile!)
                      : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : null,
                  child: _profileImageFile == null &&
                          (_profileImageUrl == null ||
                              _profileImageUrl!.isEmpty)
                      ? Icon(
                          Icons.store,
                          size: 60,
                          color: Colors.grey[800],
                        )
                      : null,
                ),
              ),
              if (_profileImageFile == null &&
                  (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please add your store profile picture',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              _buildTextField(_storeNameController, 'Store Name',
                  'Please enter your store name'),
              _buildDropdownField(
                  'Store Category', categories, _selectedCategory, (value) {
                setState(() {
                  _selectedCategory = value;
                });
              }),
              _buildTextField(_storeAddressController, 'Store Address',
                  'Please enter your store address'),
              _buildTextField(_phoneNumberController, 'Phone Number',
                  'Please enter your phone number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              _buildLocationTagging(),
              const SizedBox(height: 20),
              _buildTaxAndServiceChargeSection(), // Added Tax & Service Charge section
              _buildWorkingHours(),
              _buildTextField(
                  _noteController,
                  'Note: (example: break hours, close during public holiday, etc.)',
                  'Note: (example: break hours, close during public holiday, etc.)'),
              const SizedBox(height: 16),
              _buildSectionHeader('III. Verification'),
              GestureDetector(
                onTap: () => _showProfileImageOptions(onPicked: (file) {
                  setState(() {
                    _icImageFile = file;
                  });
                }),
                child: _buildImageBox(
                  'IC/Passport Image',
                  _icImageFile,
                  _icImageUrl,
                ),
              ),
              GestureDetector(
                onTap: () => _showProfileImageOptions(onPicked: (file) {
                  setState(() {
                    _icSelfieImageFile = file;
                  });
                }),
                child: _buildImageBox(
                  'Selfie with IC/Passport',
                  _icSelfieImageFile,
                  _icSelfieImageUrl,
                ),
              ),
              _buildICPassportNoField(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text('Sign Up'),
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

  Widget _buildTextField(
      TextEditingController controller, String label, String validationMessage,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage;
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String? selectedItem, Function(String?) onChanged) {
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
        DropdownButtonFormField<String>(
          value: selectedItem,
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageBox(String label, File? imageFile, String? imageUrl) {
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
          child: imageFile != null
              ? Image.file(imageFile, fit: BoxFit.cover)
              : imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : const Center(
                      child: Text(
                        'Tap to upload image',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
        ),
        if (imageFile == null && (imageUrl == null || imageUrl.isEmpty))
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'This field is mandatory',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWorkingHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Working Hours',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(7, (index) {
            return Row(
              children: [
                Checkbox(
                  value: _workingDays[index],
                  onChanged: (value) {
                    setState(() {
                      _workingDays[index] = value!;
                      if (value) {
                        _startTimes[index] ??=
                            const TimeOfDay(hour: 0, minute: 0);
                        _endTimes[index] ??=
                            const TimeOfDay(hour: 0, minute: 0);
                      }
                    });
                  },
                ),
                Text(_getDayOfWeek(index)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _pickTime(context, (pickedTime) {
                    setState(() {
                      _startTimes[index] = pickedTime;
                    });
                  }),
                  child: _buildTimeBox(
                      _startTimes[index]?.format(context) ?? 'Start'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _pickTime(context, (pickedTime) {
                    setState(() {
                      _endTimes[index] = pickedTime;
                    });
                  }),
                  child:
                      _buildTimeBox(_endTimes[index]?.format(context) ?? 'End'),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getDayOfWeek(int index) {
    switch (index) {
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

  Widget _buildTimeBox(String time) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(time),
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
            initialCameraPosition: const CameraPosition(
              target: LatLng(3.1390, 101.6869), // Default to Kuala Lumpur
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaxAndServiceChargeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tax & Service Charge',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _taxController,
                'Tax (%)',
                'Please enter tax percentage',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                _serviceChargeController,
                'Service Charge (%)',
                'Please enter service charge percentage',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildICPassportNoField() {
    return _buildTextField(_icNumberController, 'IC/Passport No.',
        'Please enter your IC/Passport No.');
  }
}
