import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// Service for managing provider real-time location updates
class ProviderLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Timer for periodic location updates
  static Timer? _locationUpdateTimer;
  static bool _isUpdatingLocation = false;
  
  // Configuration
  static const Duration updateInterval = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Helper: locate the provider document in 'professionals' collection.
  /// Strategy:
  /// 1. Query where id_user == current uid (preferred real structure).
  /// 2. Fallback: direct doc lookup by uid (legacy possibility).
  /// Returns the DocumentSnapshot or null if not found.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> _getProviderDocSnapshot() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final uid = user.uid;
    try {
      // Primary: query by id_user
      final query = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }

      // Fallback: direct doc id == uid
      final direct = await _firestore.collection('professionals').doc(uid).get();
      if (direct.exists) return direct;

      return null;
    } catch (e) {
      print('❌ Error locating provider document: $e');
      return null;
    }
  }

  /// Update provider's current location in Firestore
  /// Only updates if provider is available (disponible == true)
  /// Uses the correct field names: currentlocation and lastupdated
  static Future<bool> updateProviderLocation({
    bool enableRetry = true,
    int retryCount = 0,
  }) async {
    try {
      // Get current authenticated user (provider)
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }

      final providerId = user.uid;
      print('📍 Updating location for provider: $providerId');

      // Find provider document using helper (id_user match or direct doc id fallback)
      final providerDoc = await _getProviderDocSnapshot();
      if (providerDoc == null) {
        print('❌ Provider document not found for user ID: $providerId');
        return false;
      }
      
  final providerData = providerDoc.data();
  final isAvailable = (providerData?['disponible'] as bool?) ?? false;

      if (!isAvailable) {
        print('⚠️ Provider is not available (disponible == false), skipping location update');
        return false;
      }

      // Check location permissions
      final hasPermission = await _checkLocationPermissions();
      if (!hasPermission) {
        print('❌ Location permissions not granted');
        return false;
      }

      // Get current GPS coordinates
      final position = await _getCurrentPosition();
      if (position == null) {
        print('❌ Failed to get current position');
        return false;
      }

      // Create GeoPoint for Firestore
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      print('📍 Current position: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m, Speed: ${position.speed}m/s');

      // Update provider location in Firestore using correct field names
      print('🔄 Updating Firestore document: ${providerDoc.id}');
      print('📍 New location: ${geoPoint.latitude}, ${geoPoint.longitude}');
      
      await _firestore.collection('professionals').doc(providerDoc.id).update({
        'currentlocation': geoPoint,  // Using correct field name from your structure
        'lastupdated': FieldValue.serverTimestamp(),  // Using correct field name
        'locationAccuracy': position.accuracy,
        'isLocationActive': true,
      });

      // Verify the update was successful by reading the document back
      final updatedDoc = await _firestore.collection('professionals').doc(providerDoc.id).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
      
      if (updatedLocation != null) {
        print('✅ Provider location updated successfully');
        print('📍 Verified location in Firestore: ${updatedLocation.latitude}, ${updatedLocation.longitude}');
        print('⏰ Last updated: ${updatedData['lastupdated']}');
      } else {
        print('⚠️ Location update may have failed - currentlocation field is null');
        return false;
      }
      
      return true;

    } catch (e) {
      print('❌ Error updating provider location: $e');
      
      // Enhanced retry logic with exponential backoff
      if (enableRetry && retryCount < maxRetries) {
        final retryDelaySeconds = retryDelay.inSeconds * (retryCount + 1);
        print('🔄 Retrying location update in ${retryDelaySeconds}s... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        return updateProviderLocation(
          enableRetry: enableRetry,
          retryCount: retryCount + 1,
        );
      }
      
      return false;
    }
  }

  /// Check and request location permissions with comprehensive error handling
  static Future<bool> _checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled. Please enable location services in device settings.');
        return false;
      }

      // Check current location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Current permission status: $permission');
      
      // Handle different permission states
      switch (permission) {
        case LocationPermission.denied:
          print('📍 Location permission denied, requesting permission...');
          permission = await Geolocator.requestPermission();
          
          if (permission == LocationPermission.denied) {
            print('❌ Location permissions are denied by user');
            return false;
          } else if (permission == LocationPermission.deniedForever) {
            print('❌ Location permissions are permanently denied. User must enable manually in settings.');
            return false;
          }
          break;
          
        case LocationPermission.deniedForever:
          print('❌ Location permissions are permanently denied. User must enable manually in device settings.');
          return false;
          
        case LocationPermission.whileInUse:
          print('✅ Location permission granted (while in use)');
          return true;
          
        case LocationPermission.always:
          print('✅ Location permission granted (always)');
          return true;
          
        case LocationPermission.unableToDetermine:
          print('⚠️ Unable to determine location permission status');
          return false;
      }

      // Final check
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        print('✅ Location permissions granted');
        return true;
      }

      print('❌ Location permissions not granted');
      return false;

    } catch (e) {
      print('❌ Error checking location permissions: $e');
      return false;
    }
  }

  /// Get current GPS position with comprehensive error handling and null safety
  static Future<Position?> _getCurrentPosition() async {
    try {
      // Configure location settings for optimal accuracy and performance
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update only if moved 5 meters
        timeLimit: Duration(seconds: 15), // Increased timeout for better reliability
      );

      print('📍 Requesting current GPS position...');
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      // Validate position data
      if (position.latitude == 0.0 && position.longitude == 0.0) {
        print('⚠️ Received invalid coordinates (0,0), retrying...');
        return null;
      }

      // Check accuracy threshold (reject if accuracy is too poor)
      if (position.accuracy > 100) { // More than 100 meters accuracy is too poor
        print('⚠️ GPS accuracy too poor: ${position.accuracy}m, retrying...');
        return null;
      }

      print('✅ GPS position obtained successfully');
      print('📍 Coordinates: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');
      print('📍 Timestamp: ${position.timestamp}');

      return position;

    } catch (e) {
      print('❌ Error getting current position: $e');
      
      // Provide specific error information
      if (e.toString().contains('timeout')) {
        print('⏰ GPS request timed out - device may be indoors or have poor signal');
      } else if (e.toString().contains('permission')) {
        print('🔒 GPS permission error - check location permissions');
      } else if (e.toString().contains('service')) {
        print('📡 Location service error - check if GPS is enabled');
      }
      
      return null;
    }
  }

  /// Start periodic location updates
  /// Call this when provider goes online/available
  static void startLocationUpdates() {
    if (_locationUpdateTimer?.isActive == true) {
      print('⚠️ Location updates already active');
      return;
    }

    print('🚀 Starting periodic location updates every ${updateInterval.inSeconds} seconds');
    
    // Update immediately
    updateProviderLocation();
    
    // Set up periodic timer
    _locationUpdateTimer = Timer.periodic(updateInterval, (timer) {
      if (!_isUpdatingLocation) {
        _isUpdatingLocation = true;
        updateProviderLocation().then((success) {
          _isUpdatingLocation = false;
          if (!success) {
            print('⚠️ Location update failed, will retry on next cycle');
          }
        });
      } else {
        print('⚠️ Previous location update still in progress, skipping cycle');
      }
    });
  }

  /// Stop periodic location updates
  /// Call this when provider goes offline/unavailable
  static void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isUpdatingLocation = false;
    print('🛑 Stopped periodic location updates');
    
    // Mark provider as location inactive
    _markLocationInactive();
  }

  /// Mark provider as location inactive in Firestore
  static Future<void> _markLocationInactive() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final providerDoc = await _getProviderDocSnapshot();
      if (providerDoc != null) {
        await _firestore.collection('professionals').doc(providerDoc.id).update({
          'isLocationActive': false,
          'lastupdated': FieldValue.serverTimestamp(),
        });
      } else {
        print('⚠️ Could not mark inactive - provider document missing');
      }

      print('📍 Provider marked as location inactive');
    } catch (e) {
      print('❌ Error marking location inactive: $e');
    }
  }

  /// Get provider's current availability status
  static Future<bool> isProviderAvailable() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

    final providerDoc = await _getProviderDocSnapshot();
    if (providerDoc == null) return false;
  final data = providerDoc.data();
  return (data?['disponible'] as bool?) ?? false;

    } catch (e) {
      print('❌ Error checking provider availability: $e');
      return false;
    }
  }

  /// Update provider availability status
  /// Automatically starts/stops location updates based on availability
  static Future<bool> setProviderAvailability(bool isAvailable) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }

      final providerDoc = await _getProviderDocSnapshot();
      if (providerDoc == null) {
        print('❌ Cannot set availability - provider doc missing');
        return false;
      }

      await _firestore.collection('professionals').doc(providerDoc.id).update({
        'disponible': isAvailable,
        'lastupdated': FieldValue.serverTimestamp(),
      });

      if (isAvailable) {
        print('✅ Provider set as available - starting location updates');
        startLocationUpdates();
      } else {
        print('✅ Provider set as unavailable - stopping location updates');
        stopLocationUpdates();
      }

      return true;

    } catch (e) {
      print('❌ Error setting provider availability: $e');
      return false;
    }
  }

  /// One-time location update (useful for testing)
  static Future<Position?> getCurrentLocationOnce() async {
    final hasPermission = await _checkLocationPermissions();
    if (!hasPermission) return null;
    
    return _getCurrentPosition();
  }

  /// Check if location updates are currently active
  static bool get isLocationUpdatesActive => _locationUpdateTimer?.isActive == true;

  /// Get update interval in seconds
  static int get updateIntervalSeconds => updateInterval.inSeconds;

  /// Dispose resources
  static void dispose() {
    stopLocationUpdates();
  }

  /// Test function to verify the implementation works correctly
  /// This can be called from your app to test the location update functionality
  static Future<bool> testLocationUpdate() async {
    print('🧪 Testing provider location update functionality...');
    
    try {
      // Test 1: Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Test failed: No authenticated user');
        return false;
      }
      print('✅ Test 1 passed: User is authenticated (${user.uid})');

      // Test 2: Check if provider document exists
      final providerDoc = await _getProviderDocSnapshot();
      if (providerDoc == null) {
        print('❌ Test failed: Provider document not found');
        return false;
      }
      print('✅ Test 2 passed: Provider document found');

      // Test 3: Check location permissions
      final hasPermission = await _checkLocationPermissions();
      if (!hasPermission) {
        print('❌ Test failed: Location permissions not granted');
        return false;
      }
      print('✅ Test 3 passed: Location permissions granted');

      // Test 4: Try to get current position
      final position = await _getCurrentPosition();
      if (position == null) {
        print('❌ Test failed: Could not get current position');
        return false;
      }
      print('✅ Test 4 passed: Current position obtained (${position.latitude}, ${position.longitude})');

      // Test 5: Try to update location in Firestore
      final updateSuccess = await updateProviderLocation(enableRetry: false);
      if (!updateSuccess) {
        print('❌ Test failed: Could not update location in Firestore');
        return false;
      }
      print('✅ Test 5 passed: Location updated in Firestore');

      print('🎉 All tests passed! Location update functionality is working correctly.');
      return true;

    } catch (e) {
      print('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Debug function to check current location in Firestore
  /// This helps verify if the currentlocation field is actually being updated
  static Future<void> debugCurrentLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return;
      }

      print('🔍 Debugging current location in Firestore...');
      print('👤 User ID: ${user.uid}');

      // Find provider document
      final doc = await _getProviderDocSnapshot();
      if (doc == null) {
        print('❌ Provider document not found');
        return;
      }
      final data = doc.data();
      print('📄 Document ID: ${doc.id}');
      if (data != null) {
        print('📋 All fields in document: ${data.keys.toList()}');
      } else {
        print('⚠️ Document data is null');
      }
      
      // Check currentlocation field specifically
  final currentLocation = data?['currentlocation'];
      if (currentLocation != null) {
        if (currentLocation is GeoPoint) {
          print('📍 Current location (GeoPoint): ${currentLocation.latitude}, ${currentLocation.longitude}');
        } else {
          print('📍 Current location (${currentLocation.runtimeType}): $currentLocation');
        }
      } else {
        print('❌ currentlocation field is null or missing');
      }
      
      // Check lastupdated field
  final lastUpdated = data?['lastupdated'];
      if (lastUpdated != null) {
        print('⏰ Last updated: $lastUpdated');
      } else {
        print('❌ lastupdated field is null or missing');
      }
      
      // Check disponible field
  final disponible = data?['disponible'];
      print('🟢 Available: $disponible');
      
    } catch (e) {
      print('❌ Error debugging location: $e');
    }
  }

  /// Force update location with specific coordinates (for testing)
  static Future<bool> forceUpdateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('🔧 Force updating location with coordinates: $latitude, $longitude');

      // Find provider document
      final doc = await _getProviderDocSnapshot();
      if (doc == null) {
        print('❌ Provider document not found');
        return false;
      }
      final geoPoint = GeoPoint(latitude, longitude);

      print('🔄 Updating document: ${doc.id}');
      
      // Force update the location
      await _firestore.collection('professionals').doc(doc.id).update({
        'currentlocation': geoPoint,
        'lastupdated': FieldValue.serverTimestamp(),
        'disponible': true,
      });

      // Verify the update
      final updatedDoc = await _firestore.collection('professionals').doc(doc.id).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
      
      if (updatedLocation != null) {
        print('✅ Force update successful!');
        print('📍 New location: ${updatedLocation.latitude}, ${updatedLocation.longitude}');
        return true;
      } else {
        print('❌ Force update failed - location is still null');
        return false;
      }

    } catch (e) {
      print('❌ Error in force update: $e');
      return false;
    }
  }

  /// Example usage: Start periodic location updates for an online provider
  /// Call this when the provider goes online or becomes available
  static Future<void> startProviderLocationTracking() async {
    print('🚀 Starting provider location tracking...');
    
    // First, ensure the provider is marked as available
    final user = _auth.currentUser;
    if (user != null) {
      try {
          final doc = await _getProviderDocSnapshot();
          if (doc != null) {
            await _firestore.collection('professionals').doc(doc.id).update({
              'disponible': true,
              'lastupdated': FieldValue.serverTimestamp(),
            });
            print('✅ Provider marked as available');
          } else {
            print('⚠️ Provider doc not found when starting tracking');
          }
      } catch (e) {
        print('⚠️ Could not update provider availability: $e');
      }
    }

    // Start periodic location updates
    startLocationUpdates();
  }

  /// Example usage: Stop location tracking when provider goes offline
  static Future<void> stopProviderLocationTracking() async {
    print('🛑 Stopping provider location tracking...');
    
    // Stop the periodic updates
    stopLocationUpdates();
    
    // Optionally mark provider as unavailable
    final user = _auth.currentUser;
    if (user != null) {
      try {
          final doc = await _getProviderDocSnapshot();
          if (doc != null) {
            await _firestore.collection('professionals').doc(doc.id).update({
              'disponible': false,
              'isLocationActive': false,
              'lastupdated': FieldValue.serverTimestamp(),
            });
            print('✅ Provider marked as unavailable');
          } else {
            print('⚠️ Provider doc not found when stopping tracking');
          }
      } catch (e) {
        print('⚠️ Could not update provider availability: $e');
      }
    }
  }
}

/// Extension methods for easier usage
extension ProviderLocationExtension on ProviderLocationService {
  /// Quick method to toggle provider availability
  static Future<bool> toggleAvailability() async {
    final currentStatus = await ProviderLocationService.isProviderAvailable();
    return ProviderLocationService.setProviderAvailability(!currentStatus);
  }

  /// Quick method to update location once (useful for testing)
  static Future<bool> updateLocationOnce() async {
    return ProviderLocationService.updateProviderLocation(enableRetry: true);
  }
}