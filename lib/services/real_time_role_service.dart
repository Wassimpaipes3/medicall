import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_redirect_service.dart';

/// Real-time role change monitoring service
/// Listens to user role changes and triggers navigation updates automatically
class RealTimeRoleService extends ChangeNotifier {
  static final RealTimeRoleService _instance = RealTimeRoleService._internal();
  factory RealTimeRoleService() => _instance;
  RealTimeRoleService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<DocumentSnapshot>? _roleSubscription;
  String? _currentRole;
  String? _currentUserId;
  
  // Global navigation key for app-wide navigation
  static GlobalKey<NavigatorState>? navigatorKey;
  
  /// Initialize real-time role monitoring for the current user
  Future<void> startRoleMonitoring() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('🔐 No user logged in, skipping role monitoring');
        return;
      }

      // Stop any existing monitoring
      await stopRoleMonitoring();

      _currentUserId = user.uid;
      debugPrint('🎯 Starting role monitoring for user: ${user.email}');

      // Listen to real-time changes in the user's document
      _roleSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
        _onRoleDocumentChanged,
        onError: (error) {
          debugPrint('❌ Error in role monitoring: $error');
        },
      );

      debugPrint('✅ Real-time role monitoring started');
    } catch (e) {
      debugPrint('❌ Error starting role monitoring: $e');
    }
  }

  /// Stop role monitoring
  Future<void> stopRoleMonitoring() async {
    await _roleSubscription?.cancel();
    _roleSubscription = null;
    _currentRole = null;
    _currentUserId = null;
    debugPrint('🛑 Role monitoring stopped');
  }

  /// Handle role document changes
  void _onRoleDocumentChanged(DocumentSnapshot snapshot) async {
    try {
      if (!snapshot.exists) {
        debugPrint('⚠️ User document does not exist');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      final newRole = data?['role'] as String?;

      debugPrint('🔄 Role change detected: $_currentRole → $newRole');

      // If role has changed, handle the transition
      if (newRole != _currentRole && _currentRole != null) {
        debugPrint('🚀 Processing role change from $_currentRole to $newRole');
        await _handleRoleChange(newRole);
      }

      _currentRole = newRole;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error handling role document change: $e');
    }
  }

  /// Handle role change by updating data and navigation
  Future<void> _handleRoleChange(String? newRole) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      debugPrint('📋 Handling role change to: $newRole');

      // Show role change notification
      _showRoleChangeNotification(_currentRole, newRole);

      // Clean up old role data and create new role documents
      await RoleRedirectService.handleRoleTransition(userId, newRole);

      // Navigate to new home screen based on role
      await _navigateToNewRoleScreen(newRole);

      debugPrint('✅ Role change completed successfully');
    } catch (e) {
      debugPrint('❌ Error handling role change: $e');
    }
  }

  /// Navigate to appropriate screen based on new role
  Future<void> _navigateToNewRoleScreen(String? role) async {
    if (navigatorKey?.currentState == null) {
      debugPrint('⚠️ Navigator key not available for navigation');
      return;
    }

    final newRoute = _getRoleRoute(role);
    debugPrint('🧭 Navigating to: $newRoute');

    // Navigate and clear stack to prevent back navigation to old role screens
    navigatorKey!.currentState!.pushNamedAndRemoveUntil(
      newRoute,
      (route) => false, // Clear all previous routes
    );
  }

  /// Get route based on role
  String _getRoleRoute(String? role) {
    switch (role) {
      case 'patient':
        return '/home'; // Use the existing patient home route
      case 'doctor':
      case 'docteur':
      case 'infirmier':
      case 'nurse':
      case 'professional':
      case 'provider':
        return '/provider-dashboard';
      case 'admin':
        return '/admin-dashboard';
      default:
        debugPrint('⚠️ Unknown role: $role, defaulting to patient');
        return '/home';
    }
  }

  /// Show notification about role change
  void _showRoleChangeNotification(String? oldRole, String? newRole) {
    if (navigatorKey?.currentState?.context == null) return;

    final context = navigatorKey!.currentState!.context;
    
    // Show snackbar notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Votre rôle a été mis à jour: ${_getRoleName(oldRole)} → ${_getRoleName(newRole)}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Get user-friendly role name
  String _getRoleName(String? role) {
    switch (role) {
      case 'patient':
        return 'Patient';
      case 'doctor':
      case 'docteur':
        return 'Docteur';
      case 'professional':
      case 'provider':
        return 'Professionnel';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Utilisateur';
    }
  }

  /// Get current role
  String? get currentRole => _currentRole;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Check if monitoring is active
  bool get isMonitoring => _roleSubscription != null;

  /// Manually trigger role refresh (useful for testing)
  Future<void> refreshRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _onRoleDocumentChanged(doc);
      }
    } catch (e) {
      debugPrint('❌ Error refreshing role: $e');
    }
  }

  /// Admin helper: Change user role (for testing purposes)
  static Future<bool> adminChangeUserRole({
    required String targetUserId,
    required String newRole,
    required String adminUserId,
    String? reason,
  }) async {
    try {
      debugPrint('👑 Admin role change: $targetUserId → $newRole');

      final firestore = FirebaseFirestore.instance;
      
      // Step 1: Get current user data and role
      final userDoc = await firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) {
        debugPrint('❌ User document not found');
        return false;
      }
      
      final userData = userDoc.data()!;
      final oldRole = userData['role'] as String?;
      
      debugPrint('📋 Current role: $oldRole → New role: $newRole');
      
      // Step 2: Remove from old role-specific collection
      if (oldRole != null && oldRole != newRole) {
        final oldCollection = _getRoleCollection(oldRole);
        if (oldCollection != null) {
          debugPrint('🗑️ Removing from $oldCollection collection...');
          await firestore.collection(oldCollection).doc(targetUserId).delete();
          debugPrint('✅ Removed from $oldCollection collection');
        }
      }
      
      // Step 3: Add to new role-specific collection
      final newCollection = _getRoleCollection(newRole);
      if (newCollection != null) {
        debugPrint('➕ Adding to $newCollection collection...');
        
        if (newCollection == 'patients') {
          // Create patient medical document with required fields
          await firestore.collection('patients').doc(targetUserId).set({
            'allergies': '',
            'antecedents': '',
            'dossiers_medicaux': '',
            'groupe_sanguin': '',
            'notifications_non_lues': '0',
          });
          debugPrint('✅ Created patient document with medical fields');
        } else if (newCollection == 'professionals') {
          // Create professional document with required fields
          await firestore.collection('professionals').doc(targetUserId).set({
            'profession': _mapRoleToProfession(newRole),
            'specialite': 'generaliste',
            'service': 'consultation',
            'disponible': true,
            'rating': 0.0,
            'reviewsCount': 0,
            'prix': 100,
            'bio': '',
            'login': userData['email']?.split('@')[0] ?? 'user_${targetUserId.substring(0, 8)}',
            'id_user': targetUserId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Created professional document');
        }
      }
      
      // Step 4: Update user role in users collection
      await firestore.collection('users').doc(targetUserId).update({
        'role': newRole,
        'role_changed_at': FieldValue.serverTimestamp(),
        'role_changed_by': adminUserId,
        'role_change_reason': reason ?? 'Admin role update',
      });
      debugPrint('✅ Updated role in users collection');

      // Step 5: Log the role change for audit trail
      await firestore.collection('role_change_log').add({
        'target_user_id': targetUserId,
        'old_role': oldRole,
        'new_role': newRole,
        'changed_by': adminUserId,
        'changed_at': FieldValue.serverTimestamp(),
        'reason': reason ?? 'Admin role update',
      });
      debugPrint('✅ Role change logged');

      debugPrint('✅ Admin role change completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error in admin role change: $e');
      return false;
    }
  }
  
  /// Helper: Get collection name for a role
  static String? _getRoleCollection(String role) {
    final lowerRole = role.toLowerCase();
    
    if (lowerRole == 'patient') {
      return 'patients';
    } else if (lowerRole == 'docteur' || 
               lowerRole == 'doctor' || 
               lowerRole == 'medecin' ||
               lowerRole == 'infirmier' ||
               lowerRole == 'nurse' ||
               lowerRole == 'provider') {
      return 'professionals';
    }
    
    return null; // Admin or other roles don't have specific collections
  }
  
  /// Helper: Map role to profession field value
  static String _mapRoleToProfession(String role) {
    final lowerRole = role.toLowerCase();
    
    if (lowerRole == 'docteur' || lowerRole == 'doctor') {
      return 'medecin';
    } else if (lowerRole == 'infirmier' || lowerRole == 'nurse') {
      return 'infirmier';
    }
    
    return 'medecin'; // Default to medecin
  }

  /// Initialize the service when app starts
  static Future<void> initialize({required GlobalKey<NavigatorState> navKey}) async {
    navigatorKey = navKey;
    debugPrint('🏗️ RealTimeRoleService initialized');
  }
}