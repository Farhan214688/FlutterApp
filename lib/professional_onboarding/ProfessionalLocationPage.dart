import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ProfessionalCongratulationsPage.dart';

class ProfessionalLocationPage extends StatefulWidget {
  final String selectedService;
  final String frontIdPath;
  final String backIdPath;
  final String selfiePath;

  const ProfessionalLocationPage({
    Key? key,
    required this.selectedService,
    required this.frontIdPath,
    required this.backIdPath,
    required this.selfiePath,
  }) : super(key: key);

  @override
  _ProfessionalLocationPageState createState() => _ProfessionalLocationPageState();
}

class _ProfessionalLocationPageState extends State<ProfessionalLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _zipcodeController = TextEditingController();

  String _locationType = 'Home';
  bool _isLoading = false;
  List<String> _cities = ['Lahore', 'Islamabad', 'Karachi', 'Rawalpindi', 'Peshawar', 'Multan', 'Faisalabad'];
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressController.text = prefs.getString('professional_address') ?? '';
      _selectedCity = prefs.getString('professional_city');
      _areaController.text = prefs.getString('professional_area') ?? '';
      _zipcodeController.text = prefs.getString('professional_zipcode') ?? '';
      _locationType = prefs.getString('professional_location_type') ?? 'Home';
    });
  }

  Future<void> _saveLocationDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save location data
      await prefs.setString('professional_address', _addressController.text);
      await prefs.setString('professional_city', _selectedCity ?? '');
      await prefs.setString('professional_area', _areaController.text);
      await prefs.setString('professional_zipcode', _zipcodeController.text);
      await prefs.setString('professional_location_type', _locationType);

      // Also save service and verification data for later use
      await prefs.setString('professional_selected_service', widget.selectedService);
      await prefs.setString('professional_front_id_path', widget.frontIdPath);
      await prefs.setString('professional_back_id_path', widget.backIdPath);
      await prefs.setString('professional_selfie_path', widget.selfiePath);

      // Navigate to the congratulations page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfessionalCongratulationsPage()
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Location'),
        backgroundColor: Colors.lightGreen,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where will you provide services?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please provide details of your base location from where you\'ll operate.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),

              // Location Type
              Text(
                'Location Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Home'),
                      value: 'Home',
                      groupValue: _locationType,
                      onChanged: (value) {
                        setState(() {
                          _locationType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Office'),
                      value: 'Office',
                      groupValue: _locationType,
                      onChanged: (value) {
                        setState(() {
                          _locationType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // City
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                value: _selectedCity,
                hint: Text('Select your city'),
                items: _cities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your city';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),
              SizedBox(height: 16),

              // Area
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Area / Neighborhood',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your area';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Zipcode
              TextFormField(
                controller: _zipcodeController,
                decoration: InputDecoration(
                  labelText: 'Zip Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.markunread_mailbox),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your zip code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),

              Container(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveLocationDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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