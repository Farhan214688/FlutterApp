import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final Function? onProfileUpdate;
  const ProfileScreen({Key? key, this.onProfileUpdate}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  // User data
  String _name = 'Professional';
  String _phoneNumber = 'Not provided';
  String _address = '';
  String _city = '';
  String _area = '';
  String _service = 'Not specified';
  String _accountStatus = 'pending';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
    if (_userId != null) {
      _loadProfileData();
      _updateServiceName();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load basic profile information
      final name = prefs.getString('professionalName') ?? prefs.getString('userName');
      final phoneNumber = prefs.getString('professionalPhone');

      setState(() {
        _name = name ?? 'Professional';
        _phoneNumber = phoneNumber ?? 'Not provided';
      });
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateServiceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      String? currentService;

      // Try to get service from Firestore first
      if (userId != null) {
        try {
          final professionalDoc = await FirebaseFirestore.instance
              .collection('professionals')
              .doc(userId)
              .get();

          if (professionalDoc.exists) {
            currentService = professionalDoc.data()?['serviceName'] as String?;
            // Update SharedPreferences to keep in sync
            if (currentService != null) {
              await prefs.setString('lastSelectedService', currentService);
            }
          }
        } catch (e) {
          print('Error fetching service from Firestore: $e');
        }
      }

      // Fallback to SharedPreferences if Firestore fetch failed
      if (currentService == null) {
        currentService = prefs.getString('lastSelectedService');
      }

      // Update the service name in state if it exists
      if (currentService != null && currentService.isNotEmpty) {
        setState(() {
          _service = currentService!;
        });
      }
    } catch (e) {
      print('Error updating service name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Profile'),
          backgroundColor: Colors.lightGreen,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.lightGreen,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('professionals')
                  .doc(_userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading profile data'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) {
                  return Center(child: Text('No profile data found'));
                }

                // Update state with latest data
                _accountStatus = data['status'] ?? 'pending';
                _address = data['address'] ?? '';
                _city = data['city'] ?? '';
                _area = data['area'] ?? '';
                _service = data['serviceName'] ?? 'Not specified';

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header with icon
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.lightGreen.shade50,
                              child: Text(
                                _name.isNotEmpty ? _name[0] : '',
                                style: TextStyle(
                                  fontSize: 60,
                                  color: Colors.lightGreen,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              _name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Professional Service Provider',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Profile information
                      _buildInfoCard(),

                      SizedBox(height: 16),

                      // Account status
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightGreen[700],
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    _accountStatus == 'active'
                                        ? Icons.check_circle
                                        : _accountStatus == 'deactivated'
                                            ? Icons.block
                                            : Icons.pending,
                                    color: _accountStatus == 'active'
                                        ? Colors.lightGreen
                                        : _accountStatus == 'deactivated'
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _accountStatus == 'active'
                                        ? 'Verified Professional'
                                        : _accountStatus == 'deactivated'
                                            ? 'Account Deactivated'
                                            : 'Verification Pending',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _accountStatus == 'active'
                                          ? Colors.lightGreen
                                          : _accountStatus == 'deactivated'
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              if (_accountStatus == 'pending')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Your account is under review. You will be notified once approved.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              if (_accountStatus == 'deactivated')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Your account has been deactivated. Please contact support for assistance.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.home_repair_service,
                                      color: Colors.blue),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Service: $_service',
                                      style: TextStyle(fontSize: 16),
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
                );
              },
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.lightGreen[700],
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(Icons.phone, 'Phone', _phoneNumber),
            Divider(),
            _buildInfoRow(Icons.location_on, 'Address', _formatAddress()),
          ],
        ),
      ),
    );
  }

  String _formatAddress() {
    if (_address.isNotEmpty) {
      return _address;
    }

    // Fall back to old method if needed
    List<String> addressParts = [];

    if (_area.isNotEmpty) {
      addressParts.add(_area);
    }

    if (_city.isNotEmpty) {
      addressParts.add(_city);
    }

    String formattedAddress =
        addressParts.isNotEmpty ? addressParts.join(', ') : 'Not provided';

    return formattedAddress;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    bool isLocationMissing = label == 'Address' && (value == 'Not provided');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: isLocationMissing ? Colors.red : Colors.lightGreen,
              size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                if (isLocationMissing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location data missing',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showUpdateLocationDialog();
                        },
                        icon: Icon(Icons.edit_location, size: 18),
                        label: Text('Add Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateLocationDialog() {
    final addressController = TextEditingController(
        text: _address.isNotEmpty && _address != 'Not provided'
            ? _address.split(',').first.trim()
            : '');
    final cityController = TextEditingController(text: _city);
    final areaController = TextEditingController(text: _area);

    // If we have an address but no area/city parsed, try to extract them
    if (_address.isNotEmpty && _address.contains(',')) {
      final parts = _address.split(',');
      if (parts.length > 1 && areaController.text.isEmpty) {
        areaController.text = parts[1].trim();
      }
      if (parts.length > 2 && cityController.text.isEmpty) {
        cityController.text = parts[2].trim();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., House #123, Street 5',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: areaController,
                decoration: InputDecoration(
                  labelText: 'Area/Sector',
                  hintText: 'e.g., DHA Phase 2',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g., Islamabad',
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
            onPressed: () async {
              if (addressController.text.isEmpty ||
                  cityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Address and City are required')));
                return;
              }

              // Save the new location
              try {
                final prefs = await SharedPreferences.getInstance();

                await prefs.setString('address', addressController.text);
                await prefs.setString('city', cityController.text);
                await prefs.setString('area', areaController.text);

                // Remove any coordinate data to prevent confusion
                await prefs.remove('latitude');
                await prefs.remove('longitude');

                // Build full address
                String fullAddress = addressController.text;
                if (areaController.text.isNotEmpty) {
                  fullAddress += ", ${areaController.text}";
                }
                fullAddress += ", ${cityController.text}";

                // Update state
                setState(() {
                  _address = fullAddress;
                  _city = cityController.text;
                  _area = areaController.text;
                });

                // Also update in verifications if exists
                try {
                  final verificationsJson =
                      prefs.getString('professionalVerifications');
                  if (verificationsJson != null) {
                    final List<dynamic> verifications =
                        jsonDecode(verificationsJson);
                    if (verifications.isNotEmpty) {
                      // Update the latest verification
                      verifications.last['address'] = addressController.text;
                      verifications.last['city'] = cityController.text;
                      verifications.last['area'] = areaController.text;

                      // Remove coordinates from verification if they exist
                      if (verifications.last.containsKey('latitude')) {
                        verifications.last.remove('latitude');
                      }
                      if (verifications.last.containsKey('longitude')) {
                        verifications.last.remove('longitude');
                      }
                      if (verifications.last.containsKey('latitudeStr')) {
                        verifications.last.remove('latitudeStr');
                      }
                      if (verifications.last.containsKey('longitudeStr')) {
                        verifications.last.remove('longitudeStr');
                      }

                      // Save back to storage
                      await prefs.setString('professionalVerifications',
                          jsonEncode(verifications));
                    }
                  }
                } catch (e) {
                  print('Error updating verification location: $e');
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Location updated successfully')));
              } catch (e) {
                print('Error saving location: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating location: $e')));
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
