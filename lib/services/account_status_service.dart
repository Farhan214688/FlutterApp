import 'package:cloud_firestore/cloud_firestore.dart';

class AccountStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if an account is active
  Future<bool> isAccountActive(String userId, String userType) async {
    try {
      final docRef = _firestore.collection('account_status').doc(userId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        // If no status document exists, create one with active status
        await docRef.set({
          'userId': userId,
          'userType': userType,
          'isActive': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return true;
      }
      
      return doc.data()?['isActive'] ?? true;
    } catch (e) {
      print('Error checking account status: $e');
      return false;
    }
  }

  // Update account status
  Future<void> updateAccountStatus(String userId, String userType, bool isActive) async {
    try {
      await _firestore.collection('account_status').doc(userId).set({
        'userId': userId,
        'userType': userType,
        'isActive': isActive,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating account status: $e');
      throw e;
    }
  }

  // Get all accounts with their status
  Stream<QuerySnapshot> getAllAccounts() {
    return _firestore.collection('account_status').snapshots();
  }

  // Get accounts by type (customer/professional)
  Stream<QuerySnapshot> getAccountsByType(String userType) {
    return _firestore
        .collection('account_status')
        .where('userType', isEqualTo: userType)
        .snapshots();
  }
} 