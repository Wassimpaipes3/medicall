import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_models.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';

class EnhancedProviderTrackingService {
  static final EnhancedProviderTrackingService _instance = 
      EnhancedProviderTrackingService._internal();
  factory EnhancedProviderTrackingService() => _instance;
  EnhancedProviderTrackingService._internal();

  // Stream controllers
  final StreamController<List<HealthcareProvider>> _nearbyProvidersController = 
      StreamController<List<HealthcareProvider>>.broadcast();
  final StreamController<HealthcareProvider> _providerLocationController = 
      StreamController<HealthcareProvider>.broadcast();
  final StreamController<TrackingUpdate> _trackingUpdateController = 
      StreamController<TrackingUpdate>.broadcast();

  // Streams
  Stream<List<HealthcareProvider>> get nearbyProvidersStream => 
      _nearbyProvidersController.stream;
  Stream<HealthcareProvider> get providerLocationStream => 
      _providerLocationController.stream;
  Stream<TrackingUpdate> get trackingUpdatesStream => 
      _trackingUpdateController.stream;

  // Current state
  List<HealthcareProvider> _nearbyProviders = [];
  HealthcareProvider? _activeProvider;
  UserLocation? _currentUserLocation;
  Timer? _trackingTimer;
  Timer? _providersTimer;

  // Distance calculation utility
  final Distance _distance = Distance();

  /// Initialize tracking service
  Future<void> initialize() async {
    await _getCurrentLocation();
    _startPeriodicUpdates();
  }

  /// Get current user location
  Future<UserLocation> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentUserLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );
      
      return _currentUserLocation!;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Fallback to Algiers city center
      _currentUserLocation = UserLocation(
        latitude: 36.7525,
        longitude: 3.0420,
        timestamp: DateTime.now(),
        accuracy: 1000.0,
      );
      return _currentUserLocation!;
    }
  }

  /// Get nearby healthcare providers
  Future<List<HealthcareProvider>> getNearbyProviders({
    required UserLocation patientLocation,
    double radiusInKm = 10.0,
    ServiceType? serviceType,
    Specialty? specialty,
  }) async {
    try {
      // Simulate API call - in real app, this would be a network request
      await Future.delayed(const Duration(milliseconds: 800));
      
      final providers = _generateMockProviders(
        patientLocation,
        radiusInKm,
        serviceType,
        specialty,
      );
      
      // Sort providers by distance (closest first)
      final sortedProviders = _sortProvidersByDistance(providers, patientLocation);
      
      _nearbyProviders = sortedProviders;
      _nearbyProvidersController.add(_nearbyProviders);
      
      return sortedProviders;
    } catch (e) {
      debugPrint('Error getting nearby providers: $e');
      return [];
    }
  }

  /// Sort providers by distance from patient location
  List<HealthcareProvider> _sortProvidersByDistance(
    List<HealthcareProvider> providers,
    UserLocation patientLocation,
  ) {
    final patientLatLng = LatLng(patientLocation.latitude, patientLocation.longitude);
    
    // Calculate distance for each provider and sort
    providers.sort((a, b) {
      if (a.currentLocation == null && b.currentLocation == null) return 0;
      if (a.currentLocation == null) return 1;
      if (b.currentLocation == null) return -1;
      
      final aDistance = _distance.as(
        LengthUnit.Meter,
        patientLatLng,
        LatLng(a.currentLocation!.latitude, a.currentLocation!.longitude),
      );
      
      final bDistance = _distance.as(
        LengthUnit.Meter,
        patientLatLng,
        LatLng(b.currentLocation!.latitude, b.currentLocation!.longitude),
      );
      
      return aDistance.compareTo(bDistance);
    });
    
    return providers;
  }

  /// Start tracking a specific provider
  Future<void> startProviderTracking(String providerId) async {
    final provider = _nearbyProviders
        .where((p) => p.id == providerId)
        .firstOrNull;
    
    if (provider != null) {
      _activeProvider = provider;
      _startProviderLocationUpdates();
    }
  }

  /// Stop tracking current provider
  void stopProviderTracking() {
    _activeProvider = null;
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  /// Start periodic provider location updates
  void _startProviderLocationUpdates() {
    _trackingTimer?.cancel();
    
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        if (_activeProvider != null && _currentUserLocation != null) {
          await _updateProviderLocation();
          await _sendTrackingUpdate();
        }
      },
    );
  }

  /// Start periodic nearby providers updates
  void _startPeriodicUpdates() {
    _providersTimer?.cancel();
    
    _providersTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) async {
        if (_currentUserLocation != null) {
          await getNearbyProviders(
            patientLocation: _currentUserLocation!,
          );
        }
      },
    );
  }

  /// Update provider location with realistic movement simulation
  Future<void> _updateProviderLocation() async {
    if (_activeProvider == null || _currentUserLocation == null) return;

    final currentProviderLoc = _activeProvider!.currentLocation;
    if (currentProviderLoc == null) return;

    final userLatLng = LatLng(
      _currentUserLocation!.latitude,
      _currentUserLocation!.longitude,
    );
    final providerLatLng = LatLng(
      currentProviderLoc.latitude,
      currentProviderLoc.longitude,
    );

    // Calculate distance to patient
    final distanceToPatient = _distance.as(
      LengthUnit.Meter,
      userLatLng,
      providerLatLng,
    );

    // Simulate provider movement toward patient
    final newLocation = _simulateProviderMovement(
      providerLatLng,
      userLatLng,
      distanceToPatient,
    );

    // Update provider status based on distance
    final newStatus = _determineProviderStatus(distanceToPatient);

    // Create updated provider
    _activeProvider = _activeProvider!.copyWith(
      currentLocation: UserLocation(
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
      ),
      status: newStatus,
      lastLocationUpdate: DateTime.now(),
    );

    // Emit update
    _providerLocationController.add(_activeProvider!);
  }

  /// Simulate realistic provider movement
  LatLng _simulateProviderMovement(
    LatLng providerLocation,
    LatLng patientLocation,
    double distanceToPatient,
  ) {
    // If very close, don't move much
    if (distanceToPatient < 100) {
      return _addSmallRandomMovement(providerLocation);
    }

    // Calculate bearing toward patient
    final bearing = _distance.bearing(providerLocation, patientLocation);
    
    // Move 50-100 meters toward patient (realistic speed)
    final moveDistance = math.min(
      distanceToPatient * 0.05, // Move 5% of remaining distance
      100.0, // Max 100 meters per update (3 seconds)
    );
    
    return _distance.offset(
      providerLocation,
      moveDistance,
      bearing,
    );
  }

  /// Add small random movement for nearby providers
  LatLng _addSmallRandomMovement(LatLng location) {
    final random = math.Random();
    final bearing = random.nextDouble() * 360;
    final distance = random.nextDouble() * 20; // Max 20 meters
    
    return _distance.offset(location, distance, bearing);
  }

  /// Determine provider status based on distance
  ProviderStatus _determineProviderStatus(double distanceInMeters) {
    if (distanceInMeters < 50) {
      return ProviderStatus.available; // Use available when at location
    } else if (distanceInMeters < 200) {
      return ProviderStatus.enRoute; // Use enRoute when near patient
    } else if (distanceInMeters < 2000) {
      return ProviderStatus.enRoute;
    } else {
      return ProviderStatus.available;
    }
  }

  /// Send comprehensive tracking update
  Future<void> _sendTrackingUpdate() async {
    if (_activeProvider == null || _currentUserLocation == null) return;

    final providerLatLng = LatLng(
      _activeProvider!.currentLocation!.latitude,
      _activeProvider!.currentLocation!.longitude,
    );
    final userLatLng = LatLng(
      _currentUserLocation!.latitude,
      _currentUserLocation!.longitude,
    );

    final distanceInMeters = _distance.as(
      LengthUnit.Meter,
      providerLatLng,
      userLatLng,
    );

    final eta = _calculateETA(distanceInMeters);

    final trackingUpdate = TrackingUpdate(
      providerId: _activeProvider!.id,
      providerLocation: _activeProvider!.currentLocation!,
      patientLocation: _currentUserLocation!,
      distanceInMeters: distanceInMeters,
      estimatedArrivalMinutes: eta,
      providerStatus: _activeProvider!.status,
      timestamp: DateTime.now(),
    );

    _trackingUpdateController.add(trackingUpdate);
  }

  /// Calculate realistic ETA
  int _calculateETA(double distanceInMeters) {
    // Average speed: 30 km/h in city, 50 km/h on highways
    const double avgSpeedKmh = 35.0;
    const double avgSpeedMps = avgSpeedKmh * 1000 / 3600; // m/s
    
    final timeInSeconds = distanceInMeters / avgSpeedMps;
    final timeInMinutes = (timeInSeconds / 60).ceil();
    
    // Add 2-5 minutes for traffic, parking, etc.
    final random = math.Random();
    return timeInMinutes + 2 + random.nextInt(4);
  }

  /// Generate mock providers for demonstration
  List<HealthcareProvider> _generateMockProviders(
    UserLocation patientLocation,
    double radiusInKm,
    ServiceType? serviceType,
    Specialty? specialty,
  ) {
    final random = math.Random();
    final providers = <HealthcareProvider>[];
    
    // Algerian doctor names and specialties
    final doctorNames = [
      'Dr. Ahmed Benali',
      'Dr. Fatima Zerrouki',
      'Dr. Mohamed Bouteflika',
      'Dr. Aisha Hamdi',
      'Dr. Youcef Mebarki',
      'Dr. Samira Belkacem',
    ];
    
    final nurseNames = [
      'Nurse Amina Djellab',
      'Nurse Karim Bouzid',
      'Nurse Leila Mansouri',
      'Nurse Omar Chellali',
      'Nurse Nadia Benaissa',
    ];

    // Filter specialties based on service type
    List<String> availableSpecialties;
    if (serviceType == ServiceType.doctor) {
      availableSpecialties = [
        'generalMedicine', 'cardiology', 'neurology', 'pediatrics', 
        'gynecology', 'orthopedics', 'dermatology', 'psychiatry'
      ];
    } else if (serviceType == ServiceType.nurse) {
      availableSpecialties = [
        'woundCare', 'medicationAdministration', 'vitalsMonitoring', 
        'injections', 'bloodDrawing', 'homeHealthAssessment'
      ];
    } else {
      // If no specific service type, include both
      availableSpecialties = [
        'generalMedicine', 'cardiology', 'woundCare', 'injections', 
        'vitalsMonitoring', 'medicationAdministration'
      ];
    }

    // Use specific specialty if provided
    if (specialty != null) {
      availableSpecialties = [specialty.toString().split('.').last];
    }

    final int providerCount = serviceType == null ? 8 : 5;
    
    for (int i = 0; i < providerCount; i++) {
      // Determine if this should be a doctor or nurse
      bool isDoctor;
      if (serviceType == ServiceType.doctor) {
        isDoctor = true;
      } else if (serviceType == ServiceType.nurse) {
        isDoctor = false;
      } else {
        // Mixed: random but balanced
        isDoctor = random.nextBool();
      }
      
      final names = isDoctor ? doctorNames : nurseNames;
      final name = names[random.nextInt(names.length)];
      
      // Generate location within radius
      final bearing = random.nextDouble() * 360;
      final distance = random.nextDouble() * radiusInKm * 1000; // meters
      
      final providerLatLng = _distance.offset(
        LatLng(patientLocation.latitude, patientLocation.longitude),
        distance,
        bearing,
      );

      // Select appropriate specialty for this provider type
      final selectedSpecialty = isDoctor 
          ? availableSpecialties.where((s) => 
              !['woundCare', 'injections', 'vitalsMonitoring', 'medicationAdministration', 'bloodDrawing', 'homeHealthAssessment'].contains(s)
            ).isNotEmpty 
              ? (availableSpecialties.where((s) => 
                  !['woundCare', 'injections', 'vitalsMonitoring', 'medicationAdministration', 'bloodDrawing', 'homeHealthAssessment'].contains(s)
                ).toList())[random.nextInt(availableSpecialties.where((s) => 
                  !['woundCare', 'injections', 'vitalsMonitoring', 'medicationAdministration', 'bloodDrawing', 'homeHealthAssessment'].contains(s)
                ).length)]
              : 'generalMedicine'
          : availableSpecialties.where((s) => 
              ['woundCare', 'injections', 'vitalsMonitoring', 'medicationAdministration', 'bloodDrawing', 'homeHealthAssessment'].contains(s)
            ).isNotEmpty 
              ? (availableSpecialties.where((s) => 
                  ['woundCare', 'injections', 'vitalsMonitoring', 'medicationAdministration', 'bloodDrawing', 'homeHealthAssessment'].contains(s)
                ).toList())[random.nextInt(availableSpecialties.where((s) => 
                  ['woundCare', 'injections', 'vitalsMonitoring', 'medicationAdministration', 'bloodDrawing', 'homeHealthAssessment'].contains(s)
                ).length)]
              : 'woundCare';

      providers.add(HealthcareProvider(
        id: 'provider_$i',
        name: name,
        specialty: selectedSpecialty,
        rating: 4.0 + random.nextDouble(),
        totalReviews: 10 + random.nextInt(100),
        profileImage: 'assets/images/doctor_${i % 5}.png',
        services: isDoctor 
            ? ['Consultation', 'Diagnosis', 'Treatment']
            : ['Wound Care', 'Injections', 'Vital Monitoring'],
        pricing: {
          'consultation': isDoctor ? 150.0 + random.nextInt(100) : 80.0 + random.nextInt(50),
          'home_visit': 50.0,
        },
        currentLocation: UserLocation(
          latitude: providerLatLng.latitude,
          longitude: providerLatLng.longitude,
          timestamp: DateTime.now(),
          accuracy: 5.0,
        ),
        status: ProviderStatus.values[random.nextInt(3)], // available, enRoute, busy
        phoneNumber: '+213${random.nextInt(100000000) + 500000000}',
        lastLocationUpdate: DateTime.now(),
      ));
    }

    return providers;
  }

  /// Dispose resources
  void dispose() {
    _trackingTimer?.cancel();
    _providersTimer?.cancel();
    _nearbyProvidersController.close();
    _providerLocationController.close();
    _trackingUpdateController.close();
  }
}

/// Tracking update model
class TrackingUpdate {
  final String providerId;
  final UserLocation providerLocation;
  final UserLocation patientLocation;
  final double distanceInMeters;
  final int estimatedArrivalMinutes;
  final ProviderStatus providerStatus;
  final DateTime timestamp;

  TrackingUpdate({
    required this.providerId,
    required this.providerLocation,
    required this.patientLocation,
    required this.distanceInMeters,
    required this.estimatedArrivalMinutes,
    required this.providerStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'providerLocation': providerLocation.toJson(),
      'patientLocation': patientLocation.toJson(),
      'distanceInMeters': distanceInMeters,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'providerStatus': providerStatus.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
