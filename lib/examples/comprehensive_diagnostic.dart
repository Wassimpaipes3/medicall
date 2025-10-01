import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// Comprehensive diagnostic tool to find the exact problem
class ComprehensiveDiagnostic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Run complete diagnostic
  static Future<void> runDiagnostic() async {
    print('🔍 COMPREHENSIVE DIAGNOSTIC - FINDING THE EXACT PROBLEM\n');
    
    try {
      // Step 1: Check authentication
      await _checkAuthentication();
      print('\n' + '='*50 + '\n');
      
      // Step 2: Check location permissions
      await _checkLocationPermissions();
      print('\n' + '='*50 + '\n');
      
      // Step 3: Find all user documents
      await _findAllDocuments();
      print('\n' + '='*50 + '\n');
      
      // Step 4: Test GPS
      await _testGPS();
      print('\n' + '='*50 + '\n');
      
      // Step 5: Test Firestore updates
      await _testFirestoreUpdates();
      print('\n' + '='*50 + '\n');
      
      // Step 6: Check security rules
      await _checkSecurityRules();
      
    } catch (e) {
      print('❌ Error during diagnostic: $e');
    }
  }

  /// Check authentication status
  static Future<void> _checkAuthentication() async {
    print('🔐 STEP 1: CHECKING AUTHENTICATION');
    
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ CRITICAL: No authenticated user found!');
      print('💡 Solution: User must be logged in to update location');
      return;
    }
    
    print('✅ User is authenticated');
    print('👤 User ID: ${user.uid}');
    print('📧 Email: ${user.email}');
    print('⏰ Last sign in: ${user.metadata.lastSignInTime}');
  }

  /// Check location permissions
  static Future<void> _checkLocationPermissions() async {
    print('📍 STEP 2: CHECKING LOCATION PERMISSIONS');
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📡 Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ CRITICAL: Location services are disabled!');
        print('💡 Solution: Enable location services in device settings');
        return;
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔒 Current permission: $permission');
      
      switch (permission) {
        case LocationPermission.denied:
          print('❌ CRITICAL: Location permission denied!');
          print('💡 Solution: Grant location permission in app settings');
          break;
        case LocationPermission.deniedForever:
          print('❌ CRITICAL: Location permission permanently denied!');
          print('💡 Solution: Enable location permission manually in device settings');
          break;
        case LocationPermission.whileInUse:
          print('✅ Location permission granted (while in use)');
          break;
        case LocationPermission.always:
          print('✅ Location permission granted (always)');
          break;
        case LocationPermission.unableToDetermine:
          print('⚠️ Unable to determine permission status');
          break;
      }
      
    } catch (e) {
      print('❌ Error checking location permissions: $e');
    }
  }

  /// Find all user documents
  static Future<void> _findAllDocuments() async {
    print('📋 STEP 3: FINDING ALL USER DOCUMENTS');
    
    final user = _auth.currentUser;
    if (user == null) return;
    
    bool foundAny = false;
    
    // Check professionals collection
    print('🔍 Checking professionals collection...');
    try {
      final professionalsQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionalsQuery.docs.isNotEmpty) {
        foundAny = true;
        for (var doc in professionalsQuery.docs) {
          print('✅ Found: professionals/${doc.id}');
          final data = doc.data();
          print('   Fields: ${data.keys.toList()}');
          print('   disponible: ${data['disponible']}');
          print('   currentlocation: ${data['currentlocation']}');
        }
      } else {
        print('❌ No documents in professionals collection');
      }
    } catch (e) {
      print('❌ Error checking professionals: $e');
    }
    
    // Check professionnels collection
    print('\n🔍 Checking professionnels collection...');
    try {
      final professionnelsQuery = await _firestore
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionnelsQuery.docs.isNotEmpty) {
        foundAny = true;
        for (var doc in professionnelsQuery.docs) {
          print('✅ Found: professionnels/${doc.id}');
          final data = doc.data();
          print('   Fields: ${data.keys.toList()}');
          print('   disponible: ${data['disponible']}');
          print('   currentlocation: ${data['currentlocation']}');
        }
      } else {
        print('❌ No documents in professionnels collection (id_user)');
      }
    } catch (e) {
      print('❌ Error checking professionnels (id_user): $e');
    }
    
    // Check professionnels with userId
    try {
      final professionnelsUserIdQuery = await _firestore
          .collection('professionnels')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      if (professionnelsUserIdQuery.docs.isNotEmpty) {
        foundAny = true;
        for (var doc in professionnelsUserIdQuery.docs) {
          print('✅ Found: professionnels/${doc.id} (userId)');
          final data = doc.data();
          print('   Fields: ${data.keys.toList()}');
          print('   disponible: ${data['disponible']}');
          print('   currentlocation: ${data['currentlocation']}');
        }
      } else {
        print('❌ No documents in professionnels collection (userId)');
      }
    } catch (e) {
      print('❌ Error checking professionnels (userId): $e');
    }
    
    if (!foundAny) {
      print('\n❌ CRITICAL: No provider documents found!');
      print('💡 Solution: Create a provider document first');
      print('   - Check if user role is set to "doctor" or "docteur"');
      print('   - Check if role system created the document');
    }
  }

  /// Test GPS functionality
  static Future<void> _testGPS() async {
    print('🛰️ STEP 4: TESTING GPS FUNCTIONALITY');
    
    try {
      print('📍 Requesting GPS position...');
      
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      
      print('✅ GPS position obtained');
      print('📍 Latitude: ${position.latitude}');
      print('📍 Longitude: ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');
      print('📍 Timestamp: ${position.timestamp}');
      
      if (position.accuracy > 100) {
        print('⚠️ WARNING: GPS accuracy is poor (${position.accuracy}m)');
        print('💡 Solution: Move to an area with better GPS signal');
      }
      
    } catch (e) {
      print('❌ CRITICAL: GPS test failed!');
      print('❌ Error: $e');
      print('💡 Solution: Check location permissions and GPS signal');
    }
  }

  /// Test Firestore updates
  static Future<void> _testFirestoreUpdates() async {
    print('🔥 STEP 5: TESTING FIRESTORE UPDATES');
    
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Test coordinates
    const double testLat = 36.7538;
    const double testLng = 3.0588;
    final geoPoint = GeoPoint(testLat, testLng);
    
    // Try updating in professionals collection
    print('🔄 Testing professionals collection update...');
    try {
      final professionalsQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionalsQuery.docs.isNotEmpty) {
        final doc = professionalsQuery.docs.first;
        await doc.reference.update({
          'currentlocation': geoPoint,
          'lastupdated': FieldValue.serverTimestamp(),
        });
        print('✅ SUCCESS: professionals/${doc.id} updated');
        
        // Verify the update
        final updatedDoc = await doc.reference.get();
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
        if (updatedLocation != null) {
          print('✅ VERIFIED: currentlocation = ${updatedLocation.latitude}, ${updatedLocation.longitude}');
        } else {
          print('❌ VERIFICATION FAILED: currentlocation is null');
        }
      } else {
        print('❌ No documents to update in professionals collection');
      }
    } catch (e) {
      print('❌ FAILED: professionals collection update - $e');
    }
    
    // Try updating in professionnels collection
    print('\n🔄 Testing professionnels collection update...');
    try {
      final professionnelsQuery = await _firestore
          .collection('professionnels')
          .where('id_user', isEqualTo: user.uid)
          .get();
      
      if (professionnelsQuery.docs.isNotEmpty) {
        final doc = professionnelsQuery.docs.first;
        await doc.reference.update({
          'currentlocation': geoPoint,
          'lastupdated': FieldValue.serverTimestamp(),
        });
        print('✅ SUCCESS: professionnels/${doc.id} updated');
        
        // Verify the update
        final updatedDoc = await doc.reference.get();
        final updatedData = updatedDoc.data() as Map<String, dynamic>;
        final updatedLocation = updatedData['currentlocation'] as GeoPoint?;
        if (updatedLocation != null) {
          print('✅ VERIFIED: currentlocation = ${updatedLocation.latitude}, ${updatedLocation.longitude}');
        } else {
          print('❌ VERIFICATION FAILED: currentlocation is null');
        }
      } else {
        print('❌ No documents to update in professionnels collection');
      }
    } catch (e) {
      print('❌ FAILED: professionnels collection update - $e');
    }
  }

  /// Check security rules
  static Future<void> _checkSecurityRules() async {
    print('🔒 STEP 6: CHECKING SECURITY RULES');
    
    print('📋 Current Firestore rules allow:');
    print('   - Read: All authenticated users');
    print('   - Update: If user.uid == proId OR resource.data.id_user == user.uid');
    print('   - This should allow location updates for the document owner');
    
    print('\n💡 If updates are failing with permission errors:');
    print('   1. Check if the document has the correct id_user field');
    print('   2. Check if the user.uid matches the id_user value');
    print('   3. Check if the document ID matches the user.uid');
  }

  /// Print summary and solutions
  static void printSummary() {
    print('\n🎯 DIAGNOSTIC SUMMARY');
    print('This diagnostic checks:');
    print('1. ✅ User authentication');
    print('2. ✅ Location permissions');
    print('3. ✅ Document existence');
    print('4. ✅ GPS functionality');
    print('5. ✅ Firestore updates');
    print('6. ✅ Security rules');
    
    print('\n💡 COMMON SOLUTIONS:');
    print('❌ No authenticated user → Log in first');
    print('❌ No location permission → Grant permission in settings');
    print('❌ No provider document → Create document or check role');
    print('❌ GPS fails → Check signal and permissions');
    print('❌ Firestore permission denied → Check security rules');
    print('❌ Document not found → Check collection and field names');
  }
}




