import 'package:flutter/material.dart';
import 'package:firstt_project/IDCardVerificationPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalServiceSelectionPage extends StatefulWidget {
  @override
  _ProfessionalServiceSelectionPageState createState() =>
      _ProfessionalServiceSelectionPageState();
}

class _ProfessionalServiceSelectionPageState
    extends State<ProfessionalServiceSelectionPage> {
  final List<Map<String, dynamic>> services = [
    {
      'name': 'AC Service',
      'image': 'Assets/Images/AC.jpg',
    },
    {
      'name': 'Plumbing',
      'image': 'Assets/Images/Plumbing.jpg',
    },
    {
      'name': 'Electrical',
      'image': 'Assets/Images/Electrican.jpg',
    },
    {
      'name': 'Home Cleaning',
      'image': 'Assets/Images/HomeCleaning.jpg',
    },
    {
      'name': 'Carpenter',
      'image': 'Assets/Images/car1.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Save the current screen state when this page is initialized
    _saveCurrentScreenState();
  }

  Future<void> _saveCurrentScreenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastScreen', 'professional_service_selection');
      // Also ensure userType is set to professional
      await prefs.setString('userType', 'professional');
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);
    } catch (e) {
      print('Error saving screen state: $e');
    }
  }

  Future<void> _selectService(BuildContext context, String serviceName) async {
    try {
      // Set userType to professional
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userType', 'professional');
      await prefs.setBool('isUserLoggedIn', true);
      await prefs.setBool('userHasLoggedOut', false);

      // Save the selected service for resuming later
      await prefs.setString('lastSelectedService', serviceName);

      // Update the last screen to the ID verification page
      await prefs.setString('lastScreen', 'id_verification');

      // Navigate to ID verification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IDCardVerificationPage(
            selectedService: serviceName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting service: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press - could clear the lastScreen state if going back to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('lastScreen');
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Select Your Service'),
          backgroundColor: Colors.lightGreen,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              // Clear screen state when leaving this page via back button
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('lastScreen');
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Your Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return ServiceCard(
                        service: services[index],
                        onSelect: () =>
                            _selectService(context, services[index]['name']),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onSelect;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(
                service['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.home_repair_service,
                      size: 40, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                service['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
