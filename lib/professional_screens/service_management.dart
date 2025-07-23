import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ServiceManagement extends StatefulWidget {
  const ServiceManagement({Key? key}) : super(key: key);

  @override
  _ServiceManagementState createState() => _ServiceManagementState();
}

class _ServiceManagementState extends State<ServiceManagement> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  String _professionalId = '';

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

      _professionalId = userId;

      final servicesQuery = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId)
          .collection('services')
          .get();

      List<Map<String, dynamic>> services = [];
      for (var doc in servicesQuery.docs) {
        services.add({
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unnamed Service',
          'price': doc.data()['price'] ?? 0.0,
          'description': doc.data()['description'] ?? '',
          'imageUrl': doc.data()['imageUrl'] ?? '',
        });
      }

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteService(String serviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('professionals')
          .doc(_professionalId)
          .collection('services')
          .doc(serviceId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service deleted successfully')),
      );

      _loadServices();
    } catch (e) {
      print('Error deleting service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service')),
      );
    }
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => ServiceDialog(
        onSave: (name, description, price, imageFile) async {
          Navigator.of(context).pop();

          setState(() {
            _isLoading = true;
          });

          try {
            String imageUrl = '';

            // Upload image if provided
            if (imageFile != null) {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('professionals')
                  .child(_professionalId)
                  .child('services')
                  .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

              final uploadTask = storageRef.putFile(imageFile);
              final snapshot = await uploadTask;
              imageUrl = await snapshot.ref.getDownloadURL();
            }

            // Add service to Firestore
            await FirebaseFirestore.instance
                .collection('professionals')
                .doc(_professionalId)
                .collection('services')
                .add({
              'name': name,
              'description': description,
              'price': price,
              'imageUrl': imageUrl,
              'createdAt': FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Service added successfully')),
            );

            _loadServices();
          } catch (e) {
            print('Error adding service: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding service')),
            );
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  void _showEditServiceDialog(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => ServiceDialog(
        initialName: service['name'],
        initialDescription: service['description'],
        initialPrice: service['price'],
        initialImageUrl: service['imageUrl'],
        onSave: (name, description, price, imageFile) async {
          Navigator.of(context).pop();

          setState(() {
            _isLoading = true;
          });

          try {
            String imageUrl = service['imageUrl'];

            // Upload new image if provided
            if (imageFile != null) {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('professionals')
                  .child(_professionalId)
                  .child('services')
                  .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

              final uploadTask = storageRef.putFile(imageFile);
              final snapshot = await uploadTask;
              imageUrl = await snapshot.ref.getDownloadURL();
            }

            // Update service in Firestore
            await FirebaseFirestore.instance
                .collection('professionals')
                .doc(_professionalId)
                .collection('services')
                .doc(service['id'])
                .update({
              'name': name,
              'description': description,
              'price': price,
              'imageUrl': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Service updated successfully')),
            );

            _loadServices();
          } catch (e) {
            print('Error updating service: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating service')),
            );
            setState(() {
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Services'),
        centerTitle: true,
      ),
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
                Icons.miscellaneous_services,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No services added yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to add your first service',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (service['imageUrl'] != null && service['imageUrl'].isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        service['imageUrl'],
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey[700],
                              ),
                            ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service['name'] ?? 'Unnamed Service',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '\$${(service['price'] as num).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          service['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.edit),
                              label: Text('Edit'),
                              onPressed: () => _showEditServiceDialog(service),
                            ),
                            SizedBox(width: 8),
                            TextButton.icon(
                              icon: Icon(Icons.delete, color: Colors.red),
                              label: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Service'),
                                    content: Text(
                                        'Are you sure you want to delete this service?'),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      TextButton(
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _deleteService(service['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
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
        onPressed: _showAddServiceDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Service',
      ),
    );
  }
}

class ServiceDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final double? initialPrice;
  final String? initialImageUrl;
  final Function(String name, String description, double price, File? imageFile) onSave;

  const ServiceDialog({
    Key? key,
    this.initialName,
    this.initialDescription,
    this.initialPrice,
    this.initialImageUrl,
    required this.onSave,
  }) : super(key: key);

  @override
  _ServiceDialogState createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    _priceController.text = widget.initialPrice?.toString() ?? '';
    _currentImageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _currentImageUrl = null;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image')),
      );
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      widget.onSave(name, description, price, _imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Add Service' : 'Edit Service'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    ),
                  )
                      : _buildImagePlaceholder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a service name';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: Text('Save'),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey,
        ),
        SizedBox(height: 8),
        Text(
          'Tap to add image',
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}