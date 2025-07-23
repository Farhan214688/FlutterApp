import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class TermsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.lightGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Rapit!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'By using our app and services, you agree to be bound by the following Terms and Conditions.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  // Add more terms sections here...
                  Text(
                    '1. Acceptance of Terms\n'
                    'By accessing or using Rapit (the "App"), you agree to comply with and be bound by these Terms and Conditions and our Privacy Policy.\n\n'
                    '2. Services\n'
                    'Rapit provides users with access to home and maintenance services, including but not limited to repairs, installations, cleaning, and maintenance tasks.\n\n'
                    // Add more sections as needed
                    '...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Decline'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await PreferencesService.setTermsAccepted();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                  ),
                  child: Text('Accept'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 