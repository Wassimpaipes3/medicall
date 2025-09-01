import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

class ProviderTrackingService extends ChangeNotifier {
  static final ProviderTrackingService _instance = ProviderTrackingService._internal();
  factory ProviderTrackingService() => _instance;
  ProviderTrackingService._internal();

  Timer? _locationTimer;
  ProviderLocation? _currentLocation;
  bool _isTracking = false;
  String? _activeProviderId;

  ProviderLocation? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  String? get activeProviderId => _activeProviderId;

  void startTracking(String providerId, ProviderLocation initialLocation) {
    _activeProviderId = providerId;
    _currentLocation = initialLocation;
    _isTracking = true;
    
    // Simulate real-time location updates every 3 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _simulateLocationUpdate();
    });
    
    notifyListeners();
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    _activeProviderId = null;
    _currentLocation = null;
    notifyListeners();
  }

  void _simulateLocationUpdate() {
    if (_currentLocation == null) return;

    // Simulate movement with random small changes
    final random = Random();
    final latDelta = (random.nextDouble() - 0.5) * 0.001; // Small movement
    final lngDelta = (random.nextDouble() - 0.5) * 0.001;

    _currentLocation = _currentLocation!.copyWith(
      latitude: _currentLocation!.latitude + latDelta,
      longitude: _currentLocation!.longitude + lngDelta,
      lastUpdated: DateTime.now(),
    );

    notifyListeners();
  }

  // Get mock provider data
  List<HealthcareProvider> getMockProviders() {
    return [
      HealthcareProvider(
        id: 'provider_1',
        name: 'Dr. Sarah Johnson',
        specialty: 'Cardiologist',
        rating: 4.9,
        estimatedArrival: DateTime.now().add(const Duration(minutes: 15)),
        vehicleType: 'Medical Van',
        licensePlate: 'MED-001',
        phoneNumber: '+1 (555) 123-4567',
        currentLocation: ProviderLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          address: 'En route to your location',
          lastUpdated: DateTime.now(),
        ),
      ),
      HealthcareProvider(
        id: 'provider_2',
        name: 'Dr. Michael Chen',
        specialty: 'Emergency Medicine',
        rating: 4.8,
        estimatedArrival: DateTime.now().add(const Duration(minutes: 8)),
        vehicleType: 'Ambulance',
        licensePlate: 'AMB-205',
        phoneNumber: '+1 (555) 987-6543',
        currentLocation: ProviderLocation(
          latitude: 37.7849,
          longitude: -122.4294,
          address: '2 blocks away',
          lastUpdated: DateTime.now(),
        ),
      ),
    ];
  }
}

class HealthcareProvider {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final DateTime estimatedArrival;
  final String vehicleType;
  final String licensePlate;
  final String phoneNumber;
  final ProviderLocation currentLocation;

  HealthcareProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.estimatedArrival,
    required this.vehicleType,
    required this.licensePlate,
    required this.phoneNumber,
    required this.currentLocation,
  });
}

class ProviderLocation {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime lastUpdated;

  ProviderLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.lastUpdated,
  });

  ProviderLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    DateTime? lastUpdated,
  }) {
    return ProviderLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
