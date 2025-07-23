import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'admin_service_management.dart';
import 'providers/service_provider.dart';
import 'DashBoard.dart';
import 'admin_screens/DashboardScreen.dart';
import 'admin_screens/VerificationScreen.dart';
import 'admin_screens/ProfilesScreen.dart';
import 'LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'services/weekly_offers_service.dart';
import 'package:image/image.dart' as img;

class AdminPortal extends StatefulWidget {
  @override
  _AdminPortalState createState() => _AdminPortalState();
}

class _AdminPortalState extends State<AdminPortal> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final List<Map<String, dynamic>> _weeklyOffers = [];
  final List<Map<String, dynamic>> _popularServices = [];
  final _serviceNameController = TextEditingController();
  final _serviceImageController = TextEditingController();
  final _servicePriceController = TextEditingController();
  String _selectedServiceType = 'Weekly Offers';
  final AuthService _authService = AuthService();
  int _selectedTabIndex = 0;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _screens = [
      ServiceManagementScreen(),
      VerificationScreen(),
    ];
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceImageController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    // Call the auth service to sign out
    await _authService.signOut();

    // Clear any saved login information
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLoggedIn', false);
    await prefs.setBool('userHasLoggedOut', true);  // Set logout flag to true
    await prefs.remove('username');
    await prefs.remove('isAdmin');
    await prefs.remove('userType');  // Clear user type to avoid incorrect auto-login

    // Navigate to Dashboard as guest
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Dashboard()),
          (route) => false,
    );

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You have been logged out successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Portal'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Kamran',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'rapit920@gmail.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.local_offer),
              title: Text('Weekly Offers'),
              selected: _selectedIndex == 0,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.verified_user),
              title: Text('Verifications'),
              selected: _selectedIndex == 1,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Weekly Offers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Verifications',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// New screen to manage all service types
class ServiceManagementScreen extends StatefulWidget {
  @override
  _ServiceManagementScreenState createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Offers Management'),
        backgroundColor: Colors.green,
      ),
      body: WeeklyOffersTab(),
    );
  }
}

class WeeklyOffersTab extends StatefulWidget {
  @override
  _WeeklyOffersTabState createState() => _WeeklyOffersTabState();
}

class _WeeklyOffersTabState extends State<WeeklyOffersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WeeklyOffersService _weeklyOffersService = WeeklyOffersService();
  List<Map<String, dynamic>> weeklyOffers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyOffers();
  }

  Future<void> _loadWeeklyOffers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use the new service to load offers
      final offers = await _weeklyOffersService.loadWeeklyOffers();

      setState(() {
        weeklyOffers = offers;
        _isLoading = false;
      });

      print('Loaded ${weeklyOffers.length} weekly offers');
    } catch (e) {
      print('Error loading weekly offers: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading offers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddOfferDialog() {
    String name = '';
    String price = '';
    String discount = '';
    String selectedCity = 'Islamabad';  // Default city
    bool isLoading = false;
    final List<String> cities = ['Islamabad', 'Lahore', 'Karachi', 'Rawalpindi'];  // Only 4 cities

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _saveNewOffer() async {
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a service name')),
                );
                return;
              }

              if (price.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a price')),
                );
                return;
              }

              setDialogState(() {
                isLoading = true;
              });

              try {
                // Create new offer using the service
                await _weeklyOffersService.saveWeeklyOffer(
                  name: name,
                  price: int.parse(price),
                  discount: discount.isNotEmpty ? int.parse(discount) : 0,
                  city: selectedCity,
                );

                // Close dialog
                Navigator.of(dialogContext).pop();

                // Reload offers
                _loadWeeklyOffers();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New offer added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error adding weekly offer: $e');
                setDialogState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding offer: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text('Add New Weekly Offer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Service Name'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Price (Rs)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => price = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Discount (%)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => discount = value,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      items: cities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedCity = newValue;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    if (isLoading)
                      Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _saveNewOffer,
                        child: Text('Save Offer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(double.infinity, 45),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOfferDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : weeklyOffers.isEmpty
              ? Center(
                  child: Text(
                    'No weekly offers available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: weeklyOffers.length,
                  itemBuilder: (context, index) {
                    final offer = weeklyOffers[index];
                    final discountedPrice = offer['price'] - (offer['price'] * offer['discount'] / 100);
                    
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    offer['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteConfirmationDialog(offer['id']),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Rs. ${discountedPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Rs. ${offer['price']}',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '(${offer['discount']}% off)',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete Offer'),
          content: Text('Are you sure you want to delete this offer?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  // Close dialog first for better UX
                  Navigator.of(dialogContext).pop();

                  // First update UI immediately for better user experience
                  setState(() {
                    weeklyOffers.removeWhere((offer) => offer['id'] == id);
                  });

                  // Show deletion in progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleting offer...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Then delete from backend
                  await _weeklyOffersService.deleteWeeklyOffer(id);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Offer deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Optional: Reload to ensure UI is in sync with Firestore
                  _loadWeeklyOffers();
                } catch (e) {
                  print('Error deleting weekly offer: $e');

                  // Reload offers list to restore the item if deletion failed
                  _loadWeeklyOffers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting offer: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}