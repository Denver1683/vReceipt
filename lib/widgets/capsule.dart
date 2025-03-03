import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class Capsule extends StatelessWidget {
  final String storeName;
  final String storeAddress;
  final String phoneNumber;
  final String email;
  final String profileImageUrl;
  final List<bool> workingDays;
  final List<String> startTimes;
  final List<String> endTimes;
  final String note;
  final ValueNotifier<bool> isExpandedNotifier;
  final String storeId;

  const Capsule({
    super.key,
    required this.storeName,
    required this.storeAddress,
    required this.phoneNumber,
    required this.email,
    required this.profileImageUrl,
    required this.workingDays,
    required this.startTimes,
    required this.endTimes,
    required this.note,
    required this.isExpandedNotifier,
    required this.storeId,
  });

  Future<Map<String, String>> fetchStoreDetails(String storeId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Merchant')
        .where('storeid', isEqualTo: storeId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      return {
        'email': doc.id.toString(),
        'phoneNumber': data['phoneNumber'] ?? '',
      };
    } else {
      return {
        'email': '',
        'phoneNumber': '',
      };
    }
  }

  Future<void> _makePhoneCall(String storeId) async {
    final storeDetails = await fetchStoreDetails(storeId);
    final phoneNumber = storeDetails['phoneNumber'];
    if (phoneNumber!.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String storeId) async {
    final storeDetails = await fetchStoreDetails(storeId);
    final email = storeDetails['email'];
    if (email!.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'mailto',
        path: email,
        query:
            "subject=Customer Request&body=Hello, I'm contacting you from the e-Receipt App",
      );
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme
    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => isExpandedNotifier.value = !isExpandedNotifier.value,
        child: ValueListenableBuilder<bool>(
          valueListenable: isExpandedNotifier,
          builder: (context, isExpanded, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? 400 : 200,
              height: isExpanded ? 500 : 60, // Adjusted for wider open state
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.secondaryHeaderColor, // Use theme's primary color
                borderRadius: BorderRadius.circular(30.0), // More roundness
                border: Border.all(color: Colors.grey), // Grey border
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center vertically
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center horizontally
                    children: [
                      CircleAvatar(
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        radius: 15.0,
                        backgroundColor: Colors.white,
                        child:
                            (profileImageUrl == "" || profileImageUrl.isEmpty)
                                ? const Icon(
                                    Icons.store,
                                    size: 15,
                                    color: Colors.grey,
                                  )
                                : null,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          storeName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.headline6
                                ?.color, // Adjust text color
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8.0),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              const BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 4),
                                blurRadius: 4.0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 30.0,
                                  backgroundImage: profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child: profileImageUrl.isEmpty
                                      ? const Icon(Icons.store)
                                      : null,
                                ),
                                title: Text(storeName),
                                subtitle: Text(storeAddress),
                              ),
                              const SizedBox(height: 10.0),
                              const Text(
                                'Working Days:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...List.generate(7, (index) {
                                return workingDays[index]
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
                              const SizedBox(height: 10.0),
                              const Text(
                                'Note:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(note),
                              const SizedBox(height: 10.0),
                              ListTile(
                                leading: const Icon(Icons.phone),
                                title: Text(phoneNumber),
                                onTap: () => _makePhoneCall(storeId),
                              ),
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: Text(email.isNotEmpty
                                    ? email
                                    : 'No email found'),
                                onTap: () => _sendEmail(storeId),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
