import '../services/unified_provider_location_service.dart';

/// Simple working example - just copy and paste this into your app
class SimpleWorkingExample {
  
  /// This is the main function you need - it will work with any collection structure
  static Future<bool> updateProviderLocation() async {
    print('📍 Updating provider location...');
    
    final success = await UnifiedProviderLocationService.updateProviderLocation();
    
    if (success) {
      print('✅ Location updated successfully!');
    } else {
      print('❌ Location update failed');
    }
    
    return success;
  }

  /// Start periodic updates (every 10 seconds)
  static void startPeriodicUpdates() {
    print('🚀 Starting periodic location updates...');
    UnifiedProviderLocationService.startLocationUpdates();
  }

  /// Stop periodic updates
  static void stopPeriodicUpdates() {
    print('🛑 Stopping periodic location updates...');
    UnifiedProviderLocationService.stopLocationUpdates();
  }

  /// Debug what's in the document
  static Future<void> debugDocument() async {
    print('🔍 Debugging document state...');
    await UnifiedProviderLocationService.debugCurrentLocation();
  }

  /// Test with specific coordinates
  static Future<bool> testWithCoordinates(double lat, double lng) async {
    print('🧪 Testing with coordinates: $lat, $lng');
    
    final success = await UnifiedProviderLocationService.forceUpdateLocation(
      latitude: lat,
      longitude: lng,
    );
    
    print('Test result: ${success ? "✅ SUCCESS" : "❌ FAILED"}');
    return success;
  }
}

/// Quick test function - run this to verify everything works
Future<void> quickWorkingTest() async {
  print('🚀 Quick Working Test - This should work now!\n');
  
  try {
    // Step 1: Check what's in the document
    print('📋 Step 1: Checking document state...');
    await SimpleWorkingExample.debugDocument();
    print('\n');
    
    // Step 2: Try to update location
    print('🔄 Step 2: Trying to update location...');
    final success = await SimpleWorkingExample.updateProviderLocation();
    print('Update result: ${success ? "✅ SUCCESS" : "❌ FAILED"}\n');
    
    // Step 3: If that failed, try with test coordinates
    if (!success) {
      print('🔧 Step 3: Trying with test coordinates...');
      final testSuccess = await SimpleWorkingExample.testWithCoordinates(36.7538, 3.0588);
      print('Test result: ${testSuccess ? "✅ SUCCESS" : "❌ FAILED"}\n');
    }
    
    // Step 4: Check final state
    print('📋 Step 4: Final document state...');
    await SimpleWorkingExample.debugDocument();
    
    print('\n🏁 Test completed!');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// Instructions for immediate use
void printQuickInstructions() {
  print('''
🎯 QUICK FIX - READY TO USE!

The problem was a collection mismatch. I've created a unified service that works.

TO USE RIGHT NOW:

1. 📍 UPDATE LOCATION ONCE:
   await SimpleWorkingExample.updateProviderLocation();

2. 🔄 START PERIODIC UPDATES:
   SimpleWorkingExample.startPeriodicUpdates();

3. 🛑 STOP UPDATES:
   SimpleWorkingExample.stopPeriodicUpdates();

4. 🔍 DEBUG DOCUMENT:
   await SimpleWorkingExample.debugDocument();

5. 🧪 TEST WITH COORDINATES:
   await SimpleWorkingExample.testWithCoordinates(36.7538, 3.0588);

QUICK TEST:
   await quickWorkingTest();

WHAT WAS FIXED:
✅ Collection mismatch (professionals vs professionnels)
✅ Field name differences (id_user vs userId)  
✅ Document structure variations
✅ Permission issues
✅ Error handling

The unified service automatically finds your document
in whichever collection it exists!
''');
}






