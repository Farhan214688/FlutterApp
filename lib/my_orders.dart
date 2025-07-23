import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginPage.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class MyOrdersPage extends StatefulWidget {
  final bool isLoggedIn;
  final String username;
  final String? serviceName;

  MyOrdersPage(
      {required this.isLoggedIn, required this.username, this.serviceName});

  @override
  _MyOrdersPageState createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _pastOrders = [];
  bool _isLoading = true;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.isLoggedIn) {
      _setupOrdersListener();
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupOrdersListener() {
    // Cancel any existing subscription
    _ordersSubscription?.cancel();

    // Set up real-time listener for all orders
    _ordersSubscription = _firestore
        .collection('serviceBookings')
        .where('customerId', isEqualTo: widget.username)
        .snapshots()
        .listen((snapshot) {
      print('DEBUG: Orders update received');
      print('DEBUG: Total orders in snapshot: ${snapshot.docs.length}');
      
      // Process active orders
      _activeOrders = snapshot.docs
          .where((doc) {
            final status = doc.data()['status'];
            final isActive = ['pending', 'accepted'].contains(status);
            print('DEBUG: Order ${doc.id} - Status: $status, Is Active: $isActive');
            return isActive;
          })
          .map((doc) {
        final data = doc.data();
        print('DEBUG: Processing active order: ${doc.id}');
        print('DEBUG: Active order data: ${data.toString()}');
        final bool isWeeklyService = data['isWeeklyService'] == true ||
            data['serviceType'] == 'weekly' ||
            data['serviceCategory']?.toString().toLowerCase() == 'weekly service';
        print('DEBUG: Is weekly service: $isWeeklyService');
        return {
          'id': doc.id,
          'service': data['serviceName'],
          'date': data['date'],
          'time': data['time'],
          'status': data['status'],
          'price': data['finalPrice'],
          'address': data['address'],
          'image': null,
          'professionalName': data['professionalName'],
          'professionalPhone': data['professionalPhone'],
          'isWeeklyService': isWeeklyService,
          'serviceCategory': data['serviceCategory'],
          'serviceType': data['serviceType'],
        };
      }).toList();

      print('DEBUG: Active orders count: ${_activeOrders.length}');

      // Process past orders
      _pastOrders = snapshot.docs
          .where((doc) {
            final status = doc.data()['status'];
            final isPast = ['completed', 'cancelled'].contains(status);
            print('DEBUG: Order ${doc.id} - Status: $status, Is Past: $isPast');
            return isPast;
          })
          .map((doc) {
        final data = doc.data();
        print('DEBUG: Processing past order: ${doc.id}');
        print('DEBUG: Past order data: ${data.toString()}');
        final bool isWeeklyService = data['isWeeklyService'] == true ||
            data['serviceType'] == 'weekly' ||
            data['serviceCategory']?.toString().toLowerCase() == 'weekly service';
        print('DEBUG: Is weekly service: $isWeeklyService');
        return {
          'id': doc.id,
          'service': data['serviceName'],
          'date': data['date'],
          'time': data['time'],
          'status': data['status'],
          'price': data['finalPrice'],
          'address': data['address'],
          'rating': data['rating'] ?? 0.0,
          'image': null,
          'professionalName': data['professionalName'],
          'professionalPhone': data['professionalPhone'],
          'isWeeklyService': isWeeklyService,
          'serviceCategory': data['serviceCategory'],
          'serviceType': data['serviceType'],
        };
      }).toList();

      print('DEBUG: Past orders count: ${_pastOrders.length}');

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
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await _firestore.collection('serviceBookings').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _setupOrdersListener();
    } catch (e) {
      print('Error cancelling order: $e');
    }
  }

  Future<void> _completeOrder(String orderId) async {
    try {
      // Get the order data first
      final orderDoc = await FirebaseFirestore.instance
          .collection('serviceBookings')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data()!;
      final bool isWeeklyService = orderData['isWeeklyService'] == true ||
          orderData['serviceType'] == 'weekly_offer' ||
          orderData['serviceCategory']?.toString().toLowerCase() == 'weekly service';

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('serviceBookings').doc(orderId);

      if (isWeeklyService) {
        // For weekly services, calculate earnings and commission
        final discountedPrice = orderData['price'] ?? orderData['finalPrice'] ?? 0;
        final earnings = (discountedPrice * 0.90).round();
        final commission = (discountedPrice * 0.10).round();

        // Update the order with earnings and commission
        batch.update(orderRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'earnings': earnings,
          'commission': commission,
        });

        // If there's a weekly offer ID, update the weekly offer status
        if (orderData['weeklyOfferId'] != null) {
          final weeklyOfferRef = FirebaseFirestore.instance
              .collection('weeklyOffers')
              .doc(orderData['weeklyOfferId']);
          batch.update(weeklyOfferRef, {
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update professional's earnings
        if (orderData['professionalId'] != null) {
          final professionalRef = FirebaseFirestore.instance
              .collection('professionals')
              .doc(orderData['professionalId']);
          batch.update(professionalRef, {
            'earnings': FieldValue.increment(earnings),
            'commission': FieldValue.increment(commission),
            'walletBalance': FieldValue.increment(earnings),
          });
        }
      } else {
        // For regular orders, just update the status
        batch.update(orderRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit all updates
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order marked as completed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _setupOrdersListener();
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        backgroundColor: Colors.lightGreen,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Active Orders'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _activeOrders.isEmpty
                    ? _buildEmptyState(
                        'No active orders', 'Book services to see them here')
                    : _buildOrdersList(_activeOrders, true),
                _pastOrders.isEmpty
                    ? _buildEmptyState(
                        'No past orders', 'Completed orders will appear here')
                    : _buildOrdersList(_pastOrders, false),
              ],
            ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Please login to view your orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, bool isActive) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final bool isWeeklyService = order['isWeeklyService'] ?? false;
        final String serviceType = order['serviceType'] ?? '';
        final bool isWeeklyOffer = isWeeklyService || serviceType == 'weekly_offer';
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order['serviceName'] ?? order['service'] ?? 'Service',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isWeeklyOffer)
                                Container(
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.repeat, size: 14, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text(
                                        'Weekly Service',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Date: ${order['date'] ?? 'N/A'}'),
                          Text('Time: ${order['time'] ?? 'N/A'}'),
                          Text('Address: ${order['address'] ?? 'N/A'}'),
                          if (order['originalPrice'] != null && order['discount'] != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Original Price: Rs. ${order['originalPrice']?.toString() ?? '0'}',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Discounted Price: Rs. ${order['price']?.toString() ?? '0'} (${order['discount']}% off)',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Price: Rs. ${order['price']?.toString() ?? '0'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          if (order['professionalName'] != null)
                            Text('Professional: ${order['professionalName']}'),
                          if (order['professionalPhone'] != null)
                            Text('Phone: ${order['professionalPhone']}'),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order['status'] ?? '').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getStatusColor(order['status'] ?? '').withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(order['status'] ?? ''),
                                  size: 14,
                                  color: _getStatusColor(order['status'] ?? ''),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  order['status']?.toUpperCase() ?? 'UNKNOWN',
                                  style: TextStyle(
                                    color: _getStatusColor(order['status'] ?? ''),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (order['status'] == 'accepted') ...[
                            SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _completeOrder(order['id'] ?? ''),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('Complete'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.engineering;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
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
                Text(
                  order['serviceName'] ?? 'Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(order['status'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['status']?.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: _getStatusColor(order['status'] ?? ''),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
                'Price: Rs. ${order['finalPrice']?.toStringAsFixed(0) ?? '0'}'),
            SizedBox(height: 4),
            Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(order['date'] ?? ''))}'),
            SizedBox(height: 4),
            Text('Time: ${order['time'] ?? 'N/A'}'),
            SizedBox(height: 4),
            Text('Address: ${order['address'] ?? 'N/A'}'),
            if (order['professionalName'] != null) ...[
              SizedBox(height: 4),
              Text('Professional: ${order['professionalName']}'),
              if (order['professionalPhone'] != null)
                Text('Phone: ${order['professionalPhone']}'),
            ],
            if (order['status'] == 'accepted') ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeOrder(order['id'] ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Mark as Complete'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
