import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage appointment requests (pending bookings)
/// 
/// Data Flow:
/// 1. Patient creates booking → saves to 'appointment_requests' (status: pending)
/// 2. Provider sees in dashboard → can Accept or Reject
/// 3. Accepted → copied to 'appointments' collection (status: accepted)
/// 4. Rejected → deleted or marked as rejected
/// 5. Auto-cleanup: requests older than 10 minutes are deleted
class AppointmentRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new appointment request from patient
  /// This saves to 'appointment_requests' collection with status 'pending'
  static Future<String?> createAppointmentRequest({
    required String providerId,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String service,
    required double prix,
    required double serviceFee,
    required String paymentMethod,
    required String type, // 'instant' or 'scheduled'
    required DateTime appointmentDate,
    required String appointmentTime,
    Map<String, dynamic>? patientLocation,
    Map<String, dynamic>? providerLocation,
    String? patientAddress,
    String? notes,
  }) async {
    try {
      print('📝 Creating appointment request...');
      
      final requestData = {
        // Patient info
        'idpat': patientId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        
        // Provider info
        'idpro': providerId,
        
        // Service details
        'service': service,
        'prix': prix,
        'serviceFee': serviceFee,
        'paymentMethod': paymentMethod,
        'type': type,
        
        // Appointment timing
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        
        // Locations
        'patientLocation': patientLocation,
        'providerLocation': providerLocation,
        'patientAddress': patientAddress,
        
        // Additional info
        'notes': notes,
        
        // Status and timestamps
        'status': 'pending',
        'etat': 'en_attente',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('appointment_requests')
          .add(requestData);

      print('✅ Appointment request created: ${docRef.id}');
      return docRef.id;

    } catch (e) {
      print('❌ Error creating appointment request: $e');
      return null;
    }
  }

  /// Get pending appointment requests for a specific provider
  static Future<List<AppointmentRequest>> getProviderPendingRequests(String providerId) async {
    try {
      print('📋 Fetching pending requests for provider: $providerId');

      final snapshot = await _firestore
          .collection('appointment_requests')
          .where('idpro', isEqualTo: providerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      print('   ✅ Found ${snapshot.docs.length} pending requests');

      return snapshot.docs.map((doc) {
        return AppointmentRequest.fromFirestore(doc.id, doc.data());
      }).toList();

    } catch (e) {
      print('❌ Error fetching provider requests: $e');
      return [];
    }
  }

  /// Stream of pending requests for real-time updates
  static Stream<List<AppointmentRequest>> getProviderPendingRequestsStream(String providerId) {
    return _firestore
        .collection('appointment_requests')
        .where('idpro', isEqualTo: providerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppointmentRequest.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Get only instant (immediate) pending requests for a provider
  static Future<List<AppointmentRequest>> getProviderInstantRequests(String providerId) async {
    try {
      print('📋 Fetching instant requests for provider: $providerId');

      final snapshot = await _firestore
          .collection('appointment_requests')
          .where('idpro', isEqualTo: providerId)
          .where('status', isEqualTo: 'pending')
          .where('type', isEqualTo: 'instant')
          .orderBy('createdAt', descending: true)
          .get();

      print('   ✅ Found ${snapshot.docs.length} instant requests');

      return snapshot.docs.map((doc) {
        return AppointmentRequest.fromFirestore(doc.id, doc.data());
      }).toList();

    } catch (e) {
      print('❌ Error fetching instant requests: $e');
      return [];
    }
  }

  /// Get all scheduled appointments for a provider (pending, accepted, completed)
  static Future<List<AppointmentRequest>> getProviderScheduledAppointments(String providerId) async {
    try {
      print('📅 Fetching scheduled appointments for provider: $providerId');

      final snapshot = await _firestore
          .collection('appointment_requests')
          .where('idpro', isEqualTo: providerId)
          .where('type', isEqualTo: 'scheduled')
          .get();

      print('   ✅ Found ${snapshot.docs.length} scheduled appointments');

      return snapshot.docs.map((doc) {
        return AppointmentRequest.fromFirestore(doc.id, doc.data());
      }).toList();

    } catch (e) {
      print('❌ Error fetching scheduled appointments: $e');
      return [];
    }
  }

  /// Stream for instant requests only
  static Stream<List<AppointmentRequest>> getProviderInstantRequestsStream(String providerId) {
    return _firestore
        .collection('appointment_requests')
        .where('idpro', isEqualTo: providerId)
        .where('status', isEqualTo: 'pending')
        .where('type', isEqualTo: 'instant')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppointmentRequest.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Stream for all scheduled appointments (pending, accepted, completed)
  static Stream<List<AppointmentRequest>> getProviderScheduledAppointmentsStream(String providerId) {
    return _firestore
        .collection('appointment_requests')
        .where('idpro', isEqualTo: providerId)
        .where('type', isEqualTo: 'scheduled')
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppointmentRequest.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Accept an appointment request
  /// Copies data from 'appointment_requests' to 'appointments' collection
  static Future<bool> acceptAppointmentRequest(String requestId) async {
    try {
      print('✅ Accepting appointment request: $requestId');

      // Get the request data
      final requestDoc = await _firestore
          .collection('appointment_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print('❌ Request not found');
        return false;
      }

      final requestData = requestDoc.data()!;

      // Fetch real patient name from users collection
      String patientName = requestData['patientName'] ?? 'Unknown Patient';
      String patientPhone = requestData['patientPhone'] ?? '';
      
      try {
        final patientId = requestData['idpat'];
        if (patientId != null) {
          final userDoc = await _firestore.collection('users').doc(patientId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            patientName = '${userData['nom'] ?? ''} ${userData['prenom'] ?? ''}'.trim();
            if (patientName.isEmpty) patientName = userData['email'] ?? 'Unknown Patient';
            patientPhone = userData['tel'] ?? patientPhone;
            print('✅ Retrieved patient name: $patientName');
          }
        }
      } catch (e) {
        print('❌ Error fetching patient data: $e');
      }

      // Prepare appointment data for main collection
      final appointmentData = {
        'idpat': requestData['idpat'],
        'idpro': requestData['idpro'],
        'patientName': patientName,
        'patientPhone': patientPhone,
        'service': requestData['service'],
        'prix': requestData['prix'],
        'serviceFee': requestData['serviceFee'],
        'paymentMethod': requestData['paymentMethod'],
        'type': requestData['type'],
        'appointmentDate': requestData['scheduledDate'], // Map scheduledDate to appointmentDate
        'appointmentTime': requestData['appointmentTime'],
        'patientLocation': requestData['patientlocation'], // Map patientlocation to patientLocation
        'providerLocation': requestData['providerlocation'], // Map providerlocation to providerLocation
        'patientAddress': requestData['patientAddress'],
        'notes': requestData['notes'],
        
        // Update status to accepted
        'status': 'accepted',
        'etat': 'accepté',
        
        // Keep original creation time, update accepted time
        'createdAt': requestData['createdAt'],
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Add to appointments collection
      final appointmentRef = _firestore.collection('appointments').doc();
      batch.set(appointmentRef, appointmentData);

      // Delete from appointment_requests
      final requestRef = _firestore.collection('appointment_requests').doc(requestId);
      batch.delete(requestRef);

      await batch.commit();

      print('✅ Appointment accepted and moved to appointments collection');
      return true;

    } catch (e) {
      print('❌ Error accepting appointment: $e');
      return false;
    }
  }

  /// Reject an appointment request
  /// Deletes the request from 'appointment_requests' collection
  static Future<bool> rejectAppointmentRequest(String requestId, {String? reason}) async {
    try {
      print('❌ Rejecting appointment request: $requestId');

      // Option 1: Delete the request completely
      await _firestore
          .collection('appointment_requests')
          .doc(requestId)
          .delete();

      // Option 2: Mark as rejected (if you want to keep history)
      // await _firestore
      //     .collection('appointment_requests')
      //     .doc(requestId)
      //     .update({
      //   'status': 'rejected',
      //   'etat': 'rejeté',
      //   'rejectionReason': reason,
      //   'rejectedAt': FieldValue.serverTimestamp(),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });

      print('✅ Appointment request rejected');
      return true;

    } catch (e) {
      print('❌ Error rejecting appointment: $e');
      return false;
    }
  }

  /// Get upcoming accepted appointments for a provider
  /// This replaces the "Today's Schedule" with "Upcoming Appointments"
  static Future<List<UpcomingAppointment>> getProviderUpcomingAppointments(String providerId) async {
    try {
      print('📅 Fetching upcoming appointments for provider: $providerId');

      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);

      // Fetch appointments scheduled for today or future dates
      final snapshot = await _firestore
          .collection('appointments')
          .where('idpro', isEqualTo: providerId)
          .where('status', whereIn: ['accepted', 'confirmed'])
          .orderBy('appointmentDate', descending: false)
          .get();

      // Filter for upcoming appointments (today or future)
      final upcoming = snapshot.docs.where((doc) {
        final data = doc.data();
        final appointmentDate = data['appointmentDate'] as Timestamp?;
        
        if (appointmentDate == null) return false;
        
        // Include appointments from today onwards
        final apptDateTime = appointmentDate.toDate();
        final today = DateTime(now.year, now.month, now.day);
        
        return apptDateTime.isAfter(today) || 
               (apptDateTime.year == today.year && 
                apptDateTime.month == today.month && 
                apptDateTime.day == today.day);
      }).toList();

      print('   ✅ Found ${upcoming.length} upcoming appointments');

      return upcoming.map((doc) {
        return UpcomingAppointment.fromFirestore(doc.id, doc.data());
      }).toList();

    } catch (e) {
      print('❌ Error fetching upcoming appointments: $e');
      return [];
    }
  }

  /// Stream of upcoming appointments for real-time updates
  static Stream<List<UpcomingAppointment>> getProviderUpcomingAppointmentsStream(String providerId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTimestamp = Timestamp.fromDate(today);

    return _firestore
        .collection('appointments')
        .where('idpro', isEqualTo: providerId)
        .where('status', whereIn: ['accepted', 'confirmed'])
        .where('appointmentDate', isGreaterThanOrEqualTo: todayTimestamp)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UpcomingAppointment.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  /// Delete old pending requests (older than 10 minutes)
  /// Call this periodically or use Cloud Function
  static Future<int> cleanupOldPendingRequests() async {
    try {
      print('🧹 Cleaning up old pending requests...');

      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
      final cutoffTimestamp = Timestamp.fromDate(tenMinutesAgo);

      final snapshot = await _firestore
          .collection('appointment_requests')
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: cutoffTimestamp)
          .get();

      if (snapshot.docs.isEmpty) {
        print('   ✅ No old requests to clean');
        return 0;
      }

      // Delete in batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('   ✅ Deleted ${snapshot.docs.length} old pending requests');
      return snapshot.docs.length;

    } catch (e) {
      print('❌ Error cleaning up old requests: $e');
      return 0;
    }
  }
}

/// Model for appointment request (pending booking)
class AppointmentRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String providerId;
  final String service;
  final double prix;
  final double serviceFee;
  final String paymentMethod;
  final String type;
  final DateTime appointmentDate;
  final String appointmentTime;
  final Map<String, dynamic>? patientLocation;
  final Map<String, dynamic>? providerLocation;
  final String? patientAddress;
  final String? notes;
  final String status;
  final DateTime createdAt;

  AppointmentRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.providerId,
    required this.service,
    required this.prix,
    required this.serviceFee,
    required this.paymentMethod,
    required this.type,
    required this.appointmentDate,
    required this.appointmentTime,
    this.patientLocation,
    this.providerLocation,
    this.patientAddress,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory AppointmentRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return AppointmentRequest(
      id: id,
      patientId: data['idpat'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      patientPhone: data['patientPhone'] ?? '',
      providerId: data['idpro'] ?? '',
      service: data['service'] ?? 'General Consultation',
      prix: (data['prix'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (data['serviceFee'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? 'cash',
      type: data['type'] ?? 'scheduled',
      appointmentDate: (data['scheduledDate'] as Timestamp?)?.toDate() ?? (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: data['appointmentTime'] ?? '09:00',
      patientLocation: data['patientLocation'] as Map<String, dynamic>?,
      providerLocation: data['providerLocation'] as Map<String, dynamic>?,
      patientAddress: data['patientAddress'],
      notes: data['notes'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convenience getters
  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  String get formattedDateTime {
    return '$formattedDate at $appointmentTime';
  }

  String get totalAmount {
    return (prix + serviceFee).toStringAsFixed(2);
  }

  bool get isExpired {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    return createdAt.isBefore(tenMinutesAgo);
  }
}

/// Model for upcoming appointment (accepted booking)
class UpcomingAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String providerId;
  final String service;
  final double prix;
  final String paymentMethod;
  final String type;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String? patientAddress;
  final String? notes;
  final String status;

  UpcomingAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.providerId,
    required this.service,
    required this.prix,
    required this.paymentMethod,
    required this.type,
    required this.appointmentDate,
    required this.appointmentTime,
    this.patientAddress,
    this.notes,
    required this.status,
  });

  factory UpcomingAppointment.fromFirestore(String id, Map<String, dynamic> data) {
    return UpcomingAppointment(
      id: id,
      patientId: data['idpat'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      patientPhone: data['patientPhone'] ?? '',
      providerId: data['idpro'] ?? '',
      service: data['service'] ?? 'General Consultation',
      prix: (data['prix'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? 'cash',
      type: data['type'] ?? 'scheduled',
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: data['appointmentTime'] ?? '09:00',
      patientAddress: data['patientAddress'],
      notes: data['notes'],
      status: data['status'] ?? 'accepted',
    );
  }

  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  String get formattedDateTime {
    return '$formattedDate at $appointmentTime';
  }

  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[appointmentDate.weekday - 1];
  }

  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return appointmentDate.year == tomorrow.year &&
           appointmentDate.month == tomorrow.month &&
           appointmentDate.day == tomorrow.day;
  }

  String get relativeDate {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return formattedDate;
  }
}
