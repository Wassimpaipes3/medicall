import 'package:flutter/material.dart';
import 'live_tracking_map.dart';
import '../../data/models/location_models.dart';
import '../../data/services/location_service.dart';
import '../../data/services/provider_tracking_service.dart';
import '../../data/services/pricing_service.dart';

class ComprehensiveMapPage extends StatefulWidget {
  final String? serviceType;
  final String? specialty;
  final bool isEmergency;

  const ComprehensiveMapPage({
    super.key,
    this.serviceType,
    this.specialty,
    this.isEmergency = false,
  });

  @override
  State<ComprehensiveMapPage> createState() => _ComprehensiveMapPageState();
}

class _ComprehensiveMapPageState extends State<ComprehensiveMapPage>
    with TickerProviderStateMixin {
  
  // Services
  final LocationService _locationService = LocationService();
  final ProviderTrackingService _providerService = ProviderTrackingService();
  final PricingService _pricingService = PricingService();

  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // State variables
  UserLocation? _currentLocation;
  HealthcareProvider? _selectedProvider;
  Map<String, dynamic>? _selectedPricing;
  bool _isLoading = true;
  bool _showProviderSelection = false;
  bool _showPricingDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeData() async {
    await _locationService.initialize();
    _currentLocation = await _locationService.getCurrentLocation();
    
    if (_currentLocation != null) {
      await _loadNearbyProviders();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadNearbyProviders() async {
    if (_currentLocation == null) return;

    final providers = await _providerService.getNearbyProviders(
      patientLocation: _currentLocation!,
      radiusInKm: 15.0,
      specialties: widget.specialty != null ? [widget.specialty!] : null,
      statusFilter: widget.isEmergency ? null : ProviderStatus.available,
    );

    // Providers are handled by the LiveTrackingMapWidget
    if (providers.isEmpty) {
      // Show no providers message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No providers found in your area'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onProviderSelected(HealthcareProvider provider) {
    setState(() {
      _selectedProvider = provider;
      _showProviderSelection = true;
    });
    _slideController.forward();

    // Calculate pricing
    if (widget.serviceType != null) {
      _calculatePricing(provider);
    }
  }

  void _calculatePricing(HealthcareProvider provider) {
    final pricing = _pricingService.calculateServiceCost(
      provider: provider,
      patientLocation: _currentLocation!,
      serviceType: widget.serviceType!,
      appointmentDateTime: DateTime.now().add(const Duration(hours: 1)),
      isEmergency: widget.isEmergency,
    );

    setState(() => _selectedPricing = pricing);
  }

  void _showPricing() {
    setState(() => _showPricingDetails = true);
  }

  void _hidePricing() {
    setState(() => _showPricingDetails = false);
  }

  void _bookAppointment() async {
    if (_selectedProvider == null || _currentLocation == null) return;

    // Create appointment
    try {
      final appointment = await _providerService.createAppointment(
        patientId: 'patient_123', // In real app, get from auth
        providerId: _selectedProvider!.id,
        patientLocation: _currentLocation!,
        scheduledDateTime: DateTime.now().add(const Duration(hours: 1)),
        serviceType: widget.serviceType ?? 'consultation',
        pricing: _selectedPricing ?? {},
        notes: widget.isEmergency ? 'Emergency appointment' : null,
      );

      // Navigate to tracking page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AppointmentTrackingPage(
              appointmentId: appointment.id,
              provider: _selectedProvider!,
            ),
          ),
        );
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100, // Added for much lower positioning from top
        title: Text(
          widget.isEmergency ? 'Emergency Service' : 'Find Healthcare Provider',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
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
            child: const Icon(Icons.arrow_back, color: Color(0xFF3B82F6)),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isEmergency)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'EMERGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          LiveTrackingMapWidget(
            showNearbyProviders: true,
            onProviderSelected: _onProviderSelected,
          ),

          // Provider selection bottom sheet
          if (_showProviderSelection) _buildProviderSelectionSheet(),

          // Pricing details overlay
          if (_showPricingDetails) _buildPricingDetailsOverlay(),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),

          // Emergency contact button
          if (widget.isEmergency) _buildEmergencyContactButton(),
        ],
      ),
    );
  }

  Widget _buildProviderSelectionSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
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
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Provider info
              _buildProviderInfo(),

              const SizedBox(height: 16),

              // Service details
              if (widget.serviceType != null) _buildServiceDetails(),

              const SizedBox(height: 16),

              // Pricing preview
              if (_selectedPricing != null) _buildPricingPreview(),

              const SizedBox(height: 20),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderInfo() {
    if (_selectedProvider == null) return const SizedBox();

    return Row(
      children: [
        // Profile image
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, size: 30, color: Colors.white),
        ),

        const SizedBox(width: 16),

        // Provider details
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
              const SizedBox(height: 4),
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
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedProvider!.distanceFromPatient?.toStringAsFixed(1)} km',
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

        // Status badge
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
    );
  }

  Widget _buildServiceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Service: ${widget.serviceType}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          if (widget.specialty != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Specialty: ${widget.specialty}',
                  style: TextStyle(
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'ETA: ${_selectedProvider!.estimatedArrivalMinutes} minutes',
                style: TextStyle(
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPreview() {
    return GestureDetector(
      onTap: _showPricing,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Total',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _pricingService.formatCurrency(_selectedPricing!['total']),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'View Details',
                  style: TextStyle(color: Colors.green[600]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Call button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Implement call functionality
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Book appointment button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _selectedProvider?.status == ProviderStatus.available
                ? _bookAppointment
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isEmergency 
                  ? Colors.red 
                  : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.isEmergency ? 'Book Emergency' : 'Book Appointment',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingDetailsOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Price Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _hidePricing,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Breakdown items
                ...(_selectedPricing!['breakdown'] as List)
                    .map((item) => _buildBreakdownItem(item))
                    ,

                const Divider(height: 32),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _pricingService.formatCurrency(_selectedPricing!['total']),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hidePricing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_getBreakdownIcon(item['icon']), size: 20),
              const SizedBox(width: 12),
              Text(item['description']),
            ],
          ),
          Text(
            _pricingService.formatCurrency(item['amount']),
            style: const TextStyle(fontWeight: FontWeight.w500),
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
              'Finding nearby providers...',
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

  Widget _buildEmergencyContactButton() {
    return Positioned(
      top: 120,
      right: 16,
      child: FloatingActionButton(
        heroTag: "emergency_contact",
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () {
          // Implement emergency contact
        },
        child: const Icon(Icons.phone),
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

  IconData _getBreakdownIcon(String iconName) {
    switch (iconName) {
      case 'medical_services':
        return Icons.medical_services;
      case 'directions_car':
        return Icons.directions_car;
      case 'nightlight':
        return Icons.nightlight;
      case 'weekend':
        return Icons.weekend;
      case 'emergency':
        return Icons.emergency;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.info;
    }
  }
}

// Appointment tracking page
class AppointmentTrackingPage extends StatelessWidget {
  final String appointmentId;
  final HealthcareProvider provider;

  const AppointmentTrackingPage({
    super.key,
    required this.appointmentId,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking ${provider.name}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100, // Added for much lower positioning from top
      ),
      body: LiveTrackingMapWidget(
        appointmentId: appointmentId,
        showNearbyProviders: false,
      ),
    );
  }
}
