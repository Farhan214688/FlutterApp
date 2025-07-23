import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'LocationPickerPage.dart';

class SelfieVerificationPage extends StatefulWidget {
  final String selectedService;
  final File frontIDImage;
  final File backIDImage;

  const SelfieVerificationPage({
    Key? key,
    required this.selectedService,
    required this.frontIDImage,
    required this.backIDImage,
  }) : super(key: key);

  @override
  State<SelfieVerificationPage> createState() => _SelfieVerificationPageState();
}

class _SelfieVerificationPageState extends State<SelfieVerificationPage> {
  File? _selfieImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _saveCurrentScreenState();
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

      // Save ID card file paths
      await prefs.setString('lastFrontIDPath', widget.frontIDImage.path);
      await prefs.setString('lastBackIDPath', widget.backIDImage.path);
    } catch (e) {
      print('Error saving selfie verification screen state: $e');
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selfieImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking selfie: $e')),
      );
    }
  }

  Future<void> _updateVerificationWithSelfie(File selfieImage) async {
    // In a real app, you would upload this image to Firebase Storage
    // and update the Firestore document with the download URL

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the current verification ID
      final currentId = prefs.getString('currentVerificationId');
      if (currentId == null) {
        print('Error: No current verification ID found');
        return;
      }

      // Get existing verifications
      final verificationsJson = prefs.getString('professionalVerifications');
      if (verificationsJson == null) {
        print('Error: No verifications found');
        return;
      }

      // Parse and update the verifications
      final List<dynamic> verificationsData = jsonDecode(verificationsJson);
      List<Map<String, dynamic>> verifications = verificationsData.cast<Map<String, dynamic>>();

      // Find and update the current verification
      for (int i = 0; i < verifications.length; i++) {
        if (verifications[i]['id'] == currentId) {
          verifications[i]['selfiePath'] = selfieImage.path;
          break;
        }
      }

      // Save the updated verifications
      await prefs.setString('professionalVerifications', jsonEncode(verifications));

      // Save user information for future reference
      await prefs.setString('professionalService', widget.selectedService);
      await prefs.setBool('isVerificationSubmitted', true);

    } catch (e) {
      print('Error updating verification with selfie: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Your Identity'),
        backgroundColor: Colors.lightGreen,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please take a selfie',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Make sure your face is clearly visible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selfieImage == null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _takeSelfie,
                      child: Text('Take Selfie'),
                    ),
                  ],
                ),
              )
                  : Stack(
                children: [
                  Image.file(
                    _selfieImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: _takeSelfie,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _selfieImage != null
                    ? () async {
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Processing selfie...')),
                  );

                  // Update verification with selfie
                  await _updateVerificationWithSelfie(_selfieImage!);

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
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text(
                  'Complete Verification',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}