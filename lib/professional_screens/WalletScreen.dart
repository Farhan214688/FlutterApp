import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String orderID;
  final double amount;
  final String description;
  final String type; // 'credit' or 'debit'
  final String date;

  Transaction({
    required this.id,
    required this.orderID,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      orderID: json['orderID'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      type: json['type'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderID': orderID,
      'amount': amount,
      'description': description,
      'type': type,
      'date': date,
    };
  }
}

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final balance = prefs.getDouble('walletBalance') ?? 0.0;
      final transactionsJson = prefs.getString('walletTransactions');

      if (transactionsJson != null) {
        final List<dynamic> transactionsData = jsonDecode(transactionsJson);
        final transactions = transactionsData
            .map((item) => Transaction.fromJson(item))
            .toList();

        setState(() {
          _balance = balance;
          _transactions = transactions;
        });
      } else {
        // For demo purposes, create some sample transactions
        _createSampleTransactions();
      }
    } catch (e) {
      print('Error loading wallet data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('walletBalance', _balance);

      final transactionsJson =
          jsonEncode(_transactions.map((t) => t.toJson()).toList());
      await prefs.setString('walletTransactions', transactionsJson);
    } catch (e) {
      print('Error saving wallet data: $e');
    }
  }

  void _createSampleTransactions() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    _transactions = [
      Transaction(
        id: 'TRX001',
        orderID: 'ORD003',
        amount: 3000.0,
        description: 'Payment for Cleaning service',
        type: 'credit',
        date: formatter.format(now.subtract(Duration(days: 2))),
      ),
      Transaction(
        id: 'TRX002',
        orderID: 'ORD001',
        amount: 1500.0,
        description: 'Payment for Plumbing service',
        type: 'credit',
        date: formatter.format(now.subtract(Duration(days: 5))),
      ),
      Transaction(
        id: 'TRX003',
        orderID: '',
        amount: 2000.0,
        description: 'Withdrawal to bank account',
        type: 'debit',
        date: formatter.format(now.subtract(Duration(days: 7))),
      ),
    ];

    _calculateBalance();
    _saveWalletData();
  }

  void _calculateBalance() {
    double total = 0.0;
    for (var transaction in _transactions) {
      if (transaction.type == 'credit') {
        total += transaction.amount;
      } else {
        total -= transaction.amount;
      }
    }
    setState(() {
      _balance = total;
    });
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw Funds'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: 'Bank Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  if (value.length < 10) {
                    return 'Enter a valid account number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (Rs.)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Enter a valid amount';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amount > _balance) {
                    return 'Insufficient balance';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _processWithdrawal();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
            ),
            child: Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _processWithdrawal() {
    final amount = double.parse(_amountController.text);
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    // Create new transaction
    final transaction = Transaction(
      id: 'TRX${_transactions.length + 1}'.padLeft(6, '0'),
      orderID: '',
      amount: amount,
      description: 'Withdrawal to account ${_accountController.text.substring(_accountController.text.length - 4)}',
      type: 'debit',
      date: formatter.format(now),
    );

    setState(() {
      _transactions.add(transaction);
      _balance -= amount;
    });

    _saveWalletData();
    _accountController.clear();
    _amountController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Withdrawal request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.lightGreen,
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Rs. ${_balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _balance > 0 ? _showWithdrawDialog : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.lightGreen,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'Withdraw Funds',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 25),
                      
                      // Transaction History
                      Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      
                      // Transactions List
                      _transactions.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 70,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                final bool isCredit = transaction.type == 'credit';
                                
                                return Card(
                                  margin: EdgeInsets.only(bottom: 10),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: isCredit
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      child: Icon(
                                        isCredit
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isCredit
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      transaction.description,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      transaction.date,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${isCredit ? '+' : '-'} Rs. ${transaction.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isCredit
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 