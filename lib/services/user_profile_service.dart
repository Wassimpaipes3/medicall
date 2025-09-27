import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches complete user profile data by merging users/{uid} and patients/{uid} documents
  /// Returns a single map containing all user information
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return null;
      }

      final uid = user.uid;
      print('🔍 Fetching profile for user: $uid');

      // Fetch both documents in parallel
      final futures = await Future.wait([
        _firestore.collection('users').doc(uid).get(),
        _firestore.collection('patients').doc(uid).get(),
      ]);

      final userDoc = futures[0] as DocumentSnapshot;
      final patientDoc = futures[1] as DocumentSnapshot;

      // Check if user document exists
      if (!userDoc.exists) {
        print('❌ User document not found for: $uid');
        return null;
      }

      // Get user data
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) {
        print('❌ User data is null for: $uid');
        return null;
      }

      // Get patient data (may not exist for non-patients)
      Map<String, dynamic> patientData = {};
      if (patientDoc.exists) {
        patientData = patientDoc.data() as Map<String, dynamic>? ?? {};
      }

      // Merge the data - user data takes precedence for overlapping fields
      final mergedData = <String, dynamic>{
        'uid': uid,
        ...patientData, // Medical info first
        ...userData,    // Basic info second (overwrites any conflicts)
      };

      // Add computed fields
      mergedData['fullName'] = _buildFullName(userData);
      mergedData['hasMedicalInfo'] = patientDoc.exists;

      print('✅ Profile fetched successfully for: $uid');
      print('📊 Fields: ${mergedData.keys.toList()}');

      return mergedData;

    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Helper method to build full name from separate nom and prenom fields
  static String _buildFullName(Map<String, dynamic> userData) {
    final nom = userData['nom'] ?? '';
    final prenom = userData['prenom'] ?? '';
    
    if (nom.isEmpty && prenom.isEmpty) {
      return userData['email'] ?? 'Utilisateur';
    }
    
    return '$prenom $nom'.trim();
  }

  /// Update user basic information
  static Future<bool> updateUserInfo(Map<String, dynamic> updates) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update(updates);
      print('✅ User info updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating user info: $e');
      return false;
    }
  }

  /// Update patient medical information
  static Future<bool> updateMedicalInfo(Map<String, dynamic> updates) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _firestore.collection('patients').doc(user.uid).update(updates);
      print('✅ Medical info updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating medical info: $e');
      return false;
    }
  }

  /// Update medical history specifically (allergies, antecedents, medical records)
  static Future<Map<String, dynamic>> updateMedicalHistory({
    String? allergies,
    String? antecedents,
    String? dossiersMedicaux,
    String? groupeSanguin,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'no-user',
          'message': 'Aucun utilisateur connecté trouvé.',
        };
      }

      // Prepare updates map with only provided values
      Map<String, dynamic> updates = {};
      
      if (allergies != null) {
        final trimmedAllergies = allergies.toString().trim();
        updates['allergies'] = trimmedAllergies.isEmpty ? 'Aucune' : trimmedAllergies;
      }
      
      if (antecedents != null) {
        final trimmedAntecedents = antecedents.toString().trim();
        updates['antecedents'] = trimmedAntecedents.isEmpty ? 'Aucun' : trimmedAntecedents;
      }
      
      if (dossiersMedicaux != null) {
        final trimmedDossiers = dossiersMedicaux.toString().trim();
        updates['dossiers_medicaux'] = trimmedDossiers;
      }
      
      if (groupeSanguin != null) {
        final trimmedGroupe = groupeSanguin.toString().trim();
        updates['groupe_sanguin'] = trimmedGroupe.isEmpty ? 'Non renseigné' : trimmedGroupe;
      }

      if (updates.isEmpty) {
        return {
          'success': false,
          'error': 'no-updates',
          'message': 'Aucune mise à jour fournie.',
        };
      }

      // Update the patient document
      await _firestore.collection('patients').doc(user.uid).update(updates);
      
      print('✅ Medical history updated successfully: ${updates.keys.toList()}');
      
      return {
        'success': true,
        'message': 'Historique médical mis à jour avec succès!',
        'updatedFields': updates.keys.toList(),
      };

    } catch (e) {
      print('❌ Error updating medical history: $e');
      return {
        'success': false,
        'error': 'update-failed',
        'message': 'Erreur lors de la mise à jour de l\'historique médical: ${e.toString()}',
      };
    }
  }
}

