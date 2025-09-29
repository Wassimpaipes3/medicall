import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider location service that works with your actual document structure
class CorrectProviderLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Find provider document using the actual field structure (id_user field)
  static Future<String?> findProviderDocumentId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('🔍 Finding provider document using id_user field...');
      
      // Search by id_user field (this matches your document structure)
      final idUserQuery = await _firestore
          .collection('professionals')
          .where('id_user', isEqualTo: user.uid)
          .limit(1)
          .get();
          
      if (idUserQuery.docs.isNotEmpty) {
        final docId = idUserQuery.docs.first.id;
        final data = idUserQuery.docs.first.data();
        print('✅ Found document with ID: $docId');
        print('📋 Provider ID (idpro): ${data['idpro']}');
        print('📋 Specialty: ${data['specialite']}');
        print('📍 Currently available: ${data['disponible']}');
        return docId;
      }

      print('❌ Provider document not found');
      return null;
      
    } catch (e) {
      print('❌ Error finding provider document: $e');
      return null;
    }
  }

  /// Update provider location using your actual field structure
  static Future<bool> updateProviderLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Find the document
      final docId = await findProviderDocumentId();
      if (docId == null) {
        print('❌ Could not find provider document');
        return false;
      }

      print('📝 Updating location for document: $docId');
      print('📍 New coordinates: $latitude, $longitude');

      // Create GeoPoint with the new coordinates
      final location = GeoPoint(latitude, longitude);

      // Update using your actual field names
      await _firestore.collection('professionnels').doc(docId).update({
        'currentlocation': location,      // Your actual field name
        'lastupdated': FieldValue.serverTimestamp(), // Your actual field name
        'disponible': true,               // Set available when updating location
      });

      print('✅ Location updated successfully!');
      print('📍 Fields updated: currentlocation, lastupdated, disponible');
      return true;

    } catch (e) {
      print('❌ Error updating location: $e');
      
      if (e.toString().contains('permission')) {
        print('🔒 Permission denied - check Firestore rules');
      }
      if (e.toString().contains('not-found')) {
        print('📄 Document not found');
      }
      
      return false;
    }
  }

  /// Check current provider status
  static Future<Map<String, dynamic>?> getProviderStatus() async {
    try {
      final docId = await findProviderDocumentId();
      if (docId == null) return null;

      final doc = await _firestore.collection('professionals').doc(docId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      
      print('📊 Provider Status:');
      print('  🆔 ID: ${data['idpro']}');
      print('  📍 Available: ${data['disponible']}');
      print('  🏥 Specialty: ${data['specialite']}');
      print('  📍 Location: ${data['currentlocation']}');
      print('  ⏰ Last Updated: ${data['lastupdated']}');

      return data;
    } catch (e) {
      print('❌ Error getting provider status: $e');
      return null;
    }
  }

  /// Test location update with mock coordinates (Algiers center)
  static Future<bool> testLocationUpdate() async {
    print('🧪 Testing location update with mock coordinates...');
    
    // Mock coordinates for Algiers, Algeria
    const double mockLatitude = 36.7538;
    const double mockLongitude = 3.0588;
    
    return updateProviderLocation(
      latitude: mockLatitude,
      longitude: mockLongitude,
    );
  }

  /// Set provider availability status
  static Future<bool> setProviderAvailability(bool available) async {
    try {
      final docId = await findProviderDocumentId();
      if (docId == null) {
        print('❌ Could not find provider document');
        return false;
      }

      await _firestore.collection('professionnels').doc(docId).update({
        'disponible': available,
        'lastupdated': FieldValue.serverTimestamp(),
      });

      print('✅ Provider availability updated to: $available');
      return true;
    } catch (e) {
      print('❌ Error updating availability: $e');
      return false;
    }
  }
}