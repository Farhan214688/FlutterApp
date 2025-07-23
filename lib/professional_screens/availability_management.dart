import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AvailabilityManagement extends StatefulWidget {
  const AvailabilityManagement({Key? key}) : super(key: key);

  @override
  _AvailabilityManagementState createState() => _AvailabilityManagementState();
}

class _AvailabilityManagementState extends State<AvailabilityManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _professionalId = '';
  Map<String, dynamic> _availabilityData = {};
  bool _isUpdating = false;

  // Days of the week
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _professionalId = userId;

      final docSnapshot = await _firestore
          .collection('professionals')
          .doc(userId)
          .collection('settings')
          .doc('availability')
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _availabilityData = docSnapshot.data() ?? {};
          _isLoading = false;
        });
      } else {
        // Initialize default availability (9 AM to 5 PM, Monday to Friday)
        Map<String, dynamic> defaultAvailability = {};

        for (String day in _daysOfWeek) {
          defaultAvailability[day] = {
            'isAvailable': day != 'Saturday' && day != 'Sunday',
            'startTime': '09:00',
            'endTime': '17:00',
          };
        }

        setState(() {
          _availabilityData = defaultAvailability;
          _isLoading = false;
        });

        // Save default availability to Firestore
        await _firestore
            .collection('professionals')
            .doc(userId)
            .collection('settings')
            .doc('availability')
            .set(_availabilityData);
      }
    } catch (e) {
      print('Error loading availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading availability settings')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _firestore
          .collection('professionals')
          .doc(_professionalId)
          .collection('settings')
          .doc('availability')
          .set(_availabilityData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability saved successfully')),
      );

    } catch (e) {
      print('Error saving availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving availability settings')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _toggleDayAvailability(String day, bool isAvailable) {
    setState(() {
      if (_availabilityData.containsKey(day)) {
        _availabilityData[day]['isAvailable'] = isAvailable;
      } else {
        _availabilityData[day] = {
          'isAvailable': isAvailable,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
    });
  }

  Future<void> _selectTimeRange(String day, bool isStartTime) async {
    final TimeOfDay initialTime = _parseTimeOfDay(
      isStartTime
          ? _availabilityData[day]['startTime'] ?? '09:00'
          : _availabilityData[day]['endTime'] ?? '17:00',
    );

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final formattedTime = _formatTimeOfDay(pickedTime);

      setState(() {
        if (isStartTime) {
          _availabilityData[day]['startTime'] = formattedTime;
        } else {
          _availabilityData[day]['endTime'] = formattedTime;
        }
      });
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Availability'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isUpdating ? null : _saveAvailability,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isUpdating
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Updating availability...'),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _daysOfWeek.length,
        itemBuilder: (context, index) {
          final day = _daysOfWeek[index];
          final dayData = _availabilityData[day] ?? {
            'isAvailable': false,
            'startTime': '09:00',
            'endTime': '17:00',
          };
          final isAvailable = dayData['isAvailable'] ?? false;

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        onChanged: (value) => _toggleDayAvailability(day, value),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  if (isAvailable) ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTimeRange(day, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Time',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                _formatTimeDisplay(dayData['startTime'] ?? '09:00'),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'to',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTimeRange(day, false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                _formatTimeDisplay(dayData['endTime'] ?? '17:00'),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeDisplay(String timeString) {
    final time = _parseTimeOfDay(timeString);
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}