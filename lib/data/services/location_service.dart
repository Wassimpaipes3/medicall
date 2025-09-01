import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Stream controllers for real-time updates
  final StreamController<UserLocation> _currentLocationController = 
      StreamController<UserLocation>.broadcast();
  final StreamController<List<HealthcareProvider>> _nearbyProvidersController = 
      StreamController<List<HealthcareProvider>>.broadcast();
  
  // Streams
  Stream<UserLocation> get currentLocationStream => _currentLocationController.stream;
  Stream<List<HealthcareProvider>> get nearbyProvidersStream => _nearbyProvidersController.stream;

  // Current state
  UserLocation? _currentLocation;
  List<SavedLocation> _savedLocations = [];
  StreamSubscription<Position>? _locationSubscription;

  UserLocation? get currentLocation => _currentLocation;
  List<SavedLocation> get savedLocations => _savedLocations;

  /// Initialize location service
  Future<void> initialize() async {
    await _loadSavedLocations();
    await _getCurrentLocationOnce();
  }

  /// Request location permissions
  Future<bool> requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // User needs to manually enable permissions in settings
        debugPrint('Location permissions denied forever. User needs to enable manually.');
        return false;
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting location permissions: $e');
      return false;
    }
  }

  /// Get current location once
  Future<UserLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final location = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      _currentLocation = location;
      _currentLocationController.add(location);

      // Get address for the location
      _updateLocationWithAddress(location);

      return location;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get current location once (internal)
  Future<void> _getCurrentLocationOnce() async {
    await getCurrentLocation();
  }

  /// Start watching location changes
  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    int intervalMs = 5000, // 5 seconds
  }) async {
    final hasPermission = await requestLocationPermissions();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        final location = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        );

        _currentLocation = location;
        _currentLocationController.add(location);
        _updateLocationWithAddress(location);
      },
      onError: (error) {
        debugPrint('Location tracking error: $error');
      },
    );
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Update location with address
  Future<void> _updateLocationWithAddress(UserLocation location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        
        final updatedLocation = location.copyWith(
          address: address,
          name: placemark.name,
        );

        _currentLocation = updatedLocation;
        _currentLocationController.add(updatedLocation);
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
    }
    return null;
  }

  /// Get coordinates from address
  Future<UserLocation?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return UserLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
    }
    return null;
  }

  /// Calculate distance between two locations (Haversine formula)
  double calculateDistance(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  /// Calculate bearing between two locations
  double calculateBearing(
    double lat1, double lon1, 
    double lat2, double lon2
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location is within geofence
  bool isWithinGeofence(
    UserLocation userLocation,
    UserLocation centerLocation,
    double radiusInKm,
  ) {
    final distance = calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      centerLocation.latitude,
      centerLocation.longitude,
    );
    return distance <= radiusInKm;
  }

  /// Save a location
  Future<void> saveLocation(SavedLocation location) async {
    _savedLocations.add(location);
    await _persistSavedLocations();
  }

  /// Remove a saved location
  Future<void> removeSavedLocation(String locationId) async {
    _savedLocations.removeWhere((location) => location.id == locationId);
    await _persistSavedLocations();
  }

  /// Get saved locations
  List<SavedLocation> getSavedLocations() {
    return List.from(_savedLocations);
  }

  /// Load saved locations from storage
  Future<void> _loadSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList('saved_locations') ?? [];
      
      _savedLocations = locationsJson
          .map((json) => SavedLocation.fromJson(Map<String, dynamic>.from(
              Uri.splitQueryString(json).map((key, value) => MapEntry(key, value))
            )))
          .toList();
    } catch (e) {
      debugPrint('Error loading saved locations: $e');
    }
  }

  /// Persist saved locations to storage
  Future<void> _persistSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = _savedLocations
          .map((location) => location.toJson().entries
              .map((entry) => '${entry.key}=${entry.value}')
              .join('&'))
          .toList();
      
      await prefs.setStringList('saved_locations', locationsJson);
    } catch (e) {
      debugPrint('Error persisting saved locations: $e');
    }
  }

  /// Get mock nearby providers for demo
  List<HealthcareProvider> getMockNearbyProviders(UserLocation patientLocation) {
    final providers = [
      HealthcareProvider(
        id: 'provider_1',
        name: 'Dr. Sarah Johnson',
        specialty: 'General Practitioner',
        currentLocation: UserLocation(
          latitude: patientLocation.latitude + 0.01,
          longitude: patientLocation.longitude + 0.01,
          timestamp: DateTime.now(),
        ),
        status: ProviderStatus.available,
        rating: 4.8,
        totalReviews: 245,
        profileImage: 'assets/images/doctor1.jpg',
        phoneNumber: '+1234567890',
        services: ['Consultation', 'Basic Checkup', 'Prescription'],
        pricing: {'consultation': 75.0, 'travel_fee': 15.0},
        distanceFromPatient: calculateDistance(
          patientLocation.latitude,
          patientLocation.longitude,
          patientLocation.latitude + 0.01,
          patientLocation.longitude + 0.01,
        ),
        estimatedArrivalMinutes: 15,
        lastLocationUpdate: DateTime.now(),
      ),
      HealthcareProvider(
        id: 'provider_2',
        name: 'Nurse Mary Williams',
        specialty: 'Registered Nurse',
        currentLocation: UserLocation(
          latitude: patientLocation.latitude - 0.005,
          longitude: patientLocation.longitude + 0.008,
          timestamp: DateTime.now(),
        ),
        status: ProviderStatus.available,
        rating: 4.9,
        totalReviews: 180,
        profileImage: 'assets/images/nurse1.jpg',
        phoneNumber: '+1234567891',
        services: ['Vaccination', 'Wound Care', 'Vital Signs'],
        pricing: {'vaccination': 50.0, 'wound_care': 60.0, 'travel_fee': 10.0},
        distanceFromPatient: calculateDistance(
          patientLocation.latitude,
          patientLocation.longitude,
          patientLocation.latitude - 0.005,
          patientLocation.longitude + 0.008,
        ),
        estimatedArrivalMinutes: 12,
        lastLocationUpdate: DateTime.now(),
      ),
      HealthcareProvider(
        id: 'provider_3',
        name: 'Dr. Michael Chen',
        specialty: 'Cardiologist',
        currentLocation: UserLocation(
          latitude: patientLocation.latitude + 0.015,
          longitude: patientLocation.longitude - 0.01,
          timestamp: DateTime.now(),
        ),
        status: ProviderStatus.busy,
        rating: 4.7,
        totalReviews: 320,
        profileImage: 'assets/images/doctor2.jpg',
        phoneNumber: '+1234567892',
        services: ['Cardiac Consultation', 'ECG', 'Blood Pressure Monitoring'],
        pricing: {'consultation': 120.0, 'ecg': 80.0, 'travel_fee': 20.0},
        distanceFromPatient: calculateDistance(
          patientLocation.latitude,
          patientLocation.longitude,
          patientLocation.latitude + 0.015,
          patientLocation.longitude - 0.01,
        ),
        estimatedArrivalMinutes: 25,
        lastLocationUpdate: DateTime.now(),
      ),
    ];

    _nearbyProvidersController.add(providers);
    return providers;
  }

  /// Calculate estimated arrival time
  int calculateEstimatedArrival(
    UserLocation from,
    UserLocation to,
    {double averageSpeedKmh = 30.0}
  ) {
    final distance = calculateDistance(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    
    final timeInHours = distance / averageSpeedKmh;
    return (timeInHours * 60).round(); // minutes
  }

  /// Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
    _currentLocationController.close();
    _nearbyProvidersController.close();
  }
}
