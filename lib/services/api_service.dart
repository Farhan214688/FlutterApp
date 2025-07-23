import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ApiService {
  // Base URL for the API
  static const String baseUrl = 'https://api.rapit.com';
  
  // Firebase Auth instance
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Send OTP API endpoint using Firebase Authentication
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Format the phone number to E.164 format if not already
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // For Pakistan numbers, add country code
        if (phoneNumber.startsWith('03')) {
          formattedPhone = '+92' + phoneNumber.substring(1);
        } else if (phoneNumber.startsWith('3')) {
          // Handle case where user entered without leading 0
          formattedPhone = '+923' + phoneNumber.substring(1);
        } else {
          // Add default country code if not provided
          formattedPhone = '+' + phoneNumber;
        }
      }
      
      print("Attempting to send OTP to: $formattedPhone");
      
      // Verify Firebase is initialized 
      if (FirebaseAuth.instance == null) {
        print("Firebase Auth is not initialized");
        return {
          'success': false,
          'message': 'Firebase Authentication not initialized',
        };
      }
      
      // Save the phone number for verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otpPhone', formattedPhone);
      
      // For testing - store a mock OTP so users can bypass Firebase in case of issues
      final mockOtp = '123456';
      await prefs.setString('mock_otp', mockOtp);
      print("Saved mock OTP: $mockOtp for testing");
      
      // Create a completer to handle async callbacks
      Completer<Map<String, dynamic>> completer = Completer();
      
      // Request verification code from Firebase
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: Duration(seconds: 120),
        
        // When verification completes successfully without user input
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete({
                'success': true,
                'message': 'Auto-verification completed',
                'data': {
                  'expiresIn': 120
                }
              });
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete({
                'success': false,
                'message': 'Auto-verification failed: $e',
              });
            }
          }
        },
        
        // When verification fails
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            String errorMsg = 'Verification failed';
            
            // Provide more specific error messages
            if (e.code == 'invalid-phone-number') {
              errorMsg = 'The phone number format is incorrect';
            } else if (e.code == 'too-many-requests') {
              errorMsg = 'Too many requests. Try again later';
            } else if (e.code == 'quota-exceeded') {
              errorMsg = 'SMS quota exceeded. Try again tomorrow';
            } else if (e.code == 'missing-client-identifier') {
              errorMsg = 'reCAPTCHA verification failed';
            } else {
              errorMsg = 'Verification failed: ${e.message ?? e.code}';
            }
            
            completer.complete({
              'success': false,
              'message': errorMsg
            });
          }
        },
        
        // When verification code is sent
        codeSent: (String vId, int? resendToken) {
          // Store verification ID in preferences
          prefs.setString('firebase_verification_id', vId);
          prefs.setInt('verification_resend_token', resendToken ?? 0);
          
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP sent successfully',
              'data': {
                'expiresIn': 120, // 2 minutes in seconds
                'verificationId': vId,
                'resendToken': resendToken
              }
            });
          }
        },
        
        // When verification code auto-retrieval times out
        codeAutoRetrievalTimeout: (String vId) {
          // If for some reason codeSent wasn't called, complete here
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP sent, but auto-retrieval timed out',
              'data': {
                'verificationId': vId
              }
            });
          }
        },
        forceResendingToken: prefs.getInt('verification_resend_token'),
      );
      
      // Wait for a callback to complete the future
      // Add timeout to ensure we don't hang
      return await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () => {
          'success': false,
          'message': 'Verification service timed out. Please try again.',
        },
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending verification code: $e',
      };
    }
  }
  
  // Verify OTP API endpoint
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationId = prefs.getString('firebase_verification_id');
      
      if (verificationId == null) {
        return {
          'success': false,
          'message': 'Verification ID not found. Please resend the OTP',
          'data': {
            'isVerified': false,
          }
        };
      }
      
      try {
        // Create a PhoneAuthCredential with the code
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, 
          smsCode: otp
        );
        
        // Sign in with the credential
        UserCredential userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          // Clean up verification ID after successful verification
          await prefs.remove('firebase_verification_id');
          
          return {
            'success': true,
            'message': 'OTP verified successfully',
            'data': {
              'isVerified': true,
              'userId': userCredential.user!.uid,
            }
          };
        } else {
          return {
            'success': false,
            'message': 'Verification failed: No user data',
            'data': {
              'isVerified': false,
            }
          };
        }
      } catch (authError) {
        return {
          'success': false,
          'message': 'Invalid OTP',
          'data': {
            'isVerified': false,
            'error': authError.toString(),
          }
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
        'data': {
          'isVerified': false,
        }
      };
    }
  }
} 