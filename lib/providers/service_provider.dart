import 'package:flutter/foundation.dart';
import '../models/service.dart';

class ServiceProvider with ChangeNotifier {
  List<Service> _services = [];
  
  // Getter for all services
  List<Service> get services => _services;
  
  // Getter for weekly offers
  List<Service> get weeklyOffers => _services.where((service) => service.isWeeklyOffer).toList();
  
  // Getter for popular services
  List<Service> get popularServices => _services.where((service) => service.isPopular).toList();
  
  // Add a new service
  void addService(Service service) {
    _services.add(service);
    notifyListeners();
  }
  
  // Update an existing service
  void updateService(Service updatedService) {
    final index = _services.indexWhere((service) => service.id == updatedService.id);
    if (index >= 0) {
      _services[index] = updatedService;
      notifyListeners();
    }
  }
  
  // Delete a service
  void deleteService(String serviceId) {
    _services.removeWhere((service) => service.id == serviceId);
    notifyListeners();
  }
  
  // Toggle a service's weekly offer status
  void toggleWeeklyOffer(String serviceId, {double? discountPercentage}) {
    final index = _services.indexWhere((service) => service.id == serviceId);
    if (index >= 0) {
      final service = _services[index];
      _services[index] = service.copyWith(
        isWeeklyOffer: !service.isWeeklyOffer,
        discountPercentage: discountPercentage ?? service.discountPercentage,
      );
      notifyListeners();
    }
  }
  
  // Toggle a service's popular status
  void togglePopular(String serviceId) {
    final index = _services.indexWhere((service) => service.id == serviceId);
    if (index >= 0) {
      final service = _services[index];
      _services[index] = service.copyWith(isPopular: !service.isPopular);
      notifyListeners();
    }
  }
} 