import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/location_models.dart';
import '../../data/services/enhanced_provider_tracking_service.dart';
import '../../data/services/location_service.dart';
import '../../core/enhanced_theme.dart';
import '../booking/ServiceSelectionPage.dart';

class FlutterMapTrackingWidget extends StatefulWidget {
  final String? appointmentId;
  final bool showNearbyProviders;
  final LatLng? initialCenter;
  final double initialZoom;
  final ServiceType? selectedServiceType;
  final Specialty? selectedSpecialty;
  final Function(HealthcareProvider)? onProviderSelected;
  final Function(LatLng)? onLocationSelected;

  const FlutterMapTrackingWidget({
    super.key,
    this.appointmentId,
    this.showNearbyProviders = true,
    this.initialCenter,
    this.initialZoom = 14.0,
    this.selectedServiceType,
    this.selectedSpecialty,
    this.onProviderSelected,
    this.onLocationSelected,
  });

  @override
  State<FlutterMapTrackingWidget> createState() => _FlutterMapTrackingWidgetState();
}

class _FlutterMapTrackingWidgetState extends State<FlutterMapTrackingWidget>
    with TickerProviderStateMixin {
  
  // Map controller
  late MapController _mapController;
  
  // Services
  final LocationService _locationService = LocationService();
  final EnhancedProviderTrackingService _providerService = EnhancedProviderTrackingService();

  // Current state
  LatLng? _currentLocation;
  List<HealthcareProvider> _nearbyProviders = [];
  HealthcareProvider? _selectedProvider;
  List<LatLng> _routePoints = [];
  
  // Appointment tracking state
  LatLng? _patientLocation;
  LatLng? _providerLocation;
  String? _currentUserRole; // 'patient' or 'provider'
  String? _patientId;
  String? _providerId;
  
  // Route stability
  LatLng? _lastRoutePatientLocation;
  LatLng? _lastRouteProviderLocation;
  bool _isRouteStable = false;
  Timer? _routeStabilityTimer;

  // Subscriptions
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<HealthcareProvider>>? _providersSubscription;
  StreamSubscription<HealthcareProvider>? _providerLocationSubscription;
  StreamSubscription<DocumentSnapshot>? _appointmentSubscription;
  Timer? _refreshTimer;
  Timer? _locationUpdateTimer;

  // Animation controllers
  late AnimationController _markerAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeAnimations();
    _initializeMap();
  }

  void _initializeAnimations() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _initializeMap() async {
    try {
      print('🗺️ [FlutterMapTracking] Initializing with appointmentId: ${widget.appointmentId}');
      
      // Get current location
      await _getCurrentLocation();
      
      // Start listening to location updates
      _startLocationTracking();
      
      if (widget.appointmentId != null) {
        // Appointment-specific tracking mode
        print('📍 [FlutterMapTracking] Starting appointment tracking mode');
        _startAppointmentTracking();
      } else if (widget.showNearbyProviders) {
        // Provider discovery mode
        print('🔍 [FlutterMapTracking] Starting provider discovery mode');
        await _getNearbyProviders();
        _startProviderTracking();
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        // Move map to current location if no initial center provided
        if (widget.initialCenter == null && _currentLocation != null) {
          _mapController.move(_currentLocation!, widget.initialZoom);
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Use default location (Algiers, Algeria) if location access fails
      setState(() {
        _currentLocation = const LatLng(36.7525, 3.0420);
      });
      _mapController.move(_currentLocation!, widget.initialZoom);
    }
  }

  void _startLocationTracking() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters for more precision
      ),
    ).listen(
      (Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Update route if provider is selected
        if (_selectedProvider != null) {
          _updateRoute();
        }
        
        // Refresh providers periodically when location changes significantly
        _refreshProvidersIfNeeded();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  /// Refresh providers if location has changed significantly
  void _refreshProvidersIfNeeded() {
    // Refresh providers every 30 seconds when location tracking
    if (_refreshTimer?.isActive != true) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (timer) => _getNearbyProviders(),
      );
    }
  }

  Future<void> _getNearbyProviders() async {
    if (_currentLocation == null) return;

    try {
      final userLocation = UserLocation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        accuracy: 0,
        timestamp: DateTime.now(),
      );

      final providers = await _providerService.getNearbyProviders(
        patientLocation: userLocation,
        radiusInKm: 15.0,
        serviceType: widget.selectedServiceType,
        specialty: widget.selectedSpecialty,
      );

      setState(() {
        _nearbyProviders = providers;
        // Automatically select the closest provider
        if (providers.isNotEmpty) {
          _selectedProvider = _findClosestProvider(providers);
          if (_selectedProvider != null) {
            _updateRoute();
            // Notify parent about the selected provider
            widget.onProviderSelected?.call(_selectedProvider!);
          }
        }
      });
    } catch (e) {
      debugPrint('Error getting nearby providers: $e');
    }
  }

  void _startProviderTracking() {
    _providersSubscription = _providerService.nearbyProvidersStream.listen(
      (providers) {
        setState(() {
          _nearbyProviders = providers;
        });
      },
    );

    _providerLocationSubscription = _providerService.providerLocationStream.listen(
      (updatedProvider) {
        if (_selectedProvider?.id == updatedProvider.id) {
          setState(() {
            _selectedProvider = updatedProvider;
          });
          _updateRoute();
        }
      },
    );
  }

  void _updateRoute() {
    if (_currentLocation == null || _selectedProvider == null) return;

    final providerLocation = LatLng(
      _selectedProvider!.currentLocation?.latitude ?? 0,
      _selectedProvider!.currentLocation?.longitude ?? 0,
    );

    // Simple straight line route (in a real app, you'd use routing service)
    setState(() {
      _routePoints = [_currentLocation!, providerLocation];
    });

    // Adjust map bounds to show both locations
    _fitBounds([_currentLocation!, providerLocation]);
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

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

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Calculate zoom level based on bounds
    final zoom = _calculateZoomLevel(bounds);
    _mapController.move(center, zoom);
  }

  double _calculateZoomLevel(LatLngBounds bounds) {
    const double padding = 0.01; // Add padding around bounds
    final double latDiff = bounds.north - bounds.south + padding;
    final double lngDiff = bounds.east - bounds.west + padding;
    final double maxDiff = math.max(latDiff, lngDiff);
    
    // Simple zoom calculation (you might need to adjust this)
    if (maxDiff > 0.1) return 10.0;
    if (maxDiff > 0.05) return 12.0;
    if (maxDiff > 0.01) return 14.0;
    if (maxDiff > 0.005) return 15.0;
    return 16.0;
  }

  /// Find the closest provider to the patient
  HealthcareProvider? _findClosestProvider(List<HealthcareProvider> providers) {
    if (providers.isEmpty || _currentLocation == null) return null;

    HealthcareProvider? closestProvider;
    double minDistance = double.infinity;

    final distance = Distance();
    final patientLatLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);

    for (final provider in providers) {
      if (provider.currentLocation == null) continue;

      final providerLatLng = LatLng(
        provider.currentLocation!.latitude,
        provider.currentLocation!.longitude,
      );

      final distanceToProvider = distance.as(
        LengthUnit.Meter,
        patientLatLng,
        providerLatLng,
      );

      if (distanceToProvider < minDistance) {
        minDistance = distanceToProvider;
        closestProvider = provider;
      }
    }

    return closestProvider;
  }

  /// Start appointment-specific tracking for both patient and provider
  void _startAppointmentTracking() async {
    if (widget.appointmentId == null) return;
    
    print('📱 [FlutterMapTracking] Starting appointment tracking for: ${widget.appointmentId}');
    
    try {
      // Get current user role and appointment details
      await _loadAppointmentDetails();
      
      // Start role-specific tracking behavior
      if (_currentUserRole == 'patient') {
        print('👤 [Patient View] Starting patient tracking mode');
        _startPatientTrackingMode();
      } else if (_currentUserRole == 'provider') {
        print('🩺 [Provider View] Starting provider tracking mode');
        _startProviderTrackingMode();
      }
      
      // Start listening to appointment updates (real-time location sync)
      _subscribeToAppointmentUpdates();
      
    } catch (e) {
      print('❌ [FlutterMapTracking] Error starting appointment tracking: $e');
    }
  }

  /// Load appointment details from Firestore
  Future<void> _loadAppointmentDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final appointmentDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .get();

    if (!appointmentDoc.exists) {
      print('❌ Appointment not found: ${widget.appointmentId}');
      return;
    }

    final data = appointmentDoc.data()!;
    _patientId = data['idpat'] ?? data['patientId'];
    _providerId = data['idpro'] ?? data['professionnelId'];
    
    // Determine current user role
    if (user.uid == _patientId) {
      _currentUserRole = 'patient';
      print('👤 [FlutterMapTracking] User is patient');
    } else if (user.uid == _providerId) {
      _currentUserRole = 'provider'; 
      print('🩺 [FlutterMapTracking] User is provider');
    } else {
      print('❌ [FlutterMapTracking] User not found in appointment');
    }

    // Load existing locations if available
    final patientLoc = data['patientlocation'] as GeoPoint?;
    final providerLoc = data['providerlocation'] as GeoPoint?;
    
    if (patientLoc != null) {
      _patientLocation = LatLng(patientLoc.latitude, patientLoc.longitude);
    }
    if (providerLoc != null) {
      _providerLocation = LatLng(providerLoc.latitude, providerLoc.longitude);
    }

    setState(() {}); // Refresh markers
  }

  /// Patient tracking mode: Track own location, watch provider location
  void _startPatientTrackingMode() {
    print('👤 [Patient] Patient stays put, watching provider move');
    
    // Patient updates their location once initially, then stays fixed
    _updatePatientLocationInFirestore();
    
    // Patient focuses on tracking the provider's movement
    // No continuous location updates needed for patient
  }

  /// Provider tracking mode: Continuously update own location to reach patient
  void _startProviderTrackingMode() {
    print('🩺 [Provider] Provider navigates to patient location');
    
    // Provider continuously updates their location
    _startProviderLocationUpdates();
    
    // Focus map on patient location initially (destination)
    if (_patientLocation != null) {
      _mapController.move(_patientLocation!, 15.0);
      print('🎯 [Provider] Map focused on patient location (destination)');
    }
  }

  /// Update patient location once in Firestore (patient stays fixed)
  Future<void> _updatePatientLocationInFirestore() async {
    if (_currentLocation == null) return;
    
    final geoPoint = GeoPoint(_currentLocation!.latitude, _currentLocation!.longitude);
    
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
            'patientlocation': geoPoint,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('📍 [Patient] Fixed location set: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    } catch (e) {
      print('❌ [Patient] Failed to set fixed location: $e');
    }
  }

  /// Continuously update provider location (provider moves to patient)
  void _startProviderLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentLocation != null) {
        _updateProviderLocationInFirestore();
      }
    });
  }

  /// Update provider location in Firestore
  Future<void> _updateProviderLocationInFirestore() async {
    if (_currentLocation == null) return;
    
    final geoPoint = GeoPoint(_currentLocation!.latitude, _currentLocation!.longitude);
    
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
            'providerlocation': geoPoint,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('🚶 [Provider] Location updated: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
    } catch (e) {
      print('❌ [Provider] Failed to update location: $e');
    }
  }

  /// Subscribe to real-time appointment location updates  
  void _subscribeToAppointmentUpdates() {
    _appointmentSubscription = FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      
      // Update patient location
      final patientLoc = data['patientlocation'] as GeoPoint?;
      if (patientLoc != null) {
        final newPatientLoc = LatLng(patientLoc.latitude, patientLoc.longitude);
        if (_patientLocation != newPatientLoc) {
          setState(() => _patientLocation = newPatientLoc);
          
          if (_currentUserRole == 'provider') {
            print('🎯 [Provider View] Patient location received: ${patientLoc.latitude}, ${patientLoc.longitude}');
          }
        }
      }
      
      // Update provider location  
      final providerLoc = data['providerlocation'] as GeoPoint?;
      if (providerLoc != null) {
        final newProviderLoc = LatLng(providerLoc.latitude, providerLoc.longitude);
        if (_providerLocation != newProviderLoc) {
          setState(() => _providerLocation = newProviderLoc);
          
          if (_currentUserRole == 'patient') {
            print('📍 [Patient View] Provider location updated: ${providerLoc.latitude}, ${providerLoc.longitude}');
          }
        }
      }
      
      // Update route and view based on role
      _updateRoleBasedView();
    });
  }



  /// Update view and route based on user role
  void _updateRoleBasedView() {
    if (_patientLocation == null || _providerLocation == null) return;
    
    // Check if route needs significant update (prevent flickering)
    final shouldUpdateRoute = _shouldUpdateRoute();
    
    if (shouldUpdateRoute) {
      _updateRouteStably();
    }
    
    // Calculate distance
    final distance = Geolocator.distanceBetween(
      _patientLocation!.latitude,
      _patientLocation!.longitude,
      _providerLocation!.latitude,
      _providerLocation!.longitude,
    );
    
    if (_currentUserRole == 'patient') {
      print('� [Patient View] Provider is ${(distance / 1000).toStringAsFixed(2)} km away');
      // Patient view: Smoothly follow provider
      _smoothFocusOnProvider();
    } else if (_currentUserRole == 'provider') {
      print('🩺 [Provider View] ${(distance / 1000).toStringAsFixed(2)} km to patient');
      // Provider view: Stable route view
      _maintainStableRouteView();
    }
  }

  /// Patient view: Smoothly follow provider (like Uber passenger view)
  void _smoothFocusOnProvider() {
    if (_providerLocation != null) {
      // Smooth animated move instead of instant jump
      _mapController.move(_providerLocation!, 16.0);
      // TODO: Could add smooth animation here if flutter_map supports it
    }
  }

  /// Provider view: Maintain stable route view (like Uber driver view) 
  void _maintainStableRouteView() {
    // Only adjust view if route is stable
    if (_isRouteStable) {
      _fitMapToBothLocations();
    }
  }

  /// Adjust map to show both patient and provider locations
  void _fitMapToBothLocations() {
    if (_patientLocation == null || _providerLocation == null) return;
    
    final bounds = LatLngBounds.fromPoints([_patientLocation!, _providerLocation!]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  /// Check if route should be updated (avoid unnecessary redraws)
  bool _shouldUpdateRoute() {
    if (_lastRoutePatientLocation == null || _lastRouteProviderLocation == null) {
      return true; // First time
    }
    
    // Only update if significant movement (>10 meters to prevent flickering)
    final patientMoved = Geolocator.distanceBetween(
      _lastRoutePatientLocation!.latitude,
      _lastRoutePatientLocation!.longitude,
      _patientLocation!.latitude,
      _patientLocation!.longitude,
    ) > 10;
    
    final providerMoved = Geolocator.distanceBetween(
      _lastRouteProviderLocation!.latitude,
      _lastRouteProviderLocation!.longitude,
      _providerLocation!.latitude,
      _providerLocation!.longitude,
    ) > 10;
    
    return patientMoved || providerMoved;
  }

  /// Update route with stability (like Uber)
  void _updateRouteStably() {
    // Cancel any pending route update
    _routeStabilityTimer?.cancel();
    
    // Debounce route updates (wait for movement to stabilize)
    _routeStabilityTimer = Timer(const Duration(milliseconds: 500), () {
      if (_patientLocation != null && _providerLocation != null) {
        setState(() {
          _routePoints = [_patientLocation!, _providerLocation!];
          _isRouteStable = true;
        });
        
        // Remember last route positions
        _lastRoutePatientLocation = _patientLocation;
        _lastRouteProviderLocation = _providerLocation;
        
        print('📍 [Stable Route] Updated with debounce');
      }
    });
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _pulseController.dispose();
    _locationSubscription?.cancel();
    _providersSubscription?.cancel();
    _providerLocationSubscription?.cancel();
    _appointmentSubscription?.cancel();
    _refreshTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _routeStabilityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: EnhancedAppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter ?? _currentLocation ?? const LatLng(36.7525, 3.0420),
            initialZoom: widget.initialZoom,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                     InteractiveFlag.drag |
                     InteractiveFlag.doubleTapZoom,
            ),
            onTap: (tapPosition, point) {
              widget.onLocationSelected?.call(point);
            },
          ),
          children: [
            // Map tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.firstv',
              maxNativeZoom: 19,
            ),
            
            // Stable route line (like Uber)
            if (_routePoints.isNotEmpty && _isRouteStable)
              PolylineLayer(
                polylines: [
                  // Shadow line (background)
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 8.0,
                    color: Colors.black.withOpacity(0.2),
                  ),
                  // Main route line
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: _currentUserRole == 'patient' 
                        ? Colors.purple.shade600  // Patient tracking color
                        : Colors.blue.shade600,   // Provider navigation color
                    pattern: StrokePattern.solid(),
                  ),
                ],
              ),

            // Markers layer
            MarkerLayer(
              markers: [
                // Appointment mode: Show role-specific markers
                if (widget.appointmentId != null) ...[
                  // Patient marker (different emphasis based on role)
                  if (_patientLocation != null)
                    Marker(
                      point: _patientLocation!,
                      width: _currentUserRole == 'provider' ? 80 : 60, // Bigger for provider (destination)
                      height: _currentUserRole == 'provider' ? 80 : 60,
                      child: _buildPatientMarker(),
                    ),
                  // Provider marker (different emphasis based on role)
                  if (_providerLocation != null)
                    Marker(
                      point: _providerLocation!,
                      width: _currentUserRole == 'patient' ? 80 : 60, // Bigger for patient (tracking)
                      height: _currentUserRole == 'patient' ? 80 : 60,
                      child: _buildAppointmentProviderMarker(),
                    ),
                ] else ...[
                  // Discovery mode: Show current location and nearby providers
                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: _buildCurrentLocationMarker(),
                    ),
                  
                  // Provider markers
                  ..._nearbyProviders.map((provider) => Marker(
                    point: LatLng(
                      provider.currentLocation?.latitude ?? 0,
                      provider.currentLocation?.longitude ?? 0,
                    ),
                    width: 80,
                    height: 80,
                    child: _buildProviderMarker(provider),
                  )),
                ],
              ],
            ),

            // Map controls
            Positioned(
              top: 16,
              right: 16,
              child: _buildMapControls(),
            ),

            // Role indicator (only in appointment mode)
            if (widget.appointmentId != null && _currentUserRole != null)
              Positioned(
                top: 16,
                left: 16,
                child: _buildRoleIndicator(),
              ),

            // Route status indicator (show route stability)
            if (widget.appointmentId != null && _routePoints.isNotEmpty)
              Positioned(
                top: 70,
                left: 16,
                child: _buildRouteStatusIndicator(),
              ),

            // Service type indicator
            if (widget.selectedServiceType != null)
              Positioned(
                top: 16,
                left: 16,
                child: _buildServiceTypeIndicator(),
              ),

            // Current location button
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildLocationButton(),
            ),

            // Real-time location update button
            Positioned(
              bottom: 80,
              right: 16,
              child: _buildUpdateLocationButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientMarker() {
    final isCurrentUser = _currentUserRole == 'patient';
    final isDestination = _currentUserRole == 'provider'; // For provider, patient is destination
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDestination ? Colors.orange : Colors.green).withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: (isDestination ? 20 : 15) * _pulseAnimation.value,
                spreadRadius: (isDestination ? 12 : 8) * _pulseAnimation.value,
              ),
            ],
          ),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDestination ? Colors.orange : (isCurrentUser ? Colors.green : Colors.green.shade300),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isDestination ? Icons.location_on : Icons.person,
              color: Colors.white,
              size: isDestination ? 28 : (isCurrentUser ? 24 : 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentProviderMarker() {
    final isCurrentUser = _currentUserRole == 'provider';
    final isTracked = _currentUserRole == 'patient'; // For patient, provider is being tracked
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isTracked ? Colors.purple : Colors.blue).withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: (isTracked ? 20 : 15) * _pulseAnimation.value,
                spreadRadius: (isTracked ? 12 : 8) * _pulseAnimation.value,
              ),
            ],
          ),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isTracked ? Colors.purple : (isCurrentUser ? Colors.blue : Colors.blue.shade300),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isTracked ? Icons.directions_car : Icons.local_hospital,
              color: Colors.white,
              size: isTracked ? 28 : (isCurrentUser ? 24 : 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: 20 * _pulseAnimation.value,
                spreadRadius: 10 * _pulseAnimation.value,
              ),
            ],
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviderMarker(HealthcareProvider provider) {
    final isSelected = _selectedProvider?.id == provider.id;
    final statusColor = _getProviderStatusColor(provider.status);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProvider = provider;
        });
        widget.onProviderSelected?.call(provider);
        _updateRoute();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: statusColor,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _getProviderIcon(provider),
              color: statusColor,
              size: isSelected ? 28 : 24,
            ),
          ),
        ),
      ),
    );
  }

  Color _getProviderStatusColor(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.available:
        return Colors.green;
      case ProviderStatus.enRoute:
        return Colors.orange;
      case ProviderStatus.busy:
        return Colors.red;
      case ProviderStatus.offline:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon(HealthcareProvider provider) {
    // Determine if provider is a doctor or nurse based on specialty
    final doctorSpecialties = [
      'generalMedicine', 'cardiology', 'neurology', 'pediatrics', 
      'gynecology', 'orthopedics', 'dermatology', 'psychiatry',
      'ophthalmology', 'ent', 'urology', 'gastroenterology', 
      'oncology', 'emergency'
    ];
    
    final nurseSpecialties = [
      'woundCare', 'medicationAdministration', 'vitalsMonitoring', 
      'injections', 'bloodDrawing', 'homeHealthAssessment',
      'postSurgicalCare', 'chronicDiseaseManagement', 'elderCare',
      'mobilityAssistance', 'medicationReminders', 'healthEducation'
    ];

    if (doctorSpecialties.contains(provider.specialty)) {
      return Icons.medical_services; // Doctor icon
    } else if (nurseSpecialties.contains(provider.specialty)) {
      return Icons.health_and_safety; // Nurse icon  
    } else {
      // Default to doctor icon if specialty is unclear
      return Icons.medical_services;
    }
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: EnhancedAppTheme.softShadow,
          ),
          child: Column(
            children: [
              IconButton(
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    (currentZoom + 1).clamp(5.0, 18.0),
                  );
                },
                icon: const Icon(Icons.add),
              ),
              const Divider(height: 1),
              IconButton(
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    (currentZoom - 1).clamp(5.0, 18.0),
                  );
                },
                icon: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: EnhancedAppTheme.softShadow,
      ),
      child: IconButton(
        onPressed: () async {
          await _getCurrentLocation();
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 16.0);
          }
        },
        icon: Icon(
          Icons.my_location,
          color: EnhancedAppTheme.primaryIndigo,
        ),
      ),
    );
  }

  Widget _buildUpdateLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: EnhancedAppTheme.softShadow,
      ),
      child: IconButton(
        onPressed: () async {
          // Update location and refresh providers
          await _getCurrentLocation();
          await _getNearbyProviders();
          
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 15.0);
            
            // Show feedback
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.refresh, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Location updated - Found ${_nearbyProviders.length} providers'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
        icon: Icon(
          Icons.refresh,
          color: EnhancedAppTheme.primaryIndigo,
        ),
        tooltip: 'Update location & refresh providers',
      ),
    );
  }

  Widget _buildServiceTypeIndicator() {
    if (widget.selectedServiceType == null) return const SizedBox.shrink();

    final isDoctor = widget.selectedServiceType == ServiceType.doctor;
    final serviceText = isDoctor ? 'Doctors' : 'Nurses';
    final serviceIcon = isDoctor ? Icons.medical_services : Icons.health_and_safety;
    final serviceColor = isDoctor ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: EnhancedAppTheme.softShadow,
        border: Border.all(color: serviceColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            serviceIcon,
            color: serviceColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Showing $serviceText',
            style: TextStyle(
              color: serviceColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: serviceColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_nearbyProviders.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build role indicator showing current user's perspective
  Widget _buildRoleIndicator() {
    final isPatient = _currentUserRole == 'patient';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPatient ? Colors.green : Colors.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatient ? Icons.person : Icons.local_hospital,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isPatient ? 'Tracking Provider' : 'Navigating to Patient',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build route status indicator showing stability
  Widget _buildRouteStatusIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isRouteStable ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRouteStable ? Icons.navigation : Icons.refresh,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _isRouteStable ? 'Route Stable' : 'Updating...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
