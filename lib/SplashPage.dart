import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DashBoard.dart';
import 'StartingPage1.dart';
import 'professional_screens/ProfessionalDashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'LoginPage.dart';
import 'ProfessionalServiceSelectionPage.dart';
import 'IDCardVerificationPage.dart';
import 'SelfieVerificationPage.dart';
import 'SelfiePage.dart';
import 'LocationPickerPage.dart';
import 'CongratulationsPage.dart';
import 'admin_portal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

// Note: Firebase initialization is handled in main.dart

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rapit',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashPage(),
      routes: {
        '/dashboard': (context) => Dashboard(),
        '/admin': (context) => ProfessionalDashboard(),
        '/starting': (context) => StartingPage(),
        '/login': (context) => LoginPage(),
        '/professional-service': (context) =>
            ProfessionalServiceSelectionPage(),
        '/home': (context) => Dashboard(), // Add dashboard as home route
        '/professional_dashboard': (context) => ProfessionalDashboard(),
      },
    );
  }
}

// Function to force clear all login data on app restart (for development)
Future<void> clearAllLoginDataOnRestart() async {
  try {
    print("🔥 CLEARING LOGIN STATE ON RESTART 🔥");
    final prefs = await SharedPreferences.getInstance();

    // Clear only authentication state, not credentials
    await prefs.setBool('isUserLoggedIn', false);
    await prefs.setBool('isLoggedIn', false);
    await prefs.setBool('userHasLoggedOut', true);

    // DO NOT remove these credential-related fields:
    // - professionalPhone
    // - professionalPassword
    // - professionalName
    // - customerPhone
    // - customerPassword
    // - customerName

    print("✅ Login state cleared on app restart");
  } catch (e) {
    print("⚠️ Error clearing login data: $e");
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if it's the first time launching the app
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      final isUserLoggedIn = prefs.getBool('isUserLoggedIn') ?? false;
      final userHasLoggedOut = prefs.getBool('userHasLoggedOut') ?? false;
      final lastScreen = prefs.getString('lastScreen');
      final userType = prefs.getString('userType');

      print('Debug - Splash Screen Navigation:');
      print('Debug - isFirstTime: $isFirstTime');
      print('Debug - isUserLoggedIn: $isUserLoggedIn');
      print('Debug - userHasLoggedOut: $userHasLoggedOut');
      print('Debug - lastScreen: $lastScreen');
      print('Debug - userType: $userType');

      // Check Firebase Auth first to see if user is logged in
      final bool isFirebaseUserLoggedIn = await _authService.isUserLoggedIn();
      print("Debug - Firebase user logged in? $isFirebaseUserLoggedIn");

      // If user is logged in (either through Firebase or SharedPreferences)
      if (isFirebaseUserLoggedIn || (isUserLoggedIn && !userHasLoggedOut)) {
        print("Debug - User is logged in, checking user type");
        
        // For professionals, always go to professional dashboard
        if (userType == 'professional' || lastScreen == 'professional_dashboard') {
          print("Debug - Professional user detected, going to professional dashboard");
          Navigator.pushReplacementNamed(context, '/professional_dashboard');
          return;
        }
        
        // For admins, go to admin portal
        if (userType == 'admin') {
          print("Debug - Admin user detected, going to admin portal");
          Navigator.pushReplacementNamed(context, '/admin');
          return;
        }
        
        // For customers, go to customer dashboard
        print("Debug - Customer user detected, going to customer dashboard");
        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      }

      // If user is not logged in
      print("Debug - User not logged in, checking if first time");
      
      // Only show onboarding for first time users
      if (isFirstTime) {
        print("Debug - First time user, showing onboarding");
        await prefs.setBool('isFirstTime', false);
        Navigator.pushReplacementNamed(context, '/starting');
      } else {
        // For returning users who aren't logged in, go to dashboard
        print("Debug - Returning user not logged in, going to dashboard");
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('Error in splash screen navigation: $e');
      // On error, go to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'Assets/Images/Logo1.png',
                width: 200,
                height: 200,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 20),
              Text(
                'Rapit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
