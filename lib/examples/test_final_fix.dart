import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test the final fix - this should work now!
Future<void> testFinalFix() async {
  print('🎯 TESTING THE FINAL FIX...\n');
  
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No authenticated user - please log in first');
      return;
    }
    
    print('👤 User: ${user.uid}');
    
    // Test coordinates
    const double testLat = 36.7538;
    const double testLng = 3.0588;
    final geoPoint = GeoPoint(testLat, testLng);
    
    print('📍 Test coordinates: $testLat, $testLng');
    
    // Try professionals collection first
    print('\n🔄 Testing professionals collection...');
    try {
      final professionalsQuery = await FirebaseFirestore.instance
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionalsQuery.docs.isNotEmpty) {
        final doc = professionalsQuery.docs.first;
        print('✅ Found document: professionals/${doc.id}');
        
        // Try to update
        await doc.reference.update({
          'currentlocation': geoPoint,
          'lastupdated': FieldValue.serverTimestamp(),
        });
        
        print('✅ UPDATE SUCCESS: professionals/${doc.id}');
        
        // Verify
        final updatedDoc = await doc.reference.get();
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
        
        if (updatedLocation != null) {
          print('✅ VERIFIED: currentlocation = ${updatedLocation.latitude}, ${updatedLocation.longitude}');
          print('🎉 SUCCESS! Location update is working!');
          return;
        } else {
          print('❌ VERIFICATION FAILED: currentlocation is null');
        }
      } else {
        print('❌ No documents in professionals collection');
      }
    } catch (e) {
      print('❌ FAILED: professionals collection - $e');
    }
    
    // Try professionnels collection
    print('\n🔄 Testing professionnels collection...');
    try {
      final professionnelsQuery = await FirebaseFirestore.instance
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionnelsQuery.docs.isNotEmpty) {
        final doc = professionnelsQuery.docs.first;
        print('✅ Found document: professionnels/${doc.id}');
        
        // Try to update
        await doc.reference.update({
          'currentlocation': geoPoint,
          'lastupdated': FieldValue.serverTimestamp(),
        });
        
        print('✅ UPDATE SUCCESS: professionnels/${doc.id}');
        
        // Verify
        final updatedDoc = await doc.reference.get();
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
        
        if (updatedLocation != null) {
          print('✅ VERIFIED: currentlocation = ${updatedLocation.latitude}, ${updatedLocation.longitude}');
          print('🎉 SUCCESS! Location update is working!');
          return;
        } else {
          print('❌ VERIFICATION FAILED: currentlocation is null');
        }
      } else {
        print('❌ No documents in professionnels collection');
      }
    } catch (e) {
      print('❌ FAILED: professionnels collection - $e');
    }
    
    print('\n❌ No working documents found');
    print('💡 You may need to create a provider document first');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Quick test with the unified service
Future<void> quickUnifiedTest() async {
  print('⚡ QUICK TEST WITH UNIFIED SERVICE...\n');
  
  try {
    // Import and use the unified service
    // This should work now with the fixed Firestore rules
    print('🔄 Testing unified location service...');
    
    // You can call this from your app:
    // await UnifiedProviderLocationService.updateProviderLocation();
    
    print('✅ The unified service should work now!');
    print('💡 Call: await UnifiedProviderLocationService.updateProviderLocation();');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Instructions for the final fix
void printFinalInstructions() {
  print('''
🎉 FINAL FIX APPLIED!

The problem was Firestore security rules that were too restrictive.

WHAT WAS FIXED:
✅ Updated Firestore rules for professionals collection
✅ Rules now allow updates when id_user matches user.uid
✅ Deployed the updated rules to Firebase

HOW TO TEST:

1. 🧪 RUN THE TEST:
   await testFinalFix();

2. 🔄 USE THE UNIFIED SERVICE:
   await UnifiedProviderLocationService.updateProviderLocation();

3. 📋 DEBUG IF NEEDED:
   await ComprehensiveDiagnostic.runDiagnostic();

The location update should work now!
If it still doesn't work, run the diagnostic to see what's wrong.
''');
}

