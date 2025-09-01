import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/services/algeria_location_service.dart';
import '../../data/services/healthcare_service_provider.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../widgets/booking/LocationSelectionPage.dart';
import '../../widgets/booking/PaymentPage.dart';

class EnhancedServiceSummaryPage extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;
  final LocationData selectedLocation;

  const EnhancedServiceSummaryPage({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
    required this.selectedLocation,
  });

  @override
  State<EnhancedServiceSummaryPage> createState() => _EnhancedServiceSummaryPageState();
}

class _EnhancedServiceSummaryPageState extends State<EnhancedServiceSummaryPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, double> _pricingInfo = {};
  Map<String, dynamic> _arrivalInfo = {};
  double _distance = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _calculatePricing();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _calculatePricing() {
    // Calculate distance from a reference point (Algiers center)
    _distance = AlgeriaLocationService.calculateDistance(
      36.7538, 3.0588, // Algiers coordinates
      widget.selectedLocation.latitude,
      widget.selectedLocation.longitude,
    );

    // Get pricing information
    _pricingInfo = AlgeriaLocationService.calculateHealthcarePricing(
      distance: _distance,
      serviceType: _getServiceTypeString(widget.selectedService),
      specialty: _getSpecialtyString(widget.selectedSpecialty),
    );

    // Get estimated arrival time
    _arrivalInfo = AlgeriaLocationService.getEstimatedArrival(_distance);

    setState(() {});
  }

  String _getServiceTypeString(ServiceType type) {
    switch (type) {
      case ServiceType.doctor:
        return 'doctor';
      case ServiceType.nurse:
        return 'nurse';
    }
  }

  String _getSpecialtyString(Specialty specialty) {
    switch (specialty) {
      case Specialty.cardiology:
        return 'cardiology';
      case Specialty.neurology:
        return 'neurology';
      case Specialty.pediatrics:
        return 'pediatrics';
      case Specialty.emergency:
        return 'emergency';
      default:
        return 'general';
    }
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PaymentPage(
          selectedService: widget.selectedService,
          selectedSpecialty: widget.selectedSpecialty,
          selectedLocation: widget.selectedLocation,
          basePrice: _pricingInfo['basePrice'] ?? 0.0,
          travelFee: _pricingInfo['travelFee'] ?? 0.0,
          serviceFee: _pricingInfo['serviceFee'] ?? 0.0,
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
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildServiceCard(),
                        const SizedBox(height: 20),
                        _buildLocationCard(),
                        const SizedBox(height: 20),
                        _buildPricingCard(),
                        const SizedBox(height: 20),
                        _buildArrivalCard(),
                        const SizedBox(height: 20),
                        _buildFeaturesCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review your booking details',
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

  Widget _buildServiceCard() {
    return _buildCard(
      title: 'Selected Service',
      icon: Icons.medical_services,
      color: AppTheme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getServiceDisplayName(widget.selectedService),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getSpecialtyDisplayName(widget.selectedSpecialty),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getServiceDescription(widget.selectedService, widget.selectedSpecialty),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildCard(
      title: 'Service Location',
      icon: Icons.location_on,
      color: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selectedLocation.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.selectedLocation.address,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Distance: ${_distance.toStringAsFixed(1)} km from nearest provider',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    if (_pricingInfo.isEmpty) {
      return _buildCard(
        title: 'Pricing Information',
        icon: Icons.payment,
        color: Colors.amber,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildCard(
      title: 'Pricing Information',
      icon: Icons.payment,
      color: Colors.amber,
      child: Column(
        children: [
          _buildPriceRow(
            'Service Fee',
            '${_pricingInfo['basePrice']?.toStringAsFixed(0)} DZD',
            false,
          ),
          _buildPriceRow(
            'Travel Fee',
            '${_pricingInfo['travelFee']?.toStringAsFixed(0)} DZD',
            false,
          ),
          _buildPriceRow(
            'Platform Fee',
            '${_pricingInfo['serviceFee']?.toStringAsFixed(0)} DZD',
            false,
          ),
          const Divider(height: 24),
          _buildPriceRow(
            'Total Amount',
            '${_pricingInfo['totalPrice']?.toStringAsFixed(0)} DZD',
            true,
          ),
          if (_pricingInfo['timeMultiplier'] != null && _pricingInfo['timeMultiplier']! > 1.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Peak hours surcharge applied (${((_pricingInfo['timeMultiplier']! - 1) * 100).toInt()}%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArrivalCard() {
    if (_arrivalInfo.isEmpty) {
      return _buildCard(
        title: 'Estimated Arrival',
        icon: Icons.access_time,
        color: Colors.blue,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildCard(
      title: 'Estimated Arrival',
      icon: Icons.access_time,
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _arrivalInfo['formattedArrival'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _arrivalInfo['formattedDuration'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated arrival time based on current traffic conditions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return _buildCard(
      title: 'What\'s Included',
      icon: Icons.check_circle,
      color: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureItem('Real-time tracking of healthcare professional'),
          _buildFeatureItem('Professional consultation at your location'),
          _buildFeatureItem('Secure payment processing'),
          _buildFeatureItem('24/7 customer support'),
          _buildFeatureItem('Insurance documentation (if required)'),
          _buildFeatureItem('Follow-up care recommendations'),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryColor : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_pricingInfo['totalPrice']?.toStringAsFixed(0) ?? '0'} DZD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceDisplayName(ServiceType type) {
    switch (type) {
      case ServiceType.doctor:
        return 'Doctor Consultation';
      case ServiceType.nurse:
        return 'Nursing Care';
    }
  }

  String _getSpecialtyDisplayName(Specialty specialty) {
    final specialtyId = specialty.toString().split('.').last;
    
    // Check if it's a medical specialty
    final medicalSpecialty = HealthcareServiceProvider.getMedicalSpecialty(specialtyId);
    if (medicalSpecialty != null) {
      return medicalSpecialty.name;
    }
    
    // Check if it's a nursing service
    final nursingService = HealthcareServiceProvider.getNursingService(specialtyId);
    if (nursingService != null) {
      return nursingService.name;
    }
    
    // Fallback for any missing specialties
    return specialtyId.replaceAllMapped(
      RegExp(r'([A-Z])'), 
      (match) => ' ${match.group(1)}'
    ).trim();
  }

  String _getServiceDescription(ServiceType type, Specialty specialty) {
    if (type == ServiceType.doctor) {
      switch (specialty) {
        case Specialty.cardiology:
          return 'Comprehensive cardiac assessment and consultation at your location';
        case Specialty.neurology:
          return 'Neurological examination and consultation services';
        case Specialty.pediatrics:
          return 'Specialized medical care for children and adolescents';
        case Specialty.emergency:
          return 'Emergency medical consultation and immediate care';
        default:
          return 'General medical consultation and health assessment';
      }
    } else {
      return 'Professional nursing care and health support services';
    }
  }
}
