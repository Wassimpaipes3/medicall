/// Example usage of the AppointmentService after payment completion
/// This demonstrates how to integrate the service into your payment workflow

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class AppointmentServiceExample {
  
  /// Example 1: Create appointment after successful payment
  static Future<void> exampleCreateAppointment() async {
    try {
      // After payment is successfully processed, create appointment
      final appointmentId = await AppointmentService.createAppointmentWithValidation(
        service: 'generalist',                           // Selected healthcare service
        type: 'instant',                                 // instant or scheduled
        patientAddress: '123 Main St, Algiers, Algeria', // Patient's address
        patientLocation: const GeoPoint(36.7538, 3.0588), // Patient coordinates
        providerLocation: const GeoPoint(36.7538, 3.0588), // Provider coordinates (updated later)
        prix: 75.50,                                     // Total payment amount
        additionalData: {
          'paymentMethod': 'Credit Card',
          'urgency': 'normal',
          'notes': 'Patient requires home visit',
        },
      );

      print('✅ Appointment created successfully: $appointmentId');
      
      // After creating appointment, send notifications to providers
      await notifyProviders(appointmentId);
      
    } catch (e) {
      print('❌ Error: $e');
      // Handle error appropriately in your UI
    }
  }

  /// Example 2: Create scheduled appointment
  static Future<void> exampleScheduledAppointment() async {
    try {
      final appointmentId = await AppointmentService.createAppointmentWithValidation(
        service: 'wound care',                           
        type: 'scheduled',                               
        patientAddress: '456 Health Ave, Oran, Algeria',
        patientLocation: const GeoPoint(35.6976, -0.6337), // Oran coordinates
        providerLocation: const GeoPoint(35.6976, -0.6337),
        prix: 120.00,
        additionalData: {
          'scheduledDateTime': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'paymentMethod': 'Mobile Payment',
          'urgency': 'high',
        },
      );

      await notifyProviders(appointmentId);
      
    } catch (e) {
      print('❌ Error creating scheduled appointment: $e');
    }
  }

  /// Example 3: Complete appointment workflow in a payment page
  static Future<String?> completeAppointmentWorkflow({
    required String selectedService,
    required String patientAddress,
    required double latitude,
    required double longitude,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      // 1. Process payment first (your existing payment logic)
      print('💳 Processing payment...');
      await Future.delayed(const Duration(seconds: 2)); // Simulate payment
      
      // 2. Create appointment in Firestore after successful payment
      print('📝 Creating appointment after successful payment...');
      final appointmentId = await AppointmentService.createAppointmentWithValidation(
        service: selectedService,
        type: 'instant', // You can make this dynamic based on user selection
        patientAddress: patientAddress,
        patientLocation: GeoPoint(latitude, longitude),
        providerLocation: const GeoPoint(36.7538, 3.0588), // Default, updated when provider accepts
        prix: totalPrice,
        additionalData: {
          'paymentMethod': paymentMethod,
          'platform': 'mobile_app',
        },
      );

      // 3. Send notifications to available providers
      print('🔔 Sending notifications to providers...');
      await notifyProviders(appointmentId);
      
      // 4. Mark notifications as sent
      await AppointmentService.markNotificationsSent(appointmentId);
      
      return appointmentId;
      
    } catch (e) {
      print('❌ Appointment workflow failed: $e');
      return null;
    }
  }

  /// Send notifications to providers about new appointment
  static Future<void> notifyProviders(String appointmentId) async {
    try {
      // Get the appointment details
      final appointment = await AppointmentService.getAppointmentById(appointmentId);
      if (appointment == null) {
        throw Exception('Appointment not found');
      }

      print('🔔 Sending notifications to providers for appointment: $appointmentId');
      print('📍 Service: ${appointment['service']}');
      print('💰 Price: \$${appointment['prix']}');
      print('📍 Location: ${appointment['patientAddress']}');

      // Here you would integrate with your notification service
      // For example:
      
      // Option 1: Using Firebase Cloud Functions (recommended)
      // Your cloud function will automatically detect new appointments
      // and send push notifications to nearby providers
      
      // Option 2: Direct notification service call
      // await NotificationService.notifyNearbyProviders(
      //   appointmentId: appointmentId,
      //   service: appointment['service'],
      //   location: appointment['patientLocation'],
      //   price: appointment['prix'],
      // );
      
      // Option 3: Update provider-specific collections
      // await _addAppointmentToProviderQueues(appointment);

      print('✅ Provider notifications sent successfully');
      
    } catch (e) {
      print('❌ Error sending notifications: $e');
      throw Exception('Failed to notify providers: $e');
    }
  }

  /// Example of provider acceptance workflow
  static Future<void> exampleProviderAcceptance(String appointmentId, String providerId) async {
    try {
      // When provider accepts the appointment
      final success = await AppointmentService.assignProvider(appointmentId, providerId);
      
      if (success) {
        print('✅ Provider $providerId assigned to appointment $appointmentId');
        
        // Update appointment status
        await AppointmentService.updateAppointmentStatus(appointmentId, 'accepted');
        
        // Send notification to patient
        // await NotificationService.notifyPatientProviderAssigned(appointmentId, providerId);
        
      } else {
        print('❌ Failed to assign provider');
      }
      
    } catch (e) {
      print('❌ Error in provider acceptance: $e');
    }
  }

  /// Get all appointments for current patient (for appointment history screen)
  static Future<void> exampleGetPatientAppointments() async {
    try {
      final appointments = await AppointmentService.getPatientAppointments();
      
      print('📋 Patient has ${appointments.length} appointments:');
      for (final appointment in appointments) {
        print('  - ${appointment['service']} (${appointment['status']}) - \$${appointment['prix']}');
      }
      
    } catch (e) {
      print('❌ Error fetching appointments: $e');
    }
  }

  /// Integration with existing PaymentPage
  static Future<void> integrateWithPaymentPage(BuildContext context) async {
    // This is how you would modify your existing _processPayment method:
    
    /*
    Future<void> _processPayment() async {
      if (_selectedPaymentMethod == null) return;

      setState(() => _isProcessing = true);

      try {
        // 1. Simulate payment processing
        await Future.delayed(const Duration(seconds: 2));
        
        // 2. Use the new AppointmentService
        final appointmentId = await AppointmentServiceExample.completeAppointmentWorkflow(
          selectedService: _getServiceName(widget.selectedSpecialty),
          patientAddress: widget.selectedLocation.address,
          latitude: widget.selectedLocation.latitude,
          longitude: widget.selectedLocation.longitude,
          totalPrice: widget.basePrice + widget.travelFee + widget.serviceFee,
          paymentMethod: _getPaymentMethodText(),
        );

        if (appointmentId != null) {
          // 3. Navigate to tracking screen
          Navigator.pushReplacement(context, 
            MaterialPageRoute(builder: (_) => ProviderTrackingScreen(
              appointmentId: appointmentId,
              // ... other parameters
            ))
          );
        }
        
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      } finally {
        setState(() => _isProcessing = false);
      }
    }
    */
  }
}

/// Integration checklist for your existing app:
/// 
/// ✅ 1. Add AppointmentService to your project
/// ✅ 2. Update PaymentPage to use AppointmentService.createAppointmentWithValidation()
/// ✅ 3. Integrate with your notification system to alert providers
/// ✅ 4. Update ProviderTrackingScreen to use the Firestore appointment ID
/// ⬜ 5. Create provider interface to accept/reject appointments
/// ⬜ 6. Add real-time listeners for appointment status updates
/// ⬜ 7. Implement appointment history screen using getPatientAppointments()
/// ⬜ 8. Add appointment cancellation functionality
/// ⬜ 9. Integrate with your existing provider dashboard
/// ⬜ 10. Test end-to-end workflow: payment → creation → notification → acceptance