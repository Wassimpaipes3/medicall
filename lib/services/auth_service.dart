import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import 'role_redirect_service.dart';
import 'real_time_role_service.dart';

class AuthService {
  FirebaseAuth? _auth;

  // Ensure Firebase is initialized
  Future<FirebaseAuth> _getAuth() async {
    if (_auth != null) return _auth!;
    
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        print('🔄 Firebase not initialized, initializing now...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');
      }
      
      _auth = FirebaseAuth.instance;
      print('🔑 Firebase Auth ready');
      return _auth!;
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  Future<User?> get currentUser async {
    try {
      final auth = await _getAuth();
      return auth.currentUser;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Check if Firebase Auth is working
  Future<void> testFirebaseAuth() async {
    try {
      print('🔍 Testing Firebase Auth...');
      final auth = await _getAuth();
      final user = auth.currentUser;
      print('📱 Current user: ${user?.email ?? "No user"}');
      print('🔧 Firebase app name: ${auth.app.name}');
      print('🆔 Firebase app ID: ${auth.app.options.appId}');
    } catch (e) {
      print('❌ Test failed: $e');
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      print('🔄 Starting signup process...');
      final auth = await _getAuth();
      print('🔑 Firebase Auth ready, creating user...');
      
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ User created successfully: ${result.user?.email}');
      return result.user;
    } catch (e) {
      print('❌ Sign up error: $e');
      return null;
    }
  }

  /// Complete Patient Signup with Firestore Profile Creation
  /// This method creates both Firebase Auth account AND Firestore user document
  Future<Map<String, dynamic>> signUpPatient({
    required String email,
    required String password,
    required String nom,        // Changed from 'name' to 'nom'
    required String prenom,
    required String tel,        // Changed from 'telephone' to 'tel'
    String? adresse,
    String? dateNaissance,
    String genre = 'Homme',
    String? photoProfilePath,
  }) async {
    try {
      print('🔄 Starting patient signup process...');
      
      // Step 1: Initialize Firebase
      final auth = await _getAuth();
      final firestore = FirebaseFirestore.instance;
      print('🔑 Firebase Auth and Firestore ready');

      // Step 2: Create Firebase Auth user
      print('👤 Creating user authentication...');
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed - no user returned');
      }

      print('✅ Firebase Auth user created: ${user.email}');

      // Step 3: Update user display name
      await user.updateDisplayName('$prenom $nom');
      print('📝 Display name updated: $prenom $nom');

      // Step 4: Create patient medical document FIRST (to avoid Cloud Function interference)
      print('🏥 Creating patient medical document FIRST...');
      
      // Define EXACTLY the 5 fields you want (empty for user to fill)
      Map<String, dynamic> patientData = {
        'allergies': '',
        'antecedents': '',
        'dossiers_medicaux': '',
        'groupe_sanguin': '',
        'notifications_non_lues': '0',
      };

      print('📋 Patient data to be saved EXACTLY (5 fields): $patientData');
      print('🎯 Creating patient document at: patients/${user.uid}');
      
      // Create patient document with merge: false to ensure ONLY these 6 fields exist
      await firestore.collection('patients').doc(user.uid).set(
        patientData, 
        SetOptions(merge: false)
      );
      print('✅ Patient medical document created successfully with ONLY 5 fields');

      // Step 5: Create Firestore user document with EXACT fields you specified
      print('📄 Creating user profile document...');
      Map<String, dynamic> userData = {
        'email': email,
        'nom': nom,                    // Your specified field name
        'prenom': prenom,
        'tel': tel,                    // Your specified field name
        'role': 'patient',
        // Optional fields (only if provided)
        if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
        if (dateNaissance != null && dateNaissance.isNotEmpty) 'date_naissance': dateNaissance,  // Your specified field name
        if (genre.isNotEmpty) 'genre': genre,
        if (photoProfilePath != null && photoProfilePath.isNotEmpty) 'photo_profile': photoProfilePath,  // Your specified field name
        // Note: mots_de_pass handled by Firebase Auth, not stored in Firestore
      };

      print('📋 User data to be saved: $userData');
      await firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: false));
      print('✅ User profile document created successfully');

      // Step 6: Verify patient document was created correctly
      print('🔍 Verifying patient document...');
      await Future.delayed(Duration(milliseconds: 300));
      
      try {
        final docSnapshot = await firestore.collection('patients').doc(user.uid).get();
        if (docSnapshot.exists) {
          Map<String, dynamic>? data = docSnapshot.data();
          print('📊 Patient document contains fields: ${data?.keys.toList()}');
          print('📄 Patient document data: $data');
          
          // Check for unwanted fields
          List<String> expectedFields = ['allergies', 'antecedents', 'dossiers_medicaux', 'groupe_sanguin', 'notifications_non_lues'];
          List<String> actualFields = data?.keys.toList() ?? [];
          List<String> unexpectedFields = actualFields.where((field) => !expectedFields.contains(field)).toList();
          
          if (unexpectedFields.isNotEmpty) {
            print('⚠️ WARNING: Unexpected fields found: $unexpectedFields');
          } else {
            print('✅ Perfect! Patient document contains ONLY the expected 5 fields');
          }
        } else {
          print('❌ ERROR: Patient document does not exist after creation');
        }
      } catch (e) {
        print('⚠️ Could not verify patient document: $e');
      }

      return {
        'success': true,
        'user': user,
        'userData': userData,
        'patientData': patientData,
        'message': 'Compte créé avec succès! Bienvenue $prenom $nom',
      };

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Cette adresse email est déjà utilisée. Essayez de vous connecter ou utilisez une autre email.';
          break;
        case 'invalid-email':
          errorMessage = 'Format d\'email invalide. Vérifiez votre saisie.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Inscription par email désactivée. Contactez le support.';
          break;
        case 'network-request-failed':
          errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
          break;
        default:
          errorMessage = 'Erreur lors de la création du compte: ${e.message}';
      }
      
      return {
        'success': false,
        'error': e.code,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Unexpected error during signup: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Une erreur inattendue s\'est produite. Veuillez réessayer.',
      };
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      print('🔄 Starting signin process...');
      final auth = await _getAuth();
      print('🔑 Firebase Auth ready, signing in...');
      
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ User signed in successfully: ${result.user?.email}');
      
      // Get redirect route based on role and clean up old documents
      final redirectRoute = await RoleRedirectService.handleLoginRedirect();
      
      // Start real-time role monitoring
      await RealTimeRoleService().startRoleMonitoring();
      print('🎯 Real-time role monitoring started');
      
      return {
        'success': true,
        'user': result.user,
        'redirectRoute': redirectRoute,
      };
    } catch (e) {
      print('❌ Sign in error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'redirectRoute': '/login',
      };
    }
  }

  Future<void> signOut() async {
    try {
      // Stop real-time role monitoring before signing out
      await RealTimeRoleService().stopRoleMonitoring();
      print('🛑 Role monitoring stopped');
      
      final auth = await _getAuth();
      await auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }

  /// Delete current user's account and all related data
  /// This function handles the complete deletion process:
  /// 1. Deletes all Firestore documents
  /// 2. Deletes Firebase Auth account
  Future<Map<String, dynamic>> deleteUserAccount({String? password}) async {
    try {
      print('🗑️ Starting user account deletion process...');
      
      final auth = await _getAuth();
      final user = auth.currentUser;
      
      if (user == null) {
        return {
          'success': false,
          'error': 'no-user',
          'message': 'Aucun utilisateur connecté trouvé.',
        };
      }

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      
      print('🔍 Deleting data for user: $uid (${user.email})');

      // Step 1: Re-authenticate if password provided (required for sensitive operations)
      if (password != null && password.isNotEmpty && user.email != null) {
        try {
          print('🔐 Re-authenticating user for sensitive operation...');
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);
          print('✅ User re-authenticated successfully');
        } catch (e) {
          print('❌ Re-authentication failed: $e');
          return {
            'success': false,
            'error': 'wrong-password',
            'message': 'Mot de passe incorrect. Veuillez réessayer.',
          };
        }
      }

      // Step 2: Delete all Firestore documents related to this user
      print('📄 Starting Firestore cleanup...');
      
      try {
        // Delete main user document
        print('🗑️ Deleting user document: users/$uid');
        await firestore.collection('users').doc(uid).delete();
        
        // Delete patient document if exists
        print('🗑️ Deleting patient document: patients/$uid');
        await firestore.collection('patients').doc(uid).delete();
        
        // Delete professional document if exists
        print('🗑️ Deleting professional document: professionals/$uid');
        await firestore.collection('professionals').doc(uid).delete();
        
        // Delete related appointments (where user is patient or professional)
        print('🗑️ Deleting related appointments...');
        final appointmentsQuery1 = await firestore
            .collection('appointments')
            .where('patientId', isEqualTo: uid)
            .get();
        final appointmentsQuery2 = await firestore
            .collection('appointments')
            .where('professionalId', isEqualTo: uid)
            .get();
        
        for (var doc in appointmentsQuery1.docs) {
          await doc.reference.delete();
          print('🗑️ Deleted appointment: ${doc.id}');
        }
        for (var doc in appointmentsQuery2.docs) {
          await doc.reference.delete();
          print('🗑️ Deleted appointment: ${doc.id}');
        }
        
        // Delete related reviews (avis)
        print('🗑️ Deleting related reviews...');
        final avisQuery = await firestore
            .collection('avis')
            .where('userId', isEqualTo: uid)
            .get();
        
        for (var doc in avisQuery.docs) {
          await doc.reference.delete();
          print('🗑️ Deleted review: ${doc.id}');
        }
        
        // Delete availability slots (if professional)
        print('🗑️ Deleting availability slots...');
        final disponibilitesQuery = await firestore
            .collection('disponibilites')
            .where('professionalId', isEqualTo: uid)
            .get();
        
        for (var doc in disponibilitesQuery.docs) {
          await doc.reference.delete();
          print('🗑️ Deleted availability: ${doc.id}');
        }
        
        // Delete notifications
        print('🗑️ Deleting notifications...');
        final notificationsQuery = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .get();
        
        for (var doc in notificationsQuery.docs) {
          await doc.reference.delete();
          print('🗑️ Deleted notification: ${doc.id}');
        }
        
        print('✅ All Firestore documents deleted successfully');
        
      } catch (firestoreError) {
        print('⚠️ Warning: Firestore cleanup had issues: $firestoreError');
        // Continue with auth deletion even if Firestore cleanup partially fails
      }

      // Step 3: Delete Firebase Authentication account
      print('🔑 Deleting Firebase Auth account...');
      await user.delete();
      print('✅ Firebase Auth account deleted successfully');

      print('🎉 User account deletion completed successfully!');
      return {
        'success': true,
        'message': 'Votre compte a été supprimé avec succès.',
      };

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error during deletion: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Pour des raisons de sécurité, veuillez vous reconnecter avant de supprimer votre compte.';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect.';
          break;
        case 'user-not-found':
          errorMessage = 'Utilisateur introuvable.';
          break;
        case 'network-request-failed':
          errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
          break;
        default:
          errorMessage = 'Erreur lors de la suppression: ${e.message}';
      }
      
      return {
        'success': false,
        'error': e.code,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Unexpected error during account deletion: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Une erreur inattendue s\'est produite lors de la suppression.',
      };
    }
  }

  // Password Reset Function
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      print('🔄 Attempting to send password reset email to: $email');
      
      // Validate email format first
      if (email.trim().isEmpty) {
        return {
          'success': false,
          'error': 'empty-email',
          'message': 'Veuillez saisir votre adresse email.',
        };
      }

      // Basic email validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        return {
          'success': false,
          'error': 'invalid-email',
          'message': 'Veuillez saisir une adresse email valide.',
        };
      }

      final auth = await _getAuth();
      
      // Send password reset email
      await auth.sendPasswordResetEmail(email: email.trim());
      
      print('✅ Password reset email sent successfully to: $email');
      return {
        'success': true,
        'message': 'Un lien de réinitialisation du mot de passe a été envoyé à votre adresse email.',
      };

    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth error during password reset: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun compte n\'est associé à cette adresse email.';
          break;
        case 'invalid-email':
          errorMessage = 'Adresse email invalide.';
          break;
        case 'too-many-requests':
          errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
          break;
        case 'network-request-failed':
          errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet.';
          break;
        default:
          errorMessage = 'Erreur lors de l\'envoi de l\'email: ${e.message}';
      }
      
      return {
        'success': false,
        'error': e.code,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Unexpected error during password reset: $e');
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Une erreur inattendue s\'est produite. Veuillez réessayer.',
      };
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole() async {
    try {
      final user = await currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return null;
      }

      print('🔍 Getting role for user: ${user.email}');
      final firestore = FirebaseFirestore.instance;
      
      // Get user document from Firestore
      final doc = await firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data();
        final role = data?['role'] as String?;
        print('✅ User role found: $role');
        return role;
      } else {
        print('❌ User document not found in Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Error getting user role: $e');
      return null;
    }
  }

  // Get appropriate home route based on user role
  Future<String> getHomeRoute() async {
    final role = await getUserRole();
    
    switch (role) {
      case 'patient':
        return '/patient-navigation';
      case 'provider':
      case 'doctor':
        return '/provider-dashboard';
      default:
        // Default to patient navigation if role is not found or unknown
        print('⚠️ Unknown or null role: $role, defaulting to patient navigation');
        return '/patient-navigation';
    }
  }

  // Set user role in Firestore (useful for testing or admin purposes)
  Future<bool> setUserRole(String role) async {
    try {
      final user = await currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return false;
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(user.uid).update({
        'role': role,
      });
      
      print('✅ User role updated to: $role');
      return true;
    } catch (e) {
      print('❌ Error setting user role: $e');
      return false;
    }
  }

  // Update user password
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = await currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Update to new password
      await user.updatePassword(newPassword);
      
      return {
        'success': true,
        'message': 'Password updated successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log out and log in again before changing password';
          break;
        default:
          message = 'Error updating password: ${e.message}';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
      };
    }
  }
}