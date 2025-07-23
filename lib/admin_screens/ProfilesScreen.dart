import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String type; // 'customer' or 'professional'
  final String status; // 'active' or 'inactive'
  final String serviceName; // Only for professionals
  final DateTime joinDate;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.type,
    required this.status,
    required this.serviceName,
    required this.joinDate,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print('Creating User from Firestore data: $data');

    return User(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      phoneNumber: data['phoneNumber'] ?? 'No phone',
      email: data['email'] ?? 'No email',
      type: data['type'] ?? 'customer',
      status: data['status'] ?? 'active',
      serviceName: data['serviceName'] ?? 'No service',
      joinDate: (data['joinDate'] as Timestamp?)?.toDate() ??
          (data['approved_date'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'type': type,
      'status': status,
      'serviceName': serviceName,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, type: $type, status: $status)';
  }
}

class ProfilesScreen extends StatefulWidget {
  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<User> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('Starting to load users...');

      List<User> allUsers = [];

      // Load customers from users collection
      print('Loading customers...');
      try {
        // Try with admin permissions
        final customersSnapshot = await _firestore
            .collection('users')
            .where('type', isEqualTo: 'customer')
            .get();

        print('Found ${customersSnapshot.docs.length} customers');

        // Add customers
        for (var doc in customersSnapshot.docs) {
          try {
            final user = User.fromFirestore(doc);
            allUsers.add(user);
          } catch (e) {
            print('Error processing customer document ${doc.id}: $e');
          }
        }
      } catch (e) {
        print('Error loading customers: $e');
        setState(() {
          _errorMessage =
              'Permission denied: Your admin account may not have proper permissions. Please check Firestore rules.';
        });
        // Continue loading professionals even if customers fail
      }

      // Load professionals from professionals collection
      print('Loading professionals...');
      try {
        final professionalsSnapshot =
            await _firestore.collection('professionals').get();

        print('Found ${professionalsSnapshot.docs.length} professionals');

        // Add professionals
        for (var doc in professionalsSnapshot.docs) {
          try {
            // Create a new map with required fields
            Map<String, dynamic> data = doc.data();
            // Add type field since it might be missing in professionals collection
            data['type'] = 'professional';

            // Convert directly using User constructor
            final user = User(
              id: doc.id,
              name: data['name'] ?? 'Unknown',
              phoneNumber: data['phoneNumber'] ?? 'No phone',
              email: data['email'] ?? 'No email',
              type: 'professional',
              status: data['status'] ?? 'active',
              serviceName: data['serviceName'] ?? 'No service',
              joinDate: (data['approved_date'] as Timestamp?)?.toDate() ??
                  (data['joinDate'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
            allUsers.add(user);
          } catch (e) {
            print('Error processing professional document ${doc.id}: $e');
          }
        }

        // Sort the combined list by join date (client-side sorting)
        allUsers.sort((a, b) => b.joinDate.compareTo(a.joinDate));
      } catch (e) {
        print('Error loading professionals: $e');
        if (_errorMessage.isEmpty) {
          setState(() {
            _errorMessage =
                'Permission denied: Your admin account may not have proper permissions. Please check Firestore rules.';
          });
        }
      }

      setState(() {
        _users = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(
      String id, String currentStatus, String userType) async {
    try {
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      print('Updating status for $userType $id to $newStatus');

      // Update in the appropriate collection
      final collection = userType == 'professional' ? 'professionals' : 'users';
      await _firestore
          .collection(collection)
          .doc(id)
          .update({'status': newStatus});

      // Also update in account_status collection if it exists
      try {
        await _firestore.collection('account_status').doc(id).set({
          'isActive': newStatus == 'active',
          'userId': id,
          'userType': userType,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating account_status: $e');
        // Continue even if this fails
      }

      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(),
                SizedBox(height: 10),
                _detailRow('User ID', user.id),
                _detailRow('Name', user.name),
                _detailRow('Phone', user.phoneNumber),
                _detailRow('Email', user.email),
                _detailRow('User Type', user.type.toUpperCase()),
                _detailRow('Status', user.status.toUpperCase()),
                _detailRow('Join Date', user.joinDate.toString()),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildUsersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: Colors.green,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No customers found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _users.length,
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final user = _users[index];

          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor:
                    user.status == 'active' ? Colors.green : Colors.grey,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(user.phoneNumber),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: user.status == 'active',
                    onChanged: (value) =>
                        _toggleUserStatus(user.id, user.status, user.type),
                    activeColor: Colors.green,
                  ),
                  IconButton(
                    icon: Icon(Icons.visibility),
                    onPressed: () => _showUserDetails(context, user),
                  ),
                ],
              ),
              onTap: () => _showUserDetails(context, user),
            ),
          );
        },
      ),
    );
  }
}
