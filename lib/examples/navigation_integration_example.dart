import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/maps/navigation_map_widget.dart';
import '../screens/navigation/navigation_example_screen.dart';

/// Example showing how to use the navigation map widget
/// This demonstrates integration with your existing medical app
class NavigationIntegrationExample extends StatefulWidget {
  const NavigationIntegrationExample({super.key});

  @override
  State<NavigationIntegrationExample> createState() => _NavigationIntegrationExampleState();
}

class _NavigationIntegrationExampleState extends State<NavigationIntegrationExample> {
  
  // Sample locations (replace with real data from Firestore)
  final LatLng patientLocation = const LatLng(36.7538, 3.0588); // Algiers
  final LatLng providerLocation = const LatLng(36.7400, 3.0500); // Nearby location
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Map Examples'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Example 1: Basic Navigation Map
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Basic Navigation Map',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shows basic navigation with route, markers, and controls.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Basic Navigation'),
                              ),
                              body: NavigationMapWidget(
                                patientLocation: patientLocation,
                                providerLocation: providerLocation,
                                showNavigationMode: true,
                                onProviderLocationUpdate: (newLocation, heading) {
                                  print('Provider moved to: $newLocation (heading: $heading°)');
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Basic Navigation'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Example 2: Full Navigation Experience
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2. Full Navigation Experience',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete navigation with status tracking, arrival detection, and appointment integration.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NavigationExampleScreen(
                              appointmentId: 'sample_appointment_123',
                              patientLocation: patientLocation,
                              initialProviderLocation: providerLocation,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Full Navigation'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Integration instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.integration_instructions, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Integration Guide',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildIntegrationStep(
                      '1.',
                      'Add NavigationMapWidget to your existing live tracking screen',
                    ),
                    _buildIntegrationStep(
                      '2.',
                      'Replace FlutterMapTrackingWidget with NavigationMapWidget for enhanced navigation',
                    ),
                    _buildIntegrationStep(
                      '3.',
                      'Use onProviderLocationUpdate callback to update Firestore with real-time location',
                    ),
                    _buildIntegrationStep(
                      '4.',
                      'Integrate with your appointment workflow for arrival detection',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Features list
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Features Included',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeature('✓ OpenStreetMap tiles (free)'),
                    _buildFeature('✓ Real-time GPS tracking with heading'),
                    _buildFeature('✓ Route calculation (OSRM/Mapbox/Google)'),
                    _buildFeature('✓ Auto-zoom and manual controls'),
                    _buildFeature('✓ Google Maps-like navigation UI'),
                    _buildFeature('✓ Arrival detection and status tracking'),
                    _buildFeature('✓ Smooth animations and visual feedback'),
                    _buildFeature('✓ Fallback to straight-line routes'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        feature,
        style: TextStyle(color: Colors.green[700]),
      ),
    );
  }
}

/// Example of how to integrate with your existing live tracking screen
class IntegratedLiveTrackingScreen extends StatefulWidget {
  final String appointmentId;
  
  const IntegratedLiveTrackingScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<IntegratedLiveTrackingScreen> createState() => _IntegratedLiveTrackingScreenState();
}

class _IntegratedLiveTrackingScreenState extends State<IntegratedLiveTrackingScreen> {
  LatLng? patientLocation;
  LatLng? providerLocation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    // TODO: Load appointment data from Firestore
    // This is where you'd fetch the patient and provider locations
    // from your appointment document
    
    // Example implementation:
    /*
    try {
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
          
      final data = appointmentDoc.data() as Map<String, dynamic>;
      
      setState(() {
        patientLocation = LatLng(
          data['patient_location']['latitude'], 
          data['patient_location']['longitude']
        );
        providerLocation = LatLng(
          data['provider_location']['latitude'], 
          data['provider_location']['longitude']
        );
        isLoading = false;
      });
    } catch (e) {
      print('Error loading appointment: $e');
      setState(() {
        isLoading = false;
      });
    }
    */
    
    // For demo purposes, using sample data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      patientLocation = const LatLng(36.7538, 3.0588);
      providerLocation = const LatLng(36.7400, 3.0500);
      isLoading = false;
    });
  }

  void _updateProviderLocationInFirestore(LatLng newLocation, double heading) async {
    // TODO: Update provider location in Firestore
    // This keeps the patient informed of provider's real-time location
    
    /*
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'provider_location': {
          'latitude': newLocation.latitude,
          'longitude': newLocation.longitude,
          'heading': heading,
          'updated_at': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      print('Error updating provider location: $e');
    }
    */
    
    print('Provider location updated: $newLocation (heading: $heading°)');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (patientLocation == null || providerLocation == null) {
      return const Scaffold(
        body: Center(
          child: Text('Failed to load appointment data'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: NavigationMapWidget(
        patientLocation: patientLocation!,
        providerLocation: providerLocation!,
        showNavigationMode: true,
        onProviderLocationUpdate: _updateProviderLocationInFirestore,
        onNavigationComplete: () {
          // Handle when provider arrives at patient location
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentActiveScreen(
                appointmentId: widget.appointmentId,
                patientLocation: patientLocation!,
                providerLocation: providerLocation!,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder for appointment active screen
class AppointmentActiveScreen extends StatelessWidget {
  final String appointmentId;
  final LatLng patientLocation;
  final LatLng providerLocation;

  const AppointmentActiveScreen({
    super.key,
    required this.appointmentId,
    required this.patientLocation,
    required this.providerLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Appointment'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Appointment Started',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Provider has arrived and appointment is now active.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}