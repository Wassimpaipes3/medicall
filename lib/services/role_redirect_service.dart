import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple service to handle role-based redirects and cleanup
class RoleRedirectService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get redirect route based on user role
  static Future<String> getRedirectRoute() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '/login';

      // Get user document to check role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        debugPrint('User document not found, redirecting to patient home');
        return '/home';
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] as String?;

      debugPrint('User role: $role');

      // Clean up old role documents if needed
      await _cleanupOldRoleDocuments(user.uid, role);

      // Return appropriate route based on role
      switch (role) {
        case 'patient':
          return '/home';
        case 'doctor':
        case 'docteur':
        case 'professional':
          return '/provider-dashboard';
        case 'admin':
          return '/admin-dashboard';
        default:
          debugPrint('Unknown role: $role, defaulting to patient');
          return '/home';
      }
    } catch (e) {
      debugPrint('Error getting redirect route: $e');
      return '/home';
    }
  }

  /// Clean up old role documents
  static Future<void> _cleanupOldRoleDocuments(String userId, String? currentRole) async {
    try {
      // Collections to check for cleanup
      final collections = ['patients', 'providers'];
      
      for (String collection in collections) {
        // Skip the current role collection
        if (_shouldKeepDocument(collection, currentRole)) {
          continue;
        }

        // Check if document exists in this collection
        final doc = await _firestore.collection(collection).doc(userId).get();
        
        if (doc.exists) {
          debugPrint('Cleaning up old document from $collection collection');
          await _firestore.collection(collection).doc(userId).delete();
          debugPrint('Deleted old document from $collection');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old role documents: $e');
    }
  }

  /// Check if we should keep the document in this collection
  static bool _shouldKeepDocument(String collection, String? currentRole) {
    switch (currentRole) {
      case 'patient':
        return collection == 'patients';
      case 'doctor':
      case 'docteur':
      case 'professional':
        return collection == 'providers';
      default:
        return false;
    }
  }

  /// Create role-specific document if it doesn't exist
  static Future<void> ensureRoleDocument(String userId, String role) async {
    try {
      String targetCollection;
      Map<String, dynamic> defaultData;

      switch (role) {
        case 'patient':
          targetCollection = 'patients';
          // Only create the 5 desired fields (empty for user to fill)
          defaultData = {
            'allergies': '',
            'antecedents': '',
            'dossiers_medicaux': '',
            'groupe_sanguin': '',
            'notifications_non_lues': '0',
          };
          break;
        
        case 'doctor':
        case 'docteur':
        case 'professional':
          targetCollection = 'providers'; // Use existing providers collection
          defaultData = {
            'id_user': userId,
            'idpro': 'doc_${userId.substring(0, 8)}', // Generate doctor ID
            'login': 'login_${userId.substring(0, 8)}',
            'profession': 'medecin',
            'specialite': 'generaliste', // Default specialty
            'service': 'consultation', // Default service
            'bio': 'Médecin spécialisé avec plusieurs années d\'expérience.',
            'rating': '0.0',
            'disponible': true,
            'createdAt': FieldValue.serverTimestamp(),
          };
          break;
        
        default:
          debugPrint('Unknown role: $role, skipping document creation');
          return;
      }

      // Check if document exists
      final doc = await _firestore.collection(targetCollection).doc(userId).get();
      
      if (!doc.exists) {
        debugPrint('Creating new document in $targetCollection collection');
        await _firestore.collection(targetCollection).doc(userId).set(defaultData);
        debugPrint('Created new role document for $role');
      }
    } catch (e) {
      debugPrint('Error ensuring role document: $e');
    }
  }

  /// Handle login redirect with role cleanup
  static Future<String> handleLoginRedirect() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '/login';

      // Get user role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        debugPrint('User document not found');
        return '/home';
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] as String? ?? 'patient';

      debugPrint('Handling login redirect for role: $role');

      // Clean up old documents and ensure correct document exists
      await _cleanupOldRoleDocuments(user.uid, role);
      await ensureRoleDocument(user.uid, role);

      // Return redirect route
      return await getRedirectRoute();
    } catch (e) {
      debugPrint('Error handling login redirect: $e');
      return '/home';
    }
  }

  /// Handle role transition when user's role changes (for real-time updates)
  static Future<void> handleRoleTransition(String userId, String? newRole) async {
    try {
      debugPrint('🔄 Handling role transition for $userId to $newRole');
      
      // Clean up old role documents and create new ones
      await _cleanupOldRoleDocuments(userId, newRole);
      await ensureRoleDocument(userId, newRole ?? 'patient');
      
      debugPrint('✅ Role transition completed');
    } catch (e) {
      debugPrint('❌ Error in role transition: $e');
    }
  }
}