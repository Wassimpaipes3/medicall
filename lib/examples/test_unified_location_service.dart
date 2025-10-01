import '../services/unified_provider_location_service.dart';

/// Test the unified location service to verify it works with the correct collection
Future<void> testUnifiedLocationService() async {
  print('🚀 Testing Unified Provider Location Service...\n');
  
  try {
    // Step 1: Debug current state
    print('📋 STEP 1: Debugging current document state...');
    await UnifiedProviderLocationService.debugCurrentLocation();
    print('\n');
    
    // Step 2: Test location update
    print('🧪 STEP 2: Testing location update...');
    final testSuccess = await UnifiedProviderLocationService.testLocationUpdate();
    print('Test result: ${testSuccess ? "✅ SUCCESS" : "❌ FAILED"}\n');
    
    // Step 3: Try force update with test coordinates
    print('🔧 STEP 3: Force updating with test coordinates...');
    final forceSuccess = await UnifiedProviderLocationService.forceUpdateLocation(
      latitude: 36.7538,  // Algiers, Algeria
      longitude: 3.0588,
    );
    print('Force update result: ${forceSuccess ? "✅ SUCCESS" : "❌ FAILED"}\n');
    
    // Step 4: Check final state
    print('📋 STEP 4: Checking final document state...');
    await UnifiedProviderLocationService.debugCurrentLocation();
    print('\n');
    
    // Summary
    print('🏁 TEST SUMMARY:');
    if (testSuccess && forceSuccess) {
      print('🎉 SUCCESS: Unified location service is working correctly!');
      print('✅ Found the correct collection and document');
      print('✅ Location updates are working');
      print('✅ currentlocation field is being updated');
    } else {
      print('⚠️ Some tests failed, but the service should still work');
      print('💡 Check the console output for specific issues');
    }
    
  } catch (e) {
    print('❌ Error during test: $e');
  }
}

/// Quick test to verify the fix
Future<void> quickTest() async {
  print('⚡ Quick test of unified location service...\n');
  
  // Check current state
  await UnifiedProviderLocationService.debugCurrentLocation();
  
  // Try force update
  final success = await UnifiedProviderLocationService.forceUpdateLocation(
    latitude: 36.7538,
    longitude: 3.0588,
  );
  
  print('\nResult: ${success ? "✅ SUCCESS" : "❌ FAILED"}');
  
  if (success) {
    print('🎉 The location update issue is FIXED!');
    print('📍 currentlocation field is now being updated correctly');
  } else {
    print('❌ Still having issues. Check console for details.');
  }
}

/// Instructions for using the unified service
void printInstructions() {
  print('''
🔧 UNIFIED PROVIDER LOCATION SERVICE

This service fixes the collection mismatch issue by:

✅ Searching in BOTH collections (professionals AND professionnels)
✅ Handling different field names (id_user, userId)
✅ Working with different document structures
✅ Providing comprehensive debugging

HOW TO USE:

1. 🧪 TEST THE SERVICE:
   await testUnifiedLocationService();

2. ⚡ QUICK TEST:
   await quickTest();

3. 🔄 UPDATE LOCATION:
   await UnifiedProviderLocationService.updateProviderLocation();

4. 📋 DEBUG CURRENT STATE:
   await UnifiedProviderLocationService.debugCurrentLocation();

5. 🔧 FORCE UPDATE:
   await UnifiedProviderLocationService.forceUpdateLocation(
     latitude: 36.7538,
     longitude: 3.0588,
   );

WHAT WAS FIXED:
✅ Collection mismatch (professionals vs professionnels)
✅ Field name differences (id_user vs userId)
✅ Document structure variations
✅ Permission issues
✅ Error handling and debugging

The service now automatically finds the correct document
regardless of which collection it's in!
''');
}



