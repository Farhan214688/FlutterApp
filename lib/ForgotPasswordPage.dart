import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'package:flutter/services.dart';

// Move OTPVerificationPage and NewPasswordPage to the top level

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  OTPVerificationPage({required this.verificationId, required this.phoneNumber});

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _verifyOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verify the OTP and sign in
      UserCredential? userCredential = await _authService.signInWithPhoneCredential(
        widget.verificationId,
        _otpController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (userCredential != null && userCredential.user != null) {
        // Navigate to new password screen with the user's UID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordPage(
              userId: userCredential.user!.uid,
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the OTP sent to your phone'),
            SizedBox(height: 10),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyOTP,
                    child: Text('Verify OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}

class NewPasswordPage extends StatefulWidget {
  final String userId;
  final String phoneNumber;

  NewPasswordPage({required this.userId, required this.phoneNumber});

  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _setNewPassword() async {
    final newPassword = _passwordController.text.trim();
    
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user type from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
          
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userType = userData['userType'] as String? ?? 'customer';
      final name = userData['name'] as String? ?? '';
      final phone = userData['phone'] as String? ?? widget.phoneNumber;

      // Store the new password in SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      
      if (userType == 'customer') {
        // Ensure the customer record exists in SharedPreferences
        String? existingPhone = prefs.getString('customerPhone');
        if (existingPhone == null || existingPhone.isEmpty) {
          // Create the local record if it doesn't exist
          await prefs.setString('customerName', name);
          await prefs.setString('customerPhone', phone);
        }
        await prefs.setString('customerPassword', newPassword);
      } else if (userType == 'professional') {
        // Ensure the professional record exists in SharedPreferences
        String? existingPhone = prefs.getString('professionalPhone');
        if (existingPhone == null || existingPhone.isEmpty) {
          // Create the local record if it doesn't exist
          await prefs.setString('professionalName', name);
          await prefs.setString('professionalPhone', phone);
        }
        await prefs.setString('professionalPassword', newPassword);
      }

      // Update the login state
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('userId', widget.userId);
      await prefs.setString('userType', userType);
      await prefs.setString('username', name);
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully.')),
      );
      
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set New Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your new password'),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New Password',
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _setNewPassword,
                    child: Text('Set Password'),
                  ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _verificationId;

  void _sendOTP() async {
    final phoneNumber = '+92${_phoneNumberController.text.trim()}';
    final regex = RegExp(r'^\+923[0-9]{2}[0-9]{3}[0-9]{4}$');

    if (!regex.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Invalid phone number format. Please enter a valid Pakistani phone number.')),
      );
      return;
    }

    // First check if this user exists in Firestore
    bool userExists = await _authService.userExistsByPhone(phoneNumber);
    
    if (!userExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No account found with this phone number. Please sign up.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the AuthService to send verification code
      await _authService.sendPhoneVerificationCode(
        phoneNumber,
        (String verificationId) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationPage(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
              ),
            ),
          );
        },
        (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = 'Verification failed. Please try again later.';
          if (e.code == 'quotaExceeded') {
            errorMessage = 'SMS quota exceeded. Please try again later.';
          } else if (e.code == 'operation-not-allowed') {
            errorMessage = 'Phone authentication is not enabled. Please contact support.';
          } else {
            errorMessage = 'Error: ${e.message}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
          print('Verification failed with error: ${e.code} - ${e.message}');
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your contact number to receive an OTP'),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+92',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Contact Number',
                      hintText: '3XXXXXXXXX',
                      counterText: '',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _sendOTP,
                    child: Text('Send OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}
