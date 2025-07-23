import 'package:flutter/material.dart';
import 'LoginPage.dart';

class RewardsPage extends StatefulWidget {
  final bool isLoggedIn;
  final String username;

  RewardsPage({required this.isLoggedIn, required this.username});

  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  // Sample rewards data
  final int points = 350;
  final List<Map<String, dynamic>> _rewards = [
    {
      'title': '₹100 Off',
      'description': 'Get ₹100 off on your next service booking',
      'points': 200,
      'image': 'Assets/Images/discount.png',
      'expiryDate': '30 Jun 2023',
    },
    {
      'title': 'Free AC Service',
      'description': 'Get a free basic AC service',
      'points': 500,
      'image': 'Assets/Images/ac_service.png',
      'expiryDate': '15 Jul 2023',
    },
    {
      'title': '20% Off on Plumbing',
      'description': 'Get 20% off on any plumbing service',
      'points': 300,
      'image': 'Assets/Images/plumbing.png',
      'expiryDate': '31 Jul 2023',
    },
    {
      'title': 'Free Home Inspection',
      'description': 'Get a free home inspection service',
      'points': 400,
      'image': 'Assets/Images/inspection.png',
      'expiryDate': '15 Aug 2023',
    },
  ];

  final List<Map<String, dynamic>> _history = [
    {
      'title': 'Booking Completed',
      'description': 'AC Service booking completed',
      'points': '+50',
      'date': '28 May 2023',
      'type': 'earned',
    },
    {
      'title': 'Coupon Redeemed',
      'description': '₹50 discount coupon redeemed',
      'points': '-100',
      'date': '15 May 2023',
      'type': 'redeemed',
    },
    {
      'title': 'Booking Completed',
      'description': 'Plumbing service booking completed',
      'points': '+50',
      'date': '02 May 2023',
      'type': 'earned',
    },
    {
      'title': 'Welcome Bonus',
      'description': 'Points for joining Rapit',
      'points': '+150',
      'date': '25 Apr 2023',
      'type': 'earned',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Rewards'),
        backgroundColor: Colors.lightGreen,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointsCard(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Available Rewards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildRewardsList(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Points History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildHistoryList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Rewards'),
        backgroundColor: Colors.lightGreen,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'Please login to view your rewards',
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

  Widget _buildPointsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightGreen, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 25,
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.username}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your current rewards status',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '$points',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'POINTS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Earn more points by booking services and referring friends!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList() {
    return Container(
      height: 230,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _rewards.length,
        itemBuilder: (context, index) {
          final reward = _rewards[index];
          bool canRedeem = points >= reward['points'];
          
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.asset(
                    reward['image'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(Icons.card_giftcard, size: 40, color: Colors.grey[600]),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        reward['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${reward['points']} Points',
                            style: TextStyle(
                              color: canRedeem ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          ElevatedButton(
                            onPressed: canRedeem
                                ? () {
                                    // Implement reward redemption
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Redeem Reward'),
                                        content: Text('Are you sure you want to redeem ${reward['title']} for ${reward['points']} points?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Implement redemption logic
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Reward redeemed successfully!')),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.lightGreen,
                                            ),
                                            child: Text('Redeem'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: Size(60, 25),
                            ),
                            child: Text(
                              'Redeem',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final history = _history[index];
        bool isEarned = history['type'] == 'earned';
        
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              history['title'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(history['description']),
                SizedBox(height: 4),
                Text(
                  history['date'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Text(
              history['points'],
              style: TextStyle(
                color: isEarned ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
} 