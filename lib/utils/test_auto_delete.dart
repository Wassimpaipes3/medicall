import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test the auto-deletion system with a 2-minute expiry
/// This will help verify the Cloud Function is working
Future<void> testAutoDeleteFunction() async {
  print('🧪 Testing Auto-Delete Function with 2-minute expiry\n');

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Not logged in');
      return;
    }

    // Step 1: Create a test document that expires in 2 minutes
    print('📝 Step 1: Creating test document (expires in 2 min)...');
    final now = DateTime.now();
    final expireAt = Timestamp.fromDate(now.add(const Duration(minutes: 2)));

    final testDoc = await FirebaseFirestore.instance
        .collection('provider_requests')
        .add({
      'patientId': user.uid,
      'idpat': user.uid,
      'providerId': 'test_auto_delete',
      'service': 'Test Auto-Delete',
      'specialty': 'Testing',
      'prix': 1.0,
      'paymentMethod': 'test',
      'patientLocation': const GeoPoint(33.5731, -7.5898),
      'status': 'pending',
      'appointmentId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expireAt': expireAt, // ⏰ Expires in 2 minutes
      'testNote': 'This document should auto-delete in ~2-7 minutes',
    });

    print('   ✅ Document created: ${testDoc.id}');
    print('   📍 Created at: $now');
    print('   ⏰ Expires at: ${expireAt.toDate()}');
    print('   ⌚ In ~2 minutes from now\n');

    // Step 2: Verify document exists
    print('📖 Step 2: Verifying document exists...');
    var doc = await testDoc.get();
    if (doc.exists) {
      print('   ✅ Document exists in Firestore\n');
    } else {
      print('   ❌ Document not found!\n');
      return;
    }

    // Step 3: Instructions for monitoring
    print('🔍 Step 3: Monitoring Instructions:');
    print('   1. Wait 2-7 minutes');
    print('   2. Cloud Function runs every 5 minutes');
    print('   3. Document will be auto-deleted when function detects expireAt < now');
    print('   4. Check Firebase Console to see when it disappears\n');

    print('⏰ Timeline:');
    print('   Now:        $now');
    print('   Expires:    ${expireAt.toDate()}');
    print('   Function:   Runs every 5 minutes');
    print('   Expected:   Deleted within 2-7 minutes\n');

    print('🎯 To verify:');
    print('   1. Go to Firebase Console');
    print('   2. Navigate to provider_requests collection');
    print('   3. Find document: ${testDoc.id}');
    print('   4. Wait and refresh - it should disappear!\n');

    print('📊 Or check logs:');
    print('   firebase functions:log | Select-String "cleanupExpiredRequests"\n');

    print('✅ Test setup complete! Document will auto-delete soon.');
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Check if a specific document still exists
Future<bool> checkDocumentExists(String documentId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('provider_requests')
        .doc(documentId)
        .get();
    
    if (doc.exists) {
      final data = doc.data();
      final expireAt = data?['expireAt'] as Timestamp?;
      print('📍 Document exists');
      if (expireAt != null) {
        final expiresIn = expireAt.toDate().difference(DateTime.now());
        print('   ⏰ Expires in: ${expiresIn.inMinutes} min ${expiresIn.inSeconds % 60} sec');
      }
      return true;
    } else {
      print('🗑️ Document deleted (auto-cleanup worked!)');
      return false;
    }
  } catch (e) {
    print('❌ Error checking document: $e');
    return false;
  }
}

/// List all provider_requests with their expiry times
Future<void> listAllRequestsWithExpiry() async {
  try {
    print('📊 Listing all provider_requests:\n');
    
    final snapshot = await FirebaseFirestore.instance
        .collection('provider_requests')
        .get();
    
    if (snapshot.docs.isEmpty) {
      print('   (No documents found)\n');
      return;
    }

    final now = DateTime.now();
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final expireAt = data['expireAt'] as Timestamp?;
      final createdAt = data['createdAt'] as Timestamp?;
      
      print('Document: ${doc.id}');
      if (expireAt != null) {
        final expiryTime = expireAt.toDate();
        final timeUntilExpiry = expiryTime.difference(now);
        final isExpired = timeUntilExpiry.isNegative;
        
        print('   Created: ${createdAt?.toDate()}');
        print('   Expires: $expiryTime');
        
        if (isExpired) {
          print('   Status: ⚠️ EXPIRED (${timeUntilExpiry.inMinutes.abs()} min ago)');
          print('   Note: Should be deleted in next function run (every 5 min)');
        } else {
          print('   Status: ✅ Active (expires in ${timeUntilExpiry.inMinutes} min)');
        }
      } else {
        print('   ⚠️ No expireAt field (old document)');
      }
      print('');
    }
    
    print('Total documents: ${snapshot.docs.length}\n');
  } catch (e) {
    print('❌ Error: $e');
  }
}
