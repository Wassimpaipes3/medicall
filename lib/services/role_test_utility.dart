import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for testing role changes and document structure
class RoleTestUtility {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test function to manually change a user's role for testing
  static Future<void> testRoleChange({
    required String userEmail,
    required String newRole,
  }) async {
    try {
      print('🧪 Testing role change for $userEmail to $newRole');

      // Find user by email
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        print('❌ User not found with email: $userEmail');
        return;
      }

      final userDoc = usersQuery.docs.first;
      final userId = userDoc.id;
      
      print('👤 Found user: ${userId}');

      // Update user role
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'role_changed_at': FieldValue.serverTimestamp(),
        'role_changed_by': 'test_admin',
        'role_change_reason': 'Manual test role change',
      });

      print('✅ User role updated to: $newRole');
      print('🔄 Real-time listeners should detect this change automatically');
      
    } catch (e) {
      print('❌ Error in test role change: $e');
    }
  }

  /// Verify professional document structure
  static Future<void> verifyProfessionalDocument(String userId) async {
    try {
      print('🔍 Verifying professional document for user: $userId');
      
      final doc = await _firestore.collection('professionals').doc(userId).get();
      
      if (!doc.exists) {
        print('❌ Professional document does not exist');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Required fields for professional document
      final requiredFields = [
        'bio',
        'disponible', 
        'id_user',
        'idpro',
        'login',
        'profession',
        'rating',
        'service',
        'specialite'
      ];

      print('📋 Professional document structure:');
      
      bool allFieldsPresent = true;
      for (String field in requiredFields) {
        if (data.containsKey(field)) {
          print('✅ $field: ${data[field]}');
        } else {
          print('❌ Missing field: $field');
          allFieldsPresent = false;
        }
      }

      // Check for extra fields
      final extraFields = data.keys.where((key) => !requiredFields.contains(key)).toList();
      if (extraFields.isNotEmpty) {
        print('⚠️ Extra fields found: $extraFields');
      }

      if (allFieldsPresent && extraFields.isEmpty) {
        print('✅ Professional document structure is correct!');
      } else {
        print('❌ Professional document structure needs attention');
      }
      
    } catch (e) {
      print('❌ Error verifying professional document: $e');
    }
  }

  /// Check all collections for a user to see their documents
  static Future<void> checkUserDocuments(String userId) async {
    try {
      print('📊 Checking all documents for user: $userId');
      
      final collections = ['users', 'patients', 'providers', 'professionals'];
      
      for (String collection in collections) {
        final doc = await _firestore.collection(collection).doc(userId).get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          print('✅ $collection: ${data.keys.toList()}');
          
          // Show role if it exists
          if (data.containsKey('role')) {
            print('   └─ role: ${data['role']}');
          }
        } else {
          print('❌ $collection: No document found');
        }
      }
      
    } catch (e) {
      print('❌ Error checking user documents: $e');
    }
  }
}