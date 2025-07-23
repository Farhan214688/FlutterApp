import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CongratulationsPage.dart';
import 'dart:io';
import 'dart:convert';

class LocationPickerPage extends StatefulWidget {
  final String selectedService;
  final File frontIDImage;
  final File backIDImage;
  final File selfieImage;

  const LocationPickerPage({
    Key? key,
    required this.selectedService,
    required this.frontIDImage,
    required this.backIDImage,
    required this.selfieImage,
  }) : super(key: key);

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isLoading = false;
  bool _isLocationLoading = false;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _isManualInput = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Save the current screen state
    _saveCurrentScreenState();

    // Validate passed images
    _validateImages();

    _loadSavedLocation();
    // Delay getting current location to avoid UI jank
    Future.delayed(Duration(milliseconds: 500), () {
      _getCurrentLocation();
    });
  }

  // Save the current screen state to SharedPreferences
  Future<void> _saveCurrentScreenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save that we're on the location picker page
      await prefs.setString('lastScreen', 'location_picker');
      await prefs.setString('lastSelectedService', widget.selectedService);

      // Ensure login state is maintained
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);
      await prefs.setString('userType', 'professional');

      // Save ID and selfie image paths
      await prefs.setString('lastFrontIDPath', widget.frontIDImage.path);
      await prefs.setString('lastBackIDPath', widget.backIDImage.path);
      await prefs.setString('lastSelfiePath', widget.selfieImage.path);

      print(
          "Saved location picker screen state with service: ${widget.selectedService}");
    } catch (e) {
      print('Error saving location picker screen state: $e');
    }
  }

  // Check if all required images exist and are valid
  void _validateImages() {
    try {
      if (!widget.frontIDImage.existsSync()) {
        print("Front ID image does not exist: ${widget.frontIDImage.path}");
      }

      if (!widget.backIDImage.existsSync()) {
        print("Back ID image does not exist: ${widget.backIDImage.path}");
      }

      if (!widget.selfieImage.existsSync()) {
        print("Selfie image does not exist: ${widget.selfieImage.path}");
      }
    } catch (e) {
      print("Error validating images: $e");
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage =
            'Location services are disabled. Please enable location services in your device settings.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enable location services'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openLocationSettings();
            },
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage =
              'Location permissions were denied. Please enable them to use this feature.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            'Location permissions are permanently denied. Please enable them in your device settings.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permissions are permanently denied'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _errorMessage = '';
    });

    try {
      bool permissionGranted = await _checkLocationPermission();
      if (!permissionGranted) {
        setState(() => _isLocationLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ).catchError((error) {
        print("Error getting location: $error");
        throw error;
      });

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = newLocation;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId('current_location'),
            position: _selectedLocation!,
            infoWindow: InfoWindow(title: 'Your Location'),
          ),
        );
      });

      // Move camera to new location after state has been updated
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 15),
        );
      }

      // Reverse geocoding to get address details
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            // Combine street and name if both exist, otherwise use what's available
            String street = place.street ?? '';
            String name = place.name ?? '';
            _addressController.text = street.isNotEmpty && name.isNotEmpty
                ? '$street, $name'
                : '${street}${name}'.trim();

            _cityController.text =
                place.locality ?? place.administrativeArea ?? '';
            _areaController.text =
                place.subLocality ?? place.subAdministrativeArea ?? '';
          });
        } else {
          // If no placemark was found, provide generic information
          setState(() {
            _addressController.text = "Current location";
            if (_cityController.text.isEmpty) {
              _cityController.text = "Unknown city";
            }
            if (_areaController.text.isEmpty) {
              _areaController.text = "Unknown area";
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Could not get detailed address for your location')),
          );
        }
      } catch (e) {
        print("Error during reverse geocoding: $e");

        // If geocoding fails, at least provide some info to display
        setState(() {
          _addressController.text = "Current location";
          if (_cityController.text.isEmpty) {
            _cityController.text = "Unknown city";
          }
          if (_areaController.text.isEmpty) {
            _areaController.text = "Unknown area";
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not determine address from location')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load saved address information
      final savedAddress = prefs.getString('address') ?? '';
      final savedCity = prefs.getString('city') ?? '';
      final savedArea = prefs.getString('area') ?? '';

      // Load saved coordinates
      final savedLatitude = prefs.getDouble('latitude');
      final savedLongitude = prefs.getDouble('longitude');

      setState(() {
        _addressController.text = savedAddress;
        _cityController.text = savedCity;
        _areaController.text = savedArea;

        // If we have saved coordinates, update the selected location
        if (savedLatitude != null && savedLongitude != null) {
          _selectedLocation = LatLng(savedLatitude, savedLongitude);

          // Update the marker
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId('saved_location'),
              position: _selectedLocation!,
              infoWindow: InfoWindow(title: 'Saved Location'),
            ),
          );
        }
      });

      // If we have a map controller and selected location, move the camera
      if (_mapController != null && _selectedLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    } catch (e) {
      print('Error loading saved location: $e');
    }
  }

  Future<void> _saveLocation() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Update marker position if user has only entered address manually without selecting on map
        if (_selectedLocation == null && _isManualInput) {
          try {
            List<Location> locations = await locationFromAddress(
              "${_addressController.text}, ${_areaController.text}, ${_cityController.text}",
            );

            if (locations.isNotEmpty) {
              setState(() {
                _selectedLocation =
                    LatLng(locations[0].latitude, locations[0].longitude);
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: MarkerId('selected_location'),
                    position: _selectedLocation!,
                  ),
                );
              });

              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                );
              }
            }
          } catch (e) {
            print('Error geocoding address: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Could not find location from address. Please select on map.')),
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        // If we still don't have a location, show error
        if (_selectedLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Please select a location on the map or use current location')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        // Save location data
        await prefs.setString('address', _addressController.text);
        await prefs.setString('city', _cityController.text);
        await prefs.setString('area', _areaController.text);

        // Store coordinates too
        if (_selectedLocation != null) {
          await prefs.setDouble('latitude', _selectedLocation!.latitude);
          await prefs.setDouble('longitude', _selectedLocation!.longitude);
        }

        // Save all professional verification data for admin approval
        await _saveVerificationDataForAdmin();

        await _navigateToCongratulations();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving location: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveVerificationDataForAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing verification data
      final String? verificationsJson =
          prefs.getString('professionalVerifications');
      List<Map<String, dynamic>> verifications = [];

      if (verificationsJson != null) {
        final List<dynamic> existingData = jsonDecode(verificationsJson);
        verifications = existingData.cast<Map<String, dynamic>>();
      }

      // Ensure we have location data
      if (_selectedLocation == null) {
        throw Exception(
            'No location selected. Please select a location on the map.');
      }

      // Get current verification ID
      final currentId = prefs.getString('currentVerificationId');
      if (currentId == null) {
        // Create a new verification if none exists
        String id =
            'PRO${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        await prefs.setString('currentVerificationId', id);

        // Create new verification with accurate location data
        Map<String, dynamic> newVerification = {
          'id': id,
          'name': prefs.getString('professionalName') ?? 'Professional User',
          'phoneNumber': prefs.getString('professionalPhone') ?? 'Unknown',
          'serviceName': widget.selectedService,
          'frontIDPath': widget.frontIDImage.path,
          'backIDPath': widget.backIDImage.path,
          'selfiePath': widget.selfieImage.path,
          'status': 'pending',
          'submittedDate': DateTime.now().toString().substring(0, 10),
          // Location information
          'address': _addressController.text,
          'city': _cityController.text,
          'area': _areaController.text,
          'locationType': 'Home', // Default locationType
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          // Store coordinates as strings for consistency
          'latitudeStr': _selectedLocation!.latitude.toString(),
          'longitudeStr': _selectedLocation!.longitude.toString(),
        };

        verifications.add(newVerification);
        print(
            'Created new verification with location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
      } else {
        // Update existing verification
        bool found = false;
        for (int i = 0; i < verifications.length; i++) {
          if (verifications[i]['id'] == currentId) {
            // Update with location data
            verifications[i]['address'] = _addressController.text;
            verifications[i]['city'] = _cityController.text;
            verifications[i]['area'] = _areaController.text;
            verifications[i]['locationType'] = 'Home'; // Default locationType
            verifications[i]['latitude'] = _selectedLocation!.latitude;
            verifications[i]['longitude'] = _selectedLocation!.longitude;
            // Store coordinates as strings for consistency
            verifications[i]['latitudeStr'] =
                _selectedLocation!.latitude.toString();
            verifications[i]['longitudeStr'] =
                _selectedLocation!.longitude.toString();
            verifications[i]['status'] =
                'pending'; // Ensure status is pending for admin review
            verifications[i]['submittedDate'] =
                DateTime.now().toString().substring(0, 10);
            found = true;
            print(
                'Updated existing verification with location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
            break;
          }
        }

        // If no existing verification was found, create a new one
        if (!found) {
          // Create new verification as the existing ID wasn't found
          Map<String, dynamic> newVerification = {
            'id': currentId,
            'name': prefs.getString('professionalName') ?? 'Professional User',
            'phoneNumber': prefs.getString('professionalPhone') ?? 'Unknown',
            'serviceName': widget.selectedService,
            'frontIDPath': widget.frontIDImage.path,
            'backIDPath': widget.backIDImage.path,
            'selfiePath': widget.selfieImage.path,
            'status': 'pending',
            'submittedDate': DateTime.now().toString().substring(0, 10),
            // Location information
            'address': _addressController.text,
            'city': _cityController.text,
            'area': _areaController.text,
            'locationType': 'Home', // Default locationType
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            // Store coordinates as strings for consistency
            'latitudeStr': _selectedLocation!.latitude.toString(),
            'longitudeStr': _selectedLocation!.longitude.toString(),
          };

          verifications.add(newVerification);
          print(
              'Created new verification with existing ID and location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}');
        }
      }

      // Save updated verifications list
      await prefs.setString(
          'professionalVerifications', jsonEncode(verifications));

      // Set flags to indicate verification is submitted and pending review
      await prefs.setBool('isVerificationSubmitted', true);
      await prefs.setBool('isVerificationPending', true);

      // Also save location info separately for other uses
      await prefs.setString('address', _addressController.text);
      await prefs.setString('city', _cityController.text);
      await prefs.setString('area', _areaController.text);
      await prefs.setDouble('latitude', _selectedLocation!.latitude);
      await prefs.setDouble('longitude', _selectedLocation!.longitude);

      print(
          'Professional verification data saved successfully for admin review with location data');
    } catch (e) {
      print('Error saving verification data for admin: $e');
      throw e;
    }
  }

  Future<void> _navigateToCongratulations() async {
    // Check image files are still valid before proceeding
    bool imagesValid = true;
    String errorMessage = '';

    try {
      if (!widget.frontIDImage.existsSync()) {
        imagesValid = false;
        errorMessage = 'Front ID image is missing.';
      } else if (!widget.backIDImage.existsSync()) {
        imagesValid = false;
        errorMessage = 'Back ID image is missing.';
      } else if (!widget.selfieImage.existsSync()) {
        imagesValid = false;
        errorMessage = 'Selfie image is missing.';
      }
    } catch (e) {
      imagesValid = false;
      errorMessage = 'Error validating images: $e';
    }

    if (!imagesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Original navigation code
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CongratulationsPage(
          selectedService: widget.selectedService,
          frontIDImage: widget.frontIDImage,
          backIDImage: widget.backIDImage,
          selfieImage: widget.selfieImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Select Location'),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _isLocationLoading ? null : _getCurrentLocation,
            tooltip: 'Get Current Location',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Display the selected service
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.lightGreen.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.home_repair_service, color: Colors.lightGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Selected Service: ${widget.selectedService}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightGreen.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Map and form content
                Container(
                  height: 400, // Adjust height as needed
                  child: Stack(
                    children: [
                      // Initialize the map with a default position if _selectedLocation is null
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          // Default to center of Pakistan if no location is selected
                          target: _selectedLocation ?? LatLng(30.3753, 69.3451),
                          zoom: _selectedLocation != null ? 15 : 5,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) {
                          setState(() {
                            _mapController = controller;
                          });
                          // Move to selected location if already available (delay for map to properly load)
                          if (_selectedLocation != null) {
                            Future.delayed(Duration(milliseconds: 300), () {
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      _selectedLocation!, 15),
                                );
                              }
                            });
                          }
                        },
                        onTap: (LatLng position) {
                          setState(() {
                            _selectedLocation = position;
                            _markers.clear();
                            _markers.add(
                              Marker(
                                markerId: MarkerId('selected_location'),
                                position: position,
                                infoWindow:
                                    InfoWindow(title: 'Selected Location'),
                              ),
                            );
                          });
                          // Try to get address from tapped location
                          _getAddressFromLatLng(position);
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                      ),
                      // Show loading overlay if needed
                      if (_selectedLocation == null &&
                          !_isLocationLoading &&
                          _errorMessage.isEmpty)
                        Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map,
                                    size: 48, color: Colors.lightGreen),
                                SizedBox(height: 16),
                                Text(
                                  'Tap on the map to select your location\nor use the "Get Current Location" button',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_errorMessage.isNotEmpty)
                        Container(
                          color: Colors.white,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_off,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _getCurrentLocation,
                                    child: Text('Try Again'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_isLocationLoading)
                        Container(
                          color: Colors.black38,
                          child: Center(
                            child: Card(
                              color: Colors.white,
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                        color: Colors.lightGreen),
                                    SizedBox(height: 16),
                                    Text(
                                      'Getting your location...',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Form content
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Display the current selected location in text form if available
                      if (_selectedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Location:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                if (_addressController.text.isNotEmpty)
                                  Text(
                                    _addressController.text,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  ),
                                if (_areaController.text.isNotEmpty &&
                                    _cityController.text.isNotEmpty)
                                  Text(
                                    '${_areaController.text}, ${_cityController.text}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  )
                                else if (_areaController.text.isNotEmpty)
                                  Text(
                                    _areaController.text,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  )
                                else if (_cityController.text.isNotEmpty)
                                  Text(
                                    _cityController.text,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLocationLoading
                                  ? null
                                  : _getCurrentLocation,
                              icon: _isLocationLoading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Icon(Icons.my_location),
                              label: Text('Use Current Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isManualInput = !_isManualInput;
                                });
                              },
                              icon: Icon(_isManualInput
                                  ? Icons.close
                                  : Icons.edit_location),
                              label: Text(
                                  _isManualInput ? 'Cancel' : 'Enter Manually'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isManualInput ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_isManualInput) ...[
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Enter your address',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an address';
                            }
                            return null;
                          },
                        ),
                      ],
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isLocationLoading)
                              ? null
                              : _saveLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Save Location',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      setState(() {
        // Set loading state if needed
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Combine street and name if both exist, otherwise use what's available
          String street = place.street ?? '';
          String name = place.name ?? '';
          _addressController.text = street.isNotEmpty && name.isNotEmpty
              ? '$street, $name'
              : '${street}${name}'.trim();

          _cityController.text =
              place.locality ?? place.administrativeArea ?? '';
          _areaController.text =
              place.subLocality ?? place.subAdministrativeArea ?? '';
        });
      } else {
        // If no placemark was found, at least show some default text
        setState(() {
          if (_addressController.text.isEmpty) {
            _addressController.text = "Location selected on map";
          }
          // Only set city/area if they're empty and we can't get them from geocoding
          if (_cityController.text.isEmpty) {
            _cityController.text = "Unknown city";
          }
          if (_areaController.text.isEmpty) {
            _areaController.text = "Unknown area";
          }
        });
      }
    } catch (e) {
      print('Error getting address from location: $e');

      // Even on error, provide something to display
      setState(() {
        if (_addressController.text.isEmpty) {
          _addressController.text = "Selected on map (geocoding failed)";
        }
        if (_cityController.text.isEmpty) {
          _cityController.text = "Unknown";
        }
        if (_areaController.text.isEmpty) {
          _areaController.text = "Unknown";
        }
      });

      // Only show snackbar if geocoding completely failed
      if (_addressController.text == "Selected on map (geocoding failed)") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get address for selected location'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }
}
