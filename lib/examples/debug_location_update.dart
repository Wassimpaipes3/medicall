import '../services/provider_location_service.dart';

/// Debug script to help identify why currentlocation is not being updated
/// Run these functions to diagnose the issue
class DebugLocationUpdate {
  
  /// Step 1: Check if the provider document exists and has the right structure
  static Future<void> checkProviderDocument() async {
    print('🔍 Step 1: Checking provider document structure...');
    await ProviderLocationService.debugCurrentLocation();
  }

  /// Step 2: Test location update with GPS coordinates
  static Future<void> testLocationUpdate() async {
    print('🧪 Step 2: Testing location update with GPS...');
    final success = await ProviderLocationService.testLocationUpdate();
    if (success) {
      print('✅ Location update test passed!');
    } else {
      print('❌ Location update test failed!');
    }
  }

  /// Step 3: Force update with specific coordinates (Algiers, Algeria)
  static Future<void> forceUpdateWithTestCoordinates() async {
    print('🔧 Step 3: Force updating with test coordinates...');
    
    // Test coordinates for Algiers, Algeria
    const double testLatitude = 36.7538;
    const double testLongitude = 3.0588;
    
    final success = await ProviderLocationService.forceUpdateLocation(
      latitude: testLatitude,
      longitude: testLongitude,
    );
    
    if (success) {
      print('✅ Force update successful!');
    } else {
      print('❌ Force update failed!');
    }
  }

  /// Step 4: Check the location again after update
  static Future<void> verifyLocationUpdate() async {
    print('🔍 Step 4: Verifying location was updated...');
    await ProviderLocationService.debugCurrentLocation();
  }

  /// Run all debug steps in sequence
  static Future<void> runFullDebug() async {
    print('🚀 Starting full debug sequence...\n');
    
    // Step 1: Check current state
    await checkProviderDocument();
    print('\n' + '='*50 + '\n');
    
    // Step 2: Test normal location update
    await testLocationUpdate();
    print('\n' + '='*50 + '\n');
    
    // Step 3: Force update with test coordinates
    await forceUpdateWithTestCoordinates();
    print('\n' + '='*50 + '\n');
    
    // Step 4: Verify the update
    await verifyLocationUpdate();
    print('\n' + '='*50 + '\n');
    
    print('🏁 Debug sequence completed!');
  }

  /// Quick test to see if the issue is with GPS or Firestore
  static Future<void> quickTest() async {
    print('⚡ Quick test: Checking if location update works...');
    
    // First check current state
    print('📋 Current state:');
    await ProviderLocationService.debugCurrentLocation();
    
    print('\n🔄 Attempting location update...');
    final success = await ProviderLocationService.updateProviderLocation();
    
    if (success) {
      print('✅ Update successful!');
    } else {
      print('❌ Update failed!');
    }
    
    print('\n📋 State after update:');
    await ProviderLocationService.debugCurrentLocation();
  }
}

/// Simple usage examples for debugging
class QuickDebugExamples {
  
  /// Just check what's in the document right now
  static Future<void> checkCurrentState() async {
    await ProviderLocationService.debugCurrentLocation();
  }

  /// Try to update location once
  static Future<void> tryUpdateOnce() async {
    final success = await ProviderLocationService.updateProviderLocation();
    print('Update result: ${success ? "SUCCESS" : "FAILED"}');
  }

  /// Force update with specific coordinates
  static Future<void> forceUpdate(double lat, double lng) async {
    final success = await ProviderLocationService.forceUpdateLocation(
      latitude: lat,
      longitude: lng,
    );
    print('Force update result: ${success ? "SUCCESS" : "FAILED"}');
  }
}

/// Instructions for debugging the currentlocation issue
class DebugInstructions {
  
  static void printInstructions() {
    print('''
🔧 DEBUGGING INSTRUCTIONS FOR CURRENTLOCATION ISSUE

If currentlocation is not being updated, follow these steps:

1. 📋 CHECK CURRENT STATE:
   await DebugLocationUpdate.checkProviderDocument();

2. 🧪 TEST LOCATION UPDATE:
   await DebugLocationUpdate.testLocationUpdate();

3. 🔧 FORCE UPDATE WITH TEST COORDINATES:
   await DebugLocationUpdate.forceUpdateWithTestCoordinates();

4. 🔍 VERIFY THE UPDATE:
   await DebugLocationUpdate.verifyLocationUpdate();

5. 🚀 RUN FULL DEBUG SEQUENCE:
   await DebugLocationUpdate.runFullDebug();

COMMON ISSUES AND SOLUTIONS:

❌ Issue: "Provider document not found"
✅ Solution: Make sure the provider document exists in 'professionnels' collection
   and has 'id_user' field matching the authenticated user's UID

❌ Issue: "Location permissions not granted"
✅ Solution: Grant location permissions in device settings

❌ Issue: "disponible == false"
✅ Solution: Set disponible to true in the provider document

❌ Issue: "Firestore permission denied"
✅ Solution: Check Firestore security rules allow updates

❌ Issue: "GPS timeout or poor accuracy"
✅ Solution: Move to an area with better GPS signal

❌ Issue: "currentlocation field is null after update"
✅ Solution: Check if the field name is exactly 'currentlocation' (lowercase)

QUICK TESTS:

// Check current state
await QuickDebugExamples.checkCurrentState();

// Try update once
await QuickDebugExamples.tryUpdateOnce();

// Force update with specific coordinates
await QuickDebugExamples.forceUpdate(36.7538, 3.0588);
''');
  }
}

