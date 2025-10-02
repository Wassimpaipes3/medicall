import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing appointment creation and operations in Firestore
/// This service handles the complete appointment workflow: provider → type → location → payment → tracking
class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new appointment in Firestore after payment completion
  /// Returns the new appointment document ID for notification purposes
  static Future<String> createAppointment({
    required String service,           // e.g., 'generalist', 'wound care'
    required String type,              // 'instant' or 'scheduled'  
    required String patientAddress,    // Patient's address string
    required GeoPoint patientLocation, // Patient's GeoPoint(lat, lng)
    required double prix,              // Payment amount
    required String paymentMethod,     // Payment method (Cash, Card, etc.)
    required double serviceFee,        // Service fee amount
    String? notes,                     // Optional notes
    DateTime? appointmentDate,         // For scheduled appointments only
    DateTime? endTime,                 // For scheduled appointments only
  }) async {
    try {
      // Get current authenticated user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found. Please login first.');
      }

      print('📝 Creating appointment for user: ${user.uid}');
      print('👤 User email: ${user.email}');
      print('🔐 User email verified: ${user.emailVerified}');
      print('🏥 Service: $service, Type: $type, Price: \$${prix.toStringAsFixed(2)}');
      print('📍 Patient Location: ${patientLocation.latitude}, ${patientLocation.longitude}');

      // Check if patient document exists (required by security rules)
      try {
        final patientDoc = await _firestore.collection('patients').doc(user.uid).get();
        if (!patientDoc.exists) {
          print('❌ Patient document does not exist for user: ${user.uid}');
          throw Exception('Patient profile not found. Please complete your profile setup first.');
        }
        print('✅ Patient document verified for user: ${user.uid}');
      } catch (e) {
        print('❌ Error checking patient document: $e');
        throw Exception('Unable to verify patient profile. Please try again.');
      }

      // Create appointment document with your exact schema requirements
      final appointmentData = <String, dynamic>{
        // Your exact schema requirements
        'idpat': user.uid,                    // Current user UID
        'idpro': '',                          // Empty - provider will accept later
        'type': type,                         // 'instant' or 'scheduled'
        'service': service,                   // Selected service (e.g., 'generalist', 'wound care')
        'patientAddress': patientAddress,     // Patient's address string
        'patientlocation': patientLocation,   // GeoPoint(lat, lng) - note lowercase 'l'
        'providerlocation': null,             // NULL initially - will be set when provider accepts and shares location
        'status': 'pending',                  // Default status - pending provider acceptance
        'prix': prix,                         // Payment amount
        'paymentMethod': paymentMethod,       // Payment method (note: no 'e' at end)
        'serviceFee': serviceFee,             // Service fee amount
        'notes': notes ?? '',                 // Notes (empty string if null)
        
        // Conditional fields for scheduled appointments
        'appointmentDate': type == 'scheduled' ? appointmentDate?.toIso8601String() : null,
        'endTime': type == 'scheduled' ? endTime?.toIso8601String() : null,
        
        // Required timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📊 Final appointment data: ${appointmentData.toString()}');
      print('🔍 Data validation - idpat: ${appointmentData['idpat']}');
      print('🔍 Data validation - status: ${appointmentData['status']}');
      print('🔍 Data validation - user.uid: ${user.uid}');
      print('🔍 Checking: idpat == user.uid: ${appointmentData['idpat'] == user.uid}');

      // Save to Firestore appointments collection
      final docRef = await _firestore
          .collection('appointments')
          .add(appointmentData);

      final appointmentId = docRef.id;
      
      // Update the document with its own ID for easier reference
      await docRef.update({'appointmentId': appointmentId});

      print('✅ Appointment created successfully with ID: $appointmentId');
      print('🔔 Ready for provider notifications');

      return appointmentId;

    } catch (e) {
      print('❌ Error creating appointment: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check your authentication and try again.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else {
        throw Exception('Failed to create appointment: ${e.toString()}');
      }
    }
  }

  /// Get appointment by ID
  static Future<Map<String, dynamic>?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching appointment: $e');
      return null;
    }
  }

  /// Update appointment status
  static Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Appointment $appointmentId status updated to: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error updating appointment status: $e');
      return false;
    }
  }

  /// Assign provider to appointment (called when provider accepts)
  static Future<bool> assignProvider(String appointmentId, String providerId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'idpro': providerId,
            'providerAssigned': true,
            'status': 'accepted',
            'acceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Provider $providerId assigned to appointment $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error assigning provider: $e');
      return false;
    }
  }

  /// Mark notifications as sent for appointment
  static Future<bool> markNotificationsSent(String appointmentId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'notificationsSent': true,
            'notificationsSentAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      print('✅ Notifications marked as sent for appointment: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error marking notifications as sent: $e');
      return false;
    }
  }

  /// Get all appointments for current patient
  static Future<List<Map<String, dynamic>>> getPatientAppointments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final snapshot = await _firestore
          .collection('appointments')
          .where('idpat', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      print('❌ Error fetching patient appointments: $e');
      return [];
    }
  }

  /// Get pending appointments for providers (no provider assigned yet)
  static Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'pending')
          .where('idpro', isEqualTo: '')  // No provider assigned yet
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      print('❌ Error fetching pending appointments: $e');
      return [];
    }
  }

  /// Validate appointment data before creation
  static bool validateAppointmentData({
    required String service,
    required String type,
    required String patientAddress,
    required GeoPoint patientLocation,
    required double prix,
    required String paymentMethod,
    required double serviceFee,
    String? notes,
    DateTime? appointmentDate,
    DateTime? endTime,
  }) {
    // Validate service
    final validServices = [
      'generalist', 'wound care', 'consultation', 'emergency',
      'nursing', 'physical therapy', 'home visit'
    ];
    
    if (service.isEmpty || !validServices.contains(service.toLowerCase())) {
      throw ArgumentError('Invalid service: $service. Must be one of: ${validServices.join(', ')}');
    }

    // Validate type
    if (type != 'instant' && type != 'scheduled') {
      throw ArgumentError('Invalid type: $type. Must be "instant" or "scheduled"');
    }

    // Validate address
    if (patientAddress.isEmpty || patientAddress.length < 10) {
      throw ArgumentError('Patient address must be at least 10 characters long');
    }

    // Validate coordinates
    if (patientLocation.latitude < -90 || patientLocation.latitude > 90) {
      throw ArgumentError('Invalid patient latitude: ${patientLocation.latitude}');
    }
    if (patientLocation.longitude < -180 || patientLocation.longitude > 180) {
      throw ArgumentError('Invalid patient longitude: ${patientLocation.longitude}');
    }

    // Validate price
    if (prix <= 0) {
      throw ArgumentError('Price must be greater than 0: $prix');
    }

    // Validate payment method
    if (paymentMethod.isEmpty) {
      throw ArgumentError('Payment method cannot be empty');
    }

    // Validate service fee
    if (serviceFee < 0) {
      throw ArgumentError('Service fee cannot be negative: $serviceFee');
    }

    // Validate scheduled appointment fields
    if (type == 'scheduled') {
      if (appointmentDate == null) {
        throw ArgumentError('Appointment date is required for scheduled appointments');
      }
      if (endTime == null) {
        throw ArgumentError('End time is required for scheduled appointments');
      }
      if (appointmentDate.isBefore(DateTime.now())) {
        throw ArgumentError('Appointment date cannot be in the past');
      }
      if (endTime.isBefore(appointmentDate)) {
        throw ArgumentError('End time must be after appointment date');
      }
    }

    return true;
  }



  /// Create appointment with validation (main public method)
  static Future<String> createAppointmentWithValidation({
    required String service,
    required String type,
    required String patientAddress,
    required GeoPoint patientLocation,
    required double prix,
    required String paymentMethod,
    required double serviceFee,
    String? notes,
    DateTime? appointmentDate,
    DateTime? endTime,
  }) async {
    // Validate all data first
    validateAppointmentData(
      service: service,
      type: type,
      patientAddress: patientAddress,
      patientLocation: patientLocation,
      prix: prix,
      paymentMethod: paymentMethod,
      serviceFee: serviceFee,
      notes: notes,
      appointmentDate: appointmentDate,
      endTime: endTime,
    );

    // Create appointment if validation passes
    return await createAppointment(
      service: service,
      type: type,
      patientAddress: patientAddress,
      patientLocation: patientLocation,
      prix: prix,
      paymentMethod: paymentMethod,
      serviceFee: serviceFee,
      notes: notes,
      appointmentDate: appointmentDate,
      endTime: endTime,
    );
  }

  /// Update appointment when provider accepts and shares their location
  static Future<void> acceptAppointmentAndSetLocation({
    required String appointmentId,
    required String providerId,
    required GeoPoint providerLocation,
    String? providerNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found. Please login first.');
      }

      // Verify the user is accepting their own appointment
      if (user.uid != providerId) {
        throw Exception('You can only accept appointments assigned to you.');
      }

      print('🏥 Provider $providerId accepting appointment: $appointmentId');
      print('📍 Provider location: ${providerLocation.latitude}, ${providerLocation.longitude}');

      // Update the appointment with provider info
      await _firestore.collection('appointments').doc(appointmentId).update({
        'idpro': providerId,                    // Set provider ID
        'providerlocation': providerLocation,   // Set provider's actual location
        'status': 'accepted',                   // Update status to accepted
        'updatedAt': FieldValue.serverTimestamp(),
        if (providerNotes != null) 'notes': providerNotes, // Add provider notes if provided
      });

      print('✅ Appointment $appointmentId accepted by provider');
      print('📍 Provider location updated successfully');

    } catch (e) {
      print('❌ Error accepting appointment: $e');
      throw Exception('Failed to accept appointment. Please try again.');
    }
  }
}

/// Data model for appointment status tracking
class AppointmentStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String rejected = 'rejected';

  static List<String> get allStatuses => [
    pending, accepted, inProgress, completed, cancelled, rejected
  ];
}