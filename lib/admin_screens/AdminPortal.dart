import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'VerificationScreen.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/weekly_offers_service.dart';

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
  final _serviceDiscountController = TextEditingController();
  String _selectedCity = 'islamabad';  // Default city
  final List<String> _allowedCities = ['Islamabad', 'Lahore', 'Karachi', 'Rawalpindi'];
  String _selectedServiceType = 'Weekly Offers';
  final AuthService _authService = AuthService();
  int _selectedTabIndex = 0;
  File? _selectedImage;
  bool _isLoading = false;
  final WeeklyOffersService _weeklyOffersService = WeeklyOffersService();

  @override
  void initState() {
    super.initState();
    print('Initializing AdminPortal screens...');
    _screens = [
      _buildWeeklyOffersScreen(),
      VerificationScreen(),
    ];
    _loadWeeklyOffers();
    print('AdminPortal screens initialized successfully');
  }

  Future<void> _loadWeeklyOffers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final offers = await _weeklyOffersService.loadWeeklyOffers();
      setState(() {
        _weeklyOffers.clear();
        _weeklyOffers.addAll(offers);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading weekly offers: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading offers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildWeeklyOffersScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Offers Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          // Add New Offer Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Weekly Offer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _serviceNameController,
                    decoration: InputDecoration(
                      labelText: 'Service Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _servicePriceController,
                    decoration: InputDecoration(
                      labelText: 'Price (Rs.)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _serviceDiscountController,
                    decoration: InputDecoration(
                      labelText: 'Discount (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    items: _allowedCities.map((String city) {
                      return DropdownMenuItem<String>(
                        value: city.toLowerCase(),
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addWeeklyOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Add Weekly Offer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Weekly Offers List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _weeklyOffers.isEmpty
                    ? Center(
                        child: Text(
                          'No weekly offers available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _weeklyOffers.length,
                        itemBuilder: (context, index) {
                          final offer = _weeklyOffers[index];
                          final discountedPrice = offer['price'] - (offer['price'] * offer['discount'] / 100);
                          
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
                                  Text('Final Price: Rs. ${discountedPrice.toStringAsFixed(0)}'),
                                  Text('Status: ${offer['status'] ?? 'pending'}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteWeeklyOffer(offer['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _addWeeklyOffer() async {
    if (_serviceNameController.text.isEmpty ||
        _servicePriceController.text.isEmpty ||
        _serviceDiscountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await _weeklyOffersService.saveWeeklyOffer(
        name: _serviceNameController.text,
        price: int.parse(_servicePriceController.text),
        discount: int.parse(_serviceDiscountController.text),
        city: _selectedCity,
      );

      // Clear form
      _serviceNameController.clear();
      _servicePriceController.clear();
      _serviceDiscountController.clear();
      setState(() {
        _selectedCity = 'islamabad';
      });

      // Reload offers
      await _loadWeeklyOffers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weekly offer added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteWeeklyOffer(String id) async {
    try {
      await _weeklyOffersService.deleteWeeklyOffer(id);
      await _loadWeeklyOffers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Weekly offer deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building AdminPortal with selected index: $_selectedIndex');
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
                    child: Icon(Icons.admin_panel_settings,
                        size: 30, color: Colors.green),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
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
      ),
    );
  }

  void _logout() {
    // Implement logout functionality
  }

  void _onItemTapped(int index) {
    print('Tapped tab: $index');
    setState(() {
      _selectedIndex = index;
    });
  }
}
