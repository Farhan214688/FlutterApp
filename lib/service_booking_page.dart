import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_picker_screen.dart';
import 'my_orders.dart';
import 'CustomerSign.dart';

class ServiceBookingPage extends StatefulWidget {
  final String serviceName;
  final double servicePrice;
  final String? serviceImage;
  final double? discountPercentage;
  final String? description;

  const ServiceBookingPage({
    Key? key,
    required this.serviceName,
    required this.servicePrice,
    this.serviceImage,
    this.discountPercentage,
    this.description,
  }) : super(key: key);

  @override
  State<ServiceBookingPage> createState() => _ServiceBookingPageState();
}

class _ServiceBookingPageState extends State<ServiceBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  double get _finalPrice {
    if (widget.discountPercentage != null && widget.discountPercentage! > 0) {
      return widget.servicePrice -
          (widget.servicePrice * widget.discountPercentage! / 100);
    }
    return widget.servicePrice;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('customerPhone');
      final customerName = prefs.getString('customerName');

      print('DEBUG: Submitting booking with phoneNumber: $phoneNumber');
      print('DEBUG: Customer name: $customerName');

      if (phoneNumber == null || customerName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please sign up to book this service'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerSign()),
        );
        return;
      }

      // Check for existing pending or accepted orders
      final existingOrdersQuery = await FirebaseFirestore.instance
          .collection('serviceBookings')
          .where('customerId', isEqualTo: phoneNumber)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      if (existingOrdersQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You already have a pending order. Please complete or cancel it before booking a new service.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View Orders',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyOrdersPage(
                      isLoggedIn: true,
                      username: phoneNumber,
                    ),
                  ),
                );
              },
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Calculate expiration time (24 hours from now)
      final now = DateTime.now();
      final expirationTime = now.add(Duration(hours: 24));

      // Create booking data
      final bookingData = {
        'customerId': phoneNumber,
        'customerName': customerName,
        'customerPhone': phoneNumber,
        'serviceName': widget.serviceName,
        'servicePrice': widget.servicePrice,
        'finalPrice': _finalPrice,
        'address': _addressController.text,
        'city': _addressController.text.split(',').last.trim(),
        'date': _selectedDate!.toIso8601String(),
        'time': _selectedTime!.format(context),
        'description': _descriptionController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expirationTime),
        'serviceCategory': widget.serviceName.toLowerCase(),
        'image': widget.serviceImage,
        'serviceType': widget.discountPercentage != null && widget.discountPercentage! > 0 ? 'weekly_offer' : 'regular',
        'isWeeklyService': widget.discountPercentage != null && widget.discountPercentage! > 0,
      };

      print('DEBUG: Saving booking data: $bookingData');

      // Save booking to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('serviceBookings')
          .add(bookingData);

      print('DEBUG: Booking saved with ID: ${docRef.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking submitted successfully!')),
      );

      // Navigate to My Orders page with a refresh flag
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyOrdersPage(
            isLoggedIn: true,
            username: phoneNumber,
            serviceName: widget.serviceName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting booking: $e')),
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
        title: Text('Book Service'),
        backgroundColor: Colors.lightGreen,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.serviceName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.description != null) ...[
                          SizedBox(height: 4),
                          Text(
                            widget.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.lightBlue[600],
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        if (widget.discountPercentage != null &&
                            widget.discountPercentage! > 0) ...[
                          Text(
                            'Original Price: Rs. ${widget.servicePrice}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Discounted Price: Rs. ${_finalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${widget.discountPercentage!.toStringAsFixed(0)}% OFF',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            'Price: Rs. ${widget.servicePrice}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Location Section
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.location_on),
                      onPressed: () async {
                        final String? selectedAddress = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationPickerScreen(),
                          ),
                        );
                        if (selectedAddress != null) {
                          _addressController.text = selectedAddress;
                        }
                      },
                    ),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Date and Time Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today),
                                  SizedBox(width: 8),
                                  Text(
                                    _selectedDate == null
                                        ? 'Select Date'
                                        : DateFormat('MMM dd, yyyy')
                                            .format(_selectedDate!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time),
                                  SizedBox(width: 8),
                                  Text(
                                    _selectedTime == null
                                        ? 'Select Time'
                                        : _selectedTime!.format(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Description Section
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Add any specific details or requirements',
                    border: OutlineInputBorder(),
                    hintText:
                        'Enter any additional information about your service request...',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a description of your service request';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Submit and Cancel Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Submit Booking'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
