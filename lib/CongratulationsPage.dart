import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'DashBoard.dart'; // Import Dashboard directly
import 'professional_screens/ProfessionalDashboard.dart'; // Import ProfessionalDashboard
import 'services/shared_prefs_service.dart'; // Import SharedPrefsService
import 'package:cloud_firestore/cloud_firestore.dart';

class CongratulationsPage extends StatelessWidget {
  final String selectedService;
  final File frontIDImage;
  final File backIDImage;
  final File selfieImage;

  const CongratulationsPage({
    Key? key,
    required this.selectedService,
    required this.frontIDImage,
    required this.backIDImage,
    required this.selfieImage,
  }) : super(key: key);

  // Helper: Upload verification to Firestore
  Future<void> uploadVerificationToFirestore(Map<String, dynamic> verification) async {
    try {
      await FirebaseFirestore.instance
          .collection('professional_verifications')
          .doc(verification['id'])
          .set(verification);
      print('Verification uploaded to Firestore');
    } catch (e) {
      print('Error uploading verification to Firestore: $e');
    }
  }

  Future<void> _saveProfessionalData(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save professional account from temporary storage
      final name = prefs.getString('temp_professionalName');
      final phone = prefs.getString('temp_professionalPhone');
      final password = prefs.getString('temp_professionalPassword');
      final rememberPassword = prefs.getBool('temp_rememberPassword') ?? false;
      
      if (name == null || phone == null || password == null) {
        throw Exception('Missing professional data');
      }
      
      // Save professional account permanently
      await SharedPrefsService.saveProfessionalAccount(
        name: name,
        phone: phone,
        password: password,
        rememberPassword: rememberPassword,
      );
      
      // Clean up temporary data
      await prefs.remove('temp_professionalName');
      await prefs.remove('temp_professionalPhone');
      await prefs.remove('temp_professionalPassword');
      await prefs.remove('temp_rememberPassword');
      
      print('Professional account saved in final step');

      // Get existing professionals or initialize empty list
      List<Map<String, dynamic>> professionals = [];
      final professionalsJson = prefs.getString('professionals');
      if (professionalsJson != null) {
        final List<dynamic> existingData = jsonDecode(professionalsJson);
        professionals = existingData.cast<Map<String, dynamic>>();
      }

      // Get the current verification ID
      final currentId = prefs.getString('currentVerificationId');
      if (currentId == null) {
        throw Exception('No current verification ID found');
      }

      // Get verification data
      final verificationsJson = prefs.getString('professionalVerifications');
      if (verificationsJson == null) {
        throw Exception('No verification data found');
      }

      final List<dynamic> verificationsData = jsonDecode(verificationsJson);
      final verification = verificationsData.firstWhere(
            (v) => v['id'] == currentId,
        orElse: () => null,
      );

      if (verification == null) {
        throw Exception('Verification data not found');
      }

      // Add the new professional
      professionals.add({
        'id': currentId,
        'name': verification['name'],
        'phoneNumber': verification['phoneNumber'],
        'serviceName': selectedService,
        'frontIDPath': frontIDImage.path,
        'backIDPath': backIDImage.path,
        'selfiePath': selfieImage.path,
        'address': prefs.getString('address') ?? '',
        'city': prefs.getString('city') ?? '',
        'area': prefs.getString('area') ?? '',
        'status': 'pending',
        'registrationDate': DateTime.now().toString(),
        'verificationStatus': 'pending',
      });

      // Upload to Firestore so admin can see it
      await uploadVerificationToFirestore({
        ...verification,
        'frontIDPath': frontIDImage.path,
        'backIDPath': backIDImage.path,
        'selfiePath': selfieImage.path,
        'address': prefs.getString('address') ?? '',
        'city': prefs.getString('city') ?? '',
        'area': prefs.getString('area') ?? '',
        'status': 'pending',
        'verificationStatus': 'pending',
        'registrationDate': DateTime.now().toString(),
      });

      // Save updated professionals list
      await prefs.setString('professionals', jsonEncode(professionals));

      // Clear temporary data
      await prefs.remove('currentVerificationId');
      await prefs.remove('address');
      await prefs.remove('city');
      await prefs.remove('area');

    } catch (e) {
      print('Error saving professional data: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Application Submitted'),
        backgroundColor: Colors.lightGreen,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Application Submitted Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Message
              Text(
                'You have successfully created your account. Your profile is under review by Rapit team and will be approved shortly. Rapit team may contact you to provide missing information.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Continue Button
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _saveProfessionalData(context);
                    // Set userType to professional to ensure correct routing in the future
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('userType', 'professional');
                    await prefs.setBool('isUserLoggedIn', true);

                    // Set verification as completed and save that we're at the professional dashboard
                    await prefs.setBool('isVerificationCompleted', true);
                    await prefs.setString('lastScreen', 'professional_dashboard');
                    
                    // Set professional status as approved
                    await prefs.setString('professionalStatus', 'approved');

                    // Clear any previous verification flow state
                    await prefs.remove('lastFrontIDPath');
                    await prefs.remove('lastBackIDPath');
                    await prefs.remove('lastSelfiePath');

                    // Navigate to the Professional Dashboard instead of the regular Dashboard
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => ProfessionalDashboard()),
                          (Route<dynamic> route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue to Professional Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}