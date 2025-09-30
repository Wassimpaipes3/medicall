import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// Unified provider location service that works with the correct collection and structure
/// This service handles both professionnels and professionals collections
class UnifiedProviderLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Timer for periodic location updates
  static Timer? _locationUpdateTimer;
  static bool _isUpdatingLocation = false;
  
  // Configuration
  static const Duration updateInterval = Duration(seconds: 10);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Find the correct provider document in either collection
  static Future<DocumentSnapshot?> _findProviderDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('🔍 Searching for provider document...');
      print('👤 User ID: ${user.uid}');

      // Try professionals collection first (newer role system)
      print('📍 Checking professionals collection...');
      final professionalsQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (professionalsQuery.docs.isNotEmpty) {
        final doc = professionalsQuery.docs.first;
        print('✅ Found document in professionals collection: ${doc.id}');
        return doc;
      }

      // Try professionnels collection (legacy)
      print('📍 Checking professionnels collection...');
      final professionnelsQuery = await _firestore
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (professionnelsQuery.docs.isNotEmpty) {
        final doc = professionnelsQuery.docs.first;
        print('✅ Found document in professionnels collection: ${doc.id}');
        return doc;
      }

      // Try professionnels collection with userId field (Cloud Functions)
      print('📍 Checking professionnels collection with userId field...');
      final professionnelsUserIdQuery = await _firestore
          .collection('professionnels')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (professionnelsUserIdQuery.docs.isNotEmpty) {
        final doc = professionnelsUserIdQuery.docs.first;
        print('✅ Found document in professionnels collection (userId): ${doc.id}');
        return doc;
      }

      // Try direct document access by user ID
      print('📍 Trying direct document access...');
      final directDoc = await _firestore.collection('professionals').doc(user.uid).get();
      if (directDoc.exists) {
        print('✅ Found document by direct access: ${directDoc.id}');
        return directDoc;
      }

      final directDocProf = await _firestore.collection('professionnels').doc(user.uid).get();
      if (directDocProf.exists) {
        print('✅ Found document in professionnels by direct access: ${directDocProf.id}');
        return directDocProf;
      }

      print('❌ No provider document found in any collection');
      return null;

    } catch (e) {
      print('❌ Error finding provider document: $e');
      return null;
    }
  }

  /// Update provider's current location in Firestore
  /// Works with both professionals and professionnels collections
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

      // Find the correct provider document
      final providerDoc = await _findProviderDocument();
      if (providerDoc == null) {
        print('❌ Provider document not found');
        return false;
      }

      final providerData = providerDoc.data() as Map<String, dynamic>;
      
      // Check availability (handle different field names)
      final isAvailable = providerData['disponible'] as bool? ?? 
                         providerData['available'] as bool? ?? false;

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
      print('🔄 Updating document: ${providerDoc.id} in collection: ${providerDoc.reference.parent.id}');

      // Update provider location in Firestore
      await providerDoc.reference.update({
        'currentlocation': geoPoint,  // Using correct field name
        'lastupdated': FieldValue.serverTimestamp(),  // Using correct field name
        'locationAccuracy': position.accuracy,
        'isLocationActive': true,
      });

      // Verify the update was successful
      final updatedDoc = await providerDoc.reference.get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
      
      if (updatedLocation != null) {
        print('✅ Provider location updated successfully');
        print('📍 Verified location in Firestore: ${updatedLocation.latitude}, ${updatedLocation.longitude}');
        print('⏰ Last updated: ${updatedData['lastupdated']}');
        return true;
      } else {
        print('⚠️ Location update may have failed - currentlocation field is null');
        return false;
      }

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

  /// Check and request location permissions
  static Future<bool> _checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
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

  /// Get current GPS position with comprehensive error handling
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
  static void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isUpdatingLocation = false;
    print('🛑 Stopped periodic location updates');
  }

  /// Debug function to check current location in Firestore
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
      final doc = await _findProviderDocument();
      if (doc == null) {
        print('❌ Provider document not found');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      print('📄 Document ID: ${doc.id}');
      print('📄 Collection: ${doc.reference.parent.id}');
      print('📋 All fields in document: ${data.keys.toList()}');
      
      // Check currentlocation field specifically
      final currentLocation = data['currentlocation'];
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
      final lastUpdated = data['lastupdated'];
      if (lastUpdated != null) {
        print('⏰ Last updated: $lastUpdated');
      } else {
        print('❌ lastupdated field is null or missing');
      }
      
      // Check disponible field
      final disponible = data['disponible'] ?? data['available'];
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
      final doc = await _findProviderDocument();
      if (doc == null) {
        print('❌ Provider document not found');
        return false;
      }

      final geoPoint = GeoPoint(latitude, longitude);

      print('🔄 Updating document: ${doc.id} in collection: ${doc.reference.parent.id}');
      
      // Force update the location
      await doc.reference.update({
        'currentlocation': geoPoint,
        'lastupdated': FieldValue.serverTimestamp(),
        'disponible': true,
      });

      // Verify the update
      final updatedDoc = await doc.reference.get();
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

  /// Test function to verify the implementation works correctly
  static Future<bool> testLocationUpdate() async {
    print('🧪 Testing unified provider location update functionality...');
    
    try {
      // Test 1: Check if user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Test failed: No authenticated user');
        return false;
      }
      print('✅ Test 1 passed: User is authenticated (${user.uid})');

      // Test 2: Check if provider document exists
      final doc = await _findProviderDocument();
      if (doc == null) {
        print('❌ Test failed: Provider document not found');
        return false;
      }
      print('✅ Test 2 passed: Provider document found in ${doc.reference.parent.id} collection');

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

      print('🎉 All tests passed! Unified location update functionality is working correctly.');
      return true;

    } catch (e) {
      print('❌ Test failed with error: $e');
      return false;
    }
  }

  /// Dispose resources
  static void dispose() {
    stopLocationUpdates();
  }

  /// Check if location updates are currently active
  static bool get isLocationUpdatesActive => _locationUpdateTimer?.isActive == true;

  /// Get update interval in seconds
  static int get updateIntervalSeconds => updateInterval.inSeconds;
}

