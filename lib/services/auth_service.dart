import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure Firebase is initialized
      bool initialized = await _firebaseService.ensureInitialized();
      if (!initialized) {
        print("Cannot sign in with Google: Firebase not initialized");
        return null;
      }

      // Get Firebase Auth
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth == null) {
        print("Cannot sign in with Google: FirebaseAuth not available");
        return null;
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Save login state and user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userCredential.user?.uid ?? '');
      await prefs.setString('userType', 'professional');
      await prefs.setString('userName', userCredential.user?.displayName ?? '');
      await prefs.setString('userEmail', userCredential.user?.email ?? '');

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign in with Facebook - Simplified for compatibility
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Ensure Firebase is initialized
      bool initialized = await _firebaseService.ensureInitialized();
      if (!initialized) {
        print("Cannot sign in with Facebook: Firebase not initialized");
        return null;
      }

      // Get Firebase Auth
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth == null) {
        print("Cannot sign in with Facebook: FirebaseAuth not available");
        return null;
      }

      // Trigger the sign-in flow with basic permissions
      final LoginResult result = await _facebookAuth.login();

      // Check login status
      if (result.status != LoginStatus.success) {
        print("Facebook login failed with status: ${result.status}");
        return null;
      }

      // Get the token - this is now compatible with older versions
      final String? token = result.accessToken?.token;
      if (token == null) {
        print("Facebook login failed: No access token");
        return null;
      }

      // Create credential using the access token
      final credential = FacebookAuthProvider.credential(token);

      // Sign in to Firebase with the Facebook credential
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Save login state and user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userCredential.user?.uid ?? '');
      await prefs.setString('userType', 'professional');
      await prefs.setString('userName', userCredential.user?.displayName ?? '');
      await prefs.setString('userEmail', userCredential.user?.email ?? '');

      return userCredential;
    } catch (e) {
      print('Error signing in with Facebook: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth == null) {
        print("Cannot sign in: FirebaseAuth not available");
        return null;
      }

      final UserCredential userCredential =
          await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save login state and user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userCredential.user?.uid ?? '');
      await prefs.setString('userType', 'professional');
      await prefs.setString('userName', userCredential.user?.displayName ?? '');
      await prefs.setString('userEmail', userCredential.user?.email ?? '');

      return userCredential;
    } catch (e) {
      print('Error signing in with email and password: $e');
      return null;
    }
  }

  // Send verification code for phone authentication
  Future<String?> sendPhoneVerificationCode(
      String phoneNumber,
      Function(String) onCodeSent,
      Function(FirebaseAuthException) onVerificationFailed) async {
    try {
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth == null) {
        print("Cannot send verification code: FirebaseAuth not available");
        return null;
      }

      String? verificationId;

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (not typically used for most regions)
          print("Auto verification completed");
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.message}");
          onVerificationFailed(e);
        },
        codeSent: (String vId, int? resendToken) {
          verificationId = vId;
          onCodeSent(vId);
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );

      return verificationId;
    } catch (e) {
      print('Error sending phone verification code: $e');
      return null;
    }
  }

  // Sign in with phone number and verification code
  Future<UserCredential?> signInWithPhoneCredential(
      String verificationId, String smsCode) async {
    try {
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth == null) {
        print("Cannot sign in with phone: FirebaseAuth not available");
        return null;
      }

      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with the credential
      UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Get the user ID
      String uid = userCredential.user?.uid ?? '';

      // Save basic login info to SharedPreferences for convenience
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', uid);

      return userCredential;
    } catch (e) {
      print('Error signing in with phone credential: $e');
      return null;
    }
  }

  // Register a new user with phone and password in Firestore
  Future<bool> registerUserInFirestore({
    required String uid,
    required String name,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      // Access Firestore
      final firestore = FirebaseFirestore.instance;

      // Create a user document in the users collection
      await firestore.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        // Do not store the actual password in Firestore for security reasons
        // We only store it in SharedPreferences for convenience
      });

      // For backward compatibility, still store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      if (userType == 'customer') {
        await prefs.setString('customerName', name);
        await prefs.setString('customerPhone', phone);
        await prefs.setString('customerPassword', password);
      } else if (userType == 'professional') {
        await prefs.setString('professionalName', name);
        await prefs.setString('professionalPhone', phone);
        await prefs.setString('professionalPassword', password);
      }

      await prefs.setString('userType', userType);
      await prefs.setString('username', name);
      await prefs.setBool('isUserLoggedIn', true);

      return true;
    } catch (e) {
      print('Error registering user in Firestore: $e');
      return false;
    }
  }

  // Check if a user exists in Firestore by phone number
  Future<bool> userExistsByPhone(String phone) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Try with the provided phone number first
      var querySnapshot = await firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      }

      // If not found, try with a normalized version
      String normalizedPhone = _normalizePhoneNumber(phone);
      if (normalizedPhone != phone) {
        querySnapshot = await firestore
            .collection('users')
            .where('phone', isEqualTo: normalizedPhone)
            .limit(1)
            .get();

        return querySnapshot.docs.isNotEmpty;
      }

      return false;
    } catch (e) {
      print('Error checking if user exists by phone: $e');
      return false;
    }
  }

  // Helper method to normalize phone number
  String _normalizePhoneNumber(String phoneNumber) {
    // Remove spaces and dashes
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');

    // Convert to international format
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '+92' + phoneNumber.substring(1);
    } else if (!phoneNumber.startsWith('+92')) {
      phoneNumber = '+92' + phoneNumber;
    }

    return phoneNumber;
  }

  // Get user details from Firestore by phone
  Future<Map<String, dynamic>?> getUserDetailsByPhone(String phone) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Try with the provided phone number first
      var querySnapshot = await firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }

      // If not found, try with a normalized version
      String normalizedPhone = _normalizePhoneNumber(phone);
      if (normalizedPhone != phone) {
        querySnapshot = await firestore
            .collection('users')
            .where('phone', isEqualTo: normalizedPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.data();
        }
      }

      return null;
    } catch (e) {
      print('Error getting user details by phone: $e');
      return null;
    }
  }

  // Helper method to generate a random nonce
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Helper method to compute SHA256 of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final FirebaseAuth? auth = _firebaseService.getAuth();
    final prefs = await SharedPreferences.getInstance();

    final firebaseLoggedIn = auth?.currentUser != null;
    final prefsLoggedIn = prefs.getBool('isUserLoggedIn') ?? false;

    // Sync the two states if they don't match
    if (firebaseLoggedIn && !prefsLoggedIn) {
      await prefs.setBool('isUserLoggedIn', true);
    }

    return firebaseLoggedIn;
  }

  // Get current user ID
  String? getCurrentUserId() {
    final FirebaseAuth? auth = _firebaseService.getAuth();
    return auth?.currentUser?.uid;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth != null) {
        await auth.signOut();
      }

      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print("Error signing out from Google: $e");
      }

      try {
        await _facebookAuth.logOut();
      } catch (e) {
        print("Error signing out from Facebook: $e");
        // Ignore MissingPluginException for Facebook Auth
      }

      // Get current preferences
      final prefs = await SharedPreferences.getInstance();
      
      // Store important flags before clearing
      final termsAccepted = prefs.getBool('terms_accepted') ?? false;
      final isFirstTime = prefs.getBool('isFirstTime') ?? false;

      // Clear login state only, preserve credentials
      await prefs.setBool('isLoggedIn', false);
      await prefs.setBool('isUserLoggedIn', false);
      await prefs.setBool('userHasLoggedOut', true);

      // Restore important flags
      await prefs.setBool('terms_accepted', termsAccepted);
      await prefs.setBool('isFirstTime', isFirstTime);

      // DO NOT remove these credential-related fields:
      // - professionalPhone
      // - professionalPassword
      // - professionalName
      // - customerPhone
      // - customerPassword
      // - customerName

      // Only remove session-specific data
      await prefs.remove('userId');
    } catch (e) {
      print("Error during signOut: $e");
    }
  }

  // Sign in with phone and password
  Future<UserCredential?> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      final FirebaseAuth? auth = _firebaseService.getAuth();
      if (auth == null) {
        print("Cannot sign in: FirebaseAuth not available");
        return null;
      }

      // First check if user exists in Firestore
      final userDetails = await getUserDetailsByPhone(phone);
      if (userDetails == null) {
        print("User not found in Firestore");
        return null;
      }

      // Create a custom token for the user
      final customToken = await _firebaseService.createCustomToken(phone);
      if (customToken == null) {
        print("Failed to create custom token");
        return null;
      }

      // Sign in with the custom token
      final userCredential = await auth.signInWithCustomToken(customToken);
      
      if (userCredential.user == null) {
        print("Error: User credential is null after sign in");
        return null;
      }

      final userId = userCredential.user!.uid;
      print('Debug - Sign in successful, userId: $userId');

      // Save login state and user ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userType', userDetails['userType'] ?? 'customer');
      await prefs.setString('userName', userDetails['name'] ?? 'User');
      await prefs.setString('customerPhone', phone);

      // Verify that userId was saved correctly
      final savedUserId = prefs.getString('userId');
      if (savedUserId != userId) {
        print('Error: userId not saved correctly. Expected: $userId, Got: $savedUserId');
        // Try to save again
        await prefs.setString('userId', userId);
        final retryUserId = prefs.getString('userId');
        print('Debug - Retry save userId. Expected: $userId, Got: $retryUserId');
      } else {
        print('Debug - userId saved successfully: $userId');
      }

      print('Successfully saved user ID: $userId');
      return userCredential;
    } catch (e) {
      print('Error signing in with phone and password: $e');
      return null;
    }
  }
}
