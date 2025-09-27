import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../services/notification_service.dart';
import '../../services/provider/provider_service.dart';
import '../../data/models/location_models.dart' as location_models;

class PatientRequestScreen extends StatefulWidget {
  const PatientRequestScreen({super.key});

  @override
  State<PatientRequestScreen> createState() => _PatientRequestScreenState();
}

class _PatientRequestScreenState extends State<PatientRequestScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          'Request Appointment',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Appointment Request',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a test screen to simulate patient appointment requests and test the notification system.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Regular Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _sendAppointmentRequest(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(18),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Regular Appointment Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Emergency Request Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _sendAppointmentRequest(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(18),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Send Emergency Request',
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
            
            const Spacer(),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'How to test:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Tap either button to send a test request\n'
                    '2. A notification will appear for providers\n'
                    '3. Tap the notification to view appointment details\n'
                    '4. Accept or decline the appointment',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimaryColor,
                      height: 1.4,
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

  void _sendAppointmentRequest(bool isEmergency) async {
    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Create appointment request object
      final appointmentRequest = AppointmentRequest(
        id: 'apt_${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'patient_001',
        patientName: 'John Doe',
        patientPhone: '+1 (555) 123-4567',
        patientLocation: location_models.UserLocation(
          latitude: 40.7128,
          longitude: -74.0060,
          address: '123 Main St, New York, NY 10001',
          timestamp: DateTime.now(),
        ),
        serviceType: isEmergency ? 'Emergency Care' : 'General Consultation',
        requestedDateTime: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        estimatedFee: isEmergency ? 300.0 : 150.0,
        estimatedDuration: isEmergency ? 60 : 30,
        isEmergency: isEmergency,
        specialInstructions: isEmergency 
            ? 'Patient experiencing severe chest pain. Immediate attention required.'
            : 'Regular checkup and consultation for general health assessment.',
      );

      // Send notification to providers
      _notificationService.showNewAppointmentRequest(appointmentRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isEmergency 
                      ? 'Emergency request sent! Providers will be notified immediately.'
                      : 'Appointment request sent! Providers will be notified.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: isEmergency ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
