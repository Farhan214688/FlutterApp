import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class MyOrdersScreen extends StatefulWidget {
  final Function? onOrderCompleted;

  MyOrdersScreen({this.onOrderCompleted});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  Position? _currentPosition;
  late TabController _tabController;
  int _totalCommission = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      await _loadOrders();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: User ID not found')),
        );
        return;
      }

      // Set up real-time listener for orders
      FirebaseFirestore.instance
          .collection('serviceBookings')
          .where('professionalId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        // Separate orders into different categories
        _pendingOrders = snapshot.docs
            .where((doc) => doc.data()['status'] == 'accepted')
            .map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _completedOrders = snapshot.docs
            .where((doc) => doc.data()['status'] == 'completed')
            .map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Calculate total commission (Rs. 250 per completed order)
        _totalCommission = _completedOrders.length * 250;

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }, onError: (error) {
        print('Error in orders listener: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading orders: $error')),
          );
        }
      });
    } catch (e) {
      print('Error loading orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      // Instead of marking as rejected, just remove the professional's ID
      await FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(orderId)
          .update({
        'professionalId': FieldValue.delete(),
        'professionalName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Order rejected and made available to other professionals')),
      );
    } catch (e) {
      print('Error rejecting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting order: $e')),
      );
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userName = prefs.getString('professionalName') ?? 'Unknown Professional';
      final userPhone = prefs.getString('phone') ?? 'N/A';

      await FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(orderId)
          .update({
        'status': 'accepted',
        'professionalId': userId,
        'professionalName': userName,
        'professionalPhone': userPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order accepted successfully')),
      );
    } catch (e) {
      print('Error accepting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting order: $e')),
      );
    }
  }

  Future<void> _completeOrder(
      String orderId, double orderPrice, Map<String, dynamic> order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Get professional's current data
      final professionalDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId)
          .get();
      
      if (!professionalDoc.exists) {
        throw Exception('Professional not found');
      }

      final professionalData = professionalDoc.data()!;
      final currentCompletedOrders = professionalData['completedOrdersCount'] ?? 0;
      final newCompletedOrdersCount = currentCompletedOrders + 1;

      // Calculate earnings (90% of order price) and commission (10% of order price)
      final earnings = (orderPrice * 0.90).round();
      final commission = (orderPrice * 0.10).round();

      // Start a batch write to ensure all updates are atomic
      final batch = FirebaseFirestore.instance.batch();

      // Update order status
      final orderRef = FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(orderId);
      batch.update(orderRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'earnings': earnings,
        'commission': commission,
      });

      // Update professional's data
      final professionalRef = FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId);
      
      Map<String, dynamic> professionalUpdates = {
        'earnings': FieldValue.increment(earnings),
        'commission': FieldValue.increment(commission),
        'walletBalance': FieldValue.increment(earnings),
        'completedOrdersCount': newCompletedOrdersCount,
      };

      // Check if this is the 5th completed order
      if (newCompletedOrdersCount >= 5) {
        professionalUpdates['status'] = 'deactivated';
        professionalUpdates['deactivationReason'] = 'pending_commission_payment';
        professionalUpdates['deactivatedAt'] = FieldValue.serverTimestamp();
        
        // Also update account_status collection
        final accountStatusRef = FirebaseFirestore.instance
            .collection('account_status')
            .doc(userId);
        batch.set(accountStatusRef, {
          'userId': userId,
          'userType': 'professional',
          'isActive': false,
          'lastUpdated': FieldValue.serverTimestamp(),
          'deactivationReason': 'pending_commission_payment',
        }, SetOptions(merge: true));
      }

      batch.update(professionalRef, professionalUpdates);

      // Commit the batch
      await batch.commit();

      // Update local wallet balance
      final currentBalance = prefs.getDouble('walletBalance') ?? 0.0;
      final newBalance = currentBalance + earnings;
      await prefs.setDouble('walletBalance', newBalance);

      // Get existing transactions
      final transactionsJson = prefs.getString('walletTransactions');
      List<Map<String, dynamic>> transactions = [];
      if (transactionsJson != null) {
        transactions = List<Map<String, dynamic>>.from(jsonDecode(transactionsJson));
      }

      // Add new transaction for earnings
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final newTransaction = {
        'id': 'TRX${transactions.length + 1}'.padLeft(6, '0'),
        'orderID': orderId,
        'amount': earnings.toDouble(),
        'description': 'Payment for ${order['serviceName'] ?? 'service'} (Earnings)',
        'type': 'credit',
        'date': formatter.format(now),
      };
      transactions.add(newTransaction);

      // Add commission transaction
      final commissionTransaction = {
        'id': 'TRX${transactions.length + 2}'.padLeft(6, '0'),
        'orderID': orderId,
        'amount': commission.toDouble(),
        'description': 'Commission for ${order['serviceName'] ?? 'service'}',
        'type': 'debit',
        'date': formatter.format(now),
      };
      transactions.add(commissionTransaction);

      // Save updated transactions
      await prefs.setString('walletTransactions', jsonEncode(transactions));

      // Reload orders
      await _loadOrders();

      // Notify parent widget to refresh wallet
      if (widget.onOrderCompleted != null) {
        widget.onOrderCompleted!();
      }

      // Show appropriate message based on account status
      if (newCompletedOrdersCount >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order completed. Your account has been deactivated due to pending commission payment. Please pay your commission in the wallet tab to reactivate your account.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order completed successfully. Earnings: Rs. $earnings, Commission: Rs. $commission',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error completing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Safely extract values with null checks and defaults
    final serviceName = order['serviceName']?.toString() ?? 'Unknown Service';
    final status = order['status']?.toString() ?? 'pending';
    final finalPrice = (order['finalPrice'] as num?)?.toDouble() ?? 
                      (order['price'] as num?)?.toDouble() ?? 0.0;
    final createdAt = order['createdAt'] as Timestamp?;
    final acceptedAt = order['acceptedAt'] as Timestamp?;
    final completedAt = order['completedAt'] as Timestamp?;
    final address = order['address']?.toString() ?? 'Address not available';
    final customerName = order['customerName']?.toString() ?? 'Customer name not available';
    final time = order['time']?.toString() ?? 'Time not available';
    final isWeeklyService = order['isWeeklyService'] == true;
    final discount = (order['discount'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (order['originalPrice'] as num?)?.toDouble() ?? finalPrice;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isWeeklyService)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Weekly Service',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (isWeeklyService && discount > 0) ...[
              Row(
                children: [
                  Text(
                    'Original Price: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    'Rs. ${originalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${discount.toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
            ],
            Text(
              'Price: Rs. ${finalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isWeeklyService ? FontWeight.bold : FontWeight.normal,
                color: isWeeklyService ? Colors.green[700] : null,
              ),
            ),
            SizedBox(height: 4),
            if (createdAt != null)
              Text(
                'Created: ${DateFormat('MMM dd, yyyy').format(createdAt.toDate())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (acceptedAt != null)
              Text(
                'Accepted: ${DateFormat('MMM dd, yyyy').format(acceptedAt.toDate())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (completedAt != null)
              Text(
                'Completed: ${DateFormat('MMM dd, yyyy').format(completedAt.toDate())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            SizedBox(height: 4),
            Text('Time: $time'),
            SizedBox(height: 4),
            Text('Address: $address'),
            SizedBox(height: 4),
            Text('Customer: $customerName'),
            Text('Phone: ${order['customerPhone'] ?? 'N/A'}'),
            if (status == 'accepted') ...[
              SizedBox(height: 12),
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeOrder(
                      order['id'],
                      finalPrice,
                      order,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Complete Order'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        backgroundColor: Colors.lightGreen,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Pending Orders Tab
                _pendingOrders.isEmpty
                    ? Center(
                        child: Text(
                          'No pending orders',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _pendingOrders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_pendingOrders[index]);
                        },
                      ),
                // Completed Orders Tab
                _completedOrders.isEmpty
                    ? Center(
                        child: Text(
                          'No completed orders',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _completedOrders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(_completedOrders[index]);
                        },
                      ),
              ],
            ),
    );
  }
}
