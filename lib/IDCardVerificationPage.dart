import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'SelfieVerificationPage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Add this for PlatformException

class IDCardVerificationPage extends StatefulWidget {
  final String selectedService;

  const IDCardVerificationPage({
    Key? key,
    required this.selectedService,
  }) : super(key: key);

  @override
  State<IDCardVerificationPage> createState() => _IDCardVerificationPageState();
}

class _IDCardVerificationPageState extends State<IDCardVerificationPage> {
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isTakingPhoto = false; // Add this to prevent multiple simultaneous camera access

  @override
  void initState() {
    super.initState();
    _saveCurrentScreenState();
  }

  Future<void> _saveCurrentScreenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastScreen', 'id_verification');
      await prefs.setString('lastSelectedService', widget.selectedService);

      // Ensure login state is maintained
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);
      await prefs.setString('userType', 'professional');
    } catch (e) {
      print('Error saving ID verification screen state: $e');
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _frontImage = null;
    _backImage = null;
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    // Prevent multiple simultaneous camera access
    if (_isTakingPhoto) {
      print('Already taking a photo, please wait');
      return;
    }

    setState(() {
      _isTakingPhoto = true;
    });

    try {
      // Use gallery instead of camera as a workaround for memory issues
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // Change to gallery as a test
        maxWidth: 800, // Reduce dimensions even further
        maxHeight: 800,
        imageQuality: 70, // Reduce quality further to save memory
      );

      if (image != null) {
        // Create a smaller version of the image to reduce memory usage
        final File imageFile = File(image.path);

        // Update state with new image
        if (mounted) {
          setState(() {
            if (isFront) {
              _frontImage = imageFile;
            } else {
              _backImage = imageFile;
            }
          });
        }
      }
    } on PlatformException catch (e) {
      print('Platform exception during image picking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.message}')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access media: $e')),
        );
      }
    } finally {
      // Always reset the taking photo flag
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }

      // Force garbage collection (not usually recommended but can help in extreme cases)
      // This is a workaround for severe memory issues
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  // Add a method to switch to camera only if gallery option isn't working for your app
  void _showImageSourceOptions(bool isFront) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(isFront, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(isFront, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(bool isFront, ImageSource source) async {
    if (_isTakingPhoto) return;

    setState(() {
      _isTakingPhoto = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null && mounted) {
        setState(() {
          if (isFront) {
            _frontImage = File(image.path);
          } else {
            _backImage = File(image.path);
          }
        });
      }
    } catch (e) {
      print('Error picking image from $source: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing media: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  Future<void> _submitVerificationData(File frontImage, File backImage) async {
    // In a real app, you would upload these images to Firebase Storage
    // and store the download URLs in a Firestore document

    // For now, we'll store references in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if files exist and are readable
      if (!frontImage.existsSync() || !backImage.existsSync()) {
        throw Exception("One or both image files are missing or inaccessible");
      }

      // Get existing verifications or initialize empty list
      List<Map<String, dynamic>> verifications = [];
      final verificationsJson = prefs.getString('professionalVerifications');
      if (verificationsJson != null) {
        final List<dynamic> existingData = jsonDecode(verificationsJson);
        verifications = existingData.cast<Map<String, dynamic>>();
      }

      // Get a unique ID for this professional
      String id = 'PRO${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Store just the paths to the files, not the entire file objects
      verifications.add({
        'id': id,
        'name': prefs.getString('professionalName') ?? 'Professional User',
        'phoneNumber': prefs.getString('professionalPhone') ?? 'Unknown',
        'serviceName': widget.selectedService,
        'frontIDPath': frontImage.path, // In a real app, this would be a Storage URL
        'backIDPath': backImage.path,  // In a real app, this would be a Storage URL
        'selfiePath': '', // Will be set in the next step
        'status': 'pending',
        'submittedDate': DateTime.now().toString().substring(0, 10),
      });

      // Save updated verifications list
      await prefs.setString('professionalVerifications', jsonEncode(verifications));

      // Save current verification ID for next step
      await prefs.setString('currentVerificationId', id);

    } catch (e) {
      print('Error saving verification data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to save verification data - $e')),
      );
      throw e; // Re-throw to handle in the calling function
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Your Identity'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please upload photos of your ID card',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Front Side',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _frontImage == null
                      ? Center(
                    child: ElevatedButton(
                      onPressed: _isTakingPhoto ? null : () => _showImageSourceOptions(true),
                      child: Text('Select Front Photo'),
                    ),
                  )
                      : Stack(
                    children: [
                      Image.file(
                        _frontImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: _isTakingPhoto ? null : () => _showImageSourceOptions(true),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Back Side',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _backImage == null
                      ? Center(
                    child: ElevatedButton(
                      onPressed: _isTakingPhoto ? null : () => _showImageSourceOptions(false),
                      child: Text('Select Back Photo'),
                    ),
                  )
                      : Stack(
                    children: [
                      Image.file(
                        _backImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: _isTakingPhoto ? null : () => _showImageSourceOptions(false),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: (_frontImage != null && _backImage != null && !_isTakingPhoto && !_isLoading)
                        ? () async {
                      // Show loading indicator
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Processing your ID card information...')),
                        );

                        // Save verification data
                        await _submitVerificationData(_frontImage!, _backImage!);

                        // Navigate to next screen if still mounted
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelfieVerificationPage(
                                selectedService: widget.selectedService,
                                frontIDImage: _frontImage!,
                                backIDImage: _backImage!,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        // Error already shown by _submitVerificationData
                        print('Failed to process verification: $e');
                      } finally {
                        // Hide loading state if we're still on this screen
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      // Disable the button visually when loading or taking photo
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Processing images...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Add a taking photo indicator
          if (_isTakingPhoto && !_isLoading)
            Container(
              color: Colors.black38,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Accessing media...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}