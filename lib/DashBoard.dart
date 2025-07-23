import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import 'services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'services/weekly_offers_service.dart';
import 'services/account_status_service.dart';
import 'services/service_persistence_service.dart';
import 'ac_service_details_page.dart';
import 'CustomerSign.dart';
import 'SignUpPage.dart';
import 'PreSignPage.dart';

// Import the pages we created
import 'transaction_history.dart';
import 'customer_support.dart';
import 'terms_conditions.dart';
import 'services/preferences_service.dart';
import 'widgets/terms_dialog.dart';
import 'my_orders.dart';
import 'customer_profile.dart';
import 'service_booking_page.dart';
import 'service_details_page.dart';

class Dashboard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AccountStatusService _accountStatusService = AccountStatusService();

  String? selectedCity;
  final List<String> cities = ["Lahore", "Islamabad", "Rawalpindi", "Karachi"];
  // Add new variable for tracking selected index and login status
  int _selectedIndex = 0;
  bool isLoggedIn = false;
  String username = "Guest";
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isAccountActive = true;

  // Add variables to store user credentials
  String userPhone = "";
  String userEmail = "";

  // Add sample popular services data (this would come from a database in a real app)
  List<Map<String, dynamic>> rapidServices = [
    {
      'name': 'AC Service',
      'image': 'Assets/Images/AC.jpg',
    },
    {
      'name': 'Plumbing',
      'image': 'Assets/Images/Plumbing.jpg',
    },
    {
      'name': 'Electrician',
      'image': 'Assets/Images/Electrican.jpg',
    },
    {
      'name': 'Home Cleaning',
      'image': 'Assets/Images/HomeCleaning.jpg',
    },
    {
      'name': 'Carpenter',
      'image': 'Assets/Images/Construction.jpg',
    },
  ];

  // Add AC services list
  List<Map<String, dynamic>> acServices = [
    {
      'name': 'AC Discounting',
      'title': 'Service of AC',
      'description': 'Per AC(1 to 2.5 Tons)',
      'price': 1000,
      'image': 'Assets/Images/AC1.jpg',
    },
    {
      'name': 'AC General Services',
      'title': 'Service of AC',
      'description': 'Per AC(1 to 2.5 Tons)',
      'price': 2000,
      'image': 'Assets/Images/AC2.jpg',
    },
    {
      'name': 'AC Installation',
      'title': 'Service of AC',
      'description': 'Installation with 10 feet pipe (1 to 2.5 tons)',
      'price': 2800,
      'image': 'Assets/Images/AC3.jpg',
    },
    {
      'name': 'AC Mounting and Discounting + General AC',
      'title': 'Service of AC',
      'description': 'Per AC(1 to 2.5 Tons)',
      'price': 5000,
      'image': 'Assets/Images/AC4.jpg',
    },
    {
      'name': 'AC Repairing',
      'title': 'Service of AC',
      'description': 'Visit and inspection charges',
      'price': 800,
      'image': 'Assets/Images/AC5.jpg',
    },
  ];

  // Add carpenter services list
  List<Map<String, dynamic>> carpenterServices = [
    {
      'name': 'Carpenter Work',
      'description': 'Visit & Inspection Charges',
      'price': 500,
      'image': 'Assets/Images/car1.jpg',
    },
    {
      'name': 'Catcher Replacement',
      'description': 'Per Catcher',
      'price': 500,
      'image': 'Assets/Images/car2.jpg',
    },
    {
      'name': 'Door Installation',
      'description': 'Starting From',
      'price': 1500,
      'image': 'Assets/Images/car3.jpg',
    },
    {
      'name': 'Drawer Lock installation',
      'description': 'Per Lock',
      'price': 500,
      'image': 'Assets/Images/car4.jpg',
    },
    {
      'name': 'Drawer Repairing',
      'description': 'Vary After Inspection',
      'price': 500,
      'image': 'Assets/Images/car5.jpg',
    },
    {
      'name': 'Furniture Repairing',
      'description': 'Visit & Inspection Charges',
      'price': 500,
      'image': 'Assets/Images/car6.jpg',
    },
    {
      'name': 'Room Door Lock installation',
      'description': 'Vary After Inspection',
      'price': 1200,
      'image': 'Assets/Images/car7.jpg',
    },
  ];

  // Add electrician services list
  List<Map<String, dynamic>> electricianServices = [
    {
      'name': 'UPS Repairing',
      'description': 'Visit and inspection charges',
      'price': 800,
      'image': 'Assets/Images/Electrican2.jpg',
    },
    {
      'name': 'Water pump Repairing',
      'description': 'Visit & Inspection Charges',
      'price': 500,
      'image': 'Assets/Images/Electrican3.jpg',
    },
    {
      'name': 'Water Tank Automatic switch installation',
      'description': 'Vary After Inspection',
      'price': 800,
      'image': 'Assets/Images/Electrican4.jpg',
    },
    {
      'name': 'Switch Board socket replacement',
      'description': 'Per Socket',
      'price': 500,
      'image': 'Assets/Images/Electrican5.jpg',
    },
    {
      'name': 'Tube light installation',
      'description': 'Per Tube Light',
      'price': 800,
      'image': 'Assets/Images/Electrican6.jpg',
    },
    {
      'name': 'Tube Light Replacement',
      'description': 'Per Tube Light',
      'price': 600,
      'image': 'Assets/Images/Electrican7.jpg',
    },
    {
      'name': 'UPS Installation (Without Wiring)',
      'description': 'Vary After Inspection',
      'price': 1500,
      'image': 'Assets/Images/Electrican8.jpg',
    },
    {
      'name': 'Single phase breaker replacement',
      'description': 'Starting from',
      'price': 800,
      'image': 'Assets/Images/Electrican9.jpg',
    },
    {
      'name': 'Single phase distribution box installation',
      'description': 'Starting from',
      'price': 2000,
      'image': 'Assets/Images/Electrican10.jpg',
    },
    {
      'name': 'SMD Light installation (with Wiring)',
      'description': 'Per Light (discount on more than 2)',
      'price': 700,
      'image': 'Assets/Images/Electrican12.jpg',
    },
    {
      'name': 'New house wiring',
      'description': 'Visit & inspection charges',
      'price': 500,
      'image': 'Assets/Images/Electrican13.jpg',
    },
    {
      'name': 'Power plug installation (With wiring)',
      'description': 'Vary After Inspection',
      'price': 900,
      'image': 'Assets/Images/Electrican14.jpg',
    },
    {
      'name': 'Pressure motor installation',
      'description': 'Visit & inspection charges',
      'price': 500,
      'image': 'Assets/Images/Electrican16.jpg',
    },
    {
      'name': 'Kitchen Hood Repairing',
      'description': 'Visit & Inspection charges',
      'price': 800,
      'image': 'Assets/Images/Electrican17.jpg',
    },
    {
      'name': 'LED TV Dismounting',
      'description': 'Per LED/LCD',
      'price': 800,
      'image': 'Assets/Images/Electrican18.jpg',
    },
    {
      'name': 'Light plug (with wiring)',
      'description': 'Vary After Inspection',
      'price': 700,
      'image': 'Assets/Images/Electrican19.jpg',
    },
    {
      'name': 'Manual Washing machine Repairing',
      'description': 'Visit & Inspection charges',
      'price': 800,
      'image': 'Assets/Images/Electrican20.jpg',
    },
    {
      'name': 'Fancy Light installation (with wiring)',
      'description': 'Per Light (discount on more than two)',
      'price': 1000,
      'image': 'Assets/Images/Electrican21.jpg',
    },
    {
      'name': 'House electric work',
      'description': 'Visit & Inspection charges',
      'price': 800,
      'image': 'Assets/Images/Electrican22.jpg',
    },
    {
      'name': 'Change over switch installation',
      'description': 'Vary After Inspection',
      'price': 1700,
      'image': 'Assets/Images/Electrican23.jpg',
    },
    {
      'name': 'Door pillar lights',
      'description': 'Vary After Inspection',
      'price': 600,
      'image': 'Assets/Images/Electrican24.jpg',
    },
    {
      'name': 'Electrical wiring',
      'description': 'Visit & Inspection charges',
      'price': 500,
      'image': 'Assets/Images/Electrican25.jpg',
    },
    {
      'name': '32-42 inch LED TV or LCD mounting',
      'description': 'Per LED/LCD',
      'price': 1250,
      'image': 'Assets/Images/Electrican26.jpg',
    },
    {
      'name': '43-65 inch LED TV or LCD mounting',
      'description': 'Per LED/LCD',
      'price': 1600,
      'image': 'Assets/Images/Electrican27.jpg',
    },
    {
      'name': 'Ceiling fan installation',
      'description': 'Per fan',
      'price': 800,
      'image': 'Assets/Images/Electrican28.jpg',
    },
    {
      'name': 'Ceiling fan Repairing',
      'description': 'Visit & Inspection charges',
      'price': 500,
      'image': 'Assets/Images/Electrican29.jpg',
    },
  ];

  // Add plumbing services list
  List<Map<String, dynamic>> plumbingServices = [
    {
      'name': 'Automatic Washing Machine Installation (with Wiring)',
      'description': 'Vary After Inspection',
      'price': 2500,
      'image': 'Assets/Images/Plumbing12.jpg',
    },
    {
      'name': 'Bath Shower Installation',
      'description': 'Vary After Inspection',
      'price': 1500,
      'image': 'Assets/Images/Plumbing3.jpg',
    },
    {
      'name': 'Commode Installation',
      'description': 'Vary after Inspection',
      'price': 2500,
      'image': 'Assets/Images/Plumbing4.jpg',
    },
    {
      'name': 'Commode Tank Machine Replacement',
      'description': 'Per Tank',
      'price': 1000,
      'image': 'Assets/Images/Plumbing5.jpg',
    },
    {
      'name': 'Drain pipe Installation',
      'description': 'Visit and Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing7.jpg',
    },
    {
      'name': 'Gas Pipe wiring',
      'description': 'Visit & Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing8.jpg',
    },
    {
      'name': 'Handle Valve Installation',
      'description': 'Vary After Inspection',
      'price': 1000,
      'image': 'Assets/Images/Plumbing9.jpg',
    },
    {
      'name': 'Hot or cold water piping',
      'description': 'Visit and Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing11.jpg',
    },
    {
      'name': 'House Plumbing Work',
      'description': 'Visit & Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing13.jpg',
    },
    {
      'name': 'Kitchen Drain Blockage',
      'description': 'Vary After Inspection',
      'price': 1000,
      'image': 'Assets/Images/Plumbing14.jpg',
    },
    {
      'name': 'Kitchen Leakage Repairing',
      'description': 'Visit and Inspection Charges',
      'price': 1000,
      'image': 'Assets/Images/Plumbing15.jpg',
    },
    {
      'name': 'Mixer Tap Installation',
      'description': 'Per Tap',
      'price': 850,
      'image': 'Assets/Images/Plumbing16.jpg',
    },
    {
      'name': 'Pipeline Water Leakage',
      'description': 'Visit and Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing18.jpg',
    },
    {
      'name': 'Single Tap Installation',
      'description': 'Starting from',
      'price': 800,
      'image': 'Assets/Images/Plumbing19.jpg',
    },
    {
      'name': 'Sink Installation',
      'description': 'Starting from',
      'price': 1800,
      'image': 'Assets/Images/Plumbing20.jpg',
    },
    {
      'name': 'Sink spindle change',
      'description': 'Starting from',
      'price': 800,
      'image': 'Assets/Images/Plumbing34.jpg',
    },
    {
      'name': 'Washbasin Installation',
      'description': 'Starting from',
      'price': 1500,
      'image': 'Assets/Images/Plumbing35.jpg',
    },
    {
      'name': 'Water Motor installation',
      'description': 'Vary After Inspection',
      'price': 1200,
      'image': 'Assets/Images/Plumbing36.jpg',
    },
    {
      'name': 'Water Motor Repairing',
      'description': 'Visit & Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing38.jpg',
    },
    {
      'name': 'Water Tank Installation',
      'description': 'Visit and Inspection Charges',
      'price': 500,
      'image': 'Assets/Images/Plumbing39.jpg',
    },
    {
      'name': 'Water Tank supply issue',
      'description': 'Visit & Inspection Charges',
      'price': 800,
      'image': 'Assets/Images/Plumbing40.jpg',
    },
  ];

  // Add home cleaning services list
  List<Map<String, dynamic>> homeCleaningServices = [
    {
      'name': 'Deep Cleaning',
      'description': 'Depends on area',
      'price': 2000,
      'image': 'Assets/Images/HomeCleaning1.jpg',
    },
    {
      'name': 'Bathroom Cleaning',
      'description': 'Professional bathroom cleaning service',
      'price': 800,
      'image': 'Assets/Images/HomeCleaning2.jpg',
    },
    {
      'name': 'Kitchen Cleaning',
      'description': 'Professional kitchen cleaning service',
      'price': 800,
      'image': 'Assets/Images/HomeCleaning3.jpg',
    },
    {
      'name': 'Regular Maintenance Cleaning',
      'description': 'Regular home maintenance cleaning',
      'price': 1000,
      'image': 'Assets/Images/HomeCleaning4.jpg',
    },
  ];

  // Add lists for admin-managed services
  List<Map<String, dynamic>> weeklyOffers = [];

  // Function to check if user is admin
  bool get isAdmin => isLoggedIn && username == "ashrafkamran425@gmail.com";

  // Function to launch WhatsApp
  void _launchWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/+923067948948');
    if (!await launchUrl(whatsappUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  // Function to make a phone call
  void _makePhoneCall() async {
    final Uri phoneUrl = Uri.parse('tel:+923067948948');
    if (!await launchUrl(phoneUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make phone call')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
    _loadLoginStatus();
    _loadPopularServices();
    _checkAccountStatus();
    _loadUserCredentials();

    // Add listener to reload services when app resumes from background
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(
      onResumed: () {
        print('App resumed - reloading services');
        _loadPopularServices();
        _checkAccountStatus();
      },
    ));

    // Force a sync operation on app startup to ensure latest data
    _syncWeeklyOffers();
  }

  @override
  void dispose() {
    // Remove any observers when widget is disposed
    WidgetsBinding.instance
        .removeObserver(AppLifecycleObserver(onResumed: () {}));
    super.dispose();
  }

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('isUserLoggedIn') ?? false;
    String savedUsername = prefs.getString('username') ?? 'Guest';

    setState(() {
      isLoggedIn = loggedIn;
      username = loggedIn ? savedUsername : 'Guest';
    });
  }

  Future<void> _checkTermsAcceptance() async {
    bool hasAccepted = await PreferencesService.hasAcceptedTerms();
    if (!hasAccepted) {
      // Show terms dialog
      bool? accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TermsDialog(),
      );

      if (accepted != true) {
        // If user declined, close the app
        Navigator.of(context).pop();
      }
    }
  }

  // Function to check account status
  Future<void> _checkAccountStatus() async {
    if (isLoggedIn) {
      try {
        // Get the user document from Firestore
        final userDoc = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .where('type', isEqualTo: 'customer')
            .get();

        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data();
          // Only set account as inactive if it's specifically suspended
          setState(() {
            _isAccountActive = userData['status'] != 'suspended';
          });
        } else {
          // If user document not found, assume account is active
          setState(() {
            _isAccountActive = true;
          });
        }
      } catch (e) {
        print('Error checking account status: $e');
        // On error, assume account is active
        setState(() {
          _isAccountActive = true;
        });
      }
    }
  }

  // Function to prompt user to login to book a service
  void _promptLoginForBooking(BuildContext context, String serviceName) async {
    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('customerPhone') ?? '';
      // User is logged in, proceed to booking screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOrdersPage(
            isLoggedIn: isLoggedIn,
            username: phoneNumber,
            serviceName: serviceName,
          ),
        ),
      );
    } else {
      // User is not logged in, show a dialog to prompt login
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Login Required'),
            content: Text('You need to login to book this service.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate to login page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      setState(() {
                        isLoggedIn = true;
                        _loadLoginStatus(); // Reload the login status

                        // After successful login, navigate to the service booking
                        if (isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyOrdersPage(
                                isLoggedIn: true,
                                username: username,
                                serviceName: serviceName,
                              ),
                            ),
                          );
                        }
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                ),
                child: Text('Login'),
              ),
            ],
          );
        },
      );
    }
  }

  // Modify the _handleServiceBooking method to check account status
  void _handleServiceBooking(Map<String, dynamic> service) async {
    if (!isLoggedIn) {
      // Show login dialog
      bool? shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Required'),
          content: Text(
              'You need to login to book this service. Would you like to login now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Login'),
            ),
          ],
        ),
      );

      if (shouldLogin == true) {
        // Navigate to login page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        ).then((value) {
          if (value == true) {
            _loadLoginStatus(); // Reload login status after successful login
            _checkAccountStatus(); // Check account status after login
          }
        });
      }
      return;
    }

    // Check if account is active
    if (!_isAccountActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Your account is currently inactive. Please contact support.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to the service booking page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceBookingPage(
          serviceName: service['name'],
          servicePrice: service['price'].toDouble(),
          serviceImage: service['image'],
          discountPercentage: service['discount']?.toDouble(),
        ),
      ),
    );
  }

  // Update the service card widget to use the new booking handler
  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _handleServiceBooking(service),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 100,
          child: Row(
            children: [
              // Service Image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: _buildServiceImage(service['image']),
              ),
              // Service Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs. ${service['price'] ?? 999}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _handleServiceBooking(service),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                            child: Text(
                              'Book Now',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
          child: Text(
            'Rapit Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreen,
            ),
          ),
        ),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_hasError)
          Center(
            child: Column(
              children: [
                Text('Error loading services',
                    style: TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _loadPopularServices,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
        else if (rapidServices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No services available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: rapidServices.length,
            itemBuilder: (context, index) {
              final service = rapidServices[index];
              return GestureDetector(
                onTap: () {
                  if (service['name'] == 'AC Service') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPage(
                          services: acServices,
                          title: 'AC Services',
                        ),
                      ),
                    );
                  } else if (service['name'] == 'Carpenter') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPage(
                          services: carpenterServices,
                          title: 'Carpenter Services',
                        ),
                      ),
                    );
                  } else if (service['name'] == 'Plumbing') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPage(
                          services: plumbingServices,
                          title: 'Plumbing Services',
                        ),
                      ),
                    );
                  } else if (service['name'] == 'Electrician') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPage(
                          services: electricianServices,
                          title: 'Electrician Services',
                        ),
                      ),
                    );
                  } else if (service['name'] == 'Home Cleaning') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPage(
                          services: homeCleaningServices,
                          title: 'Home Cleaning Services',
                        ),
                      ),
                    );
                  } else {
                    _handleServiceBooking(service);
                  }
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.asset(
                            service['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'Assets/Images/Plumbing.jpg',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            service['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.lightGreen,
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAllServices,
          ),
        ],
      ),
      drawer: Drawer(
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
                      username.isNotEmpty ? username[0].toUpperCase() : "U",
                      style: TextStyle(color: Colors.lightGreen, fontSize: 24),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    isLoggedIn ? 'Hi, $username' : 'Hi, Guest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.person),
                title: Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerProfilePage(
                        isLoggedIn: isLoggedIn,
                        username: username,
                        userPhone: userPhone,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.support_agent),
              title: Text('Customer Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerSupportPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Terms and Conditions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TermsConditionsPage(),
                  ),
                ).then((_) {
                  if (!isLoggedIn) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Terms and Conditions'),
                        content:
                            Text('Do you accept our Terms and Conditions?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await PreferencesService.setTermsAccepted();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                            ),
                            child: Text('Accept'),
                          ),
                        ],
                      ),
                    );
                  }
                });
              },
            ),
            Divider(),
            if (!isLoggedIn) ...[
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ),
                  ).then((value) {
                    if (value == true) {
                      setState(() {
                        isLoggedIn = true;
                      });
                    }
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Sign Up'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreSignPage(),
                    ),
                  );
                },
              ),
            ],
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _performLogout();
                },
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (!_isAccountActive && isLoggedIn)
            Container(
              color: Colors.red.withOpacity(0.1),
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Your account is currently inactive',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please contact support for assistance',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          RefreshIndicator(
            onRefresh: () async {
              // Sync offers and reload data
              await _syncWeeklyOffers();
              await _loadPopularServices();
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show welcome message if not logged in
                    if (!isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 8.0),
                        child: Row(
                          children: [
                            Text(
                              isLoggedIn ? 'Hi $username,' : 'Hi Guest,',
                            ),
                            Text(
                              ' Welcome to Rapit',
                              style: TextStyle(color: Colors.lightGreen),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Professional Services at Your Doorstep',
                        style: TextStyle(
                          color: Colors.lightGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Banner image
                    Center(
                      child: Container(
                        height: 130,
                        width: 340,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            'Assets/Images/Dashboard.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Select the city in which you need service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        value: selectedCity,
                        hint: Text("Select a city"),
                        items: cities.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCity = newValue;
                          });
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    // Weekly Offers section
                    if (weeklyOffers.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 10.0, bottom: 10.0),
                        child: Text(
                          'Weekly Offers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightGreen,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Weekly Offers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to see all weekly offers
                              // This would be implemented in a real app
                            },
                            child: Text('See All',
                                style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: weeklyOffers.length,
                          itemBuilder: (context, index) {
                            final offer = weeklyOffers[index];
                            // Skip any offers that might be marked for deletion
                            if (offer['pendingDelete'] == true) {
                              return Container(); // Return empty container for deleted offers
                            }
                            final discountedPrice =
                                (offer['price'] * (1 - offer['discount'] / 100))
                                    .toInt();
                            return GestureDetector(
                              onTap: () => _handleServiceBooking(offer),
                              child: Container(
                                width: 140,
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  color: Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            offer['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                'Rs. ${offer['price']}',
                                                style: TextStyle(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.grey,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'Rs. $discountedPrice',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${offer['discount']}% OFF',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _handleServiceBooking(offer),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.lightGreen,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 6),
                                                textStyle:
                                                    TextStyle(fontSize: 11),
                                              ),
                                              child: Text('Book Now'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Rapit Services section
                    _buildServicesGrid(),

                    // Add bottom padding for floating buttons
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Floating contact buttons at the bottom right
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call button
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: FloatingActionButton(
                    heroTag: "callBtn",
                    backgroundColor: Colors.blue.withOpacity(0.8),
                    child: Icon(Icons.phone, color: Colors.white),
                    onPressed: _makePhoneCall,
                  ),
                ),

                // WhatsApp button
                FloatingActionButton(
                  heroTag: "whatsappBtn",
                  backgroundColor: Colors.green.withOpacity(0.8),
                  child: Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
                  onPressed: _launchWhatsApp,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 1) {
            // My Orders
            SharedPreferences.getInstance().then((prefs) {
              final phoneNumber = prefs.getString('customerPhone') ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyOrdersPage(
                    isLoggedIn: isLoggedIn,
                    username: phoneNumber,
                  ),
                ),
              );
            });
          } else if (index == 2) {
            // Replace Rewards with Customer Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerProfilePage(
                  isLoggedIn: isLoggedIn,
                  username: username,
                  userPhone: userPhone,
                  userEmail: userEmail,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Add a function to handle logout properly
  Future<void> _performLogout() async {
    // Call the auth service to sign out
    await _authService.signOut();

    // Clear only login state in SharedPreferences, preserve credentials
    final prefs = await SharedPreferences.getInstance();

    // Set logout flag first to ensure proper flow in SplashPage
    await prefs.setBool('userHasLoggedOut', true);

    // Clear login state
    await prefs.setBool('isUserLoggedIn', false);
    await prefs.setBool('isLoggedIn', false);

    // DO NOT remove these credential-related fields:
    // - professionalPhone
    // - professionalPassword
    // - professionalName
    // - customerPhone
    // - customerPassword
    // - customerName

    // Update local state
    setState(() {
      isLoggedIn = false;
      username = "Guest";
    });

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You have been logged out successfully')),
    );
  }

  // Load both popular services and weekly offers from Firestore
  Future<void> _loadPopularServices() async {
    print('Starting to load services from Firestore...');

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Use the WeeklyOffersService to load offers
      final weeklyOffersService = WeeklyOffersService();
      final loadedWeeklyOffers = await weeklyOffersService.loadWeeklyOffers();

      print('Loaded ${loadedWeeklyOffers.length} weekly offers from service');

      // Load admin services
      final servicePersistenceService = ServicePersistenceService();
      final adminServices = await servicePersistenceService.loadAdminServices();

      print('Loaded ${adminServices.length} admin services');

      // Attempt to sync any cached offers to Firestore
      weeklyOffersService.syncCachedOffersToFirestore();

      // Update the state with all loaded services
      if (mounted) {
        setState(() {
          weeklyOffers = loadedWeeklyOffers;
          // Add admin services to the list if they're not already in weekly offers
          final adminServiceIds = adminServices.map((s) => s['id']).toSet();
          final weeklyOfferIds = weeklyOffers.map((w) => w['id']).toSet();

          // Add admin services that aren't already in weekly offers
          for (var service in adminServices) {
            if (!weeklyOfferIds.contains(service['id'])) {
              weeklyOffers.add(service);
            }
          }

          // rapidServices list is kept as the original hardcoded list
          _isLoading = false;
        });
      }

      print(
          'Successfully loaded and updated UI: ${weeklyOffers.length} weekly offers, using ${rapidServices.length} default rapit services');
    } catch (e) {
      print('Error loading services: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load services: $e';
        });
      }
    }
  }

  // Function to explicitly sync weekly offers
  Future<void> _syncWeeklyOffers() async {
    try {
      print('Explicitly syncing weekly offers...');
      final weeklyOffersService = WeeklyOffersService();
      await weeklyOffersService.syncCachedOffersToFirestore();
      print('Weekly offers sync completed');
    } catch (e) {
      print('Error syncing weekly offers: $e');
    }
  }

  // Function to refresh all services
  Future<void> _refreshAllServices() async {
    print('Refreshing all services...');

    // Show refreshing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing services...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Force reload of all services
    await _loadPopularServices();
    await _checkAccountStatus();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Services refreshed successfully'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildServiceImage(String imagePath) {
    print('Loading image from path: $imagePath');

    // Check if the image path is a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Use Image.network for URLs
      return Image.network(
        imagePath,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          // Fallback to a default asset image in case of error
          return Image.asset(
            'Assets/Images/Plumbing.jpg',
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      // Use Image.asset for local assets
      try {
        print('Loading asset image: $imagePath');
        return Image.asset(
          imagePath,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading asset image: $error, using fallback image');
            // Fallback to a default asset image in case of error
            return Image.asset(
              'Assets/Images/Plumbing.jpg',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          },
        );
      } catch (e) {
        print('Exception while loading image: $e, using fallback image');
        return Image.asset(
          'Assets/Images/Plumbing.jpg',
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
  }

  // Add method to load user credentials from SharedPreferences
  Future<void> _loadUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userPhone = prefs.getString('customerPhone') ?? "";
      userEmail = prefs.getString('customerEmail') ?? "";
    });
  }
}

// Add this class to handle app lifecycle events
class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;

  AppLifecycleObserver({required this.onResumed});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
