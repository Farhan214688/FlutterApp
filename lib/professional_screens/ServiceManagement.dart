import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ServiceManagement extends StatefulWidget {
  const ServiceManagement({Key? key}) : super(key: key);

  @override
  _ServiceManagementState createState() => _ServiceManagementState();
}

class _ServiceManagementState extends State<ServiceManagement> {
  bool _isLoading = true;
  bool _isAddingService = false;
  String _professionalId = '';
  List<DocumentSnapshot> _services = [];
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _loadServices();
  }
  
  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _professionalId = userId;
      });
      
      // Get services from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('professionalId', isEqualTo: userId)
          .get();
      
      setState(() {
        _services = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showAddServiceDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    final TextEditingController _priceController = TextEditingController();
    final TextEditingController _durationController = TextEditingController();
    File? _serviceImage;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImage() async {
              try {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 75,
                );
                
                if (image != null) {
                  setState(() {
                    _serviceImage = File(image.path);
                  });
                }
              } catch (e) {
                print('Error picking image: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error picking image: $e')),
                );
              }
            }
            
            return AlertDialog(
              title: Text('Add New Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Service Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _serviceImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _serviceImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add service image',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Service Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Service Name*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Service Description
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    
                    // Service Price
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (₹)*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    
                    // Service Duration
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (minutes)*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                _isAddingService
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          // Validate inputs
                          if (_nameController.text.trim().isEmpty ||
                              _descriptionController.text.trim().isEmpty ||
                              _priceController.text.trim().isEmpty ||
                              _durationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill all required fields'),
                              ),
                            );
                            return;
                          }
                          
                          if (_serviceImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select a service image'),
                              ),
                            );
                            return;
                          }
                          
                          // Parse price and duration
                          final double? price = double.tryParse(_priceController.text);
                          final int? duration = int.tryParse(_durationController.text);
                          
                          if (price == null || duration == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid price or duration'),
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            _isAddingService = true;
                          });
                          
                          try {
                            // Generate unique ID for the service
                            final String serviceId = Uuid().v4();
                            
                            // Upload image to Firebase Storage
                            final ref = FirebaseStorage.instance
                                .ref()
                                .child('service_images')
                                .child('$serviceId.jpg');
                            
                            await ref.putFile(_serviceImage!);
                            final imageUrl = await ref.getDownloadURL();
                            
                            // Save service to Firestore
                            await FirebaseFirestore.instance
                                .collection('services')
                                .doc(serviceId)
                                .set({
                              'id': serviceId,
                              'professionalId': _professionalId,
                              'name': _nameController.text.trim(),
                              'description': _descriptionController.text.trim(),
                              'price': price,
                              'duration': duration,
                              'imageUrl': imageUrl,
                              'isAvailable': true,
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            
                            Navigator.pop(context);
                            _loadServices(); // Refresh the service list
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Service added successfully'),
                              ),
                            );
                          } catch (e) {
                            print('Error adding service: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding service: $e'),
                              ),
                            );
                            
                            setState(() {
                              _isAddingService = false;
                            });
                          }
                        },
                        child: Text('Add Service'),
                      ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showEditServiceDialog(DocumentSnapshot service) {
    final data = service.data() as Map<String, dynamic>;
    final TextEditingController _nameController = TextEditingController(text: data['name'] ?? '');
    final TextEditingController _descriptionController = TextEditingController(text: data['description'] ?? '');
    final TextEditingController _priceController = TextEditingController(text: data['price']?.toString() ?? '');
    final TextEditingController _durationController = TextEditingController(text: data['duration']?.toString() ?? '');
    bool _isAvailable = data['isAvailable'] ?? true;
    bool _isUpdating = false;
    
    String _serviceImageUrl = data['imageUrl'] ?? '';
    File? _serviceImage;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImage() async {
              try {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 75,
                );
                
                if (image != null) {
                  setState(() {
                    _serviceImage = File(image.path);
                  });
                }
              } catch (e) {
                print('Error picking image: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error picking image: $e')),
                );
              }
            }
            
            return AlertDialog(
              title: Text('Edit Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Service Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _serviceImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _serviceImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _serviceImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _serviceImageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error,
                                              size: 50,
                                              color: Colors.red,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Error loading image',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tap to change service image',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Service Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Service Name*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Service Description
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    
                    // Service Price
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price (₹)*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    
                    // Service Duration
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (minutes)*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    
                    // Availability Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Availability',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Switch(
                          value: _isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                _isUpdating
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          // Validate inputs
                          if (_nameController.text.trim().isEmpty ||
                              _descriptionController.text.trim().isEmpty ||
                              _priceController.text.trim().isEmpty ||
                              _durationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill all required fields'),
                              ),
                            );
                            return;
                          }
                          
                          // Parse price and duration
                          final double? price = double.tryParse(_priceController.text);
                          final int? duration = int.tryParse(_durationController.text);
                          
                          if (price == null || duration == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid price or duration'),
                              ),
                            );
                            return;
                          }
                          
                          setState(() {
                            _isUpdating = true;
                          });
                          
                          try {
                            String imageUrl = _serviceImageUrl;
                            
                            // Upload new image if selected
                            if (_serviceImage != null) {
                              final ref = FirebaseStorage.instance
                                  .ref()
                                  .child('service_images')
                                  .child('${service.id}.jpg');
                              
                              await ref.putFile(_serviceImage!);
                              imageUrl = await ref.getDownloadURL();
                            }
                            
                            // Update service in Firestore
                            await FirebaseFirestore.instance
                                .collection('services')
                                .doc(service.id)
                                .update({
                              'name': _nameController.text.trim(),
                              'description': _descriptionController.text.trim(),
                              'price': price,
                              'duration': duration,
                              'imageUrl': imageUrl,
                              'isAvailable': _isAvailable,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            
                            Navigator.pop(context);
                            _loadServices(); // Refresh the service list
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Service updated successfully'),
                              ),
                            );
                          } catch (e) {
                            print('Error updating service: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating service: $e'),
                              ),
                            );
                            
                            setState(() {
                              _isUpdating = false;
                            });
                          }
                        },
                        child: Text('Update Service'),
                      ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _confirmDeleteService(DocumentSnapshot service) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Service'),
          content: Text('Are you sure you want to delete this service? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Delete service image from storage
                  try {
                    final ref = FirebaseStorage.instance
                        .ref()
                        .child('service_images')
                        .child('${service.id}.jpg');
                    await ref.delete();
                  } catch (e) {
                    // Image might not exist, continue with service deletion
                    print('Error deleting service image: $e');
                  }
                  
                  // Delete service from Firestore
                  await FirebaseFirestore.instance
                      .collection('services')
                      .doc(service.id)
                      .delete();
                  
                  Navigator.pop(context);
                  _loadServices(); // Refresh the service list
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Service deleted successfully'),
                    ),
                  );
                } catch (e) {
                  print('Error deleting service: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting service: $e'),
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildServiceCard(DocumentSnapshot service) {
    final data = service.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unnamed Service';
    final description = data['description'] ?? '';
    final price = data['price'] ?? 0.0;
    final isAvailable = data['isAvailable'] ?? true;
    final imageUrl = data['imageUrl'] ?? '';
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
          ),
          
          // Service Info
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditServiceDialog(service),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteService(service),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServices,
              child: _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_repair_service,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No services found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add a new service',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(8),
                      child: ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          return _buildServiceCard(_services[index]);
                        },
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServiceDialog,
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
      ),
    );
  }
} 