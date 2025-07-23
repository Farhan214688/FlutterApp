import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class WeeklyOffersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'weeklyOffers';
  final String _cachedOffersKey = 'cached_weekly_offers';

  // Add list of allowed cities
  static const List<String> allowedCities = [
    'islamabad',
    'lahore',
    'karachi',
    'rawalpindi'
  ];

  // Helper method to validate city
  bool _isValidCity(String city) {
    return allowedCities.contains(city.toLowerCase());
  }

  // Load weekly offers with fallback to cached data
  Future<List<Map<String, dynamic>>> loadWeeklyOffers() async {
    try {
      print('Loading weekly offers from Firestore and cache');
      // First get any cached offers to check for pending deletions
      final cachedOffers = await _getCachedOffers();
      final pendingDeletionIds = cachedOffers
          .where((offer) => offer['pendingDelete'] == true)
          .map((offer) => offer['id'].toString())
          .toSet();

      print('Found ${pendingDeletionIds.length} offers pending deletion');

      // Try to get weekly offers from Firestore
      final snapshot = await _firestore.collection(_collectionName).get();

      if (snapshot.docs.isNotEmpty) {
        final offers = snapshot.docs
            .map((doc) {
              Map<String, dynamic> data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .where(
                (offer) => !pendingDeletionIds.contains(offer['id'].toString()))
            .toList();

        print(
            'Loaded ${snapshot.docs.length} offers from Firestore, filtered to ${offers.length} after removing pending deletions');

        // Get cached offers that are awaiting sync but not deletion
        final cachedPendingOffers = cachedOffers
            .where((offer) =>
                offer['pendingSync'] == true && offer['pendingDelete'] != true)
            .toList();

        // Combine Firestore offers with cached pending offers
        final allOffers = [...offers, ...cachedPendingOffers];

        // Cache the combined and filtered offers
        await _cacheOffers(allOffers);

        return allOffers;
      } else {
        // If no offers in Firestore, filter and return cached offers
        final filteredCachedOffers = cachedOffers
            .where((offer) => offer['pendingDelete'] != true)
            .toList();

        print(
            'No offers in Firestore, returning ${filteredCachedOffers.length} cached offers after filtering');
        return filteredCachedOffers;
      }
    } catch (e) {
      print('Error loading weekly offers from Firestore: $e');
      // On error, try to load from cache but filter out deleted items
      final cachedOffers = await _getCachedOffers();
      final filteredCachedOffers = cachedOffers
          .where((offer) => offer['pendingDelete'] != true)
          .toList();

      print(
          'Returning ${filteredCachedOffers.length} cached offers after filtering (after Firestore error)');
      return filteredCachedOffers;
    }
  }

  // Load weekly offers for all professionals with location and verification filters
  Future<List<Map<String, dynamic>>> loadWeeklyOffersForProfessionals({
    required String city,
    required bool isVerified,
  }) async {
    try {
      print('Debug - Loading weekly offers for professionals');
      print('Debug - City: ${city.toLowerCase()}');
      print('Debug - Is verified: $isVerified');

      // Get all offers from the weeklyOffers collection
      final offersSnapshot = await _firestore.collection('weeklyOffers').get();
      
      print('Debug - Total offers in collection: ${offersSnapshot.docs.length}');
      print('Debug - All offers data:');
      for (var doc in offersSnapshot.docs) {
        print('  - ID: ${doc.id}');
        print('    Data: ${doc.data()}');
      }

      // Filter offers that:
      // 1. Match the professional's city
      // 2. Are active (or null, to be more lenient)
      // 3. Have status 'pending' (or null, to be more lenient)
      final filteredOffers = offersSnapshot.docs.where((doc) {
        final data = doc.data();
        final offerCity = (data['city'] as String?)?.toLowerCase() ?? '';
        final isActive = data['isActive'] as bool? ?? true; // Default to true if not specified
        final status = data['status'] as String? ?? 'pending'; // Default to pending if not specified
        
        print('Debug - Checking offer:');
        print('  - City: $offerCity vs $city');
        print('  - IsActive: $isActive');
        print('  - Status: $status');
        
        final matches = offerCity == city.toLowerCase() && 
                       isActive && 
                       (status == 'pending' || status == null);
        
        print('  - Matches: $matches');
        return matches;
      }).map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'serviceCategory': 'weekly_offer',
          'serviceName': data['name'],
          'serviceType': 'weekly', // Explicitly set service type
          'isWeeklyService': true, // Explicitly mark as weekly service
        };
      }).toList();

      print('Debug - Filtered offers count: ${filteredOffers.length}');
      print('Debug - Filtered offers data:');
      for (var offer in filteredOffers) {
        print('  - $offer');
      }

      return filteredOffers;
    } catch (e) {
      print('Error loading weekly offers: $e');
      rethrow;
    }
  }

  // Save a new weekly offer
  Future<void> saveWeeklyOffer({
    required String name,
    required int price,
    required int discount,
    required String city,
  }) async {
    try {
      if (!_isValidCity(city)) {
        throw Exception('Invalid city. Allowed cities are: ${allowedCities.join(", ")}');
      }

      // Create the weekly offer
      final offerData = {
        'name': name,
        'price': price,
        'discount': discount,
        'city': city.toLowerCase(),
        'isActive': true,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('weeklyOffers').add(offerData);
    } catch (e) {
      print('Error saving weekly offer: $e');
      rethrow;
    }
  }

  // Update an existing weekly offer
  Future<void> updateWeeklyOffer({
    required String id,
    required String name,
    required int price,
    required int discount,
    String? city,  // Make city optional for updates
  }) async {
    try {
      print('Updating weekly offer: $id');

      // Update data
      final offerData = {
        'name': name,
        'price': price,
        'discount': discount,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // If city is provided, validate and update it
      if (city != null) {
        final normalizedCity = city.toLowerCase();
        if (!_isValidCity(normalizedCity)) {
          throw Exception('Invalid city. Allowed cities are: ${allowedCities.join(", ")}');
        }
        offerData['city'] = normalizedCity;
      }

      // Update in Firestore
      await _firestore.collection(_collectionName).doc(id).update(offerData);

      print('Weekly offer updated successfully');
    } catch (e) {
      print('Error updating weekly offer: $e');
      throw e;
    }
  }

  // Delete a weekly offer
  Future<void> deleteWeeklyOffer(String id) async {
    try {
      print('Deleting weekly offer: $id');
      await _firestore.collection(_collectionName).doc(id).delete();
      print('Weekly offer deleted successfully');
    } catch (e) {
      print('Error deleting weekly offer: $e');
      throw e;
    }
  }

  // Sync cached offers to Firestore
  Future<void> syncCachedOffersToFirestore() async {
    try {
      print('Syncing cached offers to Firestore...');
      // This is a placeholder for any future sync functionality
      print('Sync completed');
    } catch (e) {
      print('Error syncing offers: $e');
      throw e;
    }
  }

  // Cache offers for offline use
  Future<void> _cacheOffers(List<Map<String, dynamic>> offers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedOffersKey, jsonEncode(offers));
    } catch (e) {
      print('Error caching offers: $e');
    }
  }

  // Get cached offers
  Future<List<Map<String, dynamic>>> _getCachedOffers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedOffersJson = prefs.getString(_cachedOffersKey);

      if (cachedOffersJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedOffersJson);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('Error getting cached offers: $e');
    }

    return []; // Return empty list if no cached offers or error
  }

  Future<void> acceptWeeklyOffer(String offerId, String professionalId, String professionalName) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      // Get the offer document
      final offerRef = _firestore.collection('weeklyOffers').doc(offerId);
      final offerDoc = await offerRef.get();
      
      if (!offerDoc.exists) {
        throw Exception('Weekly offer not found');
      }

      final offerData = offerDoc.data()!;
      
      // Get professional's service categories
      final professionalRef = _firestore.collection('professionals').doc(professionalId);
      final professionalDoc = await professionalRef.get();
      
      if (!professionalDoc.exists) {
        throw Exception('Professional not found');
      }

      final professionalData = professionalDoc.data()!;
      final serviceName = professionalData['serviceName'] as String? ?? '';
      final serviceCategories = (professionalData['serviceCategories'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toSet() ?? {};
      
      // Add weekly_offer to professional's service categories if not already present
      serviceCategories.add('weekly_offer');
      
      // Create a service booking for this weekly offer
      final bookingRef = _firestore.collection('serviceBookings').doc();
      final bookingData = {
        'serviceId': offerId,
        'serviceName': offerData['name'],
        'serviceCategory': 'weekly_offer',
        'serviceType': serviceName.toLowerCase(), // Use professional's main service type
        'professionalId': professionalId,
        'professionalName': professionalName,
        'customerId': offerData['customerId'],
        'customerName': offerData['customerName'],
        'customerPhone': offerData['customerPhone'],
        'price': offerData['price'],
        'discount': offerData['discount'],
        'finalPrice': (offerData['price'] as int) * (1 - (offerData['discount'] as int) / 100),
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'weeklyOfferId': offerId,
        'isWeeklyService': true,
        'professionalServiceCategories': serviceCategories.toList(), // Store the updated categories
      };
      
      // Update the weekly offer status
      batch.update(offerRef, {
        'status': 'accepted',
        'acceptedBy': professionalId,
        'acceptedByName': professionalName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'isActive': false,
        'serviceType': serviceName.toLowerCase(), // Store the professional's service type
      });
      
      // Update professional's service categories
      batch.update(professionalRef, {
        'serviceCategories': serviceCategories.toList(),
      });
      
      // Create the service booking
      batch.set(bookingRef, bookingData);
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error accepting weekly offer: $e');
      rethrow;
    }
  }
}
