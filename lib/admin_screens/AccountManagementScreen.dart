import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/account_status_service.dart';

class AccountManagementScreen extends StatefulWidget {
  @override
  _AccountManagementScreenState createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AccountStatusService _accountStatusService = AccountStatusService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateAccountStatus(String userId, String userType, bool isActive) async {
    try {
      await _accountStatusService.updateAccountStatus(userId, userType, isActive);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating account status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAccountList(String userType) {
    return StreamBuilder<QuerySnapshot>(
      stream: _accountStatusService.getAccountsByType(userType),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No ${userType}s found'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] as String;
            final isActive = data['isActive'] as bool;

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection(userType == 'professional' ? 'professionals' : 'customers').doc(userId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return ListTile(
                    title: Text('Loading...'),
                  );
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final name = userData?['name'] ?? 'Unknown';
                final phone = userData?['phoneNumber'] ?? 'No phone';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(phone),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Switch(
                          value: isActive,
                          onChanged: (value) => _updateAccountStatus(userId, userType, value),
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Professionals'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountList('professional'),
          _buildAccountList('customer'),
        ],
      ),
    );
  }
} 