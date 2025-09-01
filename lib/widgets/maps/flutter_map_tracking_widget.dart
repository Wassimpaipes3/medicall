import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

  // Subscriptions
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<HealthcareProvider>>? _providersSubscription;
  StreamSubscription<HealthcareProvider>? _providerLocationSubscription;
  Timer? _refreshTimer;

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
      // Get current location
      await _getCurrentLocation();
      
      // Start listening to location updates
      _startLocationTracking();
      
      if (widget.showNearbyProviders) {
        // Get nearby providers
        await _getNearbyProviders();
        
        // Start provider tracking
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

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _pulseController.dispose();
    _locationSubscription?.cancel();
    _providersSubscription?.cancel();
    _providerLocationSubscription?.cancel();
    _refreshTimer?.cancel();
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
            
            // Route line
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: EnhancedAppTheme.primaryIndigo,
                    pattern: StrokePattern.dashed(segments: [10, 5]),
                  ),
                ],
              ),

            // Markers layer
            MarkerLayer(
              markers: [
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
            ),

            // Map controls
            Positioned(
              top: 16,
              right: 16,
              child: _buildMapControls(),
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
}
