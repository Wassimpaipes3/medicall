import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quick test to verify Firestore write permissions
class FirestoreTestService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Test if we can write to avis collection
  static Future<void> testAvisWrite() async {
    final user = _auth.currentUser;
    
    print('🧪 [FirestoreTest] Starting avis write test...');
    print('   User authenticated: ${user != null}');
    print('   User ID: ${user?.uid ?? "NOT AUTHENTICATED"}');
    print('   User email: ${user?.email ?? "N/A"}');
    
    if (user == null) {
      print('❌ [FirestoreTest] User not authenticated!');
      throw Exception('User not authenticated');
    }

    try {
      // Test 1: Simple write
      print('📝 [FirestoreTest] Test 1: Writing test document...');
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };
      
      final docRef = await _firestore.collection('avis').add(testData);
      print('✅ [FirestoreTest] Test 1 PASSED - Document created: ${docRef.id}');
      
      // Test 2: Write with review structure
      print('📝 [FirestoreTest] Test 2: Writing review-like document...');
      final reviewData = {
        'idpat': user.uid,
        'idpro': 'test_provider_id',
        'appointmentId': 'test_appointment_id',
        'note': 5,
        'commentaire': 'Test review',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final reviewDocRef = await _firestore.collection('avis').add(reviewData);
      print('✅ [FirestoreTest] Test 2 PASSED - Review document created: ${reviewDocRef.id}');
      
      // Clean up test documents
      print('🧹 [FirestoreTest] Cleaning up test documents...');
      await docRef.delete();
      await reviewDocRef.delete();
      print('✅ [FirestoreTest] All tests passed!');
      
    } catch (e, stackTrace) {
      print('❌ [FirestoreTest] Test FAILED: $e');
      print('   Error type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      
      if (e.toString().contains('PERMISSION_DENIED')) {
        print('   ⚠️ PERMISSION DENIED ERROR DETECTED');
        print('   Check: https://console.firebase.google.com/project/nursinghomecare-1807f/firestore/rules');
      }
      
      rethrow;
    }
  }

  /// Test if we can update professionals collection
  static Future<void> testProfessionalsUpdate(String providerId) async {
    final user = _auth.currentUser;
    
    print('🧪 [FirestoreTest] Testing professionals update...');
    print('   User ID: ${user?.uid}');
    print('   Provider ID: $providerId');
    
    if (user == null) {
      print('❌ [FirestoreTest] User not authenticated!');
      throw Exception('User not authenticated');
    }

    try {
      // Try to find and update provider document
      final snapshot = await _firestore
          .collection('professionals')
          .where('idpro', isEqualTo: providerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ [FirestoreTest] No provider found with idpro: $providerId');
        
        // Try with id_user
        final snapshot2 = await _firestore
            .collection('professionals')
            .where('id_user', isEqualTo: providerId)
            .limit(1)
            .get();
            
        if (snapshot2.docs.isEmpty) {
          print('❌ [FirestoreTest] Provider not found in professionals collection');
          return;
        }
        
        final docId = snapshot2.docs.first.id;
        print('✅ [FirestoreTest] Found provider by id_user: $docId');
        
        await _firestore.collection('professionals').doc(docId).update({
          'rating': 4.5,
          'reviewsCount': 1,
        });
        print('✅ [FirestoreTest] Successfully updated provider rating');
      } else {
        final docId = snapshot.docs.first.id;
        print('✅ [FirestoreTest] Found provider by idpro: $docId');
        
        await _firestore.collection('professionals').doc(docId).update({
          'rating': 4.5,
          'reviewsCount': 1,
        });
        print('✅ [FirestoreTest] Successfully updated provider rating');
      }
      
    } catch (e) {
      print('❌ [FirestoreTest] Failed to update professionals: $e');
      rethrow;
    }
  }
}
