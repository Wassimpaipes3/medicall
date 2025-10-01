import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../routes/app_routes.dart';
import '../services/appointment_service.dart';
import '../services/provider_location_service.dart';

/// Integration helper that combines appointment and location services
class AppointmentLocationIntegration {
  
  /// When provider accepts an appointment, update both appointment and start location tracking
  static Future<bool> acceptAppointmentWithLocationTracking({
    required String appointmentId,
    required String providerId,
    String? notes,
  }) async {
    try {
      print('🏥 Provider $providerId accepting appointment $appointmentId');

      // Step 1: Get provider's current GPS location
      final position = await ProviderLocationService.getCurrentLocationOnce();
      if (position == null) {
        throw Exception('Unable to get current GPS location. Please check location permissions.');
      }

      final providerLocation = GeoPoint(position.latitude, position.longitude);
      print('📍 Provider location: ${position.latitude}, ${position.longitude}');

      // Step 2: Accept the appointment with provider's location
      await AppointmentService.acceptAppointmentAndSetLocation(
        appointmentId: appointmentId,
        providerId: providerId,
        providerLocation: providerLocation,
        providerNotes: notes ?? 'On my way to your location!',
      );

      // Step 3: Set provider as available and start real-time location tracking
      await ProviderLocationService.setProviderAvailability(true);
      
      print('✅ Appointment accepted and location tracking started');
      return true;

    } catch (e) {
      print('❌ Error accepting appointment with location: $e');
      return false;
    }
  }

  /// When provider completes an appointment, update status and optionally stop location tracking
  static Future<bool> completeAppointmentAndStopTracking({
    required String appointmentId,
    required String providerId,
    bool stopLocationTracking = false,
    String? completionNotes,
  }) async {
    try {
      print('✅ Provider $providerId completing appointment $appointmentId');

      // Update appointment status to completed
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (completionNotes != null) 'completionNotes': completionNotes,
      });

      // Optionally stop location tracking if provider is going offline
      if (stopLocationTracking) {
        await ProviderLocationService.setProviderAvailability(false);
        print('🛑 Location tracking stopped - provider is now offline');
      } else {
        print('📍 Location tracking continues - provider remains available');
      }

      return true;

    } catch (e) {
      print('❌ Error completing appointment: $e');
      return false;
    }
  }

  /// Get nearby available providers with real-time locations
  static Future<List<Map<String, dynamic>>> getNearbyAvailableProviders({
    required GeoPoint patientLocation,
    double radiusInKm = 10.0,
  }) async {
    try {
      // Query available providers
      final querySnapshot = await FirebaseFirestore.instance
          .collection('professionnels')
          .where('disponible', isEqualTo: true)
          .where('isLocationActive', isEqualTo: true)
          .get();

      final availableProviders = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final currentLocation = data['currentLocation'] as GeoPoint?;
        
        if (currentLocation != null) {
          // Calculate distance between patient and provider
          final distance = Geolocator.distanceBetween(
            patientLocation.latitude,
            patientLocation.longitude,
            currentLocation.latitude,
            currentLocation.longitude,
          ) / 1000; // Convert to kilometers

          if (distance <= radiusInKm) {
            availableProviders.add({
              'providerId': doc.id,
              'name': data['name'] ?? 'Unknown Provider',
              'specialty': data['specialty'] ?? 'General',
              'currentLocation': currentLocation,
              'distanceKm': distance.round(),
              'lastUpdated': data['lastUpdated'],
              'rating': data['rating'] ?? 0.0,
            });
          }
        }
      }

      // Sort by distance (closest first)
      availableProviders.sort((a, b) => 
          (a['distanceKm'] as int).compareTo(b['distanceKm'] as int));

      print('📍 Found ${availableProviders.length} nearby providers within ${radiusInKm}km');
      return availableProviders;

    } catch (e) {
      print('❌ Error getting nearby providers: $e');
      return [];
    }
  }

  /// Monitor appointment status and automatically handle location tracking
  static Stream<Map<String, dynamic>> monitorAppointmentWithLocation(String appointmentId) {
    return FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return {'error': 'Appointment not found'};
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      final providerId = data['idpro'] as String?;

      // Return appointment data with location info
      return {
        ...data,
        'appointmentId': appointmentId,
        'hasProvider': providerId?.isNotEmpty == true,
        'isTracking': status == 'accepted' && providerId?.isNotEmpty == true,
      };
    });
  }

  /// Get real-time provider location for tracking during appointment
  static Stream<GeoPoint?> trackProviderLocation(String providerId) {
    return FirebaseFirestore.instance
        .collection('professionnels')
        .doc(providerId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final isLocationActive = data['isLocationActive'] as bool? ?? false;
      
      if (!isLocationActive) return null;
      
      return data['currentLocation'] as GeoPoint?;
    });
  }
}

/// Example usage class showing complete workflow
class ExampleProviderWorkflow {
  
  /// Complete provider workflow example
  static Future<void> demonstrateWorkflow() async {
    const appointmentId = 'example_appointment_123';
    const providerId = 'provider_456';
    
    try {
      print('🚀 Starting provider workflow demonstration...\n');

      // 1. Provider goes online and starts location tracking
      print('1️⃣ Provider going online...');
      await ProviderLocationService.setProviderAvailability(true);
      
      // 2. Provider accepts an appointment
      print('2️⃣ Accepting appointment...');
      final acceptSuccess = await AppointmentLocationIntegration
          .acceptAppointmentWithLocationTracking(
        appointmentId: appointmentId,
        providerId: providerId,
        notes: 'I will be there in 15 minutes!',
      );
      
      if (!acceptSuccess) {
        throw Exception('Failed to accept appointment');
      }

      // 3. Simulate some time passing with location updates
      print('3️⃣ Simulating service delivery (location tracking active)...');
      await Future.delayed(const Duration(seconds: 5));
      
      // 4. Provider completes appointment
      print('4️⃣ Completing appointment...');
      final completeSuccess = await AppointmentLocationIntegration
          .completeAppointmentAndStopTracking(
        appointmentId: appointmentId,
        providerId: providerId,
        stopLocationTracking: false, // Keep tracking for next appointments
        completionNotes: 'Service completed successfully!',
      );
      
      if (!completeSuccess) {
        throw Exception('Failed to complete appointment');
      }

      print('✅ Workflow completed successfully!\n');

    } catch (e) {
      print('❌ Workflow failed: $e\n');
    }
  }

  /// Example of finding nearby providers
  static Future<void> demonstrateNearbyProviders() async {
    print('🔍 Searching for nearby providers...\n');
    
    // Example patient location (Algiers)
    const patientLocation = GeoPoint(36.7538, 3.0588);
    
    final providers = await AppointmentLocationIntegration
        .getNearbyAvailableProviders(
      patientLocation: patientLocation,
      radiusInKm: 15.0,
    );
    
    if (providers.isEmpty) {
      print('😔 No providers found nearby\n');
      return;
    }
    
    print('📍 Found ${providers.length} nearby providers:\n');
    for (final provider in providers) {
      print('👨‍⚕️ ${provider['name']}');
      print('   Specialty: ${provider['specialty']}');
      print('   Distance: ${provider['distanceKm']}km away');
      print('   Rating: ${provider['rating']}/5.0');
      print('   Location: ${provider['currentLocation']}\n');
    }
  }
}

/*
=== INTEGRATION EXAMPLES ===

// 1. In your provider app main screen:
class ProviderMainScreen extends StatefulWidget {
  @override
  _ProviderMainScreenState createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndStartLocationTracking();
  }

  Future<void> _checkAndStartLocationTracking() async {
    final isAvailable = await ProviderLocationService.isProviderAvailable();
    if (isAvailable) {
      ProviderLocationService.startLocationUpdates();
    }
  }

  @override
  void dispose() {
    ProviderLocationService.dispose();
    super.dispose();
  }
}

// 2. When provider accepts appointment:
Future<void> handleAppointmentAcceptance(String appointmentId) async {
  final success = await AppointmentLocationIntegration
      .acceptAppointmentWithLocationTracking(
    appointmentId: appointmentId,
    providerId: FirebaseAuth.instance.currentUser!.uid,
    notes: 'On my way!',
  );
  
  if (success) {
    // Show success message, navigate to appointment details
    Navigator.pushNamed(context, AppRoutes.tracking, arguments: {
      'appointmentId': appointmentId,
    });
  }
}

// 3. Monitor appointment in patient app:
class PatientAppointmentTracking extends StatelessWidget {
  final String appointmentId;

  const PatientAppointmentTracking({required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AppointmentLocationIntegration
          .monitorAppointmentWithLocation(appointmentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final appointment = snapshot.data!;
        final providerId = appointment['idpro'] as String?;

        return Column(
          children: [
            Text('Status: ${appointment['status']}'),
            
            if (providerId?.isNotEmpty == true) ...[
              Text('Provider: $providerId'),
              
              // Show real-time provider location
              StreamBuilder<GeoPoint?>(
                stream: AppointmentLocationIntegration
                    .trackProviderLocation(providerId!),
                builder: (context, locationSnapshot) {
                  final location = locationSnapshot.data;
                  if (location == null) {
                    return Text('Provider location not available');
                  }
                  
                  return Text(
                    'Provider location: ${location.latitude.toStringAsFixed(4)}, '
                    '${location.longitude.toStringAsFixed(4)}'
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

*/