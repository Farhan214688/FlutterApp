import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ServiceSelectionScreen.dart';

class MyServiceScreen extends StatefulWidget {
  final Function onServiceUpdated;

  const MyServiceScreen({Key? key, required this.onServiceUpdated}) : super(key: key);

  @override
  _MyServiceScreenState createState() => _MyServiceScreenState();
}

class _MyServiceScreenState extends State<MyServiceScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        try {
          // Try to fetch from Firestore
          final snapshot = await FirebaseFirestore.instance
              .collection('professionalServices')
              .where('professionalId', isEqualTo: userId)
              .get();

          _services = snapshot.docs.map<Map<String, dynamic>>((doc) {
            return {
              'id': doc.id,
              'name': doc.data()['name'] ?? 'Unknown Service',
              'description': doc.data()['description'] ?? '',
              'price': doc.data()['price'] ?? 0.0,
              'discount': doc.data()['discount'] ?? 0.0,
              'category': doc.data()['category'] ?? 'Other',
              'isAvailable': doc.data()['isAvailable'] ?? true,
            };
          }).toList();
        } catch (e) {
          print('Error fetching services from Firestore: $e');
          // Get from SharedPreferences as fallback
          final servicesJson = prefs.getStringList('professionalServices') ?? [];
          _services = servicesJson.map((serviceStr) {
            final Map<String, dynamic> serviceMap = {};
            serviceStr.split('||').forEach((item) {
              final parts = item.split('::');
              if (parts.length == 2) {
                final key = parts[0];
                final value = parts[1];

                if (key == 'price' || key == 'discount') {
                  serviceMap[key] = double.tryParse(value) ?? 0.0;
                } else if (key == 'isAvailable') {
                  serviceMap[key] = value == 'true';
                } else {
                  serviceMap[key] = value;
                }
              }
            });
            return serviceMap;
          }).toList();
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load services: $e';
      });
    }
  }

  Future<void> _toggleServiceAvailability(int index, bool isAvailable) async {
    setState(() {
      _services[index]['isAvailable'] = isAvailable;
    });

    _saveServiceToPrefs();

    // Update Firestore if possible
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null && _services[index]['id'] != null) {
        await FirebaseFirestore.instance
            .collection('professionalServices')
            .doc(_services[index]['id'])
            .update({'isAvailable': isAvailable});
      }
    } catch (e) {
      print('Error updating service availability in Firestore: $e');
      // Show error but don't revert the UI change since it's saved in prefs
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Service updated locally but not synced to cloud'))
      );
    }

    widget.onServiceUpdated();
  }

  Future<void> _saveServiceToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert services to strings for storage
      final servicesJson = _services.map((service) {
        return service.entries.map((entry) => '${entry.key}::${entry.value}').join('||');
      }).toList();

      await prefs.setStringList('professionalServices', servicesJson);
    } catch (e) {
      print('Error saving services to SharedPreferences: $e');
    }
  }

  Future<void> _editService(int index) async {
    final service = _services[index];

    final TextEditingController nameController = TextEditingController(text: service['name']);
    final TextEditingController descriptionController = TextEditingController(text: service['description']);
    final TextEditingController priceController = TextEditingController(text: service['price'].toString());
    final TextEditingController discountController = TextEditingController(text: service['discount'].toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
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
                    SnackBar(content: Text('Service name cannot be empty'))
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid price'))
                );
                return;
              }

              final discount = double.tryParse(discountText) ?? 0.0;
              if (discount < 0 || discount > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Discount must be between 0 and 100'))
                );
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
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _services[index]['name'] = result['name'];
        _services[index]['description'] = result['description'];
        _services[index]['price'] = result['price'];
        _services[index]['discount'] = result['discount'];
      });

      _saveServiceToPrefs();

      // Update Firestore if possible
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        if (userId != null && _services[index]['id'] != null) {
          await FirebaseFirestore.instance
              .collection('professionalServices')
              .doc(_services[index]['id'])
              .update({
            'name': result['name'],
            'description': result['description'],
            'price': result['price'],
            'discount': result['discount'],
          });
        }
      } catch (e) {
        print('Error updating service in Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service updated locally but not synced to cloud'))
        );
      }

      widget.onServiceUpdated();
    }
  }

  Future<void> _deleteService(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Service'),
        content: Text('Are you sure you want to delete this service? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final serviceId = _services[index]['id'];

      setState(() {
        _services.removeAt(index);
      });

      _saveServiceToPrefs();

      // Delete from Firestore if possible
      try {
        if (serviceId != null) {
          await FirebaseFirestore.instance
              .collection('professionalServices')
              .doc(serviceId)
              .delete();
        }
      } catch (e) {
        print('Error deleting service from Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service deleted locally but not removed from cloud'))
        );
      }

      widget.onServiceUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
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
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_repair_service_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No services added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add a service to start offering your expertise',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceSelectionScreen(
                      onServiceAdded: () {
                        _loadServices();
                        widget.onServiceUpdated();
                      },
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text('Add New Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadServices,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            final bool isAvailable = service['isAvailable'] ?? true;
            final double price = service['price'] ?? 0.0;
            final double discount = service['discount'] ?? 0.0;
            final double finalPrice = price - (price * discount / 100);

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Text(
                          service['name'] ?? 'Unknown Service',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: isAvailable ? Colors.green[800] : Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text(
                          service['description'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (discount > 0) ...[
                                      Text(
                                        'Rs. ${price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                    Text(
                                      'Rs. ${finalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Spacer(),
                            if (discount > 0) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${discount.toStringAsFixed(0)}% OFF',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Category: ${service['category'] ?? 'Other'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => _toggleServiceAvailability(index, !isAvailable),
                          icon: Icon(
                            isAvailable ? Icons.visibility_off : Icons.visibility,
                            color: isAvailable ? Colors.red : Colors.green,
                          ),
                          label: Text(
                            isAvailable ? 'Mark Unavailable' : 'Mark Available',
                            style: TextStyle(
                              color: isAvailable ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _editService(index),
                          icon: Icon(Icons.edit, color: Colors.blue),
                          label: Text('Edit', style: TextStyle(color: Colors.blue)),
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteService(index),
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text('Delete', style: TextStyle(color: Colors.red)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceSelectionScreen(
                onServiceAdded: () {
                  _loadServices();
                  widget.onServiceUpdated();
                },
              ),
            ),
          );
        },
        backgroundColor: Colors.lightGreen,
        child: Icon(Icons.add),
        tooltip: 'Add More Services',
      ),
    );
  }
}