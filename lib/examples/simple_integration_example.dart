import '../services/provider_location_service.dart';

/// Simple integration example showing exactly how to use updateProviderLocation()
/// This is the minimal code you need to integrate location updates in your app
class SimpleIntegrationExample {
  
  /// Example 1: Basic usage - Update location once
  static Future<void> updateLocationOnce() async {
    print('📍 Updating provider location...');
    
    final success = await ProviderLocationService.updateProviderLocation();
    
    if (success) {
      print('✅ Location updated successfully!');
    } else {
      print('❌ Location update failed');
    }
  }

  /// Example 2: Start periodic updates (every 10 seconds)
  static void startPeriodicUpdates() {
    print('🚀 Starting periodic location updates...');
    
    // This will update location every 10 seconds while provider is available
    ProviderLocationService.startLocationUpdates();
    
    print('✅ Periodic updates started');
  }

  /// Example 3: Stop periodic updates
  static void stopPeriodicUpdates() {
    print('🛑 Stopping periodic location updates...');
    
    ProviderLocationService.stopLocationUpdates();
    
    print('✅ Periodic updates stopped');
  }

  /// Example 4: Complete provider lifecycle management
  static Future<void> handleProviderOnline() async {
    print('👨‍⚕️ Provider is now online - starting location tracking...');
    
    // This will:
    // 1. Mark provider as available (disponible = true)
    // 2. Start periodic location updates every 10 seconds
    await ProviderLocationService.startProviderLocationTracking();
    
    print('✅ Provider location tracking started');
  }

  static Future<void> handleProviderOffline() async {
    print('👨‍⚕️ Provider is now offline - stopping location tracking...');
    
    // This will:
    // 1. Stop periodic location updates
    // 2. Mark provider as unavailable (disponible = false)
    await ProviderLocationService.stopProviderLocationTracking();
    
    print('✅ Provider location tracking stopped');
  }

  /// Example 5: Test the implementation
  static Future<void> testImplementation() async {
    print('🧪 Testing location update implementation...');
    
    final success = await ProviderLocationService.testLocationUpdate();
    
    if (success) {
      print('🎉 All tests passed! Implementation is working correctly.');
    } else {
      print('❌ Tests failed. Check console for details.');
    }
  }

  /// Example 6: Check if location updates are active
  static void checkStatus() {
    final isActive = ProviderLocationService.isLocationUpdatesActive;
    final interval = ProviderLocationService.updateIntervalSeconds;
    
    print('📍 Location updates status: ${isActive ? "Active" : "Inactive"}');
    print('⏱️ Update interval: $interval seconds');
  }
}

/// Example of how to integrate in your main app
class AppIntegrationExample {
  
  /// Call this when your app starts and provider is authenticated
  static Future<void> initializeProviderLocation() async {
    // Test the implementation first
    await SimpleIntegrationExample.testImplementation();
    
    // If tests pass, start location tracking
    await SimpleIntegrationExample.handleProviderOnline();
  }

  /// Call this when provider logs out or app is closed
  static Future<void> cleanupProviderLocation() async {
    await SimpleIntegrationExample.handleProviderOffline();
  }

  /// Example of how to handle availability toggle in your UI
  static Future<void> onAvailabilityToggle(bool isAvailable) async {
    if (isAvailable) {
      await SimpleIntegrationExample.handleProviderOnline();
    } else {
      await SimpleIntegrationExample.handleProviderOffline();
    }
  }
}

/// Quick reference for the main function you requested
class QuickReference {
  
  /// This is the main function you requested: updateProviderLocation()
  /// 
  /// Usage:
  /// ```dart
  /// final success = await ProviderLocationService.updateProviderLocation();
  /// ```
  /// 
  /// What it does:
  /// 1. Gets current GPS coordinates using geolocator
  /// 2. Updates Firestore fields: currentlocation (GeoPoint) and lastupdated (timestamp)
  /// 3. Only updates if disponible == true
  /// 4. Handles errors gracefully with retry mechanism
  /// 5. Includes proper null checks and permissions handling
  static Future<bool> updateProviderLocation() {
    return ProviderLocationService.updateProviderLocation();
  }

  /// For periodic updates every 10 seconds:
  /// ```dart
  /// ProviderLocationService.startLocationUpdates();
  /// ```
  static void startPeriodicUpdates() {
    ProviderLocationService.startLocationUpdates();
  }

  /// To stop periodic updates:
  /// ```dart
  /// ProviderLocationService.stopLocationUpdates();
  /// ```
  static void stopPeriodicUpdates() {
    ProviderLocationService.stopLocationUpdates();
  }
}

