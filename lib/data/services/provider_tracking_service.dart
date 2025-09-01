import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/location_models.dart';
import 'location_service.dart';

class ProviderTrackingService {
  static final ProviderTrackingService _instance = ProviderTrackingService._internal();
  factory ProviderTrackingService() => _instance;
  ProviderTrackingService._internal();

  final LocationService _locationService = LocationService();
  
  // Stream controllers for real-time updates
  final StreamController<List<HealthcareProvider>> _nearbyProvidersController = 
      StreamController<List<HealthcareProvider>>.broadcast();
  final StreamController<HealthcareProvider> _providerLocationController = 
      StreamController<HealthcareProvider>.broadcast();
  final StreamController<Appointment> _appointmentUpdatesController = 
      StreamController<Appointment>.broadcast();

  // Streams
  Stream<List<HealthcareProvider>> get nearbyProvidersStream => _nearbyProvidersController.stream;
  Stream<HealthcareProvider> get providerLocationStream => _providerLocationController.stream;
  Stream<Appointment> get appointmentUpdatesStream => _appointmentUpdatesController.stream;

  // Current state
  List<HealthcareProvider> _nearbyProviders = [];
  final Map<String, Timer> _providerTrackingTimers = {};
  final Map<String, Appointment> _activeAppointments = {};

  List<HealthcareProvider> get nearbyProviders => _nearbyProviders;

  /// Get nearby providers based on patient location
  Future<List<HealthcareProvider>> getNearbyProviders({
    required UserLocation patientLocation,
    double radiusInKm = 10.0,
    List<String>? specialties,
    ProviderStatus? statusFilter,
  }) async {
    try {
      // In a real app, this would make an API call
      // For demo, we'll use mock data
      final allProviders = _generateMockProviders(patientLocation);
      
      // Filter providers based on criteria
      final filteredProviders = allProviders.where((provider) {
        // Distance filter
        if (provider.distanceFromPatient != null && 
            provider.distanceFromPatient! > radiusInKm) {
          return false;
        }
        
        // Specialty filter
        if (specialties != null && specialties.isNotEmpty &&
            !specialties.contains(provider.specialty)) {
          return false;
        }
        
        // Status filter
        if (statusFilter != null && provider.status != statusFilter) {
          return false;
        }
        
        return true;
      }).toList();

      // Sort by distance
      filteredProviders.sort((a, b) => 
        (a.distanceFromPatient ?? double.infinity)
        .compareTo(b.distanceFromPatient ?? double.infinity));

      _nearbyProviders = filteredProviders;
      _nearbyProvidersController.add(filteredProviders);

      return filteredProviders;
    } catch (e) {
      debugPrint('Error getting nearby providers: $e');
      return [];
    }
  }

  /// Track a specific provider's location
  void startTrackingProvider(String providerId) {
    // Cancel existing timer if any
    _providerTrackingTimers[providerId]?.cancel();
    
    // Start periodic tracking
    _providerTrackingTimers[providerId] = Timer.periodic(
      const Duration(seconds: 5), // Update every 5 seconds
      (timer) => _updateProviderLocation(providerId),
    );
  }

  /// Stop tracking a provider
  void stopTrackingProvider(String providerId) {
    _providerTrackingTimers[providerId]?.cancel();
    _providerTrackingTimers.remove(providerId);
  }

  /// Update provider location (mock implementation)
  void _updateProviderLocation(String providerId) {
    final provider = _nearbyProviders.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw StateError('Provider not found'),
    );

    if (_nearbyProviders.any((p) => p.id == providerId)) {
      // Simulate location update with small random movement
      final random = Random();
      final latOffset = (random.nextDouble() - 0.5) * 0.001; // ~100m
      final lngOffset = (random.nextDouble() - 0.5) * 0.001;

      final newLocation = UserLocation(
        latitude: provider.currentLocation!.latitude + latOffset,
        longitude: provider.currentLocation!.longitude + lngOffset,
        timestamp: DateTime.now(),
      );

      final updatedProvider = provider.copyWith(
        currentLocation: newLocation,
        lastLocationUpdate: DateTime.now(),
      );

      // Update in the list
      final index = _nearbyProviders.indexWhere((p) => p.id == providerId);
      if (index != -1) {
        _nearbyProviders[index] = updatedProvider;
        _providerLocationController.add(updatedProvider);
      }

      // Update active appointments
      for (final appointment in _activeAppointments.values) {
        if (appointment.providerId == providerId) {
          final updatedAppointment = appointment.copyWith(
            providerCurrentLocation: newLocation,
            estimatedArrivalMinutes: _locationService.calculateEstimatedArrival(
              newLocation,
              appointment.patientLocation,
            ),
          );
          
          _activeAppointments[appointment.id] = updatedAppointment;
          _appointmentUpdatesController.add(updatedAppointment);
        }
      }
    }
  }

  /// Match patient with best available provider
  HealthcareProvider? matchPatientWithProvider({
    required UserLocation patientLocation,
    required String serviceType,
    String? preferredSpecialty,
  }) {
    if (_nearbyProviders.isEmpty) return null;

    // Filter available providers
    final availableProviders = _nearbyProviders
        .where((provider) => provider.status == ProviderStatus.available)
        .where((provider) => provider.services.contains(serviceType))
        .toList();

    if (availableProviders.isEmpty) return null;

    // Prefer specialty if specified
    if (preferredSpecialty != null) {
      final specialtyProviders = availableProviders
          .where((provider) => provider.specialty == preferredSpecialty)
          .toList();
      
      if (specialtyProviders.isNotEmpty) {
        return specialtyProviders.first; // Closest with preferred specialty
      }
    }

    // Return closest available provider
    return availableProviders.first;
  }

  /// Update provider status
  void updateProviderStatus(String providerId, ProviderStatus newStatus) {
    final index = _nearbyProviders.indexWhere((p) => p.id == providerId);
    if (index != -1) {
      _nearbyProviders[index] = _nearbyProviders[index].copyWith(
        status: newStatus,
        lastLocationUpdate: DateTime.now(),
      );
      
      _nearbyProvidersController.add(_nearbyProviders);
      _providerLocationController.add(_nearbyProviders[index]);
    }
  }

  /// Create appointment and start tracking
  Future<Appointment> createAppointment({
    required String patientId,
    required String providerId,
    required UserLocation patientLocation,
    required DateTime scheduledDateTime,
    required String serviceType,
    required Map<String, dynamic> pricing,
    String? notes,
  }) async {
    final provider = _nearbyProviders.firstWhere(
      (p) => p.id == providerId,
      orElse: () => throw ArgumentError('Provider not found'),
    );

    final appointment = Appointment(
      id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      providerId: providerId,
      provider: provider,
      patientLocation: patientLocation,
      scheduledDateTime: scheduledDateTime,
      status: AppointmentStatus.confirmed,
      serviceType: serviceType,
      pricing: pricing,
      notes: notes,
      providerCurrentLocation: provider.currentLocation,
      estimatedArrivalMinutes: provider.estimatedArrivalMinutes,
    );

    _activeAppointments[appointment.id] = appointment;
    
    // Start tracking the provider
    startTrackingProvider(providerId);
    
    // Update provider status to busy
    updateProviderStatus(providerId, ProviderStatus.busy);

    _appointmentUpdatesController.add(appointment);
    return appointment;
  }

  /// Provider starts journey to patient
  void providerStartedJourney(String appointmentId) {
    final appointment = _activeAppointments[appointmentId];
    if (appointment != null) {
      final updatedAppointment = appointment.copyWith(
        status: AppointmentStatus.inProgress,
        providerDepartedAt: DateTime.now(),
      );
      
      _activeAppointments[appointmentId] = updatedAppointment;
      updateProviderStatus(appointment.providerId, ProviderStatus.enRoute);
      _appointmentUpdatesController.add(updatedAppointment);
    }
  }

  /// Provider arrived at patient location
  void providerArrived(String appointmentId) {
    final appointment = _activeAppointments[appointmentId];
    if (appointment != null) {
      final updatedAppointment = appointment.copyWith(
        providerArrivedAt: DateTime.now(),
        estimatedArrivalMinutes: 0,
      );
      
      _activeAppointments[appointmentId] = updatedAppointment;
      _appointmentUpdatesController.add(updatedAppointment);
    }
  }

  /// Complete appointment
  void completeAppointment(String appointmentId) {
    final appointment = _activeAppointments[appointmentId];
    if (appointment != null) {
      final updatedAppointment = appointment.copyWith(
        status: AppointmentStatus.completed,
        completedAt: DateTime.now(),
      );
      
      _activeAppointments[appointmentId] = updatedAppointment;
      
      // Stop tracking provider
      stopTrackingProvider(appointment.providerId);
      
      // Update provider status back to available
      updateProviderStatus(appointment.providerId, ProviderStatus.available);
      
      _appointmentUpdatesController.add(updatedAppointment);
      _activeAppointments.remove(appointmentId);
    }
  }

  /// Cancel appointment
  void cancelAppointment(String appointmentId) {
    final appointment = _activeAppointments[appointmentId];
    if (appointment != null) {
      final updatedAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
      );
      
      _activeAppointments[appointmentId] = updatedAppointment;
      
      // Stop tracking provider
      stopTrackingProvider(appointment.providerId);
      
      // Update provider status back to available
      updateProviderStatus(appointment.providerId, ProviderStatus.available);
      
      _appointmentUpdatesController.add(updatedAppointment);
      _activeAppointments.remove(appointmentId);
    }
  }

  /// Get active appointments
  List<Appointment> getActiveAppointments() {
    return _activeAppointments.values.toList();
  }

  /// Generate mock providers for demo
  List<HealthcareProvider> _generateMockProviders(UserLocation patientLocation) {
    final random = Random();
    final providers = <HealthcareProvider>[];

    final specialties = [
      'General Practitioner',
      'Registered Nurse',
      'Cardiologist',
      'Pediatrician',
      'Physical Therapist',
      'Mental Health Counselor',
    ];

    final names = [
      'Dr. Sarah Johnson', 'Dr. Michael Chen', 'Dr. Emily Davis',
      'Nurse Mary Williams', 'Nurse John Smith', 'Nurse Lisa Brown',
      'Dr. David Wilson', 'Dr. Jennifer Garcia', 'Dr. Robert Martinez',
    ];

    for (int i = 0; i < 8; i++) {
      final latOffset = (random.nextDouble() - 0.5) * 0.03; // ~3km radius
      final lngOffset = (random.nextDouble() - 0.5) * 0.03;
      
      final providerLocation = UserLocation(
        latitude: patientLocation.latitude + latOffset,
        longitude: patientLocation.longitude + lngOffset,
        timestamp: DateTime.now(),
      );

      final distance = _locationService.calculateDistance(
        patientLocation.latitude,
        patientLocation.longitude,
        providerLocation.latitude,
        providerLocation.longitude,
      );

      final estimatedArrival = _locationService.calculateEstimatedArrival(
        providerLocation,
        patientLocation,
      );

      providers.add(HealthcareProvider(
        id: 'provider_$i',
        name: names[i % names.length],
        specialty: specialties[i % specialties.length],
        currentLocation: providerLocation,
        status: _getRandomStatus(),
        rating: 4.0 + (random.nextDouble() * 1.0), // 4.0 - 5.0
        totalReviews: 50 + random.nextInt(300),
        profileImage: 'assets/images/provider$i.jpg',
        phoneNumber: '+1234567${random.nextInt(999).toString().padLeft(3, '0')}',
        services: _getServicesForSpecialty(specialties[i % specialties.length]),
        pricing: _getPricingForSpecialty(specialties[i % specialties.length]),
        distanceFromPatient: distance,
        estimatedArrivalMinutes: estimatedArrival,
        lastLocationUpdate: DateTime.now(),
      ));
    }

    return providers;
  }

  ProviderStatus _getRandomStatus() {
    final random = Random();
    final statuses = [
      ProviderStatus.available,
      ProviderStatus.available, // More available providers
      ProviderStatus.available,
      ProviderStatus.busy,
      ProviderStatus.offline,
    ];
    return statuses[random.nextInt(statuses.length)];
  }

  List<String> _getServicesForSpecialty(String specialty) {
    switch (specialty) {
      case 'General Practitioner':
        return ['Consultation', 'Basic Checkup', 'Prescription', 'Vaccination'];
      case 'Registered Nurse':
        return ['Vaccination', 'Wound Care', 'Vital Signs', 'Medication Administration'];
      case 'Cardiologist':
        return ['Cardiac Consultation', 'ECG', 'Blood Pressure Monitoring'];
      case 'Pediatrician':
        return ['Child Checkup', 'Vaccination', 'Growth Assessment'];
      case 'Physical Therapist':
        return ['Physical Assessment', 'Exercise Therapy', 'Mobility Training'];
      case 'Mental Health Counselor':
        return ['Counseling Session', 'Mental Health Assessment', 'Therapy'];
      default:
        return ['General Consultation'];
    }
  }

  Map<String, double> _getPricingForSpecialty(String specialty) {
    switch (specialty) {
      case 'General Practitioner':
        return {'consultation': 75.0, 'checkup': 50.0, 'travel_fee': 15.0};
      case 'Registered Nurse':
        return {'vaccination': 40.0, 'wound_care': 60.0, 'travel_fee': 10.0};
      case 'Cardiologist':
        return {'consultation': 120.0, 'ecg': 80.0, 'travel_fee': 20.0};
      case 'Pediatrician':
        return {'consultation': 85.0, 'checkup': 65.0, 'travel_fee': 15.0};
      case 'Physical Therapist':
        return {'assessment': 90.0, 'therapy': 100.0, 'travel_fee': 20.0};
      case 'Mental Health Counselor':
        return {'counseling': 110.0, 'assessment': 95.0, 'travel_fee': 15.0};
      default:
        return {'consultation': 75.0, 'travel_fee': 15.0};
    }
  }

  /// Dispose resources
  void dispose() {
    for (final timer in _providerTrackingTimers.values) {
      timer.cancel();
    }
    _providerTrackingTimers.clear();
    _nearbyProvidersController.close();
    _providerLocationController.close();
    _appointmentUpdatesController.close();
  }
}
