import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ServicePersistenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminServicesKey = 'admin_services_cache';
  
  // Load all admin services from Firestore
  Future<List<Map<String, dynamic>>> loadAdminServices() async {
    try {
      print('Loading admin services from Firestore');
      
      // Check if this is a fresh install or reinstall
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstRun = prefs.getBool('first_run') ?? true;
      
      // Always try to get services from Firestore first
      final snapshot = await _firestore.collection('services').get();
      
      if (snapshot.docs.isNotEmpty) {
        final services = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        print('Loaded ${services.length} admin services from Firestore');
        
        // Cache the services for offline use
        await _cacheServices(services);
        
        return services;
      } else {
        // Always try to get from cache, even on first run
        final cachedServices = await _getCachedServices();
        print('No admin services in Firestore, returning ${cachedServices.length} cached services');
        return cachedServices;
      }
    } catch (e) {
      print('Error loading admin services from Firestore: $e');
      // On error, try to load from cache
      final cachedServices = await _getCachedServices();
      print('Returning ${cachedServices.length} cached admin services after Firestore error');
      return cachedServices;
    }
  }
  
  // Cache services for offline use
  Future<void> _cacheServices(List<Map<String, dynamic>> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminServicesKey, jsonEncode(services));
      print('Cached ${services.length} admin services to SharedPreferences');
    } catch (e) {
      print('Error caching admin services: $e');
    }
  }
  
  // Get cached services
  Future<List<Map<String, dynamic>>> _getCachedServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedServicesJson = prefs.getString(_adminServicesKey);
      
      if (cachedServicesJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedServicesJson);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('Error getting cached admin services: $e');
    }
    
    return []; // Return empty list if no cached services or error
  }
  
  // Add a new service
  Future<void> addService(Map<String, dynamic> service) async {
    try {
      print('Adding admin service: ${service['name']}');
      
      // Add timestamp
      service['createdAt'] = FieldValue.serverTimestamp();
      
      // Save to Firestore
      final docRef = await _firestore.collection('services').add(service);
      
      // Get the service with the new ID
      final newService = {...service, 'id': docRef.id};
      
      // Update the cache
      final cachedServices = await _getCachedServices();
      cachedServices.add(newService);
      await _cacheServices(cachedServices);
      
      print('Admin service added successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding admin service: $e');
      throw e;
    }
  }
  
  // Delete a service
  Future<void> deleteService(String id) async {
    try {
      print('Deleting admin service: $id');
      
      // Delete from Firestore
      await _firestore.collection('services').doc(id).delete();
      
      // Update the cache
      final cachedServices = await _getCachedServices();
      final updatedCache = cachedServices.where((service) => service['id'] != id).toList();
      await _cacheServices(updatedCache);
      
      print('Admin service deleted successfully');
    } catch (e) {
      print('Error deleting admin service: $e');
      throw e;
    }
  }
  
  // Clear the service cache
  Future<void> clearServiceCache() async {
    try {
      print('Clearing admin services cache');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminServicesKey);
      print('Admin services cache cleared successfully');
    } catch (e) {
      print('Error clearing admin services cache: $e');
    }
  }
  
  // Sync cached services to Firestore
  Future<void> syncCachedServicesToFirestore() async {
    try {
      print('Syncing cached services to Firestore...');
      
      // Get cached services
      final cachedServices = await _getCachedServices();
      if (cachedServices.isEmpty) {
        print('No cached services to sync');
        return;
      }
      
      print('Found ${cachedServices.length} cached services to sync');
      
      // For each cached service, check if it exists in Firestore
      for (final service in cachedServices) {
        // Skip services that don't have an ID
        if (!service.containsKey('id') || service['id'] == null) {
          continue;
        }
        
        final serviceId = service['id'];
        
        try {
          // Check if the service exists in Firestore
          final docSnapshot = await _firestore.collection('services').doc(serviceId).get();
          
          if (!docSnapshot.exists) {
            // If the service doesn't exist in Firestore, add it
            print('Syncing service ${service['name']} to Firestore');
            
            // Create a copy of the service without the ID field
            final serviceData = Map<String, dynamic>.from(service);
            serviceData.remove('id');
            
            // Add timestamp if it doesn't exist
            if (!serviceData.containsKey('createdAt')) {
              serviceData['createdAt'] = FieldValue.serverTimestamp();
            }
            
            // Add the service to Firestore with the same ID
            await _firestore.collection('services').doc(serviceId).set(serviceData);
          }
        } catch (e) {
          print('Error syncing service $serviceId: $e');
        }
      }
      
      print('Service sync completed');
    } catch (e) {
      print('Error syncing cached services to Firestore: $e');
    }
  }
} 