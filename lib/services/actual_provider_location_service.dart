import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Location service that works with the actual Firestore document structure
class ActualProviderLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update provider location using the actual document structure
  static Future<bool> updateProviderLocationWithCorrectStructure({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return false;
      }

      print('📍 Updating location with correct structure...');
      print('👤 User ID: ${user.uid}');
      print('📍 Coordinates: $latitude, $longitude');

      // First, find the document by searching with id_user field
      final querySnapshot = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ No provider document found with id_user: ${user.uid}');
        return false;
      }

      final doc = querySnapshot.docs.first;
      final docId = doc.id;
      print('✅ Found provider document with ID: $docId');

      // Create GeoPoint for location
      final location = GeoPoint(latitude, longitude);

      // Update with the correct field names from your actual structure
      await _firestore.collection('professionals').doc(docId).update({
        'currentlocation': location,  // Using your actual field name
        'lastupdated': FieldValue.serverTimestamp(),  // Using your actual field name
        'disponible': true,  // Ensure provider is available when updating location
      });

      print('✅ Location updated successfully!');
      print('📍 Updated fields: currentlocation, lastupdated, disponible');
      
      return true;

    } catch (e) {
      print('❌ Error updating location: $e');
      
      // Provide specific error information
      if (e.toString().contains('permission')) {
        print('🔒 Permission denied - check Firestore security rules');
      } else if (e.toString().contains('not-found')) {
        print('📄 Document not found');
      } else {
        print('🔧 Detailed error: ${e.toString()}');
      }
      
      return false;
    }
  }

  /// Check if provider document exists using the correct structure
  static Future<Map<String, dynamic>?> getProviderDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('🔍 Searching for provider document...');

      // Search by id_user field (your actual structure)
      final querySnapshot = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print('✅ Found provider document with ID: ${doc.id}');
        print('📊 Document fields: ${data.keys.toList()}');
        
        // Print key information
        if (data.containsKey('profession')) print('👨‍⚕️ Profession: ${data['profession']}');
        if (data.containsKey('specialite')) print('🏥 Speciality: ${data['specialite']}');
        if (data.containsKey('disponible')) print('📍 Available: ${data['disponible']}');
        if (data.containsKey('currentlocation')) {
          final location = data['currentlocation'];
          if (location is GeoPoint) {
            print('📍 Current location: ${location.latitude}, ${location.longitude}');
          } else {
            print('📍 Current location: $location');
          }
        }
        
        return data;
      } else {
        print('❌ No provider document found');
        return null;
      }

    } catch (e) {
      print('❌ Error getting provider document: $e');
      return null;
    }
  }

  /// Test function with mock coordinates for Algiers
  static Future<bool> testLocationUpdateWithCorrectStructure() async {
    print('🧪 Testing location update with correct document structure...');
    
    // Mock coordinates for Algiers, Algeria
    const double mockLatitude = 36.7538;
    const double mockLongitude = 3.0588;
    
    return updateProviderLocationWithCorrectStructure(
      latitude: mockLatitude,
      longitude: mockLongitude,
    );
  }

  /// Set provider availability status
  static Future<bool> setProviderAvailability(bool isAvailable) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Find provider document
      final querySnapshot = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ No provider document found');
        return false;
      }

      final docId = querySnapshot.docs.first.id;
      
      await _firestore.collection('professionals').doc(docId).update({
        'disponible': isAvailable,
        'lastupdated': FieldValue.serverTimestamp(),
      });

      print('✅ Provider availability set to: $isAvailable');
      return true;

    } catch (e) {
      print('❌ Error setting availability: $e');
      return false;
    }
  }
}