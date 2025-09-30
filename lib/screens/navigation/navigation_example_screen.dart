import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/maps/navigation_map_widget.dart';
import '../../data/services/navigation_routing_service.dart';

/// Example screen showing navigation-like map implementation
/// Similar to Google Maps navigation for medical appointments
class NavigationExampleScreen extends StatefulWidget {
  final String appointmentId;
  final LatLng patientLocation;
  final LatLng initialProviderLocation;

  const NavigationExampleScreen({
    super.key,
    required this.appointmentId,
    required this.patientLocation,
    required this.initialProviderLocation,
  });

  @override
  State<NavigationExampleScreen> createState() => _NavigationExampleScreenState();
}

class _NavigationExampleScreenState extends State<NavigationExampleScreen> {
  late LatLng _currentProviderLocation;
  double _currentHeading = 0.0;
  bool _isNavigating = true;
  
  // Route information
  RouteInfo? _currentRoute;
  bool _isLoadingRoute = false;
  
  // Navigation status
  NavigationStatus _navigationStatus = NavigationStatus.enRoute;
  Timer? _navigationTimer;
  
  @override
  void initState() {
    super.initState();
    _currentProviderLocation = widget.initialProviderLocation;
    _loadInitialRoute();
    _startNavigationStatusCheck();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  /// Load initial route information
  Future<void> _loadInitialRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final route = await NavigationRoutingService.getRoute(
        start: _currentProviderLocation,
        end: widget.patientLocation,
        profile: 'driving',
      );
      
      setState(() {
        _currentRoute = route;
      });
    } catch (e) {
      print('Failed to load route: $e');
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Start periodic navigation status check
  void _startNavigationStatusCheck() {
    _navigationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNavigationStatus();
    });
  }

  /// Check if provider has arrived at patient location
  void _checkNavigationStatus() {
    final distance = _calculateDistance(
      _currentProviderLocation,
      widget.patientLocation,
    );

    if (distance < 50) { // Within 50 meters
      setState(() {
        _navigationStatus = NavigationStatus.arrived;
        _isNavigating = false;
      });
      _showArrivalDialog();
    } else if (distance < 200) { // Within 200 meters
      setState(() {
        _navigationStatus = NavigationStatus.approaching;
      });
    }
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth radius in meters
    final dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final dLng = _degreesToRadians(point2.longitude - point1.longitude);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(point1.latitude)) *
        math.cos(_degreesToRadians(point2.latitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Handle provider location updates
  void _onProviderLocationUpdate(LatLng newLocation, double heading) {
    setState(() {
      _currentProviderLocation = newLocation;
      _currentHeading = heading;
    });

    // Check navigation status
    _checkNavigationStatus();
    
    // Update route if provider has moved significantly
    final distance = _calculateDistance(
      _currentProviderLocation,
      widget.patientLocation,
    );
    
    if (distance > 100 && _currentRoute != null) {
      // Reload route if distance changed significantly
      _loadInitialRoute();
    }
  }

  /// Show arrival dialog
  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Arrived'),
          ],
        ),
        content: const Text(
          'You have arrived at the patient location. '
          'Please confirm your arrival to begin the appointment.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmArrival();
            },
            child: const Text('Confirm Arrival'),
          ),
        ],
      ),
    );
  }

  /// Confirm arrival and start appointment
  void _confirmArrival() {
    // Here you would update the appointment status in Firestore
    // and navigate to the appointment screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AppointmentActiveScreen(
          appointmentId: widget.appointmentId,
          patientLocation: widget.patientLocation,
          providerLocation: _currentProviderLocation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Navigation status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: _buildStatusChip(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main navigation map
          NavigationMapWidget(
            patientLocation: widget.patientLocation,
            providerLocation: _currentProviderLocation,
            onProviderLocationUpdate: _onProviderLocationUpdate,
            showNavigationMode: _isNavigating,
            onNavigationComplete: _confirmArrival,
          ),
          
          // Route information card
          if (_currentRoute != null && _isNavigating)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildRouteInfoCard(),
            ),
          
          // Loading overlay
          if (_isLoadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading navigation...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build navigation status chip
  Widget _buildStatusChip() {
    Color chipColor;
    IconData chipIcon;
    String chipText;

    switch (_navigationStatus) {
      case NavigationStatus.enRoute:
        chipColor = Colors.blue;
        chipIcon = Icons.navigation;
        chipText = 'En Route';
        break;
      case NavigationStatus.approaching:
        chipColor = Colors.orange;
        chipIcon = Icons.location_on;
        chipText = 'Approaching';
        break;
      case NavigationStatus.arrived:
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        chipText = 'Arrived';
        break;
    }

    return Chip(
      backgroundColor: chipColor.withOpacity(0.1),
      side: BorderSide(color: chipColor),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(color: chipColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build route information card
  Widget _buildRouteInfoCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Route Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Distance and time
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.straighten,
                    'Distance',
                    '${_currentRoute!.distanceKm.toStringAsFixed(1)} km',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time,
                    'ETA',
                    '${_currentRoute!.durationMinutes} min',
                  ),
                ),
              ],
            ),
            
            if (_currentRoute!.instructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Next Instruction',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentRoute!.instructions.split('\n').first,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build info item widget
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Navigation status enum
enum NavigationStatus {
  enRoute,
  approaching,
  arrived,
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

// Import math for calculations
import 'dart:math' as math;