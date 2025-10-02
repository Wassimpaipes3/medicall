import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/booking/ServiceSelectionPage.dart';
import '../../widgets/booking/ProviderTrackingScreen.dart';
import '../../widgets/booking/LocationSelectionPage.dart';
import '../../data/services/appointment_storage.dart';
import '../../routes/app_routes.dart';

class AppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedDoctor;
  
  const AppointmentScreen({super.key, this.selectedDoctor});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;



  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    print('DEBUG: Loading appointments from storage...');
    try {
      final appointments = await AppointmentStorage.getAllAppointments();
      print('DEBUG: Loaded ${appointments.length} appointments from storage');
      
      if (mounted) {
        setState(() {
          _appointments = appointments.map((appointment) {
            final mappedAppointment = {
              'id': appointment['id'] ?? '',
              'doctorName': _getServiceTitle(appointment),
              'specialty': _getSpecialtyName(appointment),
              'date': _formatDate(appointment['appointmentTime'] ?? ''),
              'time': _formatTime(appointment['appointmentTime'] ?? ''),
              'status': appointment['status'] ?? 'scheduled',
              'type': 'Consultation',
              'location': appointment['locationName'] ?? '',
              'avatar': 'assets/images/medlogo.png',
              'totalPrice': appointment['totalPrice'] ?? 0.0,
              'paymentMethod': appointment['paymentMethod'] ?? '',
            };
            print('DEBUG: Mapped appointment - ID: ${mappedAppointment['id']}, Doctor: ${mappedAppointment['doctorName']}, Status: ${mappedAppointment['status']}');
            return mappedAppointment;
          }).toList();
          _isLoading = false;
        });
      }
      print('DEBUG: State updated with ${_appointments.length} appointments');
    } catch (e) {
      print('DEBUG: Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading appointments: $e');
    }
  }

  String _getServiceTitle(Map<String, dynamic> appointment) {
    final serviceType = appointment['serviceType'] ?? '';
    final specialty = _getSpecialtyName(appointment);
    
    if (serviceType.contains('doctor')) {
      return 'Dr. Healthcare Provider - $specialty';
    } else {
      return 'Nurse Provider - $specialty';
    }
  }

  String _getSpecialtyName(Map<String, dynamic> appointment) {
    final specialty = appointment['specialty'] ?? '';
    return specialty.split('.').last.replaceAllMapped(
      RegExp(r'([A-Z])'), 
      (match) => ' ${match.group(1)}'
    ).trim();
  }

  String _formatDate(String dateTimeString) {
    if (dateTimeString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _formatTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
      return '$displayHour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  Future<void> _markAsCompleted(Map<String, dynamic> appointment) async {
    try {
      // Update appointment status to completed
      await AppointmentStorage.updateAppointmentStatus(
        appointment['id'], 
        'completed'
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment marked as completed'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to rating screen for patient to rate the provider
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushNamed(
          context,
          AppRoutes.ratingScreen,
          arguments: {
            'appointmentId': appointment['id'],
            'providerId': appointment['providerId'] ?? appointment['idpro'],
            'providerName': appointment['providerName'] ?? appointment['nom'] ?? 'Provider',
            'providerSpecialty': appointment['specialty'] ?? appointment['specialite'] ?? '',
            'providerPhoto': appointment['providerPhoto'] ?? appointment['photo_profile'],
          },
        );
      });
      
      // Reload appointments
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing appointment: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAppointment(Map<String, dynamic> appointment) async {
    print('DEBUG: Attempting to delete appointment with ID: ${appointment['id']}');
    
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: Text(
            'Are you sure you want to delete this appointment with ${appointment['doctorName']}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        print('DEBUG: User confirmed deletion, calling deleteAppointment');
        await AppointmentStorage.deleteAppointment(appointment['id']);
        
        print('DEBUG: Delete successful, showing snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        print('DEBUG: Reloading appointments');
        // Reload appointments
        _loadAppointments();
      } catch (e) {
        print('DEBUG: Error during deletion: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting appointment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('DEBUG: User cancelled deletion');
    }
  }

  void _trackProvider(Map<String, dynamic> appointment) {
    // Navigate to provider tracking screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProviderTrackingScreen(
          selectedService: _parseServiceType(appointment['serviceType'] ?? ''),
          selectedSpecialty: _parseSpecialty(appointment['specialty'] ?? ''),
          selectedLocation: LocationData(
            name: appointment['location'] ?? '',
            address: appointment['location'] ?? '',
            latitude: 0.0, // In real app, you'd store these
            longitude: 0.0,
          ),
          appointmentId: appointment['id'] ?? '',
        ),
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
  }

  ServiceType _parseServiceType(String serviceTypeString) {
    if (serviceTypeString.contains('doctor')) {
      return ServiceType.doctor;
    } else {
      return ServiceType.nurse;
    }
  }

  Specialty _parseSpecialty(String specialtyString) {
    // This is a simplified parsing - in a real app you'd have proper mapping
    if (specialtyString.toLowerCase().contains('cardiology')) {
      return Specialty.cardiology;
    } else if (specialtyString.toLowerCase().contains('neurology')) {
      return Specialty.neurology;
    } else if (specialtyString.toLowerCase().contains('orthopedics')) {
      return Specialty.orthopedics;
    } else if (specialtyString.toLowerCase().contains('pediatrics')) {
      return Specialty.pediatrics;
    } else {
      return Specialty.generalMedicine; // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 114, // Increased from 88 to 114 for much lower positioning from top
        titleSpacing: 12, // Increased spacing for better positioning
        leading: IconButton(
          iconSize: 24, // Increased from 20 to 24
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            // Reset navigation to home state
            NavigationController().setCurrentIndex(0);
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'My Schedule',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22, // Increased from 18 to 22
            height: 1.2,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  : Column(
                      children: [
                        // Schedule header with calendar view indicator
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Your Schedule',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_appointments.length} ${_appointments.length == 1 ? 'appointment' : 'appointments'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show appointments directly (schedule view)
                        Expanded(
                          child: _buildMyAppointments(),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ServiceSelectionPage()),
          );
        },
        icon: const Icon(Icons.medical_services_rounded, color: Colors.white),
        label: const Text(
          'Book Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMyAppointments() {
    if (_appointments.isEmpty) {
      return _buildEmptyAppointments();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final isUpcoming = appointment['status'] == 'scheduled' || appointment['status'] == 'upcoming';
    final isCompleted = appointment['status'] == 'completed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isUpcoming
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Doctor Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.person_rounded,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Appointment Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appointment['doctorName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUpcoming 
                              ? Colors.green 
                              : isCompleted 
                                  ? Colors.blue 
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment['status'].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    appointment['specialty'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${appointment['date']} at ${appointment['time']}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment['location'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            if (isUpcoming) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  // Track Provider Button
                  GestureDetector(
                    onTap: () => _trackProvider(appointment),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Complete Button
                  GestureDetector(
                    onTap: () => _markAsCompleted(appointment),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Delete Button
                  GestureDetector(
                    onTap: () => _deleteAppointment(appointment),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(width: 8),
              // Delete Button for completed appointments
              GestureDetector(
                onTap: () => _deleteAppointment(appointment),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAppointments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your schedule is clear',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "Book Service" button below to schedule your first appointment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
