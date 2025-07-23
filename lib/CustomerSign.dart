import 'package:firstt_project/DashBoard.dart';
import 'package:firstt_project/LoginPage.dart';
import 'package:firstt_project/OtpVerificationPage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/shared_prefs_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerSign extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CustomerSignState();
  }
}

class CustomerSignState extends State<CustomerSign> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool? isChecked1 = false;
  bool? isChecked2 = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  var FullNameController = TextEditingController();
  var PhoneNumberController = TextEditingController();
  var PasswordController = TextEditingController();
  var ConfirmPassController = TextEditingController();

  // Add validation functions
  bool _isValidPassword(String password) {
    // Password must be at least 8 characters and contain:
    // - At least one uppercase letter
    // - At least one lowercase letter
    // - At least one number
    // - At least one special character
    final RegExp passwordRegex = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool _isValidPhoneNumber(String phone) {
    // Phone number must be exactly 11 digits
    final RegExp phoneRegex = RegExp(r'^\d{11}$');
    return phoneRegex.hasMatch(phone);
  }

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

  Future<void> _sendVerificationCode() async {
    // Validate inputs
    if (FullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (!_isValidPhoneNumber(PhoneNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 11-digit phone number')),
      );
      return;
    }

    if (!_isValidPassword(PasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Password must be at least 8 characters and contain at least one uppercase letter, one lowercase letter, one number, and one special character')),
      );
      return;
    }

    if (PasswordController.text != ConfirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (isChecked2 != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    // Check if the account with this phone number already exists
    final normalizedPhone = _normalizePhoneNumber(PhoneNumberController.text);
    final userExists = await _authService.userExistsByPhone(normalizedPhone);

    if (userExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'An account with this phone number already exists. Please log in or use a different number.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Send verification code
      await _authService.sendPhoneVerificationCode(
        normalizedPhone,
        (String verificationId) {
          setState(() {
            _isLoading = false;
          });

          // Navigate to OTP verification page with all necessary information
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                verificationId: verificationId,
                phoneNumber: normalizedPhone,
                password: PasswordController.text,
                fullName: FullNameController.text,
                userType: 'customer',
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
            errorMessage =
                'Phone authentication is not enabled. Please contact support.';
          } else if (e.code == 'invalid-phone-number') {
            errorMessage =
                'The phone number format is incorrect. Please enter a valid number.';
          } else {
            errorMessage = 'Error: ${e.message}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
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
        backgroundColor: Colors.greenAccent,
        title: Text('Customer Sign'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 135,
                    width: 135,
                    child: Image.asset('Assets/Images/Logo1.png'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              'Sign Up as Customer',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                controller: FullNameController,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.lightGreenAccent,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.black38,
                      width: 2,
                    ),
                  ),
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.account_circle_sharp),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                controller: PhoneNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 11, // Exactly 11 digits
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.lightGreenAccent,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.black38,
                      width: 2,
                    ),
                  ),
                  hintText: '03XXXXXXXXX',
                  prefixIcon: Icon(Icons.add_call),
                  counterText: '',
                ),
                onChanged: (value) {
                  // Remove any non-digit characters
                  String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                  // Ensure only 11 digits
                  if (digitsOnly.length > 11) {
                    digitsOnly = digitsOnly.substring(0, 11);
                  }
                  // Update the text field
                  if (digitsOnly != value) {
                    PhoneNumberController.text = digitsOnly;
                    PhoneNumberController.selection =
                        TextSelection.fromPosition(
                      TextPosition(offset: digitsOnly.length),
                    );
                  }
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                controller: PasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.lightGreenAccent,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.black38,
                      width: 2,
                    ),
                  ),
                  hintText:
                      'Password (min 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special)',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                controller: ConfirmPassController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.lightGreenAccent,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.black38,
                      width: 2,
                    ),
                  ),
                  hintText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  checkColor: Colors.lightGreenAccent,
                  value: isChecked1,
                  onChanged: (newBool) {
                    setState(() {
                      isChecked1 = newBool;
                    });
                  },
                ),
                Text(
                  'Remember Password',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  checkColor: Colors.lightGreenAccent,
                  value: isChecked2,
                  onChanged: (newBool) {
                    setState(() {
                      isChecked2 = newBool;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I agree to Terms and Conditions and accept Privacy policy',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : TextButton(
                      onPressed: _sendVerificationCode,
                      child: Text('SIGN UP'),
                    ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.black,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Signup using social account',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.black,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.google),
                    SizedBox(
                      width: 8,
                    ),
                    Text('CONTINUE WITH GOOGLE'),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 25,
            ),
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.facebook),
                    SizedBox(
                      width: 8,
                    ),
                    Text('CONTINUE WITH FACEBOOK'),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?'),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
