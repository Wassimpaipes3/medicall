import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug script to find the actual document structure and identify the real problem
class DebugActualDocument {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Find and display ALL documents for the current user
  static Future<void> findAllUserDocuments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      print('🔍 SEARCHING FOR ALL DOCUMENTS FOR USER: ${user.uid}\n');

      // Check professionals collection
      print('📋 Checking professionals collection...');
      final professionalsQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionalsQuery.docs.isNotEmpty) {
        for (var doc in professionalsQuery.docs) {
          print('✅ Found in professionals: ${doc.id}');
          print('   Data: ${doc.data()}');
        }
      } else {
        print('❌ No documents in professionals collection');
      }

      // Check professionnels collection with id_user
      print('\n📋 Checking professionnels collection (id_user)...');
      final professionnelsIdUserQuery = await _firestore
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionnelsIdUserQuery.docs.isNotEmpty) {
        for (var doc in professionnelsIdUserQuery.docs) {
          print('✅ Found in professionnels (id_user): ${doc.id}');
          print('   Data: ${doc.data()}');
        }
      } else {
        print('❌ No documents in professionnels collection (id_user)');
      }

      // Check professionnels collection with userId
      print('\n📋 Checking professionnels collection (userId)...');
      final professionnelsUserIdQuery = await _firestore
          .collection('professionnels')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      if (professionnelsUserIdQuery.docs.isNotEmpty) {
        for (var doc in professionnelsUserIdQuery.docs) {
          print('✅ Found in professionnels (userId): ${doc.id}');
          print('   Data: ${doc.data()}');
        }
      } else {
        print('❌ No documents in professionnels collection (userId)');
      }

      // Check direct document access
      print('\n📋 Checking direct document access...');
      final directProfessionals = await _firestore.collection('professionals').doc(user.uid).get();
      if (directProfessionals.exists) {
        print('✅ Direct access professionals/${user.uid}: ${directProfessionals.data()}');
      } else {
        print('❌ No direct document in professionals/${user.uid}');
      }

      final directProfessionnels = await _firestore.collection('professionnels').doc(user.uid).get();
      if (directProfessionnels.exists) {
        print('✅ Direct access professionnels/${user.uid}: ${directProfessionnels.data()}');
      } else {
        print('❌ No direct document in professionnels/${user.uid}');
      }

      // Check users collection
      print('\n📋 Checking users collection...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        print('✅ User document: ${userDoc.data()}');
      } else {
        print('❌ No user document found');
      }

    } catch (e) {
      print('❌ Error finding documents: $e');
    }
  }

  /// Try to update location in each possible document
  static Future<void> tryUpdateAllDocuments() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      print('🔄 TRYING TO UPDATE LOCATION IN ALL POSSIBLE DOCUMENTS\n');

      // Test coordinates
      const double testLat = 36.7538;
      const double testLng = 3.0588;
      final geoPoint = GeoPoint(testLat, testLng);

      // Try professionals collection
      print('📋 Trying professionals collection...');
      final professionalsQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      for (var doc in professionalsQuery.docs) {
        try {
          print('   Updating professionals/${doc.id}...');
          await doc.reference.update({
            'currentlocation': geoPoint,
            'lastupdated': FieldValue.serverTimestamp(),
          });
          print('   ✅ SUCCESS: professionals/${doc.id}');
        } catch (e) {
          print('   ❌ FAILED: professionals/${doc.id} - $e');
        }
      }

      // Try professionnels collection with id_user
      print('\n📋 Trying professionnels collection (id_user)...');
      final professionnelsIdUserQuery = await _firestore
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      for (var doc in professionnelsIdUserQuery.docs) {
        try {
          print('   Updating professionnels/${doc.id}...');
          await doc.reference.update({
            'currentlocation': geoPoint,
            'lastupdated': FieldValue.serverTimestamp(),
          });
          print('   ✅ SUCCESS: professionnels/${doc.id}');
        } catch (e) {
          print('   ❌ FAILED: professionnels/${doc.id} - $e');
        }
      }

      // Try professionnels collection with userId
      print('\n📋 Trying professionnels collection (userId)...');
      final professionnelsUserIdQuery = await _firestore
          .collection('professionnels')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (var doc in professionnelsUserIdQuery.docs) {
        try {
          print('   Updating professionnels/${doc.id}...');
          await doc.reference.update({
            'currentlocation': geoPoint,
            'lastupdated': FieldValue.serverTimestamp(),
          });
          print('   ✅ SUCCESS: professionnels/${doc.id}');
        } catch (e) {
          print('   ❌ FAILED: professionnels/${doc.id} - $e');
        }
      }

      // Try direct document access
      print('\n📋 Trying direct document access...');
      try {
        await _firestore.collection('professionals').doc(user.uid).update({
          'currentlocation': geoPoint,
          'lastupdated': FieldValue.serverTimestamp(),
        });
        print('   ✅ SUCCESS: professionals/${user.uid}');
      } catch (e) {
        print('   ❌ FAILED: professionals/${user.uid} - $e');
      }

      try {
        await _firestore.collection('professionnels').doc(user.uid).update({
          'currentlocation': geoPoint,
          'lastupdated': FieldValue.serverTimestamp(),
        });
        print('   ✅ SUCCESS: professionnels/${user.uid}');
      } catch (e) {
        print('   ❌ FAILED: professionnels/${user.uid} - $e');
      }

    } catch (e) {
      print('❌ Error trying updates: $e');
    }
  }

  /// Check what actually got updated
  static Future<void> checkWhatGotUpdated() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      print('🔍 CHECKING WHAT ACTUALLY GOT UPDATED\n');

      // Check all possible documents again
      final professionalsQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      for (var doc in professionalsQuery.docs) {
        final data = doc.data();
        final location = data['currentlocation'];
        final lastUpdated = data['lastupdated'];
        print('📋 professionals/${doc.id}:');
        print('   currentlocation: $location');
        print('   lastupdated: $lastUpdated');
      }

      final professionnelsIdUserQuery = await _firestore
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      for (var doc in professionnelsIdUserQuery.docs) {
        final data = doc.data();
        final location = data['currentlocation'];
        final lastUpdated = data['lastupdated'];
        print('📋 professionnels/${doc.id} (id_user):');
        print('   currentlocation: $location');
        print('   lastupdated: $lastUpdated');
      }

      final professionnelsUserIdQuery = await _firestore
          .collection('professionnels')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (var doc in professionnelsUserIdQuery.docs) {
        final data = doc.data();
        final location = data['currentlocation'];
        final lastUpdated = data['lastupdated'];
        print('📋 professionnels/${doc.id} (userId):');
        print('   currentlocation: $location');
        print('   lastupdated: $lastUpdated');
      }

    } catch (e) {
      print('❌ Error checking updates: $e');
    }
  }

  /// Run complete debug sequence
  static Future<void> runCompleteDebug() async {
    print('🚀 COMPLETE DEBUG SEQUENCE\n');
    
    // Step 1: Find all documents
    await findAllUserDocuments();
    print('\n' + '='*60 + '\n');
    
    // Step 2: Try to update all documents
    await tryUpdateAllDocuments();
    print('\n' + '='*60 + '\n');
    
    // Step 3: Check what got updated
    await checkWhatGotUpdated();
    
    print('\n🏁 DEBUG SEQUENCE COMPLETED');
  }
}

