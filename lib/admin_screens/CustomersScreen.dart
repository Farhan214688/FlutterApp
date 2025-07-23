import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String status; // 'active' or 'inactive'
  final DateTime joinDate;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.status,
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
      status: data['status'] ?? 'active',
      joinDate: (data['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'status': status,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, status: $status)';
  }
}

class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<User> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('Starting to load users...');

      // Load customers from users collection
      print('Loading customers...');
      final customersSnapshot = await _firestore
          .collection('users')
          .where('type', isEqualTo: 'customer')
          .orderBy('joinDate', descending: true)
          .get();

      print('Found ${customersSnapshot.docs.length} customers');

      final List<User> allUsers = [];

      // Add customers
      for (var doc in customersSnapshot.docs) {
        try {
          final data = doc.data();
          allUsers.add(User.fromFirestore(doc));
        } catch (e) {
          print('Error processing customer document ${doc.id}: $e');
        }
      }

      print('Total users loaded: ${allUsers.length}');

      setState(() {
        _users = allUsers;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error in _loadUsers: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(String id, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      print('Updating status for customer $id to $newStatus');

      // Update in users collection
      await _firestore
          .collection('users')
          .doc(id)
          .update({'status': newStatus});

      // Also update in account_status collection if it exists
      try {
        await _firestore.collection('account_status').doc(id).set({
          'isActive': newStatus == 'active',
          'userId': id,
          'userType': 'customer',
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
                      'Customer Details',
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
      appBar: AppBar(
        title: Text('Customers'),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: user.status == 'active'
                            ? Colors.green
                            : Colors.grey,
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
                          IconButton(
                            icon: Icon(
                              user.status == 'active'
                                  ? Icons.toggle_on
                                  : Icons.toggle_off,
                              color: user.status == 'active'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onPressed: () =>
                                _toggleUserStatus(user.id, user.status),
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () => _showUserDetails(context, user),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
