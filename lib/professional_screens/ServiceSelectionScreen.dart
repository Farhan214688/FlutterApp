import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final Function onServiceAdded;

  const ServiceSelectionScreen({Key? key, required this.onServiceAdded})
      : super(key: key);

  @override
  _ServiceSelectionScreenState createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _availableServices = [];
  List<Map<String, dynamic>> _myServices = [];
  String _error = '';

  final List<Map<String, dynamic>> _allServices = [
    {
      'name': 'AC Service',
      'image': 'Assets/Images/AC.jpg',
      'description':
          'Air conditioning installation, maintenance, and repair services.',
      'category': 'AC Service',
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
      'image': 'Assets/Images/Plumbing.jpg',
      'description':
          'Plumbing installation, repairs, and maintenance services.',
      'category': 'Plumbing',
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
      'image': 'Assets/Images/Electrican.jpg',
      'description':
          'Electrical installation, repairs, and maintenance services.',
      'category': 'Electrical',
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
      'image': 'Assets/Images/HomeCleaning.jpg',
      'description': 'Comprehensive home cleaning and sanitization services.',
      'category': 'Home Cleaning',
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
      'image': 'Assets/Images/car1.jpg',
      'description':
          'Professional carpentry, woodworking, and furniture repair services.',
      'category': 'Carpenter',
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
    print("\n===== SERVICE SELECTION SCREEN INIT =====");
    for (var service in _allServices) {
      print(
          "Available service: ${service['name']} (category: ${service['category']})");
    }
    _loadServices();
    _verifyImageAssets();
    // Add a short delay before running the verification
    Future.delayed(Duration(seconds: 1), _verifyDatabaseContents);
  }

  void _verifyImageAssets() {
    for (var service in _allServices) {
      print("Image asset path: ${service['image']}");
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _myServices = [];
      _availableServices = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        print("DEBUG: No userId found, showing all services");
        _availableServices = List.from(_allServices);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("\n===== DEBUG: LOADING SERVICES =====");
      print("Professional ID: $userId");

      // Get professional's main service type from Firestore
      final professionalDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId)
          .get();

      if (!professionalDoc.exists) {
        print("DEBUG: Professional document not found!");
        setState(() {
          _isLoading = false;
          _error = 'Professional profile not found';
        });
        return;
      }

      final professionalData = professionalDoc.data();
      final mainServiceType =
          (professionalData?['serviceName'] ?? '').toString().trim();
      print("\nDEBUG: Main Service Type from Profile: '$mainServiceType'");

      // Get existing services
      final snapshot = await FirebaseFirestore.instance
          .collection('professionalServices')
          .where('professionalId', isEqualTo: userId)
          .get();

      print("\nDEBUG: Existing Services Count: ${snapshot.docs.length}");

      // Extract existing categories
      final existingCategoryNames = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final category = (data['category'] ?? '').toString().trim();
        if (category.isNotEmpty) {
          existingCategoryNames.add(category);
          print("DEBUG: Existing category: '$category'");

          _myServices.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Service',
            'category': data['category'] ?? '',
            'price': data['price'] ?? 0.0,
          });
        }
      }

      print("\nDEBUG: Filtering Available Services");
      print("Main Service Type: '$mainServiceType'");
      print("Existing Categories: $existingCategoryNames");

      // Define service type groups
      final Map<String, List<String>> serviceGroups = {
        'AC Service': [
          'AC Service',
          'Air Conditioner',
          'Air Conditioning',
          'AC'
        ],
        'Plumbing': ['Plumbing', 'Plumber'],
        'Electrical': ['Electrical', 'Electrician'],
        'Home Cleaning': ['Home Cleaning', 'Cleaning'],
        'Carpenter': ['Carpenter', 'Carpentry']
      };

      // Find the service group for the professional
      String? professionalServiceGroup;
      for (var entry in serviceGroups.entries) {
        if (entry.value.any((type) =>
            mainServiceType.toLowerCase().contains(type.toLowerCase()) ||
            type.toLowerCase().contains(mainServiceType.toLowerCase()))) {
          professionalServiceGroup = entry.key;
          break;
        }
      }

      print("\nDEBUG: Professional Service Group: $professionalServiceGroup");

      // Filter services
      for (var service in _allServices) {
        final serviceCategory = service['category'].toString().trim();
        final isAlreadyAdded = existingCategoryNames.contains(serviceCategory);

        // Check if service belongs to the professional's service group
        bool isMatchingServiceType = false;

        if (professionalServiceGroup != null) {
          // Get the service's group
          String? serviceGroup;
          for (var entry in serviceGroups.entries) {
            if (entry.value.any((type) =>
                serviceCategory.toLowerCase().contains(type.toLowerCase()) ||
                type.toLowerCase().contains(serviceCategory.toLowerCase()))) {
              serviceGroup = entry.key;
              break;
            }
          }

          // Service matches if it's in the same group as the professional
          isMatchingServiceType = serviceGroup == professionalServiceGroup;

          print("\nDEBUG: Checking service: ${service['name']}");
          print("  Category: '$serviceCategory'");
          print("  Service Group: $serviceGroup");
          print("  Professional Group: $professionalServiceGroup");
          print("  Already Added: $isAlreadyAdded");
          print("  Matches Service Type: $isMatchingServiceType");
        }

        if (!isAlreadyAdded && isMatchingServiceType) {
          print("  ✅ ADDING to available services");
          _availableServices.add(service);
        } else {
          print(
              "  ❌ SKIPPING - ${isAlreadyAdded ? 'already added' : 'does not match service group'}");
        }
      }

      print("\nDEBUG: Final Results");
      print("Available Services Count: ${_availableServices.length}");
      print("Available Services:");
      for (var service in _availableServices) {
        print("- ${service['name']} (${service['category']})");
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print("ERROR in _loadServices: $e");
      print("Stack trace: $stackTrace");
      setState(() {
        _isLoading = false;
        _error = 'Failed to load services: $e';
      });
    }
  }

  Future<void> _addService(Map<String, dynamic> service) async {
    // Show dialog to get price and details
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildServiceDetailsDialog(service),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get user information
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        final userName = prefs.getString('professionalName') ??
            prefs.getString('userName') ??
            'Professional';

        if (userId != null) {
          // Create a new service in Firestore
          final serviceData = {
            'name': result['name'],
            'description': result['description'],
            'price': result['price'],
            'discount': result['discount'],
            'category': service['category'],
            'subcategory':
                result['name'], // Add subcategory for plumbing services
            'isAvailable': true,
            'professionalId': userId,
            'professionalName': userName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          print("Adding new service with data:");
          print(serviceData);

          await FirebaseFirestore.instance
              .collection('professionalServices')
              .add(serviceData);

          // Update the UI
          _loadServices();

          // Notify parent
          widget.onServiceAdded();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service added successfully'),
              action: SnackBarAction(
                label: 'VIEW SERVICES',
                onPressed: () {
                  // Navigate back and select My Services tab
                  Navigator.pop(context);
                  // Pass back a flag to indicate navigation to My Services tab
                  Navigator.pop(context, true);
                },
              ),
            ),
          );

          // If no other services to add, go back to dashboard
          if (_availableServices.length <= 1) {
            Future.delayed(Duration(seconds: 2), () {
              Navigator.pop(context, true);
            });
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding service: $e')),
        );
      }
    }
  }

  Widget _buildServiceDetailsDialog(Map<String, dynamic> service) {
    final TextEditingController nameController =
        TextEditingController(text: service['name']);
    final TextEditingController descriptionController =
        TextEditingController(text: service['description']);
    final TextEditingController priceController = TextEditingController();
    final TextEditingController discountController =
        TextEditingController(text: '0');

    return AlertDialog(
      title: Text('Add ${service['name']} Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Service Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (Rs)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount (%)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate inputs
            final name = nameController.text.trim();
            final description = descriptionController.text.trim();
            final priceText = priceController.text.trim();
            final discountText = discountController.text.trim();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Service name cannot be empty')));
              return;
            }

            final price = double.tryParse(priceText);
            if (price == null || price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid price')));
              return;
            }

            final discount = double.tryParse(discountText) ?? 0.0;
            if (discount < 0 || discount > 100) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Discount must be between 0 and 100')));
              return;
            }

            Navigator.pop(context, {
              'name': name,
              'description': description,
              'price': price,
              'discount': discount,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightGreen,
          ),
          child: Text('Add Service'),
        ),
      ],
    );
  }

  Future<void> _verifyDatabaseContents() async {
    try {
      print("\n===== MANUALLY VERIFYING DATABASE CONTENTS =====");
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        print("ERROR: No userId found in SharedPreferences");
        return;
      }

      print("Checking professionalServices for userId: $userId");

      // Direct query without any filters to see all services
      final allServicesSnapshot = await FirebaseFirestore.instance
          .collection('professionalServices')
          .get();

      print(
          "Total services in professionalServices collection: ${allServicesSnapshot.docs.length}");

      // Query just for this professional
      final myServicesSnapshot = await FirebaseFirestore.instance
          .collection('professionalServices')
          .where('professionalId', isEqualTo: userId)
          .get();

      print(
          "Services for this professional: ${myServicesSnapshot.docs.length}");

      // Print details of each service
      for (var doc in myServicesSnapshot.docs) {
        final data = doc.data();
        print("Service [${doc.id}]:");
        print("  - name: ${data['name']}");
        print("  - category: ${data['category']}");
        print("  - professionalId: ${data['professionalId']}");
        print("  - isAvailable: ${data['isAvailable']}");
      }

      // Force reload services with a clear error message
      if (myServicesSnapshot.docs.isNotEmpty &&
          _availableServices.length == _allServices.length) {
        print(
            "\n⚠️ FILTERING ISSUE DETECTED: All services shown despite having existing services");
        print("Reloading services to fix the issue...");
        _loadServices();
      }
    } catch (e) {
      print("Error verifying database contents: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Service'),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Force Refresh',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing available services...')),
              );
              // Clear any cached state and force reload
              setState(() {
                _myServices = [];
                _availableServices = [];
                _isLoading = true;
              });
              _loadServices();
              _verifyDatabaseContents();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadServices,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _availableServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.lightGreen,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'You already offer all available services',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your services: ${_myServices.map((s) => s['name']).join(', ')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'You can manage your existing services in the My Services tab',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                            ),
                            child: Text('Go to My Services'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Select a service to add (${_availableServices.length} available):',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _availableServices.length,
                            itemBuilder: (context, index) {
                              final service = _availableServices[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: Image.asset(
                                        service['image'],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print("Error loading image: $error");
                                          return Container(
                                            height: 150,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                      Icons.home_repair_service,
                                                      size: 50,
                                                      color: Colors.grey[400]),
                                                  SizedBox(height: 8),
                                                  Text(service['name'],
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey[600])),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service['name'],
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            service['description'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _addService(service),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.lightGreen,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12, horizontal: 24),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add),
                                                SizedBox(width: 8),
                                                Text('Add This Service'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
