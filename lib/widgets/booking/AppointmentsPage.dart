import 'package:flutter/material.dart';
import 'package:firstv/core/enhanced_theme.dart';
import 'package:firstv/routes/app_routes.dart';
import 'package:firstv/widgets/enhanced_custom_button.dart';
import 'ServiceSelectionPage.dart';
import '../../data/services/healthcare_service_provider.dart';

class Appointment {
  final String id;
  final ServiceType serviceType;
  final Specialty specialty;
  final String locationName;
  final String address;
  final DateTime appointmentTime;
  final String status;
  final double totalPrice;
  final String paymentMethod;

  Appointment({
    required this.id,
    required this.serviceType,
    required this.specialty,
    required this.locationName,
    required this.address,
    required this.appointmentTime,
    required this.status,
    required this.totalPrice,
    required this.paymentMethod,
  });
}

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<Appointment> _appointments = [];

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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    // Add sample appointment (this would normally come from the booking system)
    _addSampleAppointment();
  }

  void _addSampleAppointment() {
    _appointments.add(Appointment(
      id: 'APT-${DateTime.now().millisecondsSinceEpoch}',
      serviceType: ServiceType.doctor,
      specialty: Specialty.cardiology,
      locationName: 'Home Visit',
      address: '123 Main Street, City',
      appointmentTime: DateTime.now().add(const Duration(days: 1)),
      status: 'Confirmed',
      totalPrice: 150.0,
      paymentMethod: 'Credit Card',
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getServiceTitle(ServiceType serviceType, Specialty specialty) {
    final specialtyName = _getSpecialtyName(specialty);
    switch (serviceType) {
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

  // Removed unused _getStatusColor; unified to theme colors for consistency

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} from now';
    } else {
      return 'Starting now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EnhancedAppTheme.primaryIndigo.withOpacity(0.05),
            EnhancedAppTheme.primaryPurple.withOpacity(0.03),
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(65), // Reduced from 80 to 65
          child: Container(
            padding: const EdgeInsets.only(top: 25), // Reduced from 40 to 25
            child: AppBar(
              toolbarHeight: 100, // Increased from 40 to 100 for much lower positioning from top
              title: FadeTransition(
                opacity: _fadeAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      EnhancedAppTheme.primaryIndigo,
                      EnhancedAppTheme.primaryPurple,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'My Appointments',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: Container(
                margin: const EdgeInsets.only(left: 16),
                child: EnhancedIconButton(
                  icon: Icons.arrow_back_ios,
                  variant: ButtonVariant.glassmorphic,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            EnhancedAppTheme.primaryIndigo,
                            EnhancedAppTheme.primaryPurple,
                            EnhancedAppTheme.cyanBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: EnhancedAppTheme.mediumShadow,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 100), // Spacing for app bar
            
            // Header section
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: EnhancedAppTheme.glassmorphicDecoration().copyWith(
                  gradient: EnhancedAppTheme.primaryGradient,
                  boxShadow: EnhancedAppTheme.coloredShadow(EnhancedAppTheme.primaryIndigo.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appointment Summary',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_appointments.length} appointment${_appointments.length == 1 ? '' : 's'} scheduled',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Appointments list
            Expanded(
              child: _appointments.isEmpty
                  ? Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    EnhancedAppTheme.primaryIndigo.withOpacity(0.1),
                                    EnhancedAppTheme.primaryPurple.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: EnhancedAppTheme.primaryIndigo.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No appointments yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: EnhancedAppTheme.primaryIndigo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Book your first appointment to get started',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(_appointments[index], index);
                      },
                    ),
            ),
            
            // Action buttons
            Container(
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: EnhancedCustomButton(
                      text: 'Home',
                      variant: ButtonVariant.secondary,
                      leadingIcon: Icons.home_outlined,
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EnhancedCustomButton(
                      text: 'Book New Appointment',
                      variant: ButtonVariant.gradient,
                      leadingIcon: Icons.add,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                const ServiceSelectionPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;
                              var tween = Tween(begin: begin, end: end).chain(
                                CurveTween(curve: curve),
                              );
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 400),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1 * (index + 1)),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index + 1) * 0.1).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        )),
        child: Container(
          decoration: EnhancedAppTheme.glassmorphicDecoration().copyWith(
            boxShadow: EnhancedAppTheme.softShadow,
          ),
          child: Column(
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EnhancedAppTheme.primaryIndigo.withOpacity(0.1),
                      EnhancedAppTheme.primaryPurple.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: EnhancedAppTheme.softShadow,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getServiceTitle(appointment.serviceType, appointment.specialty),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: EnhancedAppTheme.primaryIndigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appointment.id,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [EnhancedAppTheme.cyanBlue, EnhancedAppTheme.emeraldGreen],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: EnhancedAppTheme.softShadow,
                      ),
                      child: Text(
                        appointment.status,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      appointment.locationName,
                      EnhancedAppTheme.primaryIndigo,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.access_time,
                      'Time',
                      _formatDateTime(appointment.appointmentTime),
                      EnhancedAppTheme.cyanBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.payment,
                      'Payment',
                      '${appointment.paymentMethod} - \$${appointment.totalPrice.toStringAsFixed(2)}',
                      EnhancedAppTheme.accentAmber,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.2),
                accentColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

