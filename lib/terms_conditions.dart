import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
        backgroundColor: Colors.lightGreen,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions for Rapit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to Rapit!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Thank you for using Rapit, a home and maintenance app designed to help you with home-related services and repairs. By using our app and services, you agree to be bound by the following Terms and Conditions.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using Rapit (the "App"), you agree to comply with and be bound by these Terms and Conditions and our Privacy Policy. If you do not agree to these Terms, do not use the App.',
            ),
            _buildSection(
              '2. Services',
              'Rapit provides users with access to home and maintenance services, including but not limited to repairs, installations, cleaning, and maintenance tasks. These services are provided by third-party professionals or contractors, and Rapit is not responsible for their actions.',
            ),
            _buildSection(
              '3. User Registration',
              'To use certain services, you may be required to create an account with Rapit. You agree to provide accurate and complete information during the registration process and to keep your account information up-to-date.',
            ),
            _buildSection(
              '4. User Obligations',
              'You agree to:\n'
              '• Provide accurate information for all service requests.\n'
              '• Ensure that the services you request are for lawful purposes.\n'
              '• Follow any instructions provided by service professionals.',
            ),
            _buildSection(
              '5. Payments',
              '• All payments for services provided through the App are processed through the designated payment gateway.\n'
              '• Prices for services may vary and are subject to change based on location and service type.\n'
              '• Payment for services must be made upon completion or as per the agreement between the user and service provider.',
            ),
            _buildSection(
              '6. Third-Party Service Providers',
              'Rapit acts as an intermediary between users and service providers. We are not responsible for the actions, behavior, or performance of any third-party service provider. Any disputes or issues with a service provider must be resolved directly between the user and the service provider.',
            ),
            _buildSection(
              '7. Limitation of Liability',
              'Rapit is not liable for any direct, indirect, incidental, or consequential damages that may result from the use or inability to use the App, including damages resulting from service performance, delays, or malfunctions.',
            ),
            _buildSection(
              '8. Privacy',
              'Your use of the App is also governed by our Privacy Policy, which details how we collect, use, and protect your personal information.',
            ),
            _buildSection(
              '9. Termination',
              'Rapit reserves the right to suspend or terminate your access to the App at any time, without notice, for any violation of these Terms and Conditions.',
            ),
            _buildSection(
              '10. Modifications',
              'Rapit reserves the right to modify or update these Terms and Conditions at any time. Any changes will be posted on this page, and the updated terms will be effective immediately upon posting.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),
      ],
    );
  }
} 