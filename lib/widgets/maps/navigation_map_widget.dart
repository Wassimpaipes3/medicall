import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/navigation_routing_service.dart';

/// Enhanced navigation-like map widget for medical app
/// Features Google Maps-like navigation with real-time tracking
class NavigationMapWidget extends StatefulWidget {
  final LatLng patientLocation;
  final LatLng providerLocation;
  final Function(LatLng newProviderLocation, double heading)? onProviderLocationUpdate;
  final bool showNavigationMode;
  final VoidCallback? onNavigationComplete;

  const NavigationMapWidget({
    super.key,
    required this.patientLocation,
    required this.providerLocation,
    this.onProviderLocationUpdate,
    this.showNavigationMode = true,
    this.onNavigationComplete,
  });

  @override
  State<NavigationMapWidget> createState() => _NavigationMapWidgetState();
}

class _NavigationMapWidgetState extends State<NavigationMapWidget>
    with TickerProviderStateMixin {
  
  // Map controller
  late MapController _mapController;
  
  // Location tracking
  late LatLng _currentPatientLocation;
  late LatLng _currentProviderLocation;
  double _providerHeading = 0.0; // GPS heading in degrees
  
  // Route data
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String _routeDistance = '';
  String _routeETA = '';
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  // Location subscription
  StreamSubscription<Position>? _locationSubscription;
  
  // Auto-zoom settings
  bool _autoZoomEnabled = true;
  Timer? _autoZoomTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPatientLocation = widget.patientLocation;
    _currentProviderLocation = widget.providerLocation;
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Start location tracking and route fetching
    _initializeMap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _locationSubscription?.cancel();
    _autoZoomTimer?.cancel();
    super.dispose();
  }

  /// Initialize map with route and location tracking
  void _initializeMap() async {
    // Fetch initial route
    await _fetchRoute();
    
    // Start location tracking if in navigation mode
    if (widget.showNavigationMode) {
      _startLocationTracking();
    }
    
    // Auto-fit bounds initially
    _autoFitBounds();
  }

  /// Start real-time location tracking for the provider
  void _startLocationTracking() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      final heading = position.heading;
      
      setState(() {
        _currentProviderLocation = newLocation;
        _providerHeading = heading;
      });
      
      // Notify parent widget
      widget.onProviderLocationUpdate?.call(newLocation, heading);
      
      // Update route if provider has moved significantly
      final distance = Geolocator.distanceBetween(
        _currentProviderLocation.latitude,
        _currentProviderLocation.longitude,
        newLocation.latitude,
        newLocation.longitude,
      );
      
      if (distance > 50) { // Refetch route every 50 meters
        _fetchRoute();
      }
      
      // Auto-zoom if enabled
      if (_autoZoomEnabled) {
        _scheduleAutoZoom();
      }
    });
  }

  /// Fetch route using the enhanced routing service
  Future<void> _fetchRoute() async {
    if (_isLoadingRoute) return;
    
    setState(() {
      _isLoadingRoute = true;
    });
    
    try {
      final routeInfo = await NavigationRoutingService.getRoute(
        start: _currentProviderLocation,
        end: _currentPatientLocation,
        profile: 'driving',
      );
      
      if (routeInfo != null) {
        setState(() {
          _routePoints = routeInfo.points;
          _routeDistance = '${routeInfo.distanceKm.toStringAsFixed(1)}km';
          _routeETA = '${routeInfo.durationMinutes}min';
        });
      } else {
        _createStraightLineRoute();
      }
    } catch (e) {
      print('Route fetch error: $e');
      _createStraightLineRoute();
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  /// Create straight line route as fallback
  void _createStraightLineRoute() {
    final distance = Geolocator.distanceBetween(
      _currentProviderLocation.latitude,
      _currentProviderLocation.longitude,
      _currentPatientLocation.latitude,
      _currentPatientLocation.longitude,
    );
    
    setState(() {
      _routePoints = [_currentProviderLocation, _currentPatientLocation];
      _routeDistance = '${(distance / 1000).toStringAsFixed(1)}km';
      _routeETA = '${(distance / 1000 * 3).round()}min'; // Rough estimate
    });
  }

  /// Auto-fit bounds to show both markers and route
  void _autoFitBounds() {
    if (_routePoints.isEmpty) return;
    
    // Schedule after next frame to ensure map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final bounds = _calculateBounds(_routePoints);
        _mapController.fitCamera(CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ));
      } catch (e) {
        print('Auto-fit bounds error: $e');
      }
    });
  }

  /// Schedule auto-zoom with debouncing
  void _scheduleAutoZoom() {
    _autoZoomTimer?.cancel();
    _autoZoomTimer = Timer(const Duration(seconds: 2), () {
      if (_autoZoomEnabled && mounted) {
        _autoFitBounds();
      }
    });
  }

  /// Calculate bounds for list of points
  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        _currentPatientLocation,
        _currentProviderLocation,
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  /// Build navigation arrow marker that rotates with GPS heading
  Widget _buildNavigationArrow() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_providerHeading * math.pi / 180), // Convert degrees to radians
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  /// Build patient location marker
  Widget _buildPatientMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        return Container(
          width: 20 + (pulseValue * 10),
          height: 20 + (pulseValue * 10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Container(
            margin: EdgeInsets.all(5 + (pulseValue * 2)),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 12,
            ),
          ),
        );
      },
    );
  }

  /// Build provider location marker
  Widget _buildProviderMarker() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentProviderLocation,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              // Toggle auto-zoom on tap
              setState(() {
                _autoZoomEnabled = !_autoZoomEnabled;
              });
            },
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.medicall.app',
            ),
            
            // Route polyline
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Colors.blue,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            
            // Markers layer
            MarkerLayer(
              markers: [
                // Patient marker (green)
                Marker(
                  point: _currentPatientLocation,
                  child: _buildPatientMarker(),
                  width: 40,
                  height: 40,
                ),
                
                // Provider marker with navigation arrow (blue)
                Marker(
                  point: _currentProviderLocation,
                  child: widget.showNavigationMode 
                      ? _buildNavigationArrow() 
                      : _buildProviderMarker(),
                  width: 40,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
        
        // Navigation info panel
        if (widget.showNavigationMode)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildNavigationInfo(),
          ),
        
        // Map controls
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildMapControls(),
        ),
        
        // Loading indicator
        if (_isLoadingRoute)
          const Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Calculating route...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build navigation information panel
  Widget _buildNavigationInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.navigation, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'En route to patient',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_routeDistance • $_routeETA',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _autoZoomEnabled ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: _autoZoomEnabled ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _autoZoomEnabled = !_autoZoomEnabled;
                });
                if (_autoZoomEnabled) {
                  _autoFitBounds();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build map control buttons
  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom in
        FloatingActionButton.small(
          heroTag: "zoom_in",
          onPressed: () {
            final zoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, zoom + 1);
          },
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        
        // Zoom out  
        FloatingActionButton.small(
          heroTag: "zoom_out",
          onPressed: () {
            final zoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, zoom - 1);
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        
        // Center on route
        FloatingActionButton.small(
          heroTag: "center_route",
          onPressed: () {
            _autoFitBounds();
          },
          child: const Icon(Icons.center_focus_strong),
        ),
      ],
    );
  }
}