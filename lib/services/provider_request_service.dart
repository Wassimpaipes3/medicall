import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Data model for a provider request (pre-appointment handshake)
class ProviderRequest {
  final String id;
  final String patientId;
  final String providerId;
  final String service;
  final String? specialty;
  final double prix;
  final String paymentMethod;
  final GeoPoint patientLocation;
  final String status; // pending | accepted | cancelled | expired
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? appointmentId; // Filled once provider accepts & appointment created

  ProviderRequest({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.service,
    required this.specialty,
    required this.prix,
    required this.paymentMethod,
    required this.patientLocation,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.appointmentId,
  });

  factory ProviderRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderRequest(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      providerId: data['providerId'] ?? '',
      service: data['service'] ?? '',
      specialty: data['specialty'],
      prix: (data['prix'] is int) ? (data['prix'] as int).toDouble() : (data['prix'] ?? 0.0),
      paymentMethod: data['paymentMethod'] ?? '',
      patientLocation: data['patientLocation'] ?? const GeoPoint(0,0),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentId: data['appointmentId'],
    );
  }
}

/// Service to manage pre-appointment provider selection workflow
class ProviderRequestService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static const _collection = 'provider_requests';

  /// Quick environment snapshot (project ID + auth UID) to debug rule mismatches / wrong project
  static void debugEnvironment() {
    try {
      final app = _firestore.app; // FirebaseApp
      final projectId = app.options.projectId;
      final user = _auth.currentUser;
      print('🌐 [ProviderRequestService] projectId=$projectId');
      print('👤 [ProviderRequestService] authUser=${user?.uid}');
    } catch (e) {
      print('⚠️ [ProviderRequestService] Failed to read environment: $e');
    }
  }

  /// Create a new provider request (after payment, before appointment creation)
  static Future<String> createRequest({
    required String providerId,
    required String service,
    String? specialty,
    required double prix,
    required String paymentMethod,
    required GeoPoint patientLocation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    print('🆕 [ProviderRequestService] Creating request');
  debugEnvironment();
    print('   👤 patientId: ${user.uid}');
    print('   🩺 providerId: $providerId');
    print('   🛠 service: $service  specialty: $specialty');
    print('   💰 prix: $prix  paymentMethod: $paymentMethod');
    print('   📍 patientLocation: ${patientLocation.latitude}, ${patientLocation.longitude}');

    final data = {
      'patientId': user.uid,
      'idpat': user.uid, // duplicate for legacy rule compatibility
      'providerId': providerId,
      'service': service,
      'specialty': specialty,
      'prix': prix,
      'paymentMethod': paymentMethod,
      'patientLocation': patientLocation,
      'status': 'pending',
      'appointmentId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final doc = await _firestore.collection(_collection).add(data);
      print('✅ Request created: ${doc.id}');
      return doc.id;
    } catch (e) {
      print('❌ Failed to create provider request: $e');
      // Try to detect permission denied
      if (e.toString().contains('permission-denied')) {
        print('🔐 Firestore permission denied. Check rules for provider_requests.');
      }
      rethrow;
    }
  }

  /// Debug helper to isolate permission issues
  static Future<void> debugPermissionTest() async {
    final user = _auth.currentUser;
    print('🧪 Running provider_requests permission test');
    if (user == null) {
      print('❌ No authenticated user');
      return;
    }
    try {
      final ref = await _firestore.collection(_collection).add({
        'patientId': user.uid,
        'idpat': user.uid,
        'providerId': 'test_provider',
        'service': 'consultation',
        'specialty': 'generaliste',
        'prix': 0.0,
        'paymentMethod': 'Test',
        'patientLocation': const GeoPoint(0,0),
        'status': 'pending',
        'appointmentId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test request created: ${ref.id}');
    } catch (e) {
      print('❌ Test request failed: $e');
    }
  }

  /// Stream provider requests for a patient
  static Stream<List<ProviderRequest>> listenPatientRequests() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection(_collection)
        .where('patientId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ProviderRequest.fromDoc).toList());
  }

  /// Stream pending requests for a provider
  static Stream<List<ProviderRequest>> listenProviderPendingRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ [listenProviderPendingRequests] No authenticated user');
      return const Stream.empty();
    }
    
    print('🔍 [listenProviderPendingRequests] Looking for requests where providerId == ${user.uid}');
    
    // Primary query: match by providerId (should be the auth UID)
    final primaryStream = _firestore
        .collection(_collection)
        .where('providerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
    
    return primaryStream.map((snap) {
      print('📥 [listenProviderPendingRequests] Found ${snap.docs.length} requests for providerId=${user.uid}');
      if (snap.docs.isNotEmpty) {
        for (final doc in snap.docs) {
          final data = doc.data();
          print('   📄 Request ${doc.id}: providerId=${data['providerId']}, status=${data['status']}');
        }
      } else {
        print('   ⚠️ No requests found. This might indicate providerId mismatch.');
        // Let's also check if there are ANY pending requests to debug
        _debugCheckAllPendingRequests();
      }
      return snap.docs.map(ProviderRequest.fromDoc).toList();
    });
  }

  /// Debug helper: Check all pending requests to see what provider IDs exist
  static Future<void> _debugCheckAllPendingRequests() async {
    try {
      final allPending = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .get();
      
      print('🔍 [DEBUG] All pending requests in collection:');
      for (final doc in allPending.docs) {
        final data = doc.data();
        print('   📄 ${doc.id}: providerId=${data['providerId']}, patientId=${data['patientId']}');
      }
    } catch (e) {
      print('❌ [DEBUG] Failed to check all pending requests: $e');
    }
  }

  /// Patient cancels a pending request
  static Future<void> cancelRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _firestore.collection(_collection).doc(requestId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      if (data['patientId'] != user.uid) throw Exception('Not your request');
      if (data['status'] != 'pending') return; // Ignore if already processed
      tx.update(ref, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Provider accepts a request -> create appointment atomically
  static Future<String> acceptRequestAndCreateAppointment({
    required String requestId,
    required GeoPoint providerLocation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final reqRef = _firestore.collection(_collection).doc(requestId);

    return await _firestore.runTransaction((tx) async {
      final snap = await tx.get(reqRef);
      if (!snap.exists) throw Exception('Request not found');
      final data = snap.data() as Map<String, dynamic>;
      if (data['providerId'] != user.uid) throw Exception('Not your request');
      if (data['status'] != 'pending') throw Exception('Request already processed');

      // Build appointment data inline (accepted immediate appointment)
      final appointmentData = {
        'idpat': data['patientId'],
        'idpro': data['providerId'],
        'type': 'instant',
        'service': data['service'],
        'patientAddress': null, // Optional: supply if needed
        'patientlocation': data['patientLocation'],
        'providerlocation': providerLocation,
        'status': 'accepted',
        'prix': data['prix'],
        'paymentMethod': data['paymentMethod'],
        'serviceFee': 0.0, // Could be extended to pass through
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final appRef = _firestore.collection('appointments').doc();
      tx.set(appRef, appointmentData);

      // Update request
      tx.update(reqRef, {
        'status': 'accepted',
        'appointmentId': appRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return appRef.id;
    });
  }
}
