import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'pages/restaurant/restaurant_home_page.dart';
import 'pages/restaurant/restaurant_details_page.dart';
import 'pages/restaurant/restaurant_tables_page.dart';
import 'pages/restaurant/restaurant_notifications_page.dart';
import 'pages/restaurant/restaurant_profile_setup_page.dart';
import 'dart:async';

Future<void> main() async {
  // Capture Firebase initialization errors
  await runZonedGuarded(
    () async {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize Firebase with error handling
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Initialize Firebase App Check with debug provider
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        );

        // Disable verbose debug logs from Firebase
        FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
      }

      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('Caught error in main: $error');
      debugPrint(stackTrace.toString());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greedy Bites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const LoginPage(),
      routes: {
        '/signup': (context) => const SignUpPage(),
        '/restaurant/home': (context) => const RestaurantHomePage(),
        '/restaurant/details': (context) => const RestaurantDetailsPage(),
        '/restaurant/tables': (context) => const RestaurantTablesPage(),
        '/restaurant/notifications': (context) => const RestaurantNotificationsPage(),
        '/restaurant/profile-setup': (context) => const RestaurantProfileSetupPage(),
      },
    );
  }
}
