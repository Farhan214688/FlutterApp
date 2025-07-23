import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Generate a random 6-digit OTP
  String generateOTP() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000; // Ensures 6 digits
    return otp.toString();
  }
  
  // Hash the OTP for secure storage
  String hashOTP(String otp, String phone) {
    final bytes = utf8.encode(otp + phone); // Salt with phone number
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Send OTP to the user's phone using Firebase Authentication
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Call the API service which handles Firebase Auth
      final apiResponse = await ApiService.sendOtp(phoneNumber);
      
      if (apiResponse['success'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  // Verify the OTP entered by the user
  Future<bool> verifyOTP(String phoneNumber, String enteredOTP) async {
    try {
      // Try Firebase verification
      try {
        // Call the API service for verification through Firebase Auth
        final apiResponse = await ApiService.verifyOtp(phoneNumber, enteredOTP);
        
        if (apiResponse['success'] == true) {
          // Mark as verified in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('phoneVerified', true);
          await prefs.setString('verifiedPhone', phoneNumber);
          
          // Store the Firebase UID if available
          if (apiResponse['data'] != null && apiResponse['data']['userId'] != null) {
            await prefs.setString('firebase_uid', apiResponse['data']['userId']);
          }
          
          // Try to update Firestore if available
          try {
            await _firestore.collection('users').doc(phoneNumber).set({
              'phoneNumber': phoneNumber,
              'verified': true,
              'verifiedAt': FieldValue.serverTimestamp(),
              'firebase_uid': _auth.currentUser?.uid
            }, SetOptions(merge: true));
          } catch (firestoreError) {
            // Continue if Firestore isn't available
          }
          
          return true;
        }
        
        // If verification failed
        return false;
      } catch (firebaseError) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  // Get the current OTP for testing purposes
  Future<String?> getCurrentOTP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentOTP');
  }
  
  // Check if a phone number is verified
  Future<bool> isPhoneVerified(String phoneNumber) async {
    try {
      // First check if there's a currently signed-in user
      if (_auth.currentUser != null) {
        return true;
      }
      
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final isVerified = prefs.getBool('phoneVerified') ?? false;
      final verifiedPhone = prefs.getString('verifiedPhone');
      
      // Only return true if the phone number matches the verified one
      return isVerified && verifiedPhone == phoneNumber;
    } catch (e) {
      return false;
    }
  }
  
  // Reset verification attempts
  Future<bool> resetVerificationAttempts(String phoneNumber) async {
    try {
      // Reset attempts in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('attempts_$phoneNumber', 0);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Sign out the current user
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear verification status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('phoneVerified', false);
      await prefs.remove('verifiedPhone');
      await prefs.remove('firebase_uid');
      
      return true;
    } catch (e) {
      return false;
    }
  }
} 