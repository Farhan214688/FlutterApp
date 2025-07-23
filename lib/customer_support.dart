import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerSupportPage extends StatelessWidget {
  // Function to launch WhatsApp
  void _launchWhatsApp() async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/+923067948948');
    if (!await launchUrl(whatsappUrl)) {
      throw Exception('Could not launch WhatsApp');
    }
  }

  // Function to make a phone call
  void _makePhoneCall() async {
    final Uri phoneUrl = Uri.parse('tel:+923067948948');
    if (!await launchUrl(phoneUrl)) {
      throw Exception('Could not make phone call');
    }
  }

  // Function to launch Instagram
  void _launchInstagram() async {
    final Uri instagramUrl = Uri.parse('https://www.instagram.com/rapit2266?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==');
    if (!await launchUrl(instagramUrl)) {
      throw Exception('Could not launch Instagram');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Support'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.lightGreen,
              ),
            ),
            SizedBox(height: 15),

            // Contact options with improved UI
            _buildContactCard(
              context,
              icon: FontAwesomeIcons.whatsapp,
              title: 'WhatsApp',
              subtitle: 'Chat with us on WhatsApp',
              color: Colors.green,
              onTap: _launchWhatsApp,
            ),

            _buildContactCard(
              context,
              icon: Icons.phone,
              title: 'Phone',
              subtitle: 'Call us at +92 306 7948948',
              color: Colors.blue,
              onTap: _makePhoneCall,
            ),

            _buildContactCard(
              context,
              icon: FontAwesomeIcons.instagram,
              title: 'Instagram',
              subtitle: 'Follow us on Instagram',
              color: Colors.purple,
              onTap: _launchInstagram,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}