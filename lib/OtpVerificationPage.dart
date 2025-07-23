import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/otp_service.dart';
import 'DashBoard.dart';
import 'ProfessionalServiceSelectionPage.dart';
import 'services/shared_prefs_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Widgets/responsive_button.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String userType; // 'customer' or 'professional'
  final String? verificationId; // Added for Firebase Authentication
  final String? password; // Added for storing password after verification
  final String? fullName; // Added for storing user details after verification

  const OtpVerificationPage({
    Key? key,
    required this.phoneNumber,
    required this.userType,
    this.verificationId,
    this.password,
    this.fullName,
  }) : super(key: key);

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with WidgetsBindingObserver {
  final OtpService _otpService = OtpService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  int _remainingSeconds = 120; // 2 minutes (Firebase default timeout)
  bool _isResendEnabled = false;
  bool _isVerifying = false;
  bool _isOtpSent = false;
  String _errorMessage = '';
  Timer? _timer;

  // Handle auto SMS retrieval
  StreamSubscription<User?>? _authStateChanges;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for auth state changes (auto SMS retrieval)
    _authStateChanges = _auth.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        // User has been auto-verified - proceed to next screen
        _onVerificationSuccess(user.uid);
      }
    });

    // Start by sending OTP if we don't have a verification ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.verificationId == null) {
        _sendOTP();
      } else {
        // If verification ID was provided, mark OTP as sent
        setState(() {
          _isOtpSent = true;
          _startTimer();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authStateChanges?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume timer when app comes back to foreground
    if (state == AppLifecycleState.resumed &&
        !_isResendEnabled &&
        _timer == null) {
      _startTimer();
    }
    // Pause timer when app goes to background
    else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isOtpSent = false;
      _errorMessage = '';
      _isResendEnabled = false;
    });

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.lightGreen),
                SizedBox(width: 20),
                Text("Sending OTP..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Format phone number if needed
      String phoneToUse = widget.phoneNumber;
      if (!phoneToUse.startsWith('+')) {
        if (phoneToUse.startsWith('03')) {
          // Pakistan number
          phoneToUse = '+92' + phoneToUse.substring(1);
        } else if (phoneToUse.startsWith('3')) {
          // Handle case where user entered without leading 0
          phoneToUse = '+923' + phoneToUse.substring(1);
        } else {
          // Add default country code if needed
          phoneToUse = '+' + phoneToUse;
        }
      }

      // Use Firebase Authentication to send OTP
      await _authService.sendPhoneVerificationCode(phoneToUse,
          (String verificationId) {
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        setState(() {
          _isOtpSent = true;
          _remainingSeconds = 120; // Reset timer to 2 minutes
          _errorMessage = '';
        });

        // Store verification ID for later use
        final prefs = SharedPreferences.getInstance();
        prefs.then((p) => p.setString('verificationId', verificationId));

        // Start the countdown timer
        _startTimer();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully! Check your messages.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }, (FirebaseAuthException e) {
        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        String errorMessage = 'Error sending OTP';
        if (e.code == 'too-many-requests') {
          errorMessage = 'Too many attempts. Please try again later.';
        } else if (e.code == 'invalid-phone-number') {
          errorMessage = 'Invalid phone number format.';
        } else {
          errorMessage = e.message ?? 'Unknown error occurred';
        }

        setState(() {
          _errorMessage = errorMessage;
          _isResendEnabled = true; // Enable resend if sending fails
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 8),
          ),
        );
      });
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      setState(() {
        _errorMessage = 'Error sending OTP. Please try again.';
        _isResendEnabled = true;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending OTP. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((e) => e.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      // Get verification ID - either from widget or from SharedPreferences
      String? verificationId = widget.verificationId;
      if (verificationId == null) {
        final prefs = await SharedPreferences.getInstance();
        verificationId = prefs.getString('verificationId');
      }

      if (verificationId == null) {
        throw Exception('Verification ID not found. Please request a new OTP.');
      }

      // Use Firebase to verify OTP
      UserCredential? userCredential =
          await _authService.signInWithPhoneCredential(verificationId, otp);

      if (userCredential != null && userCredential.user != null) {
        _onVerificationSuccess(userCredential.user!.uid);
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Invalid verification code';
        });
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Invalid OTP or verification failed. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onVerificationSuccess(String uid) async {
    // Register user in Firestore if required data is provided
    if (widget.fullName != null && widget.password != null) {
      await _authService.registerUserInFirestore(
        uid: uid,
        name: widget.fullName!,
        phone: widget.phoneNumber,
        password: widget.password!,
        userType: widget.userType,
      );
    }

    // Update login status in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLoggedIn', true);
    await prefs.setString('userId', uid);
    await prefs.setString('userType', widget.userType);

    // Navigate based on user type
    if (widget.userType == 'professional') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => ProfessionalServiceSelectionPage()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Dashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: Text('Verify Mobile Number'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // Logo
              Container(
                height: 120,
                width: 120,
                child: Image.asset('Assets/Images/Logo1.png'),
              ),
              SizedBox(height: 30),
              // Heading
              Text(
                'Verify your mobile number to complete registration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              // Subheading with phone number
              Text(
                'Enter the 6 digit code that you received on',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                widget.phoneNumber,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => _buildOtpTextField(index),
                ),
              ),
              SizedBox(height: 16),
              // Error message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              SizedBox(height: 32),
              // Timer and Resend button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isResendEnabled)
                    Text(
                      'Resend code in $_formattedTime',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _sendOTP,
                      child: Text(
                        'Resend Code',
                        style: TextStyle(
                          color: Colors.lightGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 40),
              // Verify Button
              ResponsiveButton(
                text: 'VERIFY',
                onPressed: _isOtpComplete() && !_isVerifying ? _verifyOTP : null,
                isFullWidth: true,
                isLoading: _isVerifying,
                backgroundColor: Colors.lightGreen,
                textColor: Colors.white,
                fontSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTextField(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNodes[index].hasFocus ? Colors.lightGreen : Colors.grey,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }
          setState(() {}); // Update button state

          // If the last digit is entered, trigger verification automatically
          if (index == 5 && value.isNotEmpty && _isOtpComplete()) {
            _verifyOTP();
          }
        },
      ),
    );
  }

  bool _isOtpComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
