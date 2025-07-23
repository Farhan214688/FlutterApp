import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'LocationPickerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfiePage extends StatefulWidget {
  final String selectedService;
  final File frontIDImage;
  final File backIDImage;

  const SelfiePage({
    Key? key,
    required this.selectedService,
    required this.frontIDImage,
    required this.backIDImage,
  }) : super(key: key);

  @override
  _SelfiePageState createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> {
  final ImagePicker _picker = ImagePicker();
  File? _selfieImage;
  bool _isLoading = false;
  String _errorMessage = '';

  // Add flag to track if page is mounted to prevent setState on unmounted widget
  bool _isMounted = true;

  Future<void> _takeSelfie() async {
    if (_isLoading) return; // Prevent multiple calls

    try {
      if (_isMounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      // Manually handle camera error with a timeout
      XFile? photo;
      try {
        photo = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 85,
        );
      } catch (cameraError) {
        print('Camera error: $cameraError');
        if (_isMounted) {
          setState(() {
            _errorMessage = 'Camera error: $cameraError\nTry again or use gallery';
            _isLoading = false;
          });
        }
        return;
      }

      // Handle case where user cancels or camera fails
      if (photo == null) {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }

        if (_isMounted) {
          // Only show message if actual cancel, not on error
          if (_errorMessage.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No image was selected')),
            );
          }
        }
        return;
      }

      // Convert XFile to File
      final File imageFile = File(photo.path);

      // Verify the file exists before trying to copy it
      if (!imageFile.existsSync()) {
        if (_isMounted) {
          setState(() {
            _errorMessage = 'Image file not found';
            _isLoading = false;
          });
        }
        return;
      }

      // Create a copy in app documents directory for persistence
      try {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String fullPath = '${appDir.path}/$fileName';

        // Create directory if it doesn't exist
        if (!appDir.existsSync()) {
          appDir.createSync(recursive: true);
        }

        final File savedImage = await imageFile.copy(fullPath);

        if (_isMounted) {
          setState(() {
            _selfieImage = savedImage;
            _isLoading = false;
          });
        }
      } catch (fileError) {
        print('File error: $fileError');
        // If copying fails, use the original file
        if (_isMounted) {
          setState(() {
            _selfieImage = imageFile; // Use original instead of copy
            _isLoading = false;
            _errorMessage = '';
          });
        }
      }
    } catch (e) {
      print('General error taking selfie: $e');
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }

      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;

    try {
      if (_isMounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image was selected')),
          );
        }
        return;
      }

      final File imageFile = File(image.path);

      if (_isMounted) {
        setState(() {
          _selfieImage = imageFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking from gallery: $e');
      if (_isMounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  void _proceedToNextStep() {
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie before proceeding')),
      );
      return;
    }

    if (!_selfieImage!.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image file. Please take another photo.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          selectedService: widget.selectedService,
          frontIDImage: widget.frontIDImage,
          backIDImage: widget.backIDImage,
          selfieImage: _selfieImage!,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Ensure images are stored persistently
    _ensureImagesArePersistent();

    // Save the current screen state
    _saveCurrentScreenState();

    // Take selfie automatically when page loads, but with a slight delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (_isMounted) {
        _takeSelfie();
      }
    });
  }

  Future<void> _ensureImagesArePersistent() async {
    try {
      // Check if both ID images exist
      if (!widget.frontIDImage.existsSync() || !widget.backIDImage.existsSync()) {
        print("Warning: One or more ID images don't exist at their original paths");
        // We'll rely on _saveCurrentScreenState to save the current paths
        return;
      }

      // Get app documents directory for persistent storage
      final Directory appDir = await getApplicationDocumentsDirectory();

      // Create directory if it doesn't exist
      if (!appDir.existsSync()) {
        appDir.createSync(recursive: true);
      }

      // Copy front ID to persistent storage if it's not already there
      final String frontIDFileName = 'front_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String frontIDDestPath = '${appDir.path}/$frontIDFileName';
      File persistentFrontIDFile;

      // Only copy if the source and destination are different
      if (widget.frontIDImage.path != frontIDDestPath) {
        try {
          persistentFrontIDFile = await widget.frontIDImage.copy(frontIDDestPath);
          print("Front ID image copied to persistent storage: $frontIDDestPath");

          // Update SharedPreferences with the new path
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastFrontIDPath', persistentFrontIDFile.path);
        } catch (e) {
          print("Error copying front ID image: $e");
        }
      }

      // Copy back ID to persistent storage if it's not already there
      final String backIDFileName = 'back_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String backIDDestPath = '${appDir.path}/$backIDFileName';
      File persistentBackIDFile;

      // Only copy if the source and destination are different
      if (widget.backIDImage.path != backIDDestPath) {
        try {
          persistentBackIDFile = await widget.backIDImage.copy(backIDDestPath);
          print("Back ID image copied to persistent storage: $backIDDestPath");

          // Update SharedPreferences with the new path
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('lastBackIDPath', persistentBackIDFile.path);
        } catch (e) {
          print("Error copying back ID image: $e");
        }
      }
    } catch (e) {
      print("Error ensuring images are persistent: $e");
    }
  }

  Future<void> _saveCurrentScreenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastScreen', 'selfie_verification');
      await prefs.setString('lastSelectedService', widget.selectedService);

      // Ensure login state is maintained
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);
      await prefs.setString('userType', 'professional');

      // Save ID image paths temporarily
      await prefs.setString('lastFrontIDPath', widget.frontIDImage.path);
      await prefs.setString('lastBackIDPath', widget.backIDImage.path);
    } catch (e) {
      print('Error saving selfie verification screen state: $e');
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Selfie'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Take a clear selfie',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please ensure your face is clearly visible and well-lit.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selfieImage != null && _selfieImage!.existsSync()
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    _selfieImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 40, color: Colors.red),
                            SizedBox(height: 8),
                            Text('Error loading image'),
                          ],
                        ),
                      );
                    },
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takeSelfie,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_selfieImage == null ? 'Take Selfie' : 'Retake Selfie'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _proceedToNextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _selfieImage != null ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your selfie will be used for verification purposes only.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}