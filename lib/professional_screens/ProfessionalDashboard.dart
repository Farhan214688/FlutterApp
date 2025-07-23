import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firstt_project/professional_screens/service_management.dart';
import 'package:firstt_project/professional_screens/availability_management.dart';
import 'package:firstt_project/services/auth_service.dart';
import 'package:firstt_project/LoginPage.dart';
import 'package:firstt_project/DashBoard.dart';
import 'MyOrdersScreen.dart';
import 'MyServiceScreen.dart';
import 'ProfileScreen.dart';
import 'ServiceSelectionScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firstt_project/services/weekly_offers_service.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({Key? key}) : super(key: key);

  @override
  _ProfessionalDashboardState createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  final AuthService _authService = AuthService();
  // Dashboard configuration
  final String dashboardTitle = "Professional Dashboard";
  final bool isProfessionalDashboard = true;

  // Add serviceGroups as a class field
  final Map<String, List<String>> serviceGroups = {
    'AC Service': [
      'AC Discounting',
      'AC General Services',
      'AC Installation',
      'AC Mounting and Discounting',
      'AC Repairing'
    ],
    'Plumbing': [
      'Plumbing',
      'Plumber',
      'Bath Shower',
      'Commode',
      'Drain Pipe',
      'Gas Pipe',
      'Handle Valve',
      'Water Piping',
      'Kitchen Drain',
      'Kitchen Leakage',
      'Mixer Tap',
      'Pipeline Water',
      'Sink',
      'Washbasin',
      'Water Motor',
      'Water Tank'
    ],
    'Electrical': ['Electrical', 'Electrician'],
    'Home Cleaning': ['Home Cleaning', 'Cleaning'],
    'Carpenter': ['Carpenter', 'Carpentry']
  };

  int _selectedIndex = 0;
  String _userName = 'Professional';
  String _userEmail = 'user@example.com';
  String _profileImage = '';
  bool _isLoading = true;
  String _accountStatus = 'pending';
  Map<String, dynamic> _stats = {
    'totalOrders': 0,
    'completedOrders': 0,
    'pendingOrders': 0,
    'totalEarnings': 0.0,
    'serviceCount': 0,
    'avgRating': 0.0,
  };

  final List<Widget> _widgetOptions = [];
  Map<String, dynamic>? professionalData;
  List<Map<String, dynamic>> _weeklyOffers = [];
  List<Map<String, dynamic>> _allServices = [
    {
      'name': 'AC Service',
      'subcategories': [
        'AC Discounting',
        'AC General Services',
        'AC Installation',
        'AC Mounting and Discounting',
        'AC Repairing',
        'Split AC',
        'Window AC',
        'Central AC',
        'AC Maintenance'
      ],
    },
    {
      'name': 'Plumbing',
      'subcategories': [
        'Bath Shower',
        'Commode',
        'Drain Pipe',
        'Gas Pipe',
        'Handle Valve',
        'Water Piping',
        'Kitchen Drain',
        'Kitchen Leakage',
        'Mixer Tap',
        'Pipeline Water',
        'Sink',
        'Washbasin',
        'Water Motor',
        'Water Tank',
      ],
    },
    {
      'name': 'Electrical',
      'subcategories': [
        'UPS Repairing',
        'Water Pump Repairing',
        'Water Tank Switch Installation',
        'Switch Board Socket Replacement',
        'Tube Light Installation',
        'Tube Light Replacement',
        'UPS Installation',
        'Breaker Replacement',
        'Distribution Box Installation',
        'SMD Light Installation',
        'House Wiring',
        'Power Plug Installation',
        'Pressure Motor Installation',
        'Kitchen Hood Repairing',
        'LED TV Dismounting',
        'Light Plug Installation',
        'Washing Machine Repairing',
        'Fancy Light Installation',
        'House Electric Work',
        'Change Over Switch Installation',
        'Door Pillar Lights',
        'Electrical Wiring',
        'LED TV Mounting',
        'Ceiling Fan Installation',
        'Ceiling Fan Repairing'
      ],
    },
    {
      'name': 'Home Cleaning',
      'subcategories': [
        'Deep Cleaning',
        'Bathroom Cleaning',
        'Kitchen Cleaning',
        'Regular Maintenance Cleaning',
        'Spring Cleaning',
        'Move In Cleaning',
        'Move Out Cleaning',
        'Post Construction Cleaning',
        'Office Cleaning',
        'Commercial Cleaning',
        'Residential Cleaning',
        'Carpet Cleaning',
        'Floor Cleaning',
        'Window Cleaning',
        'Dusting',
        'Vacuuming',
        'Mopping',
        'Sanitization',
        'Disinfection'
      ],
    },
    {
      'name': 'Carpenter',
      'subcategories': [
        'Carpenter Work',
        'Catcher Replacement',
        'Door Installation',
        'Drawer Lock Installation',
        'Drawer Repairing',
        'Furniture Repairing',
        'Room Door Lock Installation',
        'Cabinet Installation',
        'Window Installation',
        'Wood Repair',
        'Wood Installation',
        'Furniture Assembly'
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeWidgets();
    _saveCurrentScreenState();
    _loadProfessionalData();
    _loadWeeklyOffers();
  }

  void _initializeWidgets() {
    _widgetOptions.add(_buildHomeScreen());
    _widgetOptions.add(MyOrdersScreen(
      onOrderCompleted: _refreshWalletScreen,
    ));
    _widgetOptions.add(_buildWalletScreen());
  }

  void _refreshWalletScreen() {
    // Rebuild the wallet screen with updated data
    setState(() {
      _widgetOptions[2] = _buildWalletScreen();
    });
    // Also refresh the stats to update earnings
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      final phoneNumber = prefs.getString('professionalPhone');

      print('Debug - Loading user info for ID: $userId');
      print('Debug - Phone Number: $phoneNumber');

      // If userId is null but we have phone number, try to get userId from Firestore
      if (userId == null && phoneNumber != null) {
        print('Debug - Attempting to fetch userId using phone number');
        try {
          // Try different phone number formats
          final phoneFormats = [
            phoneNumber,
            phoneNumber.replaceAll('+', ''),
            phoneNumber.replaceAll('+', '0'),
            '0${phoneNumber.replaceAll('+', '')}',
          ];

          print('Debug - Trying phone formats: $phoneFormats');

          for (final format in phoneFormats) {
            print('Debug - Trying format: $format');
            final userQuery = await FirebaseFirestore.instance
                .collection('professionals')
                .where('phoneNumber', isEqualTo: format)
                .limit(1)
                .get();

            if (userQuery.docs.isNotEmpty) {
              userId = userQuery.docs.first.id;
              final professionalData = userQuery.docs.first.data();
              print('Debug - Found professional with format: $format');
              print('Debug - Professional data: $professionalData');

              // Save the userId to SharedPreferences for future use
              await prefs.setString('userId', userId);

              // Also save the professional's data
              await prefs.setString(
                  'professionalName', professionalData['name'] ?? '');
              await prefs.setString(
                  'professionalCity', professionalData['city'] ?? '');
              await prefs.setBool('isUserLoggedIn', true);
              await prefs.setBool('userHasLoggedOut', false);

              print('Debug - Saved professional data to SharedPreferences');
              break;
            }
          }
        } catch (e) {
          print('Debug - Error fetching professional data: $e');
          // Continue with existing data
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Load user data from SharedPreferences
      final prefName = prefs.getString('professionalName') ??
          prefs.getString('userName') ??
          prefs.getString('username');
      final profileImagePath = prefs.getString('profileImage') ??
          prefs.getString('profileImagePath') ??
          '';

      if (userId != null) {
        // Get professional's current status from Firestore
        final professionalDoc = await FirebaseFirestore.instance
            .collection('professionals')
            .doc(userId)
            .get();

        if (professionalDoc.exists) {
          final professionalData = professionalDoc.data()!;
          _accountStatus = professionalData['status'] ?? 'pending';
          
          // Update local storage with current status
          await prefs.setString('accountStatus', _accountStatus);
          
          // If account is deactivated, show warning
          if (_accountStatus == 'deactivated') {
            final deactivationReason = professionalData['deactivationReason'];
            if (deactivationReason == 'pending_commission_payment') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Your account is deactivated due to pending commission payment. Please pay your commission in the wallet tab to reactivate your account.',
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 8),
                    action: SnackBarAction(
                      label: 'Go to Wallet',
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 2; // Switch to wallet tab
                        });
                      },
                    ),
                  ),
                );
              });
            }
          }
        }
      }

      setState(() {
        _userName = prefName ?? 'Professional';
        _userEmail = prefs.getString('userEmail') ?? 'user@example.com';
        _profileImage = profileImagePath;
      });

      if (userId != null) {
        print('Debug - Loading user stats for ID: $userId');
        await _loadUserStats(userId);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      // Get stats from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId)
          .get();

      print('Debug - Professional document exists: ${userDoc.exists}');
      print('Debug - Professional data: ${userDoc.data()}');

      if (userDoc.exists) {
        final firestoreName = userDoc.data()?['name'];
        final professionalCity = userDoc.data()?['city'];
        print("Debug - Username from Firestore: $firestoreName");
        print("Debug - City from Firestore: $professionalCity");

        // Update user info if available
        setState(() {
          _userName = firestoreName ?? _userName;
          _userEmail = userDoc.data()?['email'] ?? _userEmail;
          _profileImage = userDoc.data()?['profileImage'] ?? _profileImage;
        });

        // Get total service count
        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('professionalServices')
            .where('professionalId', isEqualTo: userId)
            .get();

        // Get all orders (both regular and weekly services)
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('serviceBookings')
            .where('professionalId', isEqualTo: userId)
            .get();

        // Calculate stats
        final allOrders = ordersSnapshot.docs;
        final completedOrders = allOrders
            .where((doc) => doc.data()['status'] == 'completed')
            .toList();
        final pendingOrders = allOrders
            .where((doc) =>
                doc.data()['status'] == 'pending' ||
                doc.data()['status'] == 'accepted')
            .toList();

        // Calculate total earnings and commission
        double totalEarnings = 0;
        double totalCommission = 0;

        for (var order in completedOrders) {
          final orderData = order.data();
          final orderPrice = (orderData['price'] ?? 0).toDouble();
          final finalPrice = (orderData['finalPrice'] ?? orderPrice).toDouble();
          
          // For weekly services, use the stored earnings and commission
          if (orderData['isWeeklyService'] == true) {
            totalEarnings += (orderData['earnings'] ?? 0).toDouble();
            totalCommission += (orderData['commission'] ?? 0).toDouble();
          } else {
            // For regular services, calculate 90% earnings and 10% commission
            totalEarnings += (finalPrice * 0.90);
            totalCommission += (finalPrice * 0.10);
          }
        }

        // Calculate average rating
        double totalRating = 0;
        int ratingCount = 0;

        for (var order in completedOrders) {
          if (order.data().containsKey('rating') &&
              order.data()['rating'] != null) {
            totalRating += (order.data()['rating'] ?? 0).toDouble();
            ratingCount++;
          }
        }

        double avgRating = ratingCount > 0 ? totalRating / ratingCount : 0;

        // Update SharedPreferences with the latest earnings and commission
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('earnings', totalEarnings);
        await prefs.setDouble('commission', totalCommission);

        setState(() {
          _stats = {
            'totalOrders': allOrders.length,
            'completedOrders': completedOrders.length,
            'pendingOrders': pendingOrders.length,
            'totalEarnings': totalEarnings,
            'serviceCount': servicesSnapshot.docs.length,
            'avgRating': avgRating,
            'totalCommission': totalCommission,
          };
        });

        print('Debug - Updated stats: $_stats');
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  void _refreshStats() {
    _loadUserInfo();
  }

  // Check if the account is deactivated
  bool _isDeactivated() {
    return _accountStatus == 'deactivated';
  }

  Widget _buildHomeScreen() {
    print("Building home screen with username: $_userName");
    return RefreshIndicator(
      onRefresh: () async {
        print('Debug - Home screen refresh triggered');
        await _loadUserInfo();
        await _loadProfessionalData();
        await _loadWeeklyOffers();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display deactivation message if applicable
            if (_isDeactivated())
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Your account is deactivated. Please pay your commission.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Professional Welcome Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.lightGreen.shade300,
                    Colors.lightGreen.shade700
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : "P",
                      style: TextStyle(color: Colors.lightGreen, fontSize: 24),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $_userName',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Welcome to Rapit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Weekly Service Section - Only show if there are offers
            Builder(
              builder: (context) {
                print('Debug - Building weekly offers section');
                print('Debug - _weeklyOffers length: ${_weeklyOffers.length}');
                print('Debug - _weeklyOffers data: $_weeklyOffers');
                
                if (_weeklyOffers.isEmpty) {
                  return SizedBox.shrink(); // Return empty widget instead of message
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Weekly Service',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _weeklyOffers.length,
                      itemBuilder: (context, index) {
                        final offer = _weeklyOffers[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(offer['name'] ?? 'Unnamed Offer'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('City: ${offer['city']?.toString().toUpperCase() ?? 'N/A'}'),
                                Text('Original Price: Rs. ${offer['price']}'),
                                Text('Discount: ${offer['discount']}%'),
                                Text('Final Price: Rs. ${(offer['price'] - (offer['price'] * offer['discount'] / 100)).toStringAsFixed(0)}'),
                                Text('Status: ${offer['status'] ?? 'pending'}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _acceptWeeklyService(offer),
                              child: Text('Accept'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            // Pending Bookings Section (Orders)
            Center(
              child: Text(
                'Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            FutureBuilder<String?>(
              future: SharedPreferences.getInstance()
                  .then((prefs) => prefs.getString('userId')),
              builder: (context, userIdSnapshot) {
                if (!userIdSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('professionals')
                      .doc(userIdSnapshot.data)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final professionalData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final isVerified =
                        professionalData?['approved_by_admin'] == true;

                    if (!isVerified) {
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.pending_actions,
                                size: 48,
                                color: Colors.orange,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Account Pending Verification',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Your account is currently under review. You will be able to accept bookings once your account is verified by our admin team.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('serviceBookings')
                          .where('status', isEqualTo: 'pending')  // Only show pending orders
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('Error fetching bookings: ${snapshot.error}');
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        // Create a set of service categories based on the professional's service type
                        Set<String> professionalCategories = {};

                        // Find the professional's service group
                        String? professionalServiceGroup;
                        final mainServiceType = professionalData?['serviceName']?.toString().trim().toLowerCase() ?? '';
                        print('DEBUG - Main Service Type: $mainServiceType');

                        // Simplified service group matching
                        if (mainServiceType.contains('ac')) {
                          professionalServiceGroup = 'AC Service';
                        } else if (mainServiceType == 'electrical' || mainServiceType == 'electrician') {
                          professionalServiceGroup = 'Electrical';
                        } else if (mainServiceType == 'plumbing' || mainServiceType == 'plumber') {
                          professionalServiceGroup = 'Plumbing';
                        } else {
                          // For other services, use the existing logic
                          for (var entry in serviceGroups.entries) {
                            if (entry.value.any((type) =>
                                mainServiceType.toLowerCase().contains(type.toLowerCase()) ||
                                type.toLowerCase().contains(mainServiceType.toLowerCase()))) {
                              professionalServiceGroup = entry.key;
                              break;
                            }
                          }
                        }

                        print('Debug - Professional Service Group: $professionalServiceGroup');

                        // Add only the services that belong to the professional's group
                        if (professionalServiceGroup != null) {
                          // Add the main service type
                          professionalCategories.add(mainServiceType);

                          // For AC services, add all valid AC services
                          if (professionalServiceGroup == 'AC Service') {
                            professionalCategories.addAll([
                              'ac discounting',
                              'ac general services',
                              'ac installation',
                              'ac mounting and discounting',
                              'ac repairing'
                            ]);
                          } else if (professionalServiceGroup == 'Electrical') {
                            // Add all electrical service types
                            professionalCategories.addAll([
                              'electrical',
                              'electrician',
                              'ups repairing',
                              'water pump repairing',
                              'water tank automatic switch installation',
                              'switch board socket replacement',
                              'tube light installation',
                              'tube light replacement',
                              'ups installation',
                              'single phase breaker replacement',
                              'single phase distribution box installation',
                              'smd light installation',
                              'new house wiring',
                              'power plug installation',
                              'pressure motor installation',
                              'kitchen hood repairing',
                              'led tv dismounting',
                              'light plug',
                              'manual washing machine repairing',
                              'fancy light installation',
                              'house electric work',
                              'change over switch installation',
                              'door pillar lights',
                              'electrical wiring',
                              'led tv mounting',
                              'ceiling fan installation',
                              'ceiling fan repairing'
                            ]);
                          } else if (professionalServiceGroup == 'Plumbing') {
                            // Add all plumbing service types
                            professionalCategories.addAll([
                              'plumbing',
                              'plumber',
                              'bath shower',
                              'commode',
                              'drain pipe',
                              'gas pipe',
                              'handle valve',
                              'water piping',
                              'kitchen drain',
                              'kitchen leakage',
                              'mixer tap',
                              'pipeline water',
                              'sink',
                              'washbasin',
                              'water motor',
                              'water tank',
                              'automatic washing machine installation',
                              'commode tank machine replacement',
                              'sink spindle change',
                              'water motor installation',
                              'water motor repairing',
                              'water tank installation',
                              'water tank supply issue'
                            ]);
                          } else {
                            // For other services, use the existing logic
                            final serviceDefinition = _allServices.firstWhere(
                              (service) => service['name'] == professionalServiceGroup,
                              orElse: () => {'subcategories': []},
                            );

                            if (serviceDefinition['subcategories'] != null) {
                              final subcategories = List<String>.from(serviceDefinition['subcategories']);
                              professionalCategories.addAll(subcategories.map((s) => s.toLowerCase()));
                            }
                          }

                          print('DEBUG - Professional Categories: $professionalCategories');
                        }

                        final professionalCity = professionalData?['city']?.toLowerCase() ?? '';

                        // Filter bookings with specific service type matching
                        final filteredBookings = snapshot.data?.docs.where((doc) {
                          final bookingData = doc.data() as Map<String, dynamic>;
                          
                          final address = (bookingData['address'] as String?)?.toLowerCase() ?? '';
                          final status = bookingData['status']?.toString().toLowerCase() ?? '';
                          final serviceType = (bookingData['serviceType'] as String?)?.toLowerCase() ?? '';
                          final serviceName = (bookingData['serviceName'] as String?)?.toLowerCase() ?? '';
                          final serviceCategory = (bookingData['serviceCategory'] as String?)?.toLowerCase() ?? '';
                          final isWeeklyService = bookingData['isWeeklyService'] == true;

                          // Debug logging for each booking
                          print('\nDEBUG - Checking booking:');
                          print('  Service Type: $serviceType');
                          print('  Service Name: $serviceName');
                          print('  Service Category: $serviceCategory');
                          print('  Status: $status');
                          print('  Address: $address');
                          print('  Is Weekly Service: $isWeeklyService');

                          // Check if the address contains the city name
                          final hasMatchingCity = address.contains(professionalCity);
                          print('  Has Matching City: $hasMatchingCity');

                          // For weekly offers, only check city and status
                          if (serviceType == 'weekly_offer' || isWeeklyService) {
                            print('  Weekly service detected');
                            return hasMatchingCity && status == 'pending';
                          }

                          // For regular services, check both city and service match
                          bool hasMatchingService = false;
                          if (professionalServiceGroup == 'AC Service') {
                            final acServiceKeywords = [
                              'ac discounting',
                              'ac general services',
                              'ac installation',
                              'ac mounting and discounting',
                              'ac repairing'
                            ];
                            
                            hasMatchingService = acServiceKeywords.any((keyword) {
                              return serviceName.contains(keyword) || 
                                     serviceCategory.contains(keyword) ||
                                     keyword.contains(serviceName) ||
                                     keyword.contains(serviceCategory);
                            });
                          } else if (professionalServiceGroup == 'Electrical') {
                            // Check if the service name or category matches any electrical service
                            hasMatchingService = professionalCategories.any((category) {
                              final matches = serviceName.contains(category) || 
                                            serviceCategory.contains(category) ||
                                            category.contains(serviceName) ||
                                            category.contains(serviceCategory);
                              if (matches) {
                                print('  Found matching electrical service: $category');
                              }
                              return matches;
                            });
                            
                            print('  Electrical service check:');
                            print('    Service Type match: ${serviceType == 'electrical' || serviceType == 'electrician'}');
                            print('    Service Name match: ${serviceName == 'electrical' || serviceName == 'electrician'}');
                            print('    Service Category match: ${serviceCategory == 'electrical' || serviceCategory == 'electrician'}');
                            print('    Final match: $hasMatchingService');
                          } else {
                            hasMatchingService = professionalCategories.contains(serviceCategory) ||
                                              professionalCategories.contains(serviceName);
                          }

                          final finalMatch = hasMatchingCity && hasMatchingService;
                          print('  Final match result: $finalMatch');
                          return finalMatch;
                        }).toList() ?? [];

                        print('\n===== DEBUG: Filtering Results =====');
                        print('Total orders before filtering: ${snapshot.data?.docs.length ?? 0}');
                        print('Orders after filtering: ${filteredBookings.length}');
                        print('Professional Service Group: $professionalServiceGroup');
                        print('Professional Categories: $professionalCategories');
                        print('Professional City: $professionalCity');

                        if (filteredBookings.isEmpty) {
                          return Container(
                            width: double.infinity,
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      'No pending orders',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'City: ${professionalData?['city'] ?? 'Not set'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (professionalData?['city'] == null ||
                                        professionalData?['city']?.isEmpty ==
                                            true)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Please update your profile to set your city',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredBookings.length,
                          itemBuilder: (context, index) {
                            final doc = filteredBookings[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final expiresAt =
                                (data['expiresAt'] as Timestamp).toDate();
                            final timeLeft =
                                expiresAt.difference(DateTime.now());

                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            data['serviceName'] ?? 'Service',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.visible,
                                            softWrap: true,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'Rs. ${data['finalPrice']?.toStringAsFixed(0) ?? '0'}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.lightGreen[700],
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Customer: ${data['customerName'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Phone: ${data['customerPhone'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Address: ${data['address'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(data['date']))}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Time: ${data['time'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Description: ${data['description'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Expires in: ${_formatDuration(timeLeft)}',
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () =>
                                              _rejectBooking(doc.id),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: Text('Reject'),
                                        ),
                                        SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _acceptBooking(doc.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.lightGreen,
                                          ),
                                          child: Text('Accept'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      if (_accountStatus == 'deactivated') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your account is deactivated. Please pay your commission in the wallet tab to reactivate your account.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Go to Wallet',
              onPressed: () {
                setState(() {
                  _selectedIndex = 2; // Switch to wallet tab
                });
              },
            ),
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userName = prefs.getString('professionalName') ?? 'Unknown Professional';
      final userPhone = prefs.getString('professionalPhone') ?? 'N/A';

      // Get the booking document to access customer details
      final bookingDoc = await FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      final customerPhone = bookingData['customerPhone'] ?? 'N/A';

      await FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(bookingId)
          .update({
        'status': 'accepted',
        'professionalId': userId,
        'professionalName': userName,
        'professionalPhone': userPhone,
        'customerPhone': customerPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking accepted successfully')),
      );
    } catch (e) {
      print('Error accepting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting booking: $e')),
      );
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(bookingId)
          .update({
        'status': 'rejected',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting booking: $e')),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.lightGreen.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.lightGreen[700],
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Earnings',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.lightGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Rs. ${_stats['totalEarnings'].toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.lightGreen[700],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Total earnings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.lightGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.lightGreen.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.lightGreen.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletScreen() {
    return RefreshIndicator(
      onRefresh: () async {
        print('Debug - Wallet screen refresh triggered');
        await _loadProfessionalData();
        await _loadWeeklyOffers();
        
        // Get userId from Firebase Auth first
        final auth = FirebaseAuth.instance;
        final currentUser = auth.currentUser;
        final userId = currentUser?.uid;
        
        print('Debug - Wallet refresh - userId from Firebase Auth: $userId');
        
        if (userId != null) {
          // Update SharedPreferences with the current Firebase userId
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId);
          await _loadUserStats(userId);
        } else {
          print('Debug - Wallet refresh - No userId found in Firebase Auth');
          // Fallback to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getString('userId');
          print('Debug - Wallet refresh - userId from SharedPreferences: $storedUserId');
          if (storedUserId != null) {
            await _loadUserStats(storedUserId);
          }
        }
      },
      child: FutureBuilder<String?>(
        future: () async {
          // Try to get userId from Firebase Auth first
          final auth = FirebaseAuth.instance;
          final currentUser = auth.currentUser;
          final userId = currentUser?.uid;
          
          print('Debug - Wallet screen - userId from Firebase Auth: $userId');
          
          if (userId != null) {
            // Update SharedPreferences with the current Firebase userId
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', userId);
            return userId;
          }
          
          // Fallback to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getString('userId');
          print('Debug - Wallet screen - userId from SharedPreferences: $storedUserId');
          print('Debug - Wallet screen - All SharedPreferences keys: ${prefs.getKeys()}');
          return storedUserId;
        }(),
        builder: (context, userIdSnapshot) {
          print('Debug - Wallet screen - FutureBuilder state: ${userIdSnapshot.connectionState}');
          print('Debug - Wallet screen - FutureBuilder hasError: ${userIdSnapshot.hasError}');
          print('Debug - Wallet screen - FutureBuilder hasData: ${userIdSnapshot.hasData}');
          if (userIdSnapshot.hasError) {
            print('Debug - Wallet screen - Error: ${userIdSnapshot.error}');
          }

          if (userIdSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userIdSnapshot.hasError || !userIdSnapshot.hasData) {
            return Center(child: Text('Error loading user data. Please try logging in again.'));
          }

          final userId = userIdSnapshot.data;
          if (userId == null) {
            print('Debug - Wallet screen - userId is null');
            return Center(child: Text('Please log in to view your wallet'));
          }

          print('Debug - Wallet screen - Proceeding with userId: $userId');

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('professionals')
                .doc(userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading wallet data'));
              }

              final professionalData = snapshot.data?.data() as Map<String, dynamic>?;
              final firestoreEarnings = (professionalData?['earnings'] ?? 0).toDouble();
              final firestoreCommission = (professionalData?['commission'] ?? 0).toDouble();
              final firestoreWalletBalance = (professionalData?['walletBalance'] ?? 0).toDouble();

              // Use the higher value between Firestore and local stats
              final totalEarnings = firestoreEarnings > (_stats['totalEarnings'] ?? 0) 
                  ? firestoreEarnings 
                  : (_stats['totalEarnings'] ?? 0);
              
              final totalCommission = firestoreCommission > (_stats['totalCommission'] ?? 0)
                  ? firestoreCommission
                  : (_stats['totalCommission'] ?? 0);

              print('Debug - Wallet Screen Values:');
              print('Firestore Earnings: $firestoreEarnings');
              print('Firestore Commission: $firestoreCommission');
              print('Firestore Wallet Balance: $firestoreWalletBalance');
              print('Local Stats Earnings: ${_stats['totalEarnings']}');
              print('Local Stats Commission: ${_stats['totalCommission']}');
              print('Final Display Earnings: $totalEarnings');
              print('Final Display Commission: $totalCommission');

              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Card
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Earnings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Rs. ${totalEarnings.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightGreen[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Available Balance: Rs. ${firestoreWalletBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Commission Card
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commission to Pay',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Rs. ${totalCommission.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '10% of total earnings',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Payment Methods Section
                    Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // EasyPaisa Section
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EasyPaisa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: Image.asset(
                                  'Assets/Images/Payment.jpeg',
                                  height: 300,
                                  width: 300,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Bank Account Section
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bank Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Dubai Islamic Bank',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '0803208001',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Payment Instructions
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Once you have made your payment, please send your payment screenshot to our helpline:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  final Uri whatsappUrl =
                                      Uri.parse('https://wa.me/+923067948948');
                                  launchUrl(whatsappUrl);
                                },
                                child: Text(
                                  '+92 306 7948948',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightGreen[700],
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'We will confirm your payment and update your account accordingly. Thank you!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.lightGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.lightGreen,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : "P",
                    style: TextStyle(color: Colors.lightGreen, fontSize: 24),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Hi, $_userName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Professional Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.lightGreen),
            title: Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    onProfileUpdate: () {
                      _loadUserInfo();
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.lightGreen),
            title: Text('My Orders'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          ListTile(
            leading:
                Icon(Icons.account_balance_wallet, color: Colors.lightGreen),
            title: Text('Wallet'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _performLogout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
                ),
                SizedBox(width: 20),
                Text("Logging out..."),
              ],
            ),
          );
        },
      );

      // Call the auth service to sign out
      await _authService.signOut();

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Save current wallet data temporarily
      final walletBalance = prefs.getDouble('walletBalance');
      final walletTransactions = prefs.getString('walletTransactions');
      final earnings = prefs.getDouble('earnings');
      final commission = prefs.getDouble('commission');
      final userId = prefs.getString('userId');
      final professionalName = prefs.getString('professionalName');
      final professionalCity = prefs.getString('professionalCity');
      final professionalPhone = prefs.getString('professionalPhone');
      final professionalPassword = prefs.getString('professionalPassword');
      final profileImage = prefs.getString('profileImage');
      final serviceName = prefs.getString('serviceName');
      final approvedByAdmin = prefs.getBool('approved_by_admin');
      final termsAccepted = prefs.getBool('terms_accepted') ?? false;
      final isFirstTime = prefs.getBool('isFirstTime') ?? false;

      // Clear all data
      await prefs.clear();

      // Restore important data
      if (walletBalance != null) await prefs.setDouble('walletBalance', walletBalance);
      if (walletTransactions != null) await prefs.setString('walletTransactions', walletTransactions);
      if (earnings != null) await prefs.setDouble('earnings', earnings);
      if (commission != null) await prefs.setDouble('commission', commission);
      if (userId != null) await prefs.setString('userId', userId);
      if (professionalName != null) await prefs.setString('professionalName', professionalName);
      if (professionalCity != null) await prefs.setString('professionalCity', professionalCity);
      if (professionalPhone != null) await prefs.setString('professionalPhone', professionalPhone);
      if (professionalPassword != null) await prefs.setString('professionalPassword', professionalPassword);
      if (profileImage != null) await prefs.setString('profileImage', profileImage);
      if (serviceName != null) await prefs.setString('serviceName', serviceName);
      if (approvedByAdmin != null) await prefs.setBool('approved_by_admin', approvedByAdmin);

      // Restore important flags
      await prefs.setBool('terms_accepted', termsAccepted);
      await prefs.setBool('isFirstTime', isFirstTime);

      // Set logout state
      await prefs.setBool('userHasLoggedOut', true);
      await prefs.setBool('isUserLoggedIn', false);

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to guest dashboard with a clean navigation stack
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => Dashboard(),
          ),
          (route) => false);

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have been logged out successfully')),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    // No status check - directly navigate
    setState(() {
      _selectedIndex = index;
    });
  }

  // Save the current screen state to SharedPreferences
  Future<void> _saveCurrentScreenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save that we're on the professional dashboard
      await prefs.setString('lastScreen', 'professional_dashboard');

      // Mark professional verification as completed
      await prefs.setBool('isVerificationCompleted', true);

      // Ensure login state is maintained
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);
      await prefs.setString('userType', 'professional');

      // Remove any temporary verification file paths
      await prefs.remove('lastFrontIDPath');

      await prefs.remove('lastBackIDPath');
      await prefs.remove('lastSelfiePath');

      print("Saved professional dashboard as current screen state");
    } catch (e) {
      print('Error saving professional dashboard screen state: $e');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  Future<void> _loadWeeklyOffers() async {
    try {
      print('Debug - Starting _loadWeeklyOffers');
      
      if (!mounted) {
        print('Debug - Widget not mounted, returning early');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      // Always ensure we have the latest professional data first
      await _loadProfessionalData();
      
      if (!mounted) {
        print('Debug - Widget not mounted after loading professional data, returning early');
        return;
      }

      // Get professional's city, verification status, and service type
      final professionalCity = professionalData?['city']?.toLowerCase() ?? '';
      final isVerified = professionalData?['approved_by_admin'] ?? false;
      final professionalServiceType = professionalData?['serviceName']?.toString().toLowerCase() ?? '';
      final professionalServiceCategories = (professionalData?['serviceCategories'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];

      print('Debug - Professional details:');
      print('  City: $professionalCity');
      print('  Is verified: $isVerified');
      print('  Service type: $professionalServiceType');
      print('  Service categories: $professionalServiceCategories');
      print('  Full professional data: $professionalData');

      if (professionalCity.isEmpty) {
        print('Debug - Warning: professional city is empty, cannot load offers');
        setState(() {
          _isLoading = false;
          _weeklyOffers = [];
        });
        return;
      }

      // Load weekly offers for all professionals in the city
      final weeklyOffersService = WeeklyOffersService();
      print('Debug - Calling loadWeeklyOffersForProfessionals with:');
      print('Debug - City: $professionalCity');
      print('Debug - IsVerified: $isVerified');
      
      final offers = await weeklyOffersService.loadWeeklyOffersForProfessionals(
        city: professionalCity,
        isVerified: isVerified,
      );

      print('Debug - Loaded offers before filtering: ${offers.length}');
      print('Debug - Raw offers data:');
      for (var offer in offers) {
        print('  Offer:');
        print('    ID: ${offer['id']}');
        print('    Name: ${offer['name']}');
        print('    City: ${offer['city']}');
        print('    Status: ${offer['status']}');
        print('    IsActive: ${offer['isActive']}');
        print('    ServiceType: ${offer['serviceType']}');
        print('    ServiceName: ${offer['serviceName']}');
      }

      // Simplified filtering - just check if the offer is marked as weekly
      final filteredOffers = offers.where((offer) {
        final isWeeklyOffer = offer['isWeeklyService'] == true || 
                            offer['serviceType'] == 'weekly' ||
                            offer['serviceCategory'] == 'weekly_offer';
        
        print('\nDEBUG - Checking offer:');
        print('  Offer ID: ${offer['id']}');
        print('  IsWeeklyOffer: $isWeeklyOffer');
        print('  ServiceType: ${offer['serviceType']}');
        print('  ServiceCategory: ${offer['serviceCategory']}');
        
        return isWeeklyOffer;
      }).toList();

      print('Debug - Filtered offers count: ${filteredOffers.length}');
      print('Debug - Filtered offers data:');
      for (var offer in filteredOffers) {
        print('  - Name: ${offer['name']}');
        print('    Service Type: ${offer['serviceType']}');
        print('    Service Name: ${offer['serviceName']}');
        print('    Status: ${offer['status']}');
        print('    isActive: ${offer['isActive']}');
        print('    City: ${offer['city']}');
        print('    Price: ${offer['price']}');
        print('    Discount: ${offer['discount']}');
        print('    ---');
      }

      if (!mounted) {
        print('Debug - Widget not mounted after filtering offers, returning early');
        return;
      }
      
      setState(() {
        _weeklyOffers = filteredOffers;
        _isLoading = false;
      });

      print('Debug - Updated state with ${_weeklyOffers.length} offers');
      print('Debug - Current _weeklyOffers: $_weeklyOffers');
    } catch (e) {
      print('Error loading weekly offers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _weeklyOffers = [];
        });
      }
    }
  }

  Future<void> _loadProfessionalData() async {
    try {
      print('\n===== DEBUG: Loading Professional Data =====');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      print('User ID: $userId');

      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('professionals')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          print('Professional Data:');
          print('- Service Name: ${data?['serviceName']}');
          print('- City: ${data?['city']}');
          print('- Status: ${data?['status']}');
          print('- Approved by Admin: ${data?['approved_by_admin']}');
          print('- Account Status: ${data?['accountStatus']}');
          
          setState(() {
            professionalData = data;
          });
        } else {
          print('Professional document does not exist!');
        }
      } else {
        print('No userId found in SharedPreferences!');
      }
    } catch (e) {
      print('Error loading professional data: $e');
    }
  }

  Future<void> _acceptWeeklyService(Map<String, dynamic> offer) async {
    try {
      if (_accountStatus == 'deactivated') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your account is deactivated. Please pay your commission in the wallet tab to reactivate your account.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Go to Wallet',
              onPressed: () {
                setState(() {
                  _selectedIndex = 2; // Switch to wallet tab
                });
              },
            ),
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userName = prefs.getString('professionalName') ?? 'Unknown Professional';
      final userPhone = prefs.getString('professionalPhone') ?? 'N/A';
      
      if (userId == null || userName == null) {
        throw Exception('User information not found');
      }

      // Start a batch write to ensure atomic updates
      final batch = FirebaseFirestore.instance.batch();
      
      // Create the service booking record
      final bookingRef = FirebaseFirestore.instance.collection('serviceBookings').doc();
      final bookingData = {
        'serviceId': offer['id'],
        'serviceName': offer['name'],
        'serviceType': 'weekly_offer',
        'customerId': offer['customerId'],
        'customerName': offer['customerName'],
        'customerPhone': offer['customerPhone'] ?? 'N/A',
        'professionalId': userId,
        'professionalName': userName,
        'professionalPhone': userPhone,
        'price': offer['discountedPrice'],
        'originalPrice': offer['price'],
        'discount': offer['discount'],
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'weeklyOfferId': offer['id'], // Store the original weekly offer ID
        'isWeeklyService': true,
      };
      batch.set(bookingRef, bookingData);

      // Update the weekly offer status
      final offerRef = FirebaseFirestore.instance.collection('weeklyOffers').doc(offer['id']);
      batch.update(offerRef, {
        'status': 'accepted',
        'acceptedBy': userId,
        'acceptedByName': userName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'isActive': false, // Mark as inactive so it won't show up in the list
      });

      // Commit both updates atomically
      await batch.commit();

      // Refresh the weekly offers list
      await _loadWeeklyOffers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly service accepted successfully')),
        );
      }
    } catch (e) {
      print('Error accepting weekly service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting service: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rejectWeeklyService(Map<String, dynamic> offer) async {
    try {
      // For weekly services, we'll just remove it from the professional's view
      // by not creating a booking record
      await _loadWeeklyOffers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weekly service rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error rejecting weekly service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting weekly service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeWeeklyService(Map<String, dynamic> offer) async {
    try {
      print('DEBUG: Starting weekly service completion for offer: ${offer['id']}');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Find the accepted weekly service booking
      final bookingQuery = await FirebaseFirestore.instance
          .collection('serviceBookings')
          .where('weeklyOfferId', isEqualTo: offer['id'])
          .where('professionalId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      print('DEBUG: Found ${bookingQuery.docs.length} accepted weekly services');

      if (bookingQuery.docs.isEmpty) {
        throw Exception('No accepted weekly service found');
      }

      final bookingDoc = bookingQuery.docs.first;
      final bookingId = bookingDoc.id;
      final bookingData = bookingDoc.data();
      
      print('DEBUG: Updating booking $bookingId with data: $bookingData');

      // Calculate earnings (90% of discounted price) and commission (10% of discounted price)
      final discountedPrice = bookingData['finalPrice'];
      final earnings = (discountedPrice * 0.90).round();
      final commission = (discountedPrice * 0.10).round();

      print('DEBUG: Calculated earnings: $earnings, commission: $commission');

      // Start a batch write to ensure all updates are atomic
      final batch = FirebaseFirestore.instance.batch();

      // Update order status
      final orderRef = FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(bookingId);
      batch.update(orderRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'earnings': earnings,
        'commission': commission,
      });

      print('DEBUG: Added order status update to batch');

      // Update professional's earnings in Firestore
      final professionalRef = FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId);
      batch.update(professionalRef, {
        'earnings': FieldValue.increment(earnings),
        'commission': FieldValue.increment(commission),
        'walletBalance': FieldValue.increment(earnings),
      });

      print('DEBUG: Added professional earnings update to batch');

      // Commit the batch
      await batch.commit();
      print('DEBUG: Batch commit successful');

      // Update local wallet balance
      final currentBalance = prefs.getDouble('walletBalance') ?? 0.0;
      final newBalance = currentBalance + earnings;
      await prefs.setDouble('walletBalance', newBalance);

      print('DEBUG: Updated local wallet balance to: $newBalance');

      // Get existing transactions
      final transactionsJson = prefs.getString('walletTransactions');
      List<Map<String, dynamic>> transactions = [];
      if (transactionsJson != null) {
        transactions = List<Map<String, dynamic>>.from(jsonDecode(transactionsJson));
      }

      // Add new transaction for earnings
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final newTransaction = {
        'id': 'TRX${transactions.length + 1}'.padLeft(6, '0'),
        'orderID': bookingId,
        'amount': earnings.toDouble(),
        'description': 'Payment for ${offer['name']} (Weekly Service Earnings)',
        'type': 'credit',
        'date': formatter.format(now),
      };
      transactions.add(newTransaction);

      // Add commission transaction
      final commissionTransaction = {
        'id': 'TRX${transactions.length + 2}'.padLeft(6, '0'),
        'orderID': bookingId,
        'amount': commission.toDouble(),
        'description': 'Commission for ${offer['name']} (Weekly Service)',
        'type': 'debit',
        'date': formatter.format(now),
      };
      transactions.add(commissionTransaction);

      // Save updated transactions
      await prefs.setString('walletTransactions', jsonEncode(transactions));
      print('DEBUG: Updated wallet transactions');

      // Refresh the wallet screen
      _refreshWalletScreen();

      // Refresh weekly offers
      await _loadWeeklyOffers();

      print('DEBUG: Weekly service completion successful');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weekly service completed successfully. Earnings: Rs. $earnings, Commission: Rs. $commission',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error completing weekly service: $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing weekly service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
