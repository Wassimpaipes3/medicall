import '../services/provider_location_service.dart';

/// Quick test function to debug why currentlocation is not updating
/// Call this function to identify the issue
Future<void> quickLocationTest() async {
  print('🚀 Starting quick location test...\n');
  
  try {
    // Step 1: Check current state
    print('📋 STEP 1: Checking current document state...');
    await ProviderLocationService.debugCurrentLocation();
    print('\n');
    
    // Step 2: Try to update location
    print('🔄 STEP 2: Attempting location update...');
    final updateSuccess = await ProviderLocationService.updateProviderLocation();
    print('Update result: ${updateSuccess ? "✅ SUCCESS" : "❌ FAILED"}\n');
    
    // Step 3: Check state after update
    print('📋 STEP 3: Checking state after update...');
    await ProviderLocationService.debugCurrentLocation();
    print('\n');
    
    // Step 4: If update failed, try force update with test coordinates
    if (!updateSuccess) {
      print('🔧 STEP 4: Trying force update with test coordinates...');
      final forceSuccess = await ProviderLocationService.forceUpdateLocation(
        latitude: 36.7538,  // Algiers, Algeria
        longitude: 3.0588,
      );
      print('Force update result: ${forceSuccess ? "✅ SUCCESS" : "❌ FAILED"}\n');
      
      // Step 5: Check final state
      print('📋 STEP 5: Final state check...');
      await ProviderLocationService.debugCurrentLocation();
    }
    
    print('\n🏁 Quick test completed!');
    
  } catch (e) {
    print('❌ Error during quick test: $e');
  }
}

/// Alternative test with mock coordinates
Future<void> testWithMockLocation() async {
  print('🧪 Testing with mock location coordinates...\n');
  
  // Test with different coordinates to see if the issue is with GPS or Firestore
  final testCoordinates = [
    {'lat': 36.7538, 'lng': 3.0588, 'name': 'Algiers, Algeria'},
    {'lat': 48.8566, 'lng': 2.3522, 'name': 'Paris, France'},
    {'lat': 40.7128, 'lng': -74.0060, 'name': 'New York, USA'},
  ];
  
  for (final coords in testCoordinates) {
    print('📍 Testing with ${coords['name']} (${coords['lat']}, ${coords['lng']})');
    
    final success = await ProviderLocationService.forceUpdateLocation(
      latitude: coords['lat'] as double,
      longitude: coords['lng'] as double,
    );
    
    print('Result: ${success ? "✅ SUCCESS" : "❌ FAILED"}\n');
    
    if (success) {
      print('✅ Location update is working! The issue might be with GPS coordinates.');
      break;
    }
  }
  
  // Check final state
  print('📋 Final document state:');
  await ProviderLocationService.debugCurrentLocation();
}

/// Simple function to just check what's in the document
Future<void> checkDocumentState() async {
  print('📋 Checking current document state...\n');
  await ProviderLocationService.debugCurrentLocation();
}

/// Simple function to try updating once
Future<void> tryUpdateOnce() async {
  print('🔄 Trying to update location once...\n');
  final success = await ProviderLocationService.updateProviderLocation();
  print('Result: ${success ? "✅ SUCCESS" : "❌ FAILED"}');
  
  if (success) {
    print('✅ Location updated successfully!');
  } else {
    print('❌ Location update failed. Check console for details.');
  }
}




