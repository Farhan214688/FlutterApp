import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static SharedPreferences? _prefs;

  // Initialize the SharedPreferences instance
  static Future<void> init() async {
    try {
      if (_prefs == null) {
        print('Initializing SharedPrefsService...');
        _prefs = await SharedPreferences.getInstance();
        print('SharedPrefsService initialized successfully');
      } else {
        print('SharedPrefsService already initialized');
      }
    } catch (e) {
      print('Error initializing SharedPrefsService: $e');
      // Try again with a new instance
      try {
        _prefs = await SharedPreferences.getInstance();
        print('SharedPrefsService initialized on second attempt');
      } catch (e) {
        print('Failed to initialize SharedPrefsService: $e');
      }
    }
  }

  // Get the SharedPreferences instance
  static Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      await init();
    }

    // Double-check initialization was successful
    if (_prefs == null) {
      print(
          'WARNING: SharedPrefsService not initialized properly. Creating new instance.');
      _prefs = await SharedPreferences.getInstance();
    }

    return _prefs!;
  }

  // Save customer account
  static Future<bool> saveCustomerAccount({
    required String name,
    required String phone,
    required String password,
    required bool rememberPassword,
  }) async {
    try {
      final prefs = await SharedPrefsService.prefs;

      // Save customer info
      await prefs.setString('customerName', name);
      await prefs.setString('customerPhone', phone);
      await prefs.setString('customerPassword', password);

      // Set login status
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('username', name);
      await prefs.setString('userType', 'customer');

      // Save remember password preference
      await prefs.setBool('rememberPassword', rememberPassword);

      print('Customer account saved successfully:');
      print('Name: $name');
      print('Phone: $phone');

      // Verify the data was saved
      final verifyPhone = prefs.getString('customerPhone');
      if (verifyPhone != phone) {
        print('ERROR: Customer phone verification failed');
        return false;
      }

      return true;
    } catch (e) {
      print('Error saving customer account: $e');
      return false;
    }
  }

  // Save professional account
  static Future<bool> saveProfessionalAccount({
    required String name,
    required String phone,
    required String password,
    required bool rememberPassword,
  }) async {
    try {
      final prefs = await SharedPrefsService.prefs;

      // Save professional info
      await prefs.setString('professionalName', name);
      await prefs.setString('professionalPhone', phone);
      await prefs.setString('professionalPassword', password);

      // Set login status
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('username', name);
      await prefs.setString('userType', 'professional');

      // Save remember password preference
      await prefs.setBool('rememberPassword', rememberPassword);

      print('Professional account saved successfully:');
      print('Name: $name');
      print('Phone: $phone');

      // Verify the data was saved
      final verifyPhone = prefs.getString('professionalPhone');
      if (verifyPhone != phone) {
        print('ERROR: Professional phone verification failed');
        return false;
      }

      return true;
    } catch (e) {
      print('Error saving professional account: $e');
      return false;
    }
  }

  // Check if customer account exists
  static Future<bool> customerAccountExists(String phone) async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final customerPhone = prefs.getString('customerPhone') ?? '';
      return phone.isNotEmpty && customerPhone == phone;
    } catch (e) {
      print('Error checking if customer account exists: $e');
      return false;
    }
  }

  // Check if professional account exists
  static Future<bool> professionalAccountExists(String phone) async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final professionalPhone = prefs.getString('professionalPhone') ?? '';
      return phone.isNotEmpty && professionalPhone == phone;
    } catch (e) {
      print('Error checking if professional account exists: $e');
      return false;
    }
  }

  // Check if any customer account exists
  static Future<bool> anyCustomerAccountExists() async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final customerPhone = prefs.getString('customerPhone') ?? '';
      return customerPhone.isNotEmpty;
    } catch (e) {
      print('Error checking if any customer account exists: $e');
      return false;
    }
  }

  // Check if any professional account exists
  static Future<bool> anyProfessionalAccountExists() async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final professionalPhone = prefs.getString('professionalPhone') ?? '';
      return professionalPhone.isNotEmpty;
    } catch (e) {
      print('Error checking if any professional account exists: $e');
      return false;
    }
  }

  // Validate customer login
  static Future<bool> validateCustomerLogin(
      String phone, String password) async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final customerPhone = prefs.getString('customerPhone') ?? '';
      final customerPassword = prefs.getString('customerPassword') ?? '';

      print('Validating customer login:');
      print('Entered phone: $phone, Stored phone: $customerPhone');
      print('Password match: ${customerPassword == password}');

      return customerPhone == phone && customerPassword == password;
    } catch (e) {
      print('Error validating customer login: $e');
      return false;
    }
  }

  // Validate professional login
  static Future<bool> validateProfessionalLogin(
      String phone, String password) async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final professionalPhone = prefs.getString('professionalPhone') ?? '';
      final professionalPassword =
          prefs.getString('professionalPassword') ?? '';

      print('Validating professional login:');
      print('Entered phone: $phone, Stored phone: $professionalPhone');
      print('Password match: ${professionalPassword == password}');

      return professionalPhone == phone && professionalPassword == password;
    } catch (e) {
      print('Error validating professional login: $e');
      return false;
    }
  }

  // Debug method to print all SharedPreferences data
  static Future<String> debugSharedPrefs() async {
    try {
      final prefs = await SharedPrefsService.prefs;
      final allKeys = prefs.getKeys();

      String debugInfo = 'SharedPreferences Debug:\n';
      debugInfo += 'All Keys: ${allKeys.join(", ")}\n';

      for (final key in allKeys) {
        final value = prefs.get(key);
        debugInfo += '$key: $value\n';
      }

      // Add specific diagnostics for user accounts
      debugInfo += '\nUser Account Diagnostics:\n';

      // Check for customer account
      final customerPhone = prefs.getString('customerPhone');
      final customerName = prefs.getString('customerName');
      final customerPassword = prefs.getString('customerPassword');

      debugInfo +=
          'Customer account exists: ${customerPhone != null && customerPhone.isNotEmpty}\n';
      if (customerPhone != null && customerPhone.isNotEmpty) {
        debugInfo += '  - Phone: $customerPhone\n';
        debugInfo += '  - Name: $customerName\n';
        debugInfo +=
            '  - Password exists: ${customerPassword != null && customerPassword.isNotEmpty}\n';
      }

      // Check for professional account
      final professionalPhone = prefs.getString('professionalPhone');
      final professionalName = prefs.getString('professionalName');
      final professionalPassword = prefs.getString('professionalPassword');

      debugInfo +=
          'Professional account exists: ${professionalPhone != null && professionalPhone.isNotEmpty}\n';
      if (professionalPhone != null && professionalPhone.isNotEmpty) {
        debugInfo += '  - Phone: $professionalPhone\n';
        debugInfo += '  - Name: $professionalName\n';
        debugInfo +=
            '  - Password exists: ${professionalPassword != null && professionalPassword.isNotEmpty}\n';
      }

      // Check login status
      final isUserLoggedIn = prefs.getBool('isUserLoggedIn') ?? false;
      final userType = prefs.getString('userType') ?? 'none';
      final username = prefs.getString('username') ?? 'none';

      debugInfo +=
          'Login status: isUserLoggedIn=$isUserLoggedIn, userType=$userType, username=$username\n';

      print(debugInfo);
      return debugInfo;
    } catch (e) {
      print('Error debugging SharedPreferences: $e');
      return 'Error: $e';
    }
  }

  // Clear all SharedPreferences data
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPrefsService.prefs;
      await prefs.clear();
      return true;
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
      return false;
    }
  }

  // Fix common SharedPreferences issues
  static Future<bool> fixCommonIssues() async {
    try {
      print('Attempting to fix common SharedPreferences issues...');

      // 1. Ensure SharedPreferences is initialized
      await init();

      // 2. Get current SharedPreferences instance
      final prefs = await SharedPrefsService.prefs;

      // 3. Check for inconsistent login state
      final isUserLoggedIn = prefs.getBool('isUserLoggedIn') ?? false;
      final userHasLoggedOut = prefs.getBool('userHasLoggedOut') ?? false;
      final userType = prefs.getString('userType') ?? '';
      final username = prefs.getString('username') ?? '';

      // 4. Check for customer account
      final customerPhone = prefs.getString('customerPhone') ?? '';
      final customerName = prefs.getString('customerName') ?? '';
      final customerPassword = prefs.getString('customerPassword') ?? '';

      // 5. Check for professional account
      final professionalPhone = prefs.getString('professionalPhone') ?? '';
      final professionalName = prefs.getString('professionalName') ?? '';
      final professionalPassword =
          prefs.getString('professionalPassword') ?? '';

      // 6. Fix the userHasLoggedOut flag if it's preventing login
      if (userHasLoggedOut) {
        print('Found userHasLoggedOut=true - resetting to allow login');
        await prefs.setBool('userHasLoggedOut', false);
      }

      // 7. Fix inconsistencies
      if (customerPhone.isNotEmpty &&
          (customerName.isEmpty || customerPassword.isEmpty)) {
        print('Found inconsistent customer data - attempting to fix');
        if (customerName.isEmpty) {
          await prefs.setString('customerName', 'Customer');
          print('Set default customer name');
        }
        if (customerPassword.isEmpty) {
          print('Warning: Customer has phone but no password');
        }
      }

      if (professionalPhone.isNotEmpty &&
          (professionalName.isEmpty || professionalPassword.isEmpty)) {
        print('Found inconsistent professional data - attempting to fix');
        if (professionalName.isEmpty) {
          await prefs.setString('professionalName', 'Professional');
          print('Set default professional name');
        }
        if (professionalPassword.isEmpty) {
          print('Warning: Professional has phone but no password');
        }
      }

      // 8. Fix login state inconsistencies
      if ((customerPhone.isNotEmpty || professionalPhone.isNotEmpty) &&
          !isUserLoggedIn) {
        print(
            'Found accounts but user is not logged in - this is normal if user logged out');
      }

      if (isUserLoggedIn && userType.isEmpty) {
        print('User is logged in but has no user type - fixing');
        if (customerPhone.isNotEmpty) {
          await prefs.setString('userType', 'customer');
          print('Set user type to customer');
        } else if (professionalPhone.isNotEmpty) {
          await prefs.setString('userType', 'professional');
          print('Set user type to professional');
        } else {
          await prefs.setBool('isUserLoggedIn', false);
          print('No accounts found but user was marked as logged in - fixed');
        }
      }

      if (isUserLoggedIn && username.isEmpty) {
        print('User is logged in but has no username - fixing');
        if (customerPhone.isNotEmpty && customerName.isNotEmpty) {
          await prefs.setString('username', customerName);
          print('Set username to customer name');
        } else if (professionalPhone.isNotEmpty &&
            professionalName.isNotEmpty) {
          await prefs.setString('username', professionalName);
          print('Set username to professional name');
        }
      }

      // 9. Check for missing account data but existing user info
      if (customerPhone.isEmpty &&
          professionalPhone.isEmpty &&
          username.isNotEmpty) {
        print(
            'Found username but no account data - this might be causing login issues');

        // Try to restore from username if possible
        if (username.isNotEmpty) {
          print(
              'Attempting to create customer account from username: $username');
          await prefs.setString('customerName', username);
          await prefs.setString(
              'customerPhone', '03000000000'); // Default emergency phone
          await prefs.setString(
              'customerPassword', 'Test@123'); // Default emergency password
          print('Created emergency account with existing username');
        }
      }

      // 10. Print debug info after fixes
      await debugSharedPrefs();

      return true;
    } catch (e) {
      print('Error fixing SharedPreferences issues: $e');
      return false;
    }
  }

  // Create emergency test account
  static Future<bool> createEmergencyAccount() async {
    try {
      print('Creating emergency test account...');

      // Initialize SharedPreferences
      await init();

      final prefs = await SharedPrefsService.prefs;

      // Clear any userHasLoggedOut flag that might prevent login
      await prefs.setBool('userHasLoggedOut', false);

      // Create a test customer account
      await prefs.setString('customerName', 'Test User');
      await prefs.setString('customerPhone', '03000000000');
      await prefs.setString('customerPassword', 'Test@123');

      // Set login status
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('username', 'Test User');
      await prefs.setString('userType', 'customer');

      // Verify the data was saved
      final verifyPhone = prefs.getString('customerPhone');
      if (verifyPhone != '03000000000') {
        print('ERROR: Emergency account creation failed');
        return false;
      }

      print('Emergency account created successfully');
      print('Phone: 03000000000');
      print('Password: Test@123');

      // Print debug info
      await debugSharedPrefs();

      return true;
    } catch (e) {
      print('Error creating emergency account: $e');
      return false;
    }
  }

  // Restore the specific account from logs
  static Future<bool> restoreAccountFromLogs() async {
    try {
      print('Restoring account from logs...');

      // Initialize SharedPreferences
      await init();

      final prefs = await SharedPrefsService.prefs;

      // Clear any userHasLoggedOut flag that might prevent login
      await prefs.setBool('userHasLoggedOut', false);

      // Create the specific account from logs
      await prefs.setString('customerName', 'Farhan Ali');
      await prefs.setString('customerPhone', '03151716194');
      await prefs.setString('customerPassword',
          'Test@123'); // Using a default password since original is unknown

      // Set login status
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setString('username', 'Farhan Ali');
      await prefs.setString('userType', 'customer');

      // Verify the data was saved
      final verifyPhone = prefs.getString('customerPhone');
      if (verifyPhone != '03151716194') {
        print('ERROR: Account restoration failed');
        return false;
      }

      print('Account restored successfully');
      print('Phone: 03151716194');
      print('Password: Test@123');

      // Print debug info
      await debugSharedPrefs();

      return true;
    } catch (e) {
      print('Error restoring account: $e');
      return false;
    }
  }

  // Diagnose and repair account issues between Firestore and SharedPreferences
  static Future<bool> syncAccountWithFirestore(
      String phone, String userType, String name) async {
    try {
      print(
          'Syncing account with Firestore for phone: $phone, type: $userType');

      // Initialize SharedPreferences
      await init();

      final prefs = await SharedPrefsService.prefs;

      if (userType == 'customer') {
        // Check if the account exists in SharedPreferences
        final customerPhone = prefs.getString('customerPhone') ?? '';

        // If the account doesn't exist in SharedPreferences, create it
        if (customerPhone.isEmpty || customerPhone != phone) {
          print(
              'Creating missing customer account in SharedPreferences: $phone');
          await prefs.setString('customerName', name);
          await prefs.setString('customerPhone', phone);
          await prefs.setString(
              'customerPassword', 'Default@123'); // Default password
          print('Created customer account with default password');
        }
      } else if (userType == 'professional') {
        // Check if the account exists in SharedPreferences
        final professionalPhone = prefs.getString('professionalPhone') ?? '';

        // If the account doesn't exist in SharedPreferences, create it
        if (professionalPhone.isEmpty || professionalPhone != phone) {
          print(
              'Creating missing professional account in SharedPreferences: $phone');
          await prefs.setString('professionalName', name);
          await prefs.setString('professionalPhone', phone);
          await prefs.setString(
              'professionalPassword', 'Default@123'); // Default password
          print('Created professional account with default password');
        }
      }

      return true;
    } catch (e) {
      print('Error syncing account with Firestore: $e');
      return false;
    }
  }

  // Verify and repair account data
  static Future<bool> verifyAndRepairAccount(
      String phone, String userType) async {
    try {
      print(
          'Verifying and repairing account for phone: $phone, type: $userType');

      // Initialize SharedPreferences
      await init();

      final prefs = await SharedPrefsService.prefs;

      bool needsRepair = false;

      if (userType == 'customer') {
        final customerPhone = prefs.getString('customerPhone') ?? '';
        final customerPassword = prefs.getString('customerPassword') ?? '';

        // Check if the account data is inconsistent
        if (customerPhone.isEmpty || customerPassword.isEmpty) {
          needsRepair = true;
        }
      } else if (userType == 'professional') {
        final professionalPhone = prefs.getString('professionalPhone') ?? '';
        final professionalPassword =
            prefs.getString('professionalPassword') ?? '';

        // Check if the account data is inconsistent
        if (professionalPhone.isEmpty || professionalPassword.isEmpty) {
          needsRepair = true;
        }
      }

      if (needsRepair) {
        print('Account data is inconsistent - repairing');
        return await fixCommonIssues();
      }

      return true;
    } catch (e) {
      print('Error verifying and repairing account: $e');
      return false;
    }
  }
}
