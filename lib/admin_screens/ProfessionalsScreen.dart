import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class ProfessionalVerification {
  final String id;
  final String name;
  final String phoneNumber;
  final String serviceName;
  final String frontIDPath;
  final String backIDPath;
  final String selfiePath;
  final String status; // 'pending', 'approved', 'rejected'
  final String submittedDate;
  final String? locationType; // 'Home' or 'Office'
  final String? address;
  final String? city;
  final String? area;
  // Location coordinates
  final double? latitude;
  final double? longitude;
  // New fields for offer details
  final String? offerName;
  final double? offerPrice;
  final double? offerDiscount;
  final String? offerImage;
  final String? offerId;
  final bool isOfferApplication;
  final bool isLocalData; // Flag to indicate if this is from SharedPreferences
  // Direct image URLs
  final String? frontIDUrl;
  final String? backIDUrl;
  final String? selfieUrl;

  ProfessionalVerification({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.serviceName,
    required this.frontIDPath,
    required this.backIDPath,
    required this.selfiePath,
    required this.status,
    required this.submittedDate,
    this.locationType,
    this.address,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.offerName,
    this.offerPrice,
    this.offerDiscount,
    this.offerImage,
    this.offerId,
    this.isOfferApplication = false,
    this.isLocalData = false,
    this.frontIDUrl,
    this.backIDUrl,
    this.selfieUrl,
  });

  factory ProfessionalVerification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProfessionalVerification(
      id: doc.id,
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      serviceName: data['serviceName'] ?? data['offerName'] ?? '',
      frontIDPath: data['frontIDPath'] ?? '',
      backIDPath: data['backIDPath'] ?? '',
      selfiePath: data['selfiePath'] ?? '',
      status: data['status'] ?? 'pending',
      submittedDate: data['submittedDate'] ?? '',
      locationType: data['locationType'],
      address: data['address'],
      city: data['city'],
      area: data['area'],
      // Parse latitude and longitude from numeric or string values
      latitude: _parseDoubleValue(data['latitude']),
      longitude: _parseDoubleValue(data['longitude']),
      offerName: data['offerName'],
      offerPrice: data['offerPrice'],
      offerDiscount: data['offerDiscount'],
      offerImage: data['offerImage'],
      offerId: data['offerId'],
      isOfferApplication: data.containsKey('offerName'),
      // Include the direct URLs if they exist
      frontIDUrl: data['frontIDUrl'],
      backIDUrl: data['backIDUrl'],
      selfieUrl: data['selfieUrl'],
    );
  }

  // Helper method to parse double values from various sources
  static double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double value: $e');
        return null;
      }
    }
    return null;
  }

  factory ProfessionalVerification.fromLocalStorage(Map<String, dynamic> data) {
    return ProfessionalVerification(
      id: data['id'] ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      serviceName: data['serviceName'] ?? '',
      frontIDPath: data['frontIDPath'] ?? '',
      backIDPath: data['backIDPath'] ?? '',
      selfiePath: data['selfiePath'] ?? '',
      status: data['status'] ?? 'pending',
      submittedDate: data['submittedDate'] ?? '',
      address: data['address'],
      city: data['city'],
      area: data['area'],
      locationType: data['locationType'] ?? 'Home',
      // Parse latitude and longitude from numeric or string values
      latitude: _parseDoubleValue(data['latitude']),
      longitude: _parseDoubleValue(data['longitude']),
      isLocalData: true,
      // Include the direct URLs if they exist
      frontIDUrl: data['frontIDUrl'],
      backIDUrl: data['backIDUrl'],
      selfieUrl: data['selfieUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'name': name,
      'phoneNumber': phoneNumber,
      'frontIDPath': frontIDPath,
      'backIDPath': backIDPath,
      'selfiePath': selfiePath,
      'status': status,
      'submittedDate': submittedDate,
      'locationType': locationType,
      'address': address,
      'city': city,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      // Include the direct URLs if they exist
      'frontIDUrl': frontIDUrl,
      'backIDUrl': backIDUrl,
      'selfieUrl': selfieUrl,
    };

    if (isOfferApplication) {
      data['offerName'] = offerName;
      data['offerPrice'] = offerPrice;
      data['offerDiscount'] = offerDiscount;
      data['offerImage'] = offerImage;
      data['offerId'] = offerId;
    } else {
      data['serviceName'] = serviceName;
    }

    return data;
  }
}

