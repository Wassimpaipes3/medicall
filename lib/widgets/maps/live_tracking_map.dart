import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/location_models.dart';
import '../../data/services/location_service.dart';
import '../../data/services/map_service.dart';
import '../../data/services/provider_tracking_service.dart';

class LiveTrackingMapWidget extends StatefulWidget {
  final String? appointmentId;
  final bool showNearbyProviders;
  final Function(HealthcareProvider)? onProviderSelected;
  final Function(UserLocation)? onLocationSelected;

  const LiveTrackingMapWidget({
    super.key,
    this.appointmentId,
    this.showNearbyProviders = true,
    this.onProviderSelected,
    this.onLocationSelected,
  });

  @override
  State<LiveTrackingMapWidget> createState() => _LiveTrackingMapWidgetState();
}

class _LiveTrackingMapWidgetState extends State<LiveTrackingMapWidget>
    with TickerProviderStateMixin {
  // Services
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final ProviderTrackingService _providerService = ProviderTrackingService();

  // Map controller
  GoogleMapController? _mapController;

  // Current state
  UserLocation? _currentLocation;
  List<HealthcareProvider> _nearbyProviders = [];
  Appointment? _currentAppointment;

  // Subscriptions
  StreamSubscription<UserLocation>? _locationSubscription;
  StreamSubscription<List<HealthcareProvider>>? _providersSubscription;
  StreamSubscription<HealthcareProvider>? _providerLocationSubscription;
  StreamSubscription<Appointment>? _appointmentSubscription;

  // Animation controllers
  late AnimationController _markerAnimationController;
  late AnimationController _routeAnimationController;

  // UI State
  bool _isLoading = true;
  bool _showProviderDetails = false;
  HealthcareProvider? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _routeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    await _locationService.initialize();
    await _setupLocationTracking();
    await _setupProviderTracking();
    
    if (widget.appointmentId != null) {
      _setupAppointmentTracking();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _setupLocationTracking() async {
    // Get initial location
    _currentLocation = await _locationService.getCurrentLocation();
    if (_currentLocation != null) {
      await _mapService.addPatientMarker(_currentLocation!);
      _markerAnimationController.forward();
    }

    // Listen for location updates
    _locationSubscription = _locationService.currentLocationStream.listen(
      (location) async {
        if (mounted) {
          setState(() => _currentLocation = location);
          await _mapService.addPatientMarker(location);
          
          // Update nearby providers if showing them
          if (widget.showNearbyProviders) {
            await _loadNearbyProviders();
          }
        }
      },
    );

    // Start continuous tracking
    await _locationService.startLocationTracking();
  }

  Future<void> _setupProviderTracking() async {
    if (!widget.showNearbyProviders) return;

    // Listen for provider updates
    _providersSubscription = _providerService.nearbyProvidersStream.listen(
      (providers) async {
        if (mounted) {
          setState(() => _nearbyProviders = providers);
          await _mapService.addProviderMarkers(providers);
          _markerAnimationController.forward();
        }
      },
    );

    // Listen for individual provider location updates
    _providerLocationSubscription = _providerService.providerLocationStream.listen(
      (provider) async {
        if (mounted) {
          await _mapService.updateProviderLocation(
            provider.id,
            provider.currentLocation!,
          );
        }
      },
    );

    // Load initial providers
    if (_currentLocation != null) {
      await _loadNearbyProviders();
    }
  }

  void _setupAppointmentTracking() {
    _appointmentSubscription = _providerService.appointmentUpdatesStream.listen(
      (appointment) async {
        if (appointment.id == widget.appointmentId && mounted) {
          setState(() => _currentAppointment = appointment);
          
          // Draw route if provider is en route
          if (appointment.status == AppointmentStatus.inProgress &&
              appointment.providerCurrentLocation != null &&
              _currentLocation != null) {
            await _drawRouteToProvider(appointment);
          }
        }
      },
    );
  }

  Future<void> _loadNearbyProviders() async {
    if (_currentLocation == null) return;

    final providers = await _providerService.getNearbyProviders(
      patientLocation: _currentLocation!,
      radiusInKm: 15.0,
    );

    if (mounted) {
      setState(() => _nearbyProviders = providers);
    }
  }

  Future<void> _drawRouteToProvider(Appointment appointment) async {
    if (appointment.providerCurrentLocation == null || _currentLocation == null) return;

    final routeInfo = await _mapService.drawRoute(
      start: LatLng(
        appointment.providerCurrentLocation!.latitude,
        appointment.providerCurrentLocation!.longitude,
      ),
      end: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
      polylineColor: const Color(0xFF3B82F6),
      polylineWidth: 4.0,
    );

    if (routeInfo != null && mounted) {
      _routeAnimationController.forward();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapService.setMapController(controller);
    _mapService.setMapStyle();

    // Center map on current location if available
    if (_currentLocation != null) {
      _mapService.animateToLocation(
        location: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        zoom: 15.0,
      );
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _showProviderDetails = false;
      _selectedProvider = null;
    });

    // Create location object and notify parent
    final location = UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
    widget.onLocationSelected?.call(location);
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      await _mapService.animateToLocation(
        location: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
        zoom: 15.0,
      );
    }
  }

  Future<void> _fitAllMarkers() async {
    await _mapService.animateToFitMarkers();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _providersSubscription?.cancel();
    _providerLocationSubscription?.cancel();
    _appointmentSubscription?.cancel();
    _markerAnimationController.dispose();
    _routeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),
          
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
          
          // Map controls
          _buildMapControls(),
          
          // Provider details bottom sheet
          if (_showProviderDetails && _selectedProvider != null)
            _buildProviderDetailsSheet(),
          
          // Appointment status card
          if (_currentAppointment != null) _buildAppointmentStatusCard(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      onTap: _onMapTap,
      initialCameraPosition: CameraPosition(
        target: _currentLocation != null
            ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
            : const LatLng(37.7749, -122.4194), // San Francisco default
        zoom: 15.0,
      ),
      markers: _mapService.markers,
      polylines: _mapService.polylines,
      circles: _mapService.circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false,
      mapType: MapType.normal,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          // Current location button
          FloatingActionButton(
            heroTag: "current_location",
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3B82F6),
            onPressed: _centerOnCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          
          const SizedBox(height: 12),
          
          // Fit all markers button
          if (_nearbyProviders.isNotEmpty)
            FloatingActionButton(
              heroTag: "fit_markers",
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              onPressed: _fitAllMarkers,
              child: const Icon(Icons.center_focus_strong),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderDetailsSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProvider!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedProvider!.specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedProvider!.rating.toStringAsFixed(1)} (${_selectedProvider!.totalReviews})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedProvider!.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(_selectedProvider!.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Distance and ETA
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Distance',
                    value: '${_selectedProvider!.distanceFromPatient?.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'ETA',
                    value: '${_selectedProvider!.estimatedArrivalMinutes} min',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Call provider
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedProvider!.status == ProviderStatus.available
                        ? () {
                            // Book provider
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusCard() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAppointmentStatusIcon(_currentAppointment!.status),
                  color: _getAppointmentStatusColor(_currentAppointment!.status),
                ),
                const SizedBox(width: 8),
                Text(
                  _getAppointmentStatusText(_currentAppointment!.status),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (_currentAppointment!.provider != null) ...[
              const SizedBox(height: 8),
              Text(
                'Provider: ${_currentAppointment!.provider!.name}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (_currentAppointment!.estimatedArrivalMinutes != null &&
                _currentAppointment!.estimatedArrivalMinutes! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'ETA: ${_currentAppointment!.estimatedArrivalMinutes} minutes',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.available:
        return Colors.green;
      case ProviderStatus.busy:
        return Colors.orange;
      case ProviderStatus.offline:
        return Colors.red;
      case ProviderStatus.enRoute:
        return Colors.blue;
    }
  }

  String _getStatusText(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.available:
        return 'Available';
      case ProviderStatus.busy:
        return 'Busy';
      case ProviderStatus.offline:
        return 'Offline';
      case ProviderStatus.enRoute:
        return 'En Route';
    }
  }

  IconData _getAppointmentStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.directions_car;
      case AppointmentStatus.completed:
        return Icons.check_circle_outline;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getAppointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _getAppointmentStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Appointment Pending';
      case AppointmentStatus.confirmed:
        return 'Appointment Confirmed';
      case AppointmentStatus.inProgress:
        return 'Provider En Route';
      case AppointmentStatus.completed:
        return 'Appointment Completed';
      case AppointmentStatus.cancelled:
        return 'Appointment Cancelled';
    }
  }
}
