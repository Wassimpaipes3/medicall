import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/location_models.dart';
import '../../data/services/location_service.dart';
import '../../data/services/provider_tracking_service.dart';

class MockMapWidget extends StatefulWidget {
  final String? appointmentId;
  final bool showNearbyProviders;
  final Function(HealthcareProvider)? onProviderSelected;
  final Function(UserLocation)? onLocationSelected;

  const MockMapWidget({
    super.key,
    this.appointmentId,
    this.showNearbyProviders = true,
    this.onProviderSelected,
    this.onLocationSelected,
  });

  @override
  State<MockMapWidget> createState() => _MockMapWidgetState();
}

class _MockMapWidgetState extends State<MockMapWidget>
    with TickerProviderStateMixin {
  // Services
  final LocationService _locationService = LocationService();
  final ProviderTrackingService _providerService = ProviderTrackingService();

  // Current state
  UserLocation? _currentLocation;
  List<HealthcareProvider> _nearbyProviders = [];
  Appointment? _currentAppointment;
  HealthcareProvider? _selectedProvider;

  // Subscriptions
  StreamSubscription<UserLocation>? _locationSubscription;
  StreamSubscription<List<HealthcareProvider>>? _providersSubscription;
  StreamSubscription<Appointment>? _appointmentSubscription;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // UI State
  bool _isLoading = true;
  bool _showProviderDetails = false;

  // Mock coordinates for New York City
  final double _centerLat = 40.7128;
  final double _centerLng = -74.0060;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
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
    // Mock current location (Manhattan, NYC)
    _currentLocation = UserLocation(
      latitude: _centerLat + (0.01 * (0.5 - (DateTime.now().millisecond % 1000) / 1000)),
      longitude: _centerLng + (0.01 * (0.5 - (DateTime.now().second % 60) / 60)),
      address: "123 Main St, New York, NY",
      name: "Current Location",
      timestamp: DateTime.now(),
    );

    // Simulate location updates
    _locationSubscription = Stream.periodic(
      const Duration(seconds: 10),
      (i) => UserLocation(
        latitude: _centerLat + (0.01 * (0.5 - ((DateTime.now().millisecond + i * 100) % 1000) / 1000)),
        longitude: _centerLng + (0.01 * (0.5 - ((DateTime.now().second + i) % 60) / 60)),
        address: "123 Main St, New York, NY",
        name: "Current Location",
        timestamp: DateTime.now(),
      ),
    ).listen((location) {
      if (mounted) {
        setState(() => _currentLocation = location);
      }
    });
  }

  Future<void> _setupProviderTracking() async {
    if (!widget.showNearbyProviders) return;

    // Load initial providers
    if (_currentLocation != null) {
      await _loadNearbyProviders();
    }

    _providersSubscription = _providerService.nearbyProvidersStream.listen(
      (providers) async {
        if (mounted) {
          setState(() => _nearbyProviders = providers);
        }
      },
    );
  }

  void _setupAppointmentTracking() {
    _appointmentSubscription = _providerService.appointmentUpdatesStream.listen(
      (appointment) async {
        if (appointment.id == widget.appointmentId && mounted) {
          setState(() => _currentAppointment = appointment);
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

  void _onProviderTapped(HealthcareProvider provider) {
    setState(() {
      _selectedProvider = provider;
      _showProviderDetails = true;
    });
    widget.onProviderSelected?.call(provider);
  }

  void _onMapTapped() {
    setState(() {
      _showProviderDetails = false;
      _selectedProvider = null;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _providersSubscription?.cancel();
    _appointmentSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mock Map Background
          _buildMockMap(),
          
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

  Widget _buildMockMap() {
    return GestureDetector(
      onTap: _onMapTapped,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[100]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Grid pattern to simulate map
            ...List.generate(20, (i) => List.generate(20, (j) {
              return Positioned(
                left: (i * 50.0) + 25,
                top: (j * 50.0) + 25,
                child: Container(
                  width: 1,
                  height: 1,
                  color: Colors.grey[300],
                ),
              );
            })).expand((x) => x),
            
            // Mock streets
            ...List.generate(5, (i) {
              return Positioned(
                left: 0,
                top: 100.0 + (i * 100),
                child: Container(
                  width: double.infinity,
                  height: 3,
                  color: Colors.grey[400],
                ),
              );
            }),
            
            ...List.generate(5, (i) {
              return Positioned(
                left: 80.0 + (i * 80),
                top: 0,
                child: Container(
                  width: 3,
                  height: double.infinity,
                  color: Colors.grey[400],
                ),
              );
            }),

            // Patient location marker
            if (_currentLocation != null) _buildPatientMarker(),

            // Provider markers
            ..._nearbyProviders.map((provider) => _buildProviderMarker(provider)),

            // Mock buildings/landmarks
            _buildMockLandmarks(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientMarker() {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.5 - 20,
      top: MediaQuery.of(context).size.height * 0.5 - 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderMarker(HealthcareProvider provider) {
    final index = _nearbyProviders.indexOf(provider);
    final radius = 100.0;
    
    final left = MediaQuery.of(context).size.width * 0.5 + (radius * 1.5 * (index % 2 == 0 ? 1 : -1)) - 15;
    final top = MediaQuery.of(context).size.height * 0.5 + (radius * (index / _nearbyProviders.length - 0.5)) - 15;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _onProviderTapped(provider),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _getProviderColor(provider.status),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            _getProviderIcon(provider.specialty),
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMockLandmarks() {
    return Stack(
      children: [
        // Hospital
        Positioned(
          left: 50,
          top: 100,
          child: Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: const Center(
              child: Icon(Icons.local_hospital, color: Colors.red, size: 20),
            ),
          ),
        ),
        // Pharmacy
        Positioned(
          right: 80,
          top: 150,
          child: Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: const Center(
              child: Icon(Icons.local_pharmacy, color: Colors.green, size: 16),
            ),
          ),
        ),
        // Clinic
        Positioned(
          left: MediaQuery.of(context).size.width - 120,
          bottom: 200,
          child: Container(
            width: 70,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: const Center(
              child: Icon(Icons.medical_services, color: Colors.blue, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "current_location",
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3B82F6),
            onPressed: () {
              // Animate to current location (mock)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Centered on current location'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          if (_nearbyProviders.isNotEmpty)
            FloatingActionButton(
              heroTag: "fit_markers",
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitted all providers'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.center_focus_strong),
            ),
        ],
      ),
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
                  backgroundColor: _getProviderColor(_selectedProvider!.status),
                  child: Icon(
                    _getProviderIcon(_selectedProvider!.specialty),
                    color: Colors.white,
                    size: 30,
                  ),
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
                    color: _getProviderColor(_selectedProvider!.status),
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
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
                            widget.onProviderSelected?.call(_selectedProvider!);
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
          ],
        ),
      ),
    );
  }

  Color _getProviderColor(ProviderStatus status) {
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

  IconData _getProviderIcon(String specialty) {
    switch (specialty) {
      case 'General Practitioner':
        return Icons.medical_services;
      case 'Registered Nurse':
        return Icons.healing;
      case 'Cardiologist':
        return Icons.favorite;
      case 'Pediatrician':
        return Icons.child_care;
      case 'Physical Therapist':
        return Icons.accessibility_new;
      case 'Mental Health Counselor':
        return Icons.psychology;
      default:
        return Icons.person;
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
