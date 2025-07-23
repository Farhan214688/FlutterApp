import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import reference to our global FirebaseApp variable
import '../main.dart' show firebaseApp;

// Singleton service to manage Firebase instance
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  // Getter for the singleton instance
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  // Check if Firebase is initialized
  bool get isInitialized => Firebase.apps.isNotEmpty && firebaseApp != null;

  // Get Firebase Auth instance safely
  FirebaseAuth? getAuth() {
    if (!isInitialized) {
      print("Firebase not initialized when trying to access Auth");
      return null;
    }

    try {
      return FirebaseAuth.instance;
    } catch (e) {
      print("Error getting FirebaseAuth: $e");
      return null;
    }
  }

  // Initialize Firebase if needed
  Future<bool> ensureInitialized() async {
    if (isInitialized) {
      return true;
    }

    try {
      // Check if Firebase is already initialized before initializing
      if (Firebase.apps.isEmpty) {
        print("Firebase not initialized, initializing now");
        await Firebase.initializeApp();
      } else {
        print("Firebase already initialized, using existing app");
      }
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      print("Couldn't initialize Firebase: $e");
      return false;
    }
  }

  // Create a custom token for phone authentication
  Future<String?> createCustomToken(String phone) async {
    try {
      // Get the Firebase Auth instance
      final auth = getAuth();
      if (auth == null) {
        print("Firebase Auth not available");
        return null;
      }

      // Create a custom token using the phone number as the UID
      final customToken = await auth.currentUser?.getIdToken();
      if (customToken == null) {
        print("Failed to get custom token");
        return null;
      }

      return customToken;
    } catch (e) {
      print("Error creating custom token: $e");
      return null;
    }
  }
}