class ProfessionalsScreen extends StatefulWidget {
  @override
  _ProfessionalsScreenState createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<ProfessionalVerification> _verifications = [];
  List<ProfessionalVerification> _offerApplications = [];
  List<ProfessionalVerification> _pendingVerifications =
      []; // Renamed from _localVerifications
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _refreshCurrentTab();
    }
  }

  Future<void> _refreshCurrentTab() async {
    final int currentTab = _tabController.index;
    if (currentTab == 0) {
      // Pending tab
      await _loadPendingVerifications();
    } else {
      // Approved or Rejected tab
      await _loadVerifications();
      await _loadOfferApplications();
    }
  }

  Future<void> _loadAllData() async {
    await _loadVerifications();
    await _loadOfferApplications();
    await _loadPendingVerifications();
  }

  Future<void> _loadVerifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('professional_verifications')
          .orderBy('submittedDate', descending: true)
          .get();

      final List<ProfessionalVerification> firestoreVerifications = snapshot
          .docs
          .map((doc) => ProfessionalVerification.fromFirestore(doc))
          .toList();

      setState(() {
        // Retain any local verifications from the current list
        final List<ProfessionalVerification> localVerifications =
            _verifications.where((v) => v.isLocalData).toList();

        // Combine Firestore and local verifications
        _verifications = [...firestoreVerifications];

        // Add local verifications if they don't already exist
        for (final localVerification in localVerifications) {
          if (!_verifications.any((v) => v.id == localVerification.id)) {
            _verifications.add(localVerification);
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load verifications. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOfferApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('professional_applications')
          .orderBy('submittedDate', descending: true)
          .get();

      setState(() {
        // Clear existing applications first
        _offerApplications = [];

        // Only load applications with explicit admin approval/rejection
        _offerApplications = snapshot.docs
            .map((doc) => ProfessionalVerification.fromFirestore(doc))
            .where((verification) =>
                verification.status == 'approved' ||
                verification.status == 'rejected')
            .toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load offer applications. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // This loads the pending verifications from SharedPreferences
  Future<void> _loadPendingVerifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);
        final List<ProfessionalVerification> allVerifications =
            verificationsList
                .map((data) => ProfessionalVerification.fromLocalStorage(data))
                .toList();

        setState(() {
          // Filter only pending verifications for the pending list
          _pendingVerifications = allVerifications
              .where((verification) => verification.status == 'pending')
              .toList();

          // Process local verifications with approved or rejected status
          final List<ProfessionalVerification> processedVerifications =
              allVerifications
                  .where((verification) =>
                      verification.status == 'approved' ||
                      verification.status == 'rejected')
                  .toList();

          // Remove existing local verifications from the _verifications list
          _verifications.removeWhere((v) => v.isLocalData);

          // Add all processed local verifications to the main verification list
          _verifications.addAll(processedVerifications);
        });
      }
    } catch (e) {
      // Error handling without print statements
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVerificationStatus(
      String id, String newStatus, bool isOfferApplication) async {
    try {
      final collectionName = isOfferApplication
          ? 'professional_applications'
          : 'professional_verifications';

      // Check if this is a local verification with a generated ID (starts with 'local-')
      bool isLocalVerification = id.startsWith('local-');

      // Get the verification object from the appropriate list
      ProfessionalVerification? verification;

      if (isOfferApplication) {
        verification = _offerApplications.firstWhere((v) => v.id == id,
            orElse: () => ProfessionalVerification(
                  id: '',
                  name: '',
                  phoneNumber: '',
                  serviceName: '',
                  frontIDPath: '',
                  backIDPath: '',
                  selfiePath: '',
                  status: '',
                  submittedDate: '',
                ));
      } else {
        // For regular verification, check both pending and main lists
        verification = _verifications.firstWhere((v) => v.id == id, orElse: () {
          // If not found in _verifications, try _pendingVerifications
          return _pendingVerifications.firstWhere((v) => v.id == id,
              orElse: () => ProfessionalVerification(
                    id: '',
                    name: '',
                    phoneNumber: '',
                    serviceName: '',
                    frontIDPath: '',
                    backIDPath: '',
                    selfiePath: '',
                    status: '',
                    submittedDate: '',
                  ));
        });
      }

      if (verification.id.isEmpty) {
        throw Exception("Verification not found");
      }

      // Pre-fetch image URLs to store them directly
      final List<String> imageUrls = await Future.wait([
        _getImageUrl(verification.frontIDPath),
        _getImageUrl(verification.backIDPath),
        _getImageUrl(verification.selfiePath),
      ]);

      // Create a map of data to update
      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'frontIDUrl': imageUrls[0],
        'backIDUrl': imageUrls[1],
        'selfieUrl': imageUrls[2],
        // Include any existing location data
        'address': verification.address,
        'city': verification.city,
        'area': verification.area,
        'locationType': verification.locationType ?? 'Home',
        'latitude': verification.latitude,
        'longitude': verification.longitude,
      };

      if (!isLocalVerification) {
        // For Firebase verifications, update the status in the database
        await _firestore.collection(collectionName).doc(id).update(updateData);
      }

      // If approved, update the professional's status in the professionals collection
      if (newStatus == 'approved' && verification.id.isNotEmpty) {
        Map<String, dynamic> professionalData = {
          'id': verification.id,
          'name': verification.name,
          'phoneNumber': verification.phoneNumber,
          'serviceName': verification.isOfferApplication
              ? verification.offerName
              : verification.serviceName,
          'status': 'active',
          'locationType': verification.locationType ?? 'Home',
          'address': verification.address,
          'city': verification.city,
          'area': verification.area,
          'latitude': verification.latitude,
          'longitude': verification.longitude,
          'coordinates':
              verification.latitude != null && verification.longitude != null
                  ? GeoPoint(verification.latitude!, verification.longitude!)
                  : null,
          'isOfferProfessional': verification.isOfferApplication,
          'frontIDUrl': imageUrls[0],
          'backIDUrl': imageUrls[1],
          'selfieUrl': imageUrls[2],
          'approved_date': DateTime.now().toIso8601String(),
          'approved_by_admin': true,
        };

        // Add offer details if this is an offer application
        if (verification.isOfferApplication) {
          professionalData['offerDetails'] = {
            'name': verification.offerName,
            'price': verification.offerPrice,
            'discount': verification.offerDiscount,
            'image': verification.offerImage,
            'id': verification.offerId,
          };
        }

        await _firestore
            .collection('professionals')
            .doc(verification.id)
            .set(professionalData, SetOptions(merge: true));
      }

      // Create a new verification object with updated status
      final ProfessionalVerification updatedVerification =
          ProfessionalVerification(
        id: verification.id,
        name: verification.name,
        phoneNumber: verification.phoneNumber,
        serviceName: verification.serviceName,
        frontIDPath: verification.frontIDPath,
        backIDPath: verification.backIDPath,
        selfiePath: verification.selfiePath,
        status: newStatus,
        submittedDate: verification.submittedDate,
        address: verification.address,
        city: verification.city,
        area: verification.area,
        locationType: verification.locationType,
        latitude: verification.latitude,
        longitude: verification.longitude,
        offerName: verification.offerName,
        offerPrice: verification.offerPrice,
        offerDiscount: verification.offerDiscount,
        offerImage: verification.offerImage,
        offerId: verification.offerId,
        isOfferApplication: verification.isOfferApplication,
        isLocalData: verification.isLocalData || isLocalVerification,
        frontIDUrl:
            imageUrls[0].isNotEmpty ? imageUrls[0] : verification.frontIDUrl,
        backIDUrl:
            imageUrls[1].isNotEmpty ? imageUrls[1] : verification.backIDUrl,
        selfieUrl:
            imageUrls[2].isNotEmpty ? imageUrls[2] : verification.selfieUrl,
      );

      // Update local state immediately
      setState(() {
        // Remove from pending list if it's there
        _pendingVerifications.removeWhere((v) => v.id == id);

        // Remove from main lists
        _verifications.removeWhere((v) => v.id == id);
        _offerApplications.removeWhere((v) => v.id == id);

        // Add to the appropriate list
        if (isOfferApplication) {
          _offerApplications.add(updatedVerification);
        } else {
          _verifications.add(updatedVerification);
        }
      });

      // Also update in SharedPreferences if it's a local verification
      if (isLocalVerification) {
        await _updateLocalVerificationStatus(
            verification.id, newStatus, imageUrls);
      }

      // Reload data to ensure everything is up to date
      await _loadVerifications();
      await _loadOfferApplications();
      await _loadPendingVerifications();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated successfully')),
      );

      // Switch to the appropriate tab
      if (newStatus == 'approved') {
        _tabController.animateTo(1); // Switch to Approved tab
      } else if (newStatus == 'rejected') {
        _tabController.animateTo(2); // Switch to Rejected tab
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e.toString()}')),
      );
    }
  }

  // Helper method to update a local verification in SharedPreferences
  Future<void> _updateLocalVerificationStatus(
      String id, String newStatus, List<String> imageUrls) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);

        for (int i = 0; i < verificationsList.length; i++) {
          if (verificationsList[i]['id'] == id) {
            // Update status
            verificationsList[i]['status'] = newStatus;

            // Add image URLs if they're available
            if (imageUrls[0].isNotEmpty)
              verificationsList[i]['frontIDUrl'] = imageUrls[0];
            if (imageUrls[1].isNotEmpty)
              verificationsList[i]['backIDUrl'] = imageUrls[1];
            if (imageUrls[2].isNotEmpty)
              verificationsList[i]['selfieUrl'] = imageUrls[2];

            break;
          }
        }

        // Save updated list
        await prefs.setString(
            'professionalVerifications', jsonEncode(verificationsList));
      }
    } catch (e) {
      print('Error updating local verification status: $e');
    }
  }

  List<ProfessionalVerification> _getFilteredVerifications(
      String status, bool isOfferApplications) {
    final List<ProfessionalVerification> sourceList =
        isOfferApplications ? _offerApplications : _verifications;
    return sourceList
        .where((verification) => verification.status == status)
        .toList();
  }

  Future<String> _getImageUrl(String path) async {
    if (path.isEmpty) {
      return '';
    }

    try {
      // If the URL is already a valid HTTP/HTTPS URL, return it directly
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }

      // Otherwise get from Firebase Storage
      final url = await _storage.ref(path).getDownloadURL();
      return url;
    } catch (e) {
      // If there's an error and the path contains 'Assets/', it might be a local asset
      if (path.contains('Assets/')) {
        return path;
      }

      // Output error details for debugging
      print('Error loading image from path $path: $e');
      return '';
    }
  }

  void _showImageDialog(
      BuildContext context, String imagePath, String title) async {
    // If the path is already a full URL, use it directly
    String imageUrl = '';

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      imageUrl = imagePath;
    } else if (imagePath.isNotEmpty) {
      // Otherwise try to get the URL from Firebase Storage
      try {
        imageUrl = await _getImageUrl(imagePath);
      } catch (e) {
        print('Error getting image URL: $e');
        // Continue with empty URL, will show error image
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(title),
                  backgroundColor: Colors.green,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 300,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                  'Error showing image in dialog: $error, url: $imageUrl');
                              return _buildErrorImage();
                            },
                          )
                        else
                          _buildErrorImage(),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                            ),
                            child: Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: Colors.grey),
          Text('Image not available', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingVerificationList(),
              _buildCombinedVerificationList('approved'),
              _buildCombinedVerificationList('rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedVerificationList(String status) {
    // Get both regular verifications and offer applications with this status
    List<ProfessionalVerification> allVerifications = [];

    // Add regular verifications with the correct status
    allVerifications.addAll(_verifications.where((v) => v.status == status));

    // Add offer applications with the correct status
    allVerifications
        .addAll(_offerApplications.where((v) => v.status == status));

    // Sort by most recent first
    if (allVerifications.isNotEmpty) {
      allVerifications
          .sort((a, b) => b.submittedDate.compareTo(a.submittedDate));
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (allVerifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No ${status} professionals',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (allVerifications.isEmpty &&
                (status == 'approved' || status == 'rejected'))
              ElevatedButton.icon(
                icon: Icon(Icons.delete_sweep),
                label: Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showDeleteAllConfirmationDialog(status),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.delete_sweep),
                label: Text('Delete All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showDeleteAllConfirmationDialog(status),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadAllData();
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: allVerifications.length,
              itemBuilder: (context, index) {
                final verification = allVerifications[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                                verification.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: _firestore
                                  .collection('professionals')
                                  .doc(verification.id)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return SizedBox();

                                final professionalData = snapshot.data?.data()
                                    as Map<String, dynamic>?;
                                final currentStatus =
                                    professionalData?['status'] ?? 'active';

                                return Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(currentStatus)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        currentStatus.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(currentStatus),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (verification.status == 'approved')
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.check_circle,
                                              color: currentStatus == 'active'
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            tooltip: 'Activate',
                                            onPressed: () =>
                                                _updateProfessionalStatus(
                                                    verification, 'active'),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.block,
                                              color:
                                                  currentStatus == 'deactivated'
                                                      ? Colors.red
                                                      : Colors.grey,
                                            ),
                                            tooltip: 'Deactivate',
                                            onPressed: () =>
                                                _updateProfessionalStatus(
                                                    verification,
                                                    'deactivated'),
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteVerification(verification),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                verification.isOfferApplication
                                    ? 'Offer: ${verification.offerName ?? verification.serviceName} ${verification.offerDiscount != null ? "(${verification.offerDiscount}% off)" : ""}'
                                    : 'Service: ${verification.serviceName}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (verification.isOfferApplication &&
                            verification.offerPrice != null) ...[
                          SizedBox(height: 4),
                          Text(
                            'Price: Rs. ${verification.offerPrice} (Original price before discount)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        Text(
                          'Phone: ${verification.phoneNumber}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Location Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20.0, top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (verification.address?.isNotEmpty == true)
                                    Text(
                                      'Address: ${verification.address}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                  if (verification.area?.isNotEmpty == true ||
                                      verification.city?.isNotEmpty == true)
                                    Text(
                                      '${verification.area ?? ''} ${verification.city != null ? ', ${verification.city}' : ''}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                  if (verification.locationType?.isNotEmpty ==
                                      true)
                                    Text(
                                      'Type: ${verification.locationType}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                  if (verification.latitude != null &&
                                      verification.longitude != null)
                                    Text(
                                      'Coordinates: ${verification.latitude!.toStringAsFixed(6)}, ${verification.longitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Submitted on: ${verification.submittedDate}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String title, String imageUrl, String imagePath) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            _showImageDialog(context, imageUrl, title), // Use imageUrl directly
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error displaying image: $error, url: $imageUrl');
                      return _buildErrorThumbnail();
                    },
                  ),
                )
              : _buildErrorThumbnail(),
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 24, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(String title, String imagePath) {
    // For image button we directly use the provided path/url
    return ElevatedButton.icon(
      onPressed: () => _showImageDialog(context, imagePath, title),
      icon: Icon(Icons.image),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.withOpacity(0.1),
        foregroundColor: Colors.green,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.green;
      case 'deactivated':
        return Colors.red;
      case 'carpenter':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPendingVerificationList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_pendingVerifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No pending professionals',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.delete_sweep),
                label: Text('Delete All Pending'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showDeleteAllPendingConfirmationDialog(),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPendingVerifications,
            child: ListView.builder(
              itemCount: _pendingVerifications.length,
              itemBuilder: (context, index) {
                final verification = _pendingVerifications[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                        '${verification.name} (${verification.serviceName})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${verification.status} - ${verification.submittedDate}',
                          style: TextStyle(
                            color: _getStatusColor(verification.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (verification.address != null &&
                            verification.address!.isNotEmpty)
                          Text(
                            'Location: ${verification.address} ${verification.area != null ? ', ${verification.area}' : ''} ${verification.city != null ? ', ${verification.city}' : ''}',
                            style: TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    leading: _buildServiceIcon(verification.serviceName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteLocalVerification(verification),
                        ),
                        Icon(Icons.expand_more),
                      ],
                    ),
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone: ${verification.phoneNumber}'),
                              SizedBox(height: 8),

                              // Enhanced location display
                              if (verification.address != null ||
                                  verification.city != null ||
                                  verification.area != null ||
                                  verification.latitude != null ||
                                  verification.longitude != null) ...[
                                Text('Location Details:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (verification.address != null &&
                                          verification.address!.isNotEmpty)
                                        Text(
                                            'Address: ${verification.address}'),
                                      if (verification.city != null &&
                                          verification.city!.isNotEmpty)
                                        Text('City: ${verification.city}'),
                                      if (verification.area != null &&
                                          verification.area!.isNotEmpty)
                                        Text('Area: ${verification.area}'),
                                      if (verification.locationType != null &&
                                          verification.locationType!.isNotEmpty)
                                        Text(
                                            'Type: ${verification.locationType}'),
                                      if (verification.latitude != null &&
                                          verification.longitude != null)
                                        Text(
                                            'Coordinates: ${verification.latitude!.toStringAsFixed(6)}, ${verification.longitude!.toStringAsFixed(6)}'),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                              ],

                              Text('ID Card Images:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Container(
                                height: 200, // Fixed height container
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildLocalImagePreview(
                                          verification.frontIDPath, 'Front ID'),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _buildLocalImagePreview(
                                          verification.backIDPath, 'Back ID'),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text('Selfie Image:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Container(
                                height: 200, // Fixed height container
                                child: _buildLocalImagePreview(
                                    verification.selfiePath, 'Selfie'),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (verification.status == 'pending') ...[
                                    ElevatedButton(
                                      onPressed: () => _rejectLocalVerification(
                                          verification),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: Text('Reject'),
                                    ),
                                    SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _approveLocalVerification(
                                              verification),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: Text('Approve'),
                                    ),
                                  ] else if (verification.status == 'approved')
                                    Text('✅ Approved',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold))
                                  else if (verification.status == 'rejected')
                                    Text('❌ Rejected',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold))
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
          ),
        ),
      ],
    );
  }

  Widget _buildLocalImagePreview(String? imagePath, String label) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(child: Text('No $label')),
      );
    }

    try {
      // If the path is a network URL, use Image.network
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(4),
                child:
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                        child:
                            CircularProgressIndicator()), // Show loading indicator
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imagePath,
                        fit: BoxFit.contain,
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
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              'Error loading network image in preview: $error, path: $imagePath');
                          return Container(
                            color: Colors.grey[200],
                            child: Center(child: Text('Error loading image')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // For Firebase Storage paths, get the URL and use Image.network
      if (imagePath.startsWith('verification/') ||
          imagePath.contains('professional/')) {
        return FutureBuilder<String>(
          future: _getImageUrl(imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final imageUrl = snapshot.data ?? '';

            if (imageUrl.isEmpty) {
              return Container(
                color: Colors.grey[200],
                child: Center(child: Text('No $label image')),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(label,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
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
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              'Error loading Firebase image in preview: $error, path: $imagePath, url: $imageUrl');
                          return Container(
                            color: Colors.grey[200],
                            child: Center(child: Text('Error loading image')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }

      // For local file paths, use Image.file
      final file = File(imagePath);
      if (!file.existsSync()) {
        print('Local file not found: $imagePath');
        return Container(
          color: Colors.grey[200],
          child: Center(child: Text('$label file not found')),
        );
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4),
              child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print(
                        'Error loading file image in preview: $error, path: $imagePath');
                    return Container(
                      color: Colors.grey[200],
                      child: Center(child: Text('Error loading image')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('General error in _buildLocalImagePreview: $e, path: $imagePath');
      return Container(
        color: Colors.grey[200],
        child: Center(child: Text('Unable to load image')),
      );
    }
  }

  Widget _buildServiceIcon(String serviceName) {
    IconData icon;
    switch (serviceName.toLowerCase()) {
      case 'ac service':
        icon = Icons.ac_unit;
        break;
      case 'plumbing':
        icon = Icons.plumbing;
        break;
      case 'electrical':
        icon = Icons.electrical_services;
        break;
      case 'home cleaning':
        icon = Icons.cleaning_services;
        break;
      case 'carpenter':
        icon = Icons.carpenter;
        break;
      default:
        icon = Icons.miscellaneous_services;
    }
    return CircleAvatar(
      backgroundColor: Colors.green,
      child: Icon(icon, color: Colors.white),
    );
  }

  // Function to approve a pending verification
  Future<void> _approveLocalVerification(
      ProfessionalVerification verification) async {
    try {
      // Get image URLs first
      final List<String> imageUrls = await Future.wait([
        _getImageUrl(verification.frontIDPath),
        _getImageUrl(verification.backIDPath),
        _getImageUrl(verification.selfiePath),
      ]);

      // Update status in local storage
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);
        bool found = false;

        for (int i = 0; i < verificationsList.length; i++) {
          if (verificationsList[i]['id'] == verification.id) {
            // Update status
            verificationsList[i]['status'] = 'approved';
            // Add image URLs if they're available
            if (imageUrls[0].isNotEmpty)
              verificationsList[i]['frontIDUrl'] = imageUrls[0];
            if (imageUrls[1].isNotEmpty)
              verificationsList[i]['backIDUrl'] = imageUrls[1];
            if (imageUrls[2].isNotEmpty)
              verificationsList[i]['selfieUrl'] = imageUrls[2];
            found = true;
            break;
          }
        }

        if (!found) {
          // Item not found in the list, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification record not found')),
          );
          return;
        }

        // Save updated list
        await prefs.setString(
            'professionalVerifications', jsonEncode(verificationsList));

        // Create an approved version of this verification
        final ProfessionalVerification approvedVerification =
            ProfessionalVerification(
          id: verification.id,
          name: verification.name,
          phoneNumber: verification.phoneNumber,
          serviceName: verification.serviceName,
          frontIDPath: verification.frontIDPath,
          backIDPath: verification.backIDPath,
          selfiePath: verification.selfiePath,
          status: 'approved',
          submittedDate: verification.submittedDate,
          address: verification.address,
          city: verification.city,
          area: verification.area,
          locationType: verification.locationType ?? 'Home',
          latitude: verification.latitude,
          longitude: verification.longitude,
          isLocalData: true,
          frontIDUrl:
              imageUrls[0].isNotEmpty ? imageUrls[0] : verification.frontIDUrl,
          backIDUrl:
              imageUrls[1].isNotEmpty ? imageUrls[1] : verification.backIDUrl,
          selfieUrl:
              imageUrls[2].isNotEmpty ? imageUrls[2] : verification.selfieUrl,
        );

        // Update local state immediately to reflect changes
        setState(() {
          // Remove from pending list
          _pendingVerifications.removeWhere((v) => v.id == verification.id);

          // Remove any existing entry for this verification from the main list
          _verifications.removeWhere((v) => v.id == verification.id);

          // Add to approved list
          _verifications.add(approvedVerification);
        });

        // Add professional to Firestore professionals collection
        Map<String, dynamic> professionalData = {
          'id': verification.id,
          'name': verification.name,
          'phoneNumber': verification.phoneNumber,
          'serviceName': verification.serviceName,
          'status': 'active',
          'locationType': verification.locationType ?? 'Home',
          'address': verification.address,
          'city': verification.city,
          'area': verification.area,
          'isOfferProfessional': false,
          'approved_date': DateTime.now().toIso8601String(),
          'approved_by_admin': true,
          'frontIDUrl':
              imageUrls[0].isNotEmpty ? imageUrls[0] : verification.frontIDUrl,
          'backIDUrl':
              imageUrls[1].isNotEmpty ? imageUrls[1] : verification.backIDUrl,
          'selfieUrl':
              imageUrls[2].isNotEmpty ? imageUrls[2] : verification.selfieUrl,
        };

        // Add coordinates if available
        if (verification.latitude != null && verification.longitude != null) {
          professionalData['latitude'] = verification.latitude;
          professionalData['longitude'] = verification.longitude;
          professionalData['coordinates'] =
              GeoPoint(verification.latitude!, verification.longitude!);
        }

        // Add to professionals collection
        await _firestore
            .collection('professionals')
            .doc(verification.id)
            .set(professionalData, SetOptions(merge: true));

        // Add to account_status collection
        await _firestore.collection('account_status').doc(verification.id).set({
          'userId': verification.id,
          'userType': 'professional',
          'isActive': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Switch to approved tab
        _tabController.animateTo(1);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Professional verification approved successfully and added to professionals section')),
        );

        // Reload all data to ensure everything is up to date
        await _loadVerifications();
        await _loadOfferApplications();
        await _loadPendingVerifications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error approving verification: ${e.toString()}')),
      );
    }
  }

  // Function to reject a pending verification
  Future<void> _rejectLocalVerification(
      ProfessionalVerification verification) async {
    try {
      // Get image URLs first
      final List<String> imageUrls = await Future.wait([
        _getImageUrl(verification.frontIDPath),
        _getImageUrl(verification.backIDPath),
        _getImageUrl(verification.selfiePath),
      ]);

      // Update status in local storage
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);
        bool found = false;

        for (int i = 0; i < verificationsList.length; i++) {
          if (verificationsList[i]['id'] == verification.id) {
            // Update status
            verificationsList[i]['status'] = 'rejected';
            // Add image URLs if they're available
            if (imageUrls[0].isNotEmpty)
              verificationsList[i]['frontIDUrl'] = imageUrls[0];
            if (imageUrls[1].isNotEmpty)
              verificationsList[i]['backIDUrl'] = imageUrls[1];
            if (imageUrls[2].isNotEmpty)
              verificationsList[i]['selfieUrl'] = imageUrls[2];
            found = true;
            break;
          }
        }

        if (!found) {
          // Item not found in the list, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification record not found')),
          );
          return;
        }

        // Save updated list
        await prefs.setString(
            'professionalVerifications', jsonEncode(verificationsList));

        // Create a rejected version of this verification
        final ProfessionalVerification rejectedVerification =
            ProfessionalVerification(
          id: verification.id,
          name: verification.name,
          phoneNumber: verification.phoneNumber,
          serviceName: verification.serviceName,
          frontIDPath: verification.frontIDPath,
          backIDPath: verification.backIDPath,
          selfiePath: verification.selfiePath,
          status: 'rejected',
          submittedDate: verification.submittedDate,
          address: verification.address,
          city: verification.city,
          area: verification.area,
          locationType: verification.locationType ?? 'Home',
          latitude: verification.latitude,
          longitude: verification.longitude,
          isLocalData: true,
          frontIDUrl:
              imageUrls[0].isNotEmpty ? imageUrls[0] : verification.frontIDUrl,
          backIDUrl:
              imageUrls[1].isNotEmpty ? imageUrls[1] : verification.backIDUrl,
          selfieUrl:
              imageUrls[2].isNotEmpty ? imageUrls[2] : verification.selfieUrl,
        );

        // Update local state immediately to reflect changes
        setState(() {
          // Remove from pending list
          _pendingVerifications.removeWhere((v) => v.id == verification.id);

          // Remove any existing entry for this verification from the main list
          _verifications.removeWhere((v) => v.id == verification.id);

          // Add to rejected list
          _verifications.add(rejectedVerification);
        });

        // Switch to rejected tab
        _tabController.animateTo(2);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Professional verification rejected')),
        );

        // Reload all data to ensure everything is up to date
        await _loadVerifications();
        await _loadOfferApplications();
        await _loadPendingVerifications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error rejecting verification: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteAllConfirmationDialog(String status) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All ${status.toUpperCase()} Professionals'),
        content:
            Text('Are you sure you want to clear all ${status} professionals?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _clearAllVerifications(status);
    }
  }

  Future<void> _clearAllVerifications(String status) async {
    try {
      // First handle Firebase verifications
      final verificationSnapshot = await _firestore
          .collection('professional_verifications')
          .where('status', isEqualTo: status)
          .get();

      final applicationSnapshot = await _firestore
          .collection('professional_applications')
          .where('status', isEqualTo: status)
          .get();

      // Create batch for efficiency
      final batch = _firestore.batch();

      // Add all verification documents to batch
      for (final doc in verificationSnapshot.docs) {
        batch.delete(
            _firestore.collection('professional_verifications').doc(doc.id));

        // If approved, also remove from professionals collection
        if (status == 'approved') {
          try {
            batch.delete(_firestore.collection('professionals').doc(doc.id));
          } catch (e) {
            print('Error adding professional deletion to batch: $e');
          }
        }
      }

      // Add all application documents to batch
      for (final doc in applicationSnapshot.docs) {
        batch.delete(
            _firestore.collection('professional_applications').doc(doc.id));

        // If approved, also remove from professionals collection
        if (status == 'approved') {
          try {
            batch.delete(_firestore.collection('professionals').doc(doc.id));
          } catch (e) {
            print('Error adding professional deletion to batch: $e');
          }
        }
      }

      // Commit the batch
      await batch.commit();

      // Now handle local verifications
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);

        // Filter out verifications with the given status
        final filteredList = verificationsList
            .where((verification) => verification['status'] != status)
            .toList();

        // Save the filtered list back to SharedPreferences
        await prefs.setString(
            'professionalVerifications', jsonEncode(filteredList));
      }

      // Reload all data
      await _loadVerifications();
      await _loadOfferApplications();
      await _loadPendingVerifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All ${status} professionals cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error clearing professionals: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteVerification(
      ProfessionalVerification verification) async {
    try {
      // Show confirmation dialog
      final bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Delete Professional'),
              content: Text(
                  'Are you sure you want to delete this professional for ${verification.name}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      if (verification.isLocalData) {
        // Handle local verification
        final prefs = await SharedPreferences.getInstance();
        final verificationsJson = prefs.getString('professionalVerifications');

        if (verificationsJson != null) {
          final List<dynamic> verificationsList = jsonDecode(verificationsJson);

          // Filter out the verification to delete
          final filteredList = verificationsList
              .where((v) => v['id'] != verification.id)
              .toList();

          // Save the filtered list back to SharedPreferences
          await prefs.setString(
              'professionalVerifications', jsonEncode(filteredList));

          // Update the state
          setState(() {
            _pendingVerifications.removeWhere((v) => v.id == verification.id);
            _verifications.removeWhere((v) => v.id == verification.id);
          });
        }
      } else {
        // Handle Firebase verification
        final collectionName = verification.isOfferApplication
            ? 'professional_applications'
            : 'professional_verifications';

        await _firestore
            .collection(collectionName)
            .doc(verification.id)
            .delete();

        // If it was an approved verification, also delete from professionals collection
        if (verification.status == 'approved') {
          try {
            await _firestore
                .collection('professionals')
                .doc(verification.id)
                .delete();

            print('Professional deleted from professionals collection.');
          } catch (e) {
            print('Error deleting from professionals collection: $e');
          }
        }
      }

      // Reload all data
      await _loadVerifications();
      await _loadOfferApplications();
      await _loadPendingVerifications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Professional deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting professional: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteAllPendingConfirmationDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Pending Professionals'),
        content: Text(
            'Are you sure you want to delete all pending professional requests? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _clearAllPendingVerifications();
    }
  }

  Future<void> _clearAllPendingVerifications() async {
    try {
      // Get the stored verifications from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);

        // Filter out the pending verifications
        final filteredList = verificationsList
            .where((verification) => verification['status'] != 'pending')
            .toList();

        // Save the filtered list back to SharedPreferences
        await prefs.setString(
            'professionalVerifications', jsonEncode(filteredList));

        // Update the state
        setState(() {
          _pendingVerifications = [];
        });

        // Reload all data to ensure everything is up to date
        await _loadVerifications();
        await _loadOfferApplications();
        await _loadPendingVerifications();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('All pending professionals have been deleted')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error deleting pending professionals: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteLocalVerification(
      ProfessionalVerification verification) async {
    try {
      // Get the stored verifications from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final verificationsJson = prefs.getString('professionalVerifications');

      if (verificationsJson != null) {
        final List<dynamic> verificationsList = jsonDecode(verificationsJson);

        // Filter out the verification to delete
        final filteredList =
            verificationsList.where((v) => v['id'] != verification.id).toList();

        // Save the filtered list back to SharedPreferences
        await prefs.setString(
            'professionalVerifications', jsonEncode(filteredList));

        // Update the state
        setState(() {
          _pendingVerifications.removeWhere((v) => v.id == verification.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Professional deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting professional: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToProfessional(String professionalId) async {
    try {
      // Check if professional exists
      final docSnapshot = await _firestore
          .collection('professionals')
          .doc(professionalId)
          .get();

      if (!docSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Professional not found in database')),
        );
        return;
      }

      // Navigate to professionals section (you'll need to implement this based on your app's navigation)
      // For example:
      // Navigator.of(context).pushNamed('/admin/professionals', arguments: professionalId);
      // or
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => ProfessionalsScreen(initialProfessionalId: professionalId),
      //   ),
      // );

      // This is a placeholder message until you implement the actual navigation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Professional found! ID: $professionalId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error accessing professional: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfessionalStatus(
      ProfessionalVerification verification, String newStatus) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Status Change'),
            content: Text(
                'Are you sure you want to ${newStatus == 'active' ? 'activate' : 'deactivate'} this professional?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Confirm'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Update in professionals collection
      await _firestore
          .collection('professionals')
          .doc(verification.id)
          .update({'status': newStatus});

      // Update in account_status collection
      await _firestore.collection('account_status').doc(verification.id).set({
        'userId': verification.id,
        'userType': 'professional',
        'isActive': newStatus == 'active',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reload data
      await _loadAllData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Professional ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating professional status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
