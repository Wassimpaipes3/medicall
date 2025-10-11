import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ServiceSelectionPage.dart';
import 'LocationSelectionPage.dart';
import '../../screens/booking/polished_select_provider_screen.dart';
import '../../core/enhanced_theme.dart';
import '../../data/services/healthcare_service_provider.dart';
import '../../data/services/appointment_storage.dart';

enum PaymentMethod {
  cash,
  creditCard,
  mobilePayment,
  bankTransfer,
}

class PaymentPage extends StatefulWidget {
  final ServiceType selectedService;
  final Specialty selectedSpecialty;
  final LocationData selectedLocation;

  const PaymentPage({
    super.key,
    required this.selectedService,
    required this.selectedSpecialty,
    required this.selectedLocation,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.cash; // Default to cash
  bool _isProcessing = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBookingSummary(),
                        const SizedBox(height: 24),
                        _buildPaymentMethods(),
                        const SizedBox(height: 100), // Extra space for fixed button
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Fixed Payment Button at Bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _buildPaymentButton(),
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
                  'Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your payment method',
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

  Widget _buildBookingSummary() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Booking Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Service', _getServiceTitle()),
          const SizedBox(height: 12),
          _buildSummaryRow('Location', widget.selectedLocation.name),
          const SizedBox(height: 12),
          _buildSummaryRow('Address', widget.selectedLocation.address),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF1E293B) : Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF3B82F6) : Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodCard(
          PaymentMethod.cash,
          'Cash Payment',
          'Pay with cash upon service completion',
          Icons.money,
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: isSelected
          ? (Matrix4.identity()..scale(1.02))
          : Matrix4.identity(),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Glassmorphism effect like doctor/nurse cards
            gradient: isSelected 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.9),
                      color.withOpacity(0.8),
                      color.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                      color.withOpacity(0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected 
                  ? Colors.white.withOpacity(0.3)
                  : color.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              // Neon glow effect
              if (isSelected) ...[
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: -8,
                  offset: const Offset(0, 20),
                ),
              ],
              // Soft shadow for unselected
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? RadialGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        )
                      : RadialGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.black.withOpacity(0.15)
                          : color.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: color,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final canProceed = _selectedPaymentMethod != null && !_isProcessing;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        transform: canProceed
            ? (Matrix4.identity()
                ..scale(1.02)
                ..translate(0.0, -2.0))
            : Matrix4.identity(),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: canProceed
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA), // Soft Blue
                      Color(0xFF764BA2), // Purple
                      Color(0xFF6B73FF), // Indigo
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: canProceed 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: canProceed
                ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF764BA2).withOpacity(0.3),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                      spreadRadius: -10,
                    ),
                    // Inner glow effect
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                      spreadRadius: -5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canProceed ? _processPayment : null,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Processing Payment...',
                            style: EnhancedAppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Leading Icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: canProceed 
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: canProceed
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.lock_outlined,
                              color: canProceed ? Colors.white : Colors.grey.shade500,
                              size: 22,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Button Text
                          Expanded(
                            child: Text(
                              canProceed ? 'Confirm Payment' : 'Select Payment Method',
                              textAlign: TextAlign.center,
                              style: EnhancedAppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: canProceed ? Colors.white : Colors.grey.shade500,
                                letterSpacing: 0.3,
                                shadows: canProceed
                                    ? [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Trailing Icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: canProceed 
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: canProceed
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 300),
                              turns: canProceed ? 0 : -0.5,
                              child: Icon(
                                canProceed 
                                    ? Icons.check_circle_outlined
                                    : Icons.close_rounded,
                                color: canProceed ? Colors.white : Colors.grey.shade500,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }  String _getServiceTitle() {
    final specialtyName = _getSpecialtyName(widget.selectedSpecialty);
    switch (widget.selectedService) {
      case ServiceType.doctor:
        return 'Doctor Consultation - $specialtyName';
      case ServiceType.nurse:
        return 'Nursing Care - $specialtyName';
    }
  }

  String _getSpecialtyName(Specialty specialty) {
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

  /// Convert specialty to service name for Firestore appointment
  String _getServiceName(Specialty specialty) {
    final specialtyName = _getSpecialtyName(specialty).toLowerCase();
    
    // Map common specialties to service names
    if (specialtyName.contains('general') || specialtyName.contains('family')) {
      return 'generalist';
    } else if (specialtyName.contains('wound') || specialtyName.contains('care')) {
      return 'wound care';
    } else if (specialtyName.contains('emergency')) {
      return 'emergency';
    } else if (specialtyName.contains('nursing') || specialtyName.contains('nurse')) {
      return 'nursing';
    } else if (specialtyName.contains('therapy') || specialtyName.contains('physical')) {
      return 'physical therapy';
    } else if (specialtyName.contains('consultation')) {
      return 'consultation';
    } else {
      return 'consultation'; // Default to consultation
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Prepare appointment data for Firestore
      final service = _getServiceName(widget.selectedSpecialty);
  // Appointment type deferred; will be set when provider accepts
      
      // Create GeoPoint for patient location (using selected location coordinates)
      final patientLocation = GeoPoint(
        widget.selectedLocation.latitude,
        widget.selectedLocation.longitude,
      );
      
      print('💳 Payment successful! Deferring appointment creation until provider accepts.');

      // Also save to local storage as backup (keep existing functionality)
      final localAppointmentData = {
        'id': null,  // No appointment yet
        'serviceType': widget.selectedService.toString(),
        'specialty': widget.selectedSpecialty.toString(),
        'locationName': widget.selectedLocation.name,
        'locationAddress': widget.selectedLocation.address,
        'paymentMethod': _getPaymentMethodText(),
        'status': 'searching_provider',
        'createdAt': DateTime.now().toIso8601String(),
      };

      try {
        await AppointmentStorage.saveAppointment(localAppointmentData);
        print('✅ Local backup saved successfully');
      } catch (e) {
        print('⚠️ Local backup failed (non-critical): $e');
        // Don't throw error here as Firestore save was successful
      }

      setState(() {
        _isProcessing = false;
      });

      // Navigate to provider selection screen after payment
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PolishedSelectProviderScreen(
            service: service,
            specialty: _getServiceName(widget.selectedSpecialty),
            prix: 0.0, // Price will be determined later
            paymentMethod: _getPaymentMethodText(),
            patientLocation: patientLocation,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      print('❌ Error processing payment and creating appointment: $e');
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _processPayment,
          ),
        ),
      );
    }
  }

  String _getPaymentMethodText() {
    switch (_selectedPaymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.mobilePayment:
        return 'Mobile Payment';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      default:
        return 'Not Selected';
    }
  }
}
