import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/enhanced_theme.dart';
import '../../core/services/call_service.dart';
import '../maps/flutter_map_tracking_widget.dart';
import '../../data/models/location_models.dart';
import '../../data/services/enhanced_provider_tracking_service.dart';
import '../../data/services/location_service.dart';
import '../../screens/chat/provider_chat_screen.dart';
import 'ServiceSelectionPage.dart';
import 'LocationSelectionPage.dart';
import 'package:latlong2/latlong.dart';

class ProviderTrackingScreen extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;
  final LocationData selectedLocation;
  final String appointmentId;
  final Map<String, dynamic>? preSelectedDoctor;
  
  const ProviderTrackingScreen({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
    required this.selectedLocation,
    required this.appointmentId,
    this.preSelectedDoctor,
  });

  @override
  State<ProviderTrackingScreen> createState() => _ProviderTrackingScreenState();
}

class _ProviderTrackingScreenState extends State<ProviderTrackingScreen>
    with TickerProviderStateMixin {
  
  final EnhancedProviderTrackingService _trackingService = EnhancedProviderTrackingService();
  final LocationService _locationService = LocationService();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State
  HealthcareProvider? _assignedProvider;
  UserLocation? _currentLocation;
  bool _isLoading = true;
  String _statusMessage = "Finding nearby provider...";
  int _estimatedArrival = 15;
  
  // Streams
  StreamSubscription<HealthcareProvider>? _providerLocationSubscription;
  StreamSubscription<TrackingUpdate>? _trackingUpdateSubscription;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTrackingProcess();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startTrackingProcess() async {
    try {
      // Get current location
      _currentLocation = await _locationService.getCurrentLocation();
      
      // Simulate finding provider (in real app, this would be an API call)
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if we have a pre-selected doctor
      if (widget.preSelectedDoctor != null) {
        // Create HealthcareProvider from pre-selected doctor
        final doctor = widget.preSelectedDoctor!;
        final selectedProvider = HealthcareProvider(
          id: doctor['id'] ?? 'selected_doctor',
          name: doctor['name'] ?? 'Selected Doctor',
          specialty: doctor['specialty'] ?? 'Medical Professional',
          rating: (doctor['rating'] ?? 4.8).toDouble(),
          currentLocation: UserLocation(
            latitude: doctor['latitude'] ?? 36.7538,
            longitude: doctor['longitude'] ?? 3.0588,
            address: doctor['address'] ?? doctor['location'] ?? 'Algeria',
            timestamp: DateTime.now(),
          ),
          status: ProviderStatus.enRoute,
          totalReviews: doctor['reviews'] ?? 100,
          profileImage: doctor['avatar'] ?? 'assets/images/avatar.png',
          phoneNumber: '+213 ${doctor['id']?.hashCode.abs().toString().substring(0, 8)}',
          services: [doctor['specialty'] ?? 'General Medicine'],
          pricing: {'consultation': (doctor['consultationFee'] ?? 150).toDouble()},
          distanceFromPatient: 2.5, // Default distance
          estimatedArrivalMinutes: 15,
        );
        
        setState(() {
          _assignedProvider = selectedProvider;
          _isLoading = false;
          _statusMessage = "${doctor['name']} is assigned and on the way!";
        });
      } else {
        // Get nearby providers (original logic)
        final providers = await _trackingService.getNearbyProviders(
          patientLocation: _currentLocation!,
          radiusInKm: 10.0,
          serviceType: widget.selectedService,
        );
        
        // Apply specialty filtering if we have providers
        List<HealthcareProvider> filteredProviders = providers;
        if (providers.isNotEmpty && widget.selectedService == ServiceType.doctor) {
          // Use the selected specialty for filtering
          String targetSpecialty = widget.selectedSpecialty.toString().split('.').last;
          filteredProviders = _filterProvidersBySpecialty(providers, targetSpecialty);
          
          // If no specialty match found, fall back to all providers
          if (filteredProviders.isEmpty) {
            filteredProviders = providers;
          }
        }
        
        if (filteredProviders.isNotEmpty) {
          setState(() {
            _assignedProvider = filteredProviders.first;
            _isLoading = false;
            _statusMessage = "Provider assigned and on the way!";
          });
        }
      }
      
      if (_assignedProvider != null) {
        
        // Start tracking the assigned provider
        _trackingService.startProviderTracking(_assignedProvider!.id);
        
        // Listen to provider location updates
        _providerLocationSubscription = _trackingService.providerLocationStream.listen(
          (updatedProvider) {
            if (updatedProvider.id == _assignedProvider!.id) {
              setState(() {
                _assignedProvider = updatedProvider;
                _estimatedArrival = _calculateETA(updatedProvider);
                _statusMessage = _getStatusMessage(updatedProvider);
              });
            }
          },
        );
        
        // Listen to tracking updates
        _trackingUpdateSubscription = _trackingService.trackingUpdatesStream.listen(
          (trackingUpdate) {
            if (trackingUpdate.providerId == _assignedProvider!.id) {
              setState(() {
                _estimatedArrival = trackingUpdate.estimatedArrivalMinutes;
                _statusMessage = _getTrackingStatusMessage(trackingUpdate);
              });
            }
          },
        );
        
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = "No providers available at the moment";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error finding provider. Please try again.";
      });
    }
  }

  int _calculateETA(HealthcareProvider provider) {
    // Simple ETA calculation based on distance and average speed
    if (provider.distanceFromPatient == null) return 15;
    
    final distanceKm = provider.distanceFromPatient!;
    final averageSpeedKmh = 30; // Average city driving speed
    final timeInMinutes = (distanceKm / averageSpeedKmh * 60).round();
    
    return timeInMinutes.clamp(5, 60); // Between 5 and 60 minutes
  }

  String _getStatusMessage(HealthcareProvider provider) {
    switch (provider.status) {
      case ProviderStatus.available:
        return "Provider is on the way to your location";
      case ProviderStatus.enRoute:
        return "Provider is traveling to you";
      case ProviderStatus.busy:
        return "Provider is currently busy";
      case ProviderStatus.offline:
        return "Provider is offline";
    }
  }

  String _getTrackingStatusMessage(TrackingUpdate update) {
    switch (update.providerStatus) {
      case ProviderStatus.available:
        return "Provider is preparing to come to you";
      case ProviderStatus.enRoute:
        return "Provider is on the way!";
      case ProviderStatus.busy:
        return "Provider is currently busy";
      case ProviderStatus.offline:
        return "Provider is offline";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _providerLocationSubscription?.cancel();
    _trackingUpdateSubscription?.cancel();
    _statusUpdateTimer?.cancel();
    
    // Stop tracking
    if (_assignedProvider != null) {
      _trackingService.stopProviderTracking();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Map section
                      Expanded(
                        flex: 3,
                        child: _buildMapSection(),
                      ),
                      
                      // Status and provider info section
                      Expanded(
                        flex: 2,
                        child: _buildStatusSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
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
              child: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Provider',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time location tracking',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _currentLocation != null
            ? FlutterMapTrackingWidget(
                appointmentId: widget.appointmentId,
                showNearbyProviders: true,
                selectedServiceType: widget.selectedService,
                selectedSpecialty: widget.selectedSpecialty,
                initialCenter: LatLng(
                  _currentLocation!.latitude,
                  _currentLocation!.longitude,
                ),
                initialZoom: 15.0,
                onProviderSelected: (provider) {
                  setState(() {
                    _assignedProvider = provider;
                  });
                },
              )
            : Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Specialty filter info
            if (widget.selectedService == ServiceType.doctor)
              _buildSpecialtyFilterInfo(),
            const SizedBox(height: 16),
            
            // Status indicator
            _buildStatusIndicator(),
            const SizedBox(height: 24),
            
            // Provider info card
            if (_assignedProvider != null)
              _buildProviderInfoCard(),
            
            const SizedBox(height: 24),
            
            // Communication buttons
            if (_assignedProvider != null)
              _buildCommunicationButtons(),
            
            const SizedBox(height: 16),
            
            // Emergency contact button
            _buildEmergencyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilterInfo() {
    final specialtyName = _getSpecialtyDisplayName(
      widget.selectedSpecialty.toString().split('.').last,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EnhancedAppTheme.primaryIndigo.withOpacity(0.1),
            EnhancedAppTheme.primaryIndigo.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EnhancedAppTheme.primaryIndigo.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: EnhancedAppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Specialty Filter Active',
                  style: TextStyle(
                    color: EnhancedAppTheme.primaryIndigo,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Showing $specialtyName specialists in your area',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isLoading ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? EnhancedAppTheme.primaryGradient
                        : EnhancedAppTheme.successGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoading ? EnhancedAppTheme.primaryIndigo : EnhancedAppTheme.successGreen).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isLoading ? Icons.search_rounded : Icons.person_pin_circle_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: EnhancedAppTheme.headingSmall.copyWith(
              color: const Color(0xFF1E293B),
            ),
          ),
          
          if (_assignedProvider != null && !_isLoading) ...[
            const SizedBox(height: 8),
            Text(
              'ETA: $_estimatedArrival minutes',
              style: EnhancedAppTheme.bodyLarge.copyWith(
                color: EnhancedAppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderInfoCard() {
    final provider = _assignedProvider!;
    final isDoctor = _isDoctorSpecialty(provider.specialty);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EnhancedAppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EnhancedAppTheme.primaryIndigo.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: EnhancedAppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Provider Header
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: isDoctor 
                      ? EnhancedAppTheme.primaryGradient
                      : const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDoctor 
                          ? EnhancedAppTheme.primaryIndigo 
                          : const Color(0xFF10B981)).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isDoctor ? Icons.medical_services : Icons.health_and_safety,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: EnhancedAppTheme.headingSmall.copyWith(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDoctor 
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF10B981), const Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getSpecialtyDisplayName(provider.specialty),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(provider.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(provider.status),
                      style: TextStyle(
                        color: _getStatusColor(provider.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Provider Stats Row
          Row(
            children: [
              _buildStatItem(
                icon: Icons.star,
                color: EnhancedAppTheme.accentAmber,
                label: 'Rating',
                value: provider.rating.toStringAsFixed(1),
                subtitle: '${provider.totalReviews} reviews',
              ),
              const SizedBox(width: 16),
              if (provider.distanceFromPatient != null)
                _buildStatItem(
                  icon: Icons.location_on,
                  color: EnhancedAppTheme.successGreen,
                  label: 'Distance',
                  value: '${provider.distanceFromPatient!.toStringAsFixed(1)} km',
                  subtitle: '$_estimatedArrival min ETA',
                ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: Icons.medical_information,
                color: EnhancedAppTheme.primaryIndigo,
                label: 'Services',
                value: '${provider.services.length}',
                subtitle: 'available',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Services List
          _buildServicesList(provider.services, isDoctor),
          
          const SizedBox(height: 16),
          
          // Pricing Information
          _buildPricingInfo(provider.pricing, isDoctor),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList(List<String> services, bool isDoctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDoctor ? Icons.medical_services : Icons.health_and_safety,
                color: EnhancedAppTheme.primaryIndigo,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Services',
                style: TextStyle(
                  color: EnhancedAppTheme.primaryIndigo,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((service) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EnhancedAppTheme.primaryIndigo.withOpacity(0.2)),
              ),
              child: Text(
                service,
                style: TextStyle(
                  color: EnhancedAppTheme.primaryIndigo,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingInfo(Map<String, double> pricing, bool isDoctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EnhancedAppTheme.successGreen.withOpacity(0.1),
            EnhancedAppTheme.successGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EnhancedAppTheme.successGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments,
                color: EnhancedAppTheme.successGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Pricing Information',
                style: TextStyle(
                  color: EnhancedAppTheme.successGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...pricing.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _getPricingLabel(entry.key),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value.toStringAsFixed(0)} DZD',
                  style: TextStyle(
                    color: EnhancedAppTheme.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  bool _isDoctorSpecialty(String specialty) {
    final doctorSpecialties = [
      'generalMedicine', 'cardiology', 'neurology', 'pediatrics', 
      'gynecology', 'orthopedics', 'dermatology', 'psychiatry',
      'ophthalmology', 'ent', 'urology', 'gastroenterology', 
      'oncology', 'emergency'
    ];
    return doctorSpecialties.contains(specialty);
  }

  String _getSpecialtyDisplayName(String specialty) {
    final specialtyNames = {
      'generalMedicine': 'General Medicine',
      'cardiology': 'Cardiology',
      'neurology': 'Neurology',
      'pediatrics': 'Pediatrics',
      'gynecology': 'Gynecology',
      'orthopedics': 'Orthopedics',
      'dermatology': 'Dermatology',
      'psychiatry': 'Psychiatry',
      'ophthalmology': 'Ophthalmology',
      'ent': 'ENT Specialist',
      'urology': 'Urology',
      'gastroenterology': 'Gastroenterology',
      'oncology': 'Oncology',
      'emergency': 'Emergency Medicine',
      'woundCare': 'Wound Care',
      'medicationAdministration': 'Medication Administration',
      'vitalsMonitoring': 'Vitals Monitoring',
      'injections': 'Injections',
      'bloodDrawing': 'Blood Drawing',
      'homeHealthAssessment': 'Home Health Assessment',
    };
    return specialtyNames[specialty] ?? specialty;
  }

  Color _getStatusColor(ProviderStatus status) {
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

  String _getStatusText(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.available:
        return 'Available';
      case ProviderStatus.enRoute:
        return 'En Route';
      case ProviderStatus.busy:
        return 'Busy';
      case ProviderStatus.offline:
        return 'Offline';
    }
  }

  String _getPricingLabel(String key) {
    final labels = {
      'consultation': 'Consultation',
      'home_visit': 'Home Visit Fee',
      'emergency': 'Emergency Fee',
      'treatment': 'Treatment',
    };
    return labels[key] ?? key;
  }

  Widget _buildCommunicationButtons() {
    return Row(
      children: [
        // Chat button
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EnhancedAppTheme.primaryIndigo,
                  EnhancedAppTheme.primaryIndigo.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: EnhancedAppTheme.primaryIndigo.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openChat(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Call button
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EnhancedAppTheme.successGreen,
                  EnhancedAppTheme.successGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: EnhancedAppTheme.successGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _makeCall(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          _showEmergencyDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: EnhancedAppTheme.dangerRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.emergency),
        label: const Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Filter providers by specialty (especially useful for doctors)
  List<HealthcareProvider> _filterProvidersBySpecialty(
    List<HealthcareProvider> providers,
    String? targetSpecialty,
  ) {
    if (targetSpecialty == null || targetSpecialty.isEmpty) {
      return providers;
    }
    
    return providers.where((provider) {
      // For exact specialty match
      if (provider.specialty.toLowerCase() == targetSpecialty.toLowerCase()) {
        return true;
      }
      
      // For partial specialty match (e.g., "general" matches "generalMedicine")
      if (provider.specialty.toLowerCase().contains(targetSpecialty.toLowerCase())) {
        return true;
      }
      
      // For common aliases
      final aliases = {
        'general': ['generalMedicine', 'general medicine', 'family medicine'],
        'heart': ['cardiology', 'cardiac'],
        'brain': ['neurology', 'neurological'],
        'children': ['pediatrics', 'pediatric'],
        'women': ['gynecology', 'obstetrics'],
        'bones': ['orthopedics', 'orthopedic'],
        'skin': ['dermatology', 'dermatological'],
        'mind': ['psychiatry', 'psychology', 'mental health'],
        'eye': ['ophthalmology', 'eye care'],
        'ear': ['ent', 'otolaryngology'],
        'emergency': ['emergency medicine', 'urgent care'],
        'wound': ['woundCare', 'wound care'],
        'medication': ['medicationAdministration', 'medication'],
        'injection': ['injections', 'vaccination'],
        'vitals': ['vitalsMonitoring', 'vital signs'],
        'blood': ['bloodDrawing', 'blood work'],
      };
      
      for (final alias in aliases.keys) {
        if (targetSpecialty.toLowerCase().contains(alias)) {
          return aliases[alias]!.any((spec) => 
            provider.specialty.toLowerCase().contains(spec.toLowerCase()));
        }
      }
      
      return false;
    }).toList();
  }

  void _openChat() {
    if (_assignedProvider != null) {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              ProviderChatScreen(
                providerId: _assignedProvider!.id,
                providerName: _assignedProvider!.name,
                specialty: _assignedProvider!.specialty.toString().split('.').last,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _makeCall() async {
    if (_assignedProvider != null) {
      final phoneNumber = _assignedProvider!.phoneNumber;
      await CallService.makeCall(
        phoneNumber,
        context: context,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No provider assigned yet'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.emergency,
              color: EnhancedAppTheme.dangerRed,
            ),
            const SizedBox(width: 8),
            const Text('Emergency'),
          ],
        ),
        content: const Text(
          'Do you need to contact emergency services? This will call 911 immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              CallService.makeEmergencyCall(
                context: context,
                showConfirmation: false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EnhancedAppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call 911'),
          ),
        ],
      ),
    );
  }
}
