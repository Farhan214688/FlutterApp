import 'package:firstt_project/PreSignPage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'admin_portal.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/shared_prefs_service.dart';
import 'ProfessionalServiceSelectionPage.dart';
import 'professional_screens/ProfessionalDashboard.dart';
import 'DashBoard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/firebase_error_widget.dart';
import 'ForgotPasswordPage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  bool? isChecked1 = false;
  bool _isPasswordVisible = false;
  bool isLogin = false;
  bool _isFirebaseInitialized = false;
  bool _isLoading = true;
  var PhoneNumberController = TextEditingController();
  var PasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkFirebaseInitialization();
    _loadSavedCredentials();
    // Initialize SharedPrefsService
    SharedPrefsService.init();
  }

  Future<void> _checkFirebaseInitialization() async {
    setState(() {
      _isLoading = true;
    });

    bool isInitialized = _firebaseService.isInitialized;
    if (!isInitialized) {
      // Try to initialize
      isInitialized = await _firebaseService.ensureInitialized();
    }

    setState(() {
      _isFirebaseInitialized = isInitialized;
      _isLoading = false;
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberPassword = prefs.getBool('rememberPassword') ?? false;

      print('Loading saved credentials, remember password: $rememberPassword');

      if (rememberPassword) {
        final savedCustomerPhone = prefs.getString('customerPhone') ?? '';
        final savedCustomerPassword = prefs.getString('customerPassword') ?? '';
        final savedProfessionalPhone =
            prefs.getString('professionalPhone') ?? '';
        final savedProfessionalPassword =
            prefs.getString('professionalPassword') ?? '';

        if (savedCustomerPhone.isNotEmpty && savedCustomerPassword.isNotEmpty) {
          setState(() {
            PhoneNumberController.text = savedCustomerPhone;
            PasswordController.text = savedCustomerPassword;
            isChecked1 = true;
          });
        } else if (savedProfessionalPhone.isNotEmpty &&
            savedProfessionalPassword.isNotEmpty) {
          setState(() {
            PhoneNumberController.text = savedProfessionalPhone;
            PasswordController.text = savedProfessionalPassword;
            isChecked1 = true;
          });
        }
      }

      // Debug all SharedPreferences
      await SharedPrefsService.debugSharedPrefs();
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_isFirebaseInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Firebase is not initialized. Cannot sign in with Google.')),
      );
      return;
    }

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      final userCredential = await _authService.signInWithGoogle();

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      if (userCredential != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isUserLoggedIn', true);
        await prefs.setBool('userHasLoggedOut', false);

        // Check if this is an admin login
        if (userCredential.user?.phoneNumber == "0348 7248948") {
          await prefs.setString('userType', 'admin');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPortal()),
          );
        } else {
          // Default to customer for Google sign-in
          await prefs.setString('userType', 'customer');
          Navigator.pop(context, true);
        }

        // Get and save Firebase user ID
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? currentUser = auth.currentUser;
        if (currentUser != null) {
          await prefs.setString('userId', currentUser.uid);
          print('Saved Firebase user ID: ${currentUser.uid}');
        } else {
          print('Warning: No Firebase user found after successful login');
        }
      } else {
        // Google sign-in was cancelled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Google sign-in was cancelled or failed. Please try again.')),
        );
      }
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error signing in with Google';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('canceled')) {
        errorMessage = 'Sign-in was cancelled.';
      } else {
        errorMessage = 'Error signing in with Google: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _handleFacebookSignIn() async {
    if (!_isFirebaseInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Firebase is not initialized. Cannot sign in with Facebook.')),
      );
      return;
    }

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      final userCredential = await _authService.signInWithFacebook();

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      if (userCredential != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isUserLoggedIn', true);

        // Check if this is an admin login
        if (userCredential.user?.phoneNumber == "0348 7248948") {
          await prefs.setString('userType', 'admin');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPortal()),
          );
        } else {
          // Default to customer for Facebook sign-in
          await prefs.setString('userType', 'customer');
          Navigator.pop(context, true);
        }

        // Get and save Firebase user ID
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User? currentUser = auth.currentUser;
        if (currentUser != null) {
          await prefs.setString('userId', currentUser.uid);
          print('Saved Firebase user ID: ${currentUser.uid}');
        } else {
          print('Warning: No Firebase user found after successful login');
        }
      } else {
        // Facebook sign-in was cancelled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Facebook sign-in was cancelled or failed. Please try again.')),
        );
      }
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error signing in with Facebook';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('canceled')) {
        errorMessage = 'Sign-in was cancelled.';
      } else {
        errorMessage = 'Error signing in with Facebook: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _login() async {
    if (PhoneNumberController.text.isEmpty || PasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both phone number and password')),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting login process...');

      // Hardcoded admin check
      if (PhoneNumberController.text == "03487248948" &&
          PasswordController.text == "Kamran@123") {
        print('Admin login detected with hardcoded credentials');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isUserLoggedIn', true);
        await prefs.setBool('userHasLoggedOut', false);
        await prefs.setString('userType', 'admin');
        await prefs.setString('username', 'Admin');

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPortal()),
        );
        return;
      }

      // Get the phone number as entered by the user - AuthService will handle normalization
      String phoneNumber = PhoneNumberController.text;

      // Check if user exists in Firestore by phone number
      final userDetails = await _authService.getUserDetailsByPhone(phoneNumber);

      if (userDetails == null) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No account found with this phone number. Please sign up first.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // We found the user in Firestore, now authenticate them
      final userType = userDetails['userType'] as String? ?? 'customer';
      final name = userDetails['name'] as String? ?? 'User';
      final firestorePhone = userDetails['phone'] as String? ?? phoneNumber;

      // Initialize SharedPrefsService if not already initialized
      await SharedPrefsService.init();

      // For backward compatibility, check SharedPreferences too
      final prefs = await SharedPreferences.getInstance();

      // Try to validate with SharedPreferences first (for backward compatibility)
      bool isValid = false;

      if (userType == 'customer') {
        isValid = await SharedPrefsService.validateCustomerLogin(
            PhoneNumberController.text, PasswordController.text);
      } else if (userType == 'professional') {
        isValid = await SharedPrefsService.validateProfessionalLogin(
            PhoneNumberController.text, PasswordController.text);
      }

      if (!isValid) {
        // Check if the stored password in SharedPreferences matches
        String? storedPassword;
        if (userType == 'customer') {
          storedPassword = prefs.getString('customerPassword');
        } else if (userType == 'professional') {
          storedPassword = prefs.getString('professionalPassword');
        }

        isValid = storedPassword == PasswordController.text;
      }

      // If still not valid but user exists in Firestore, create local credentials
      if (!isValid) {
        print(
            'User found in Firestore but not in SharedPreferences. Creating local credentials.');

        // Create local credentials if user exists in Firestore but not in SharedPreferences
        if (userType == 'customer') {
          // Check if customer account exists in SharedPreferences
          String? storedCustomerPhone = prefs.getString('customerPhone');
          if (storedCustomerPhone == null || storedCustomerPhone.isEmpty) {
            // No local account, create one
            await prefs.setString('customerName', name);
            await prefs.setString('customerPhone', firestorePhone);
            await prefs.setString('customerPassword', PasswordController.text);
            print('Created local customer account with phone: $firestorePhone');
            isValid = true;
          }
        } else if (userType == 'professional') {
          // Check if professional account exists in SharedPreferences
          String? storedProfessionalPhone =
              prefs.getString('professionalPhone');
          if (storedProfessionalPhone == null ||
              storedProfessionalPhone.isEmpty) {
            // No local account, create one
            await prefs.setString('professionalName', name);
            await prefs.setString('professionalPhone', firestorePhone);
            await prefs.setString(
                'professionalPassword', PasswordController.text);
            print(
                'Created local professional account with phone: $firestorePhone');
            isValid = true;
          }
        }
      }

      if (!isValid) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid password. Please try again.')),
        );
        return;
      }

      // Authentication successful
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);
      await prefs.setString('userType', userType);
      await prefs.setString('username', name);

      // Get and save Firebase user ID
      final FirebaseAuth auth = FirebaseAuth.instance;
      final User? currentUser = auth.currentUser;
      if (currentUser != null) {
        await prefs.setString('userId', currentUser.uid);
        print('Saved Firebase user ID: ${currentUser.uid}');
      } else {
        // If no Firebase user, create one with the phone number
        try {
          final userCredential = await auth.signInAnonymously();
          if (userCredential.user != null) {
            await prefs.setString('userId', userCredential.user!.uid);
            print(
                'Created and saved anonymous Firebase user ID: ${userCredential.user!.uid}');
          }
        } catch (e) {
          print('Error creating anonymous user: $e');
        }
      }

      // Authenticate with Firebase
      try {
        final userCredential = await _authService.signInWithPhoneAndPassword(
            PhoneNumberController.text, PasswordController.text);

        if (userCredential != null) {
          print('Firebase authentication successful');
          // The user ID is already saved in the auth service
        } else {
          print('Warning: Firebase authentication failed');
        }
      } catch (e) {
        print('Error during Firebase authentication: $e');
        // Continue with the login process even if Firebase auth fails
      }

      // Save credentials if "Remember Password" is checked
      if (isChecked1 == true) {
        if (userType == 'customer') {
          await prefs.setString('customerPhone', firestorePhone);
          await prefs.setString('customerPassword', PasswordController.text);
        } else if (userType == 'professional') {
          await prefs.setString('professionalPhone', firestorePhone);
          await prefs.setString(
              'professionalPassword', PasswordController.text);
        }
        await prefs.setBool('rememberPassword', true);
      }

      setState(() {
        _isLoading = false;
      });

      // Navigate based on user type
      if (userType == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else if (userType == 'professional') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfessionalDashboard()),
        );
      } else if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPortal()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Login error: $e. Please try again or sign up if you don\'t have an account.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only clear login status, not credentials
      await prefs.setBool('isUserLoggedIn', false);
      await prefs.setBool('userHasLoggedOut', true);

      // Don't clear these:
      // - customerPhone
      // - customerPassword
      // - customerName
      // - professionalPhone
      // - professionalPassword
      // - professionalName

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  Future<void> _fixLoginIssues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SharedPrefsService.fixCommonIssues();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Login issues fixed. Please try logging in again.')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fixing issues: $e')),
      );
    }
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SharedPrefsService.clearAll();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('All user data cleared. You will need to sign up again.')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

  void _showDebugOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Debug Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('These options can help fix login issues:'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _showDebugInfo();
                },
                child: Text('Show Account Debug Info'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _fixLoginIssues();
                },
                child: Text('Fix Login Issues'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _clearAllData();
                },
                child: Text('Clear All User Data'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debugInfo = await SharedPrefsService.debugSharedPrefs();

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Account Debug Info'),
            content: SingleChildScrollView(
              child: Text(debugInfo),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting debug info: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isFirebaseInitialized) {
      return FirebaseErrorWidget(
        message:
            'Firebase services are not available. Social login options will not work.',
        onRetry: _checkFirebaseInitialization,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: 50),
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
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rapit',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: 380,
                  child: TextField(
                    controller: PhoneNumberController,
                    keyboardType: TextInputType.phone,
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
                      hintText: 'Phone Number',
                      prefixIcon: Icon(Icons.add_call),
                    ),
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
                      hintText: 'Password',
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
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage()),
                          );
                        },
                        child: Text('Forgot Password? Click here')),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: _login,
                    child: Text('LOGIN'),
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
                        'Login using social account',
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
                    onPressed: _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.google),
                        SizedBox(width: 8),
                        Text('CONTINUE WITH GOOGLE'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: _handleFacebookSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.facebook),
                        SizedBox(width: 8),
                        Text('CONTINUE WITH FACEBOOK'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 15, // Adds space below the Register button
                ),
                Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                SizedBox(
                  height: 15, // Adds space below the Register button
                ),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.green, // Green border
                      width: 2, // Border width
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => PreSignPage()));
                    },
                    child: Text('Register'),
                  ),
                ),
                SizedBox(
                  height: 20, // Adds space below the Register button
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
