import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vreceipt_customer/firebase_options.dart';
import 'package:vreceipt_customer/screen/login_screen.dart';
import 'package:vreceipt_customer/screen/home.dart';
import 'package:vreceipt_customer/screen/receipt_details.dart';
import 'package:vreceipt_customer/services/app_initilaizer.dart';
import 'package:vreceipt_customer/services/notification_controller.dart';
import 'package:vreceipt_customer/services/permission_service.dart';
import 'package:vreceipt_customer/theme_provider.dart'; // Import ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  tz.initializeTimeZones();
  await PermissionService.requestNotificationPermission();
  await AppInitialization.initialize();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelGroupKey: 'warranty_channel_group',
      channelKey: 'warranty_channel',
      channelName: 'Warranty Reminder',
      channelDescription: 'Warranty Notification Channel',
      importance: NotificationImportance.High,
    ),
  ], channelGroups: [
    NotificationChannelGroup(
      channelGroupKey: 'warranty_channel_group',
      channelGroupName: 'Warranty Group',
    ),
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: 'vReceipt Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const AuthWrapper());
          case '/notification-page':
            final transactionId = settings.arguments as String?;
            return MaterialPageRoute(
                builder: (context) => ReceiptDetailsPage(
                      transactionId: transactionId!,
                    ));
          default:
            assert(false, 'Page ${settings.name} not found');
            return null;
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          _requestPermissions(context); // Request permissions after login
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Customer')
                .doc(snapshot.data!.email)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasData &&
                  snapshot.data!.exists &&
                  snapshot.data!.data() != null) {
                return const TransactionScreen();
              }
              return const Scaffold(
                body: Center(
                  child: Text('No shopping receipts found.'),
                ),
              );
            },
          );
        }
        return const LoginScreen();
      },
    );
  }

  void _requestPermissions(BuildContext context) async {
    await PermissionService.requestNotificationPermission();
    await PermissionService.requestCameraPermission(context);
    await PermissionService.requestGalleryPermission(context);
    await PermissionService.requestLocationPermission(
        context); // Request location permission
  }
}
