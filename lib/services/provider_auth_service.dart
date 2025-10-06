import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider-specific authentication and profile management service
class ProviderAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Provider profile data model
  static const String COLLECTION_NAME = 'professionals';

  /// Get current provider profile
  static Future<ProviderProfile?> getCurrentProviderProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      // Check if user has provider role
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('❌ User document not found');
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] as String?;
      
      if (role != 'doctor' && 
          role != 'docteur' && 
          role != 'infirmier' && 
          role != 'nurse' && 
          role != 'professional') {
        print('❌ User is not a provider. Role: $role');
        return null;
      }

      // Get provider document
      final providerDoc = await _firestore.collection(COLLECTION_NAME).doc(user.uid).get();
      
      if (!providerDoc.exists) {
        print('⚠️ Provider document not found, creating default...');
        await _createDefaultProviderProfile(user.uid, userData);
        return await getCurrentProviderProfile(); // Retry after creation
      }

      final providerData = providerDoc.data() as Map<String, dynamic>;
      
      return ProviderProfile.fromFirestore(
        uid: user.uid,
        userdata: userData,
        providerData: providerData,
      );
      
    } catch (e) {
      print('❌ Error getting provider profile: $e');
      return null;
    }
  }

  /// Create default provider profile
  static Future<void> _createDefaultProviderProfile(String uid, Map<String, dynamic> userData) async {
    try {
      print('🏗️ Creating default provider profile for: $uid');
      
      final defaultProfile = {
        'bio': 'Médecin spécialisé avec plusieurs années d\'expérience.',
        'disponible': true,
        'id_user': uid,
        'idpro': 'doc_${uid.substring(0, 8)}',
        'login': 'login_${uid.substring(0, 8)}',
        'profession': 'medecin',
        'rating': '0.0',
        'service': 'consultation',
        'specialite': 'generaliste',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(COLLECTION_NAME).doc(uid).set(defaultProfile);
      print('✅ Default provider profile created');
      
    } catch (e) {
      print('❌ Error creating default provider profile: $e');
      rethrow;
    }
  }

  /// Update provider profile
  static Future<bool> updateProviderProfile({
    required String uid,
    String? bio,
    String? specialite,
    String? service,
    String? profession,
    bool? disponible,
    String? photoUrl,
  }) async {
    try {
      print('🔄 Updating provider profile for: $uid');
      
      Map<String, dynamic> updates = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (bio != null) updates['bio'] = bio;
      if (specialite != null) updates['specialite'] = specialite;
      if (service != null) updates['service'] = service;
      if (profession != null) updates['profession'] = profession;
      if (disponible != null) updates['disponible'] = disponible;
      if (photoUrl != null) updates['photo_url'] = photoUrl;

      await _firestore.collection(COLLECTION_NAME).doc(uid).update(updates);
      print('✅ Provider profile updated successfully');
      
      return true;
    } catch (e) {
      print('❌ Error updating provider profile: $e');
      return false;
    }
  }

  /// Update provider personal info (in users collection)
  static Future<bool> updateProviderPersonalInfo({
    required String uid,
    String? nom,
    String? prenom,
    String? tel,
    String? adresse,
    String? photoProfile,
  }) async {
    try {
      print('🔄 Updating provider personal info for: $uid');
      
      Map<String, dynamic> updates = {};

      if (nom != null) updates['nom'] = nom;
      if (prenom != null) updates['prenom'] = prenom;
      if (tel != null) updates['tel'] = tel;
      if (adresse != null) updates['adresse'] = adresse;
      if (photoProfile != null) updates['photo_profile'] = photoProfile;

      await _firestore.collection('users').doc(uid).update(updates);
      print('✅ Provider personal info updated successfully');
      
      return true;
    } catch (e) {
      print('❌ Error updating provider personal info: $e');
      return false;
    }
  }

  /// Get provider profile stream for real-time updates
  static Stream<ProviderProfile?> getProviderProfileStream(String uid) {
    return _firestore.collection(COLLECTION_NAME).doc(uid).snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;
      
      // Also get user data
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      
      return ProviderProfile.fromFirestore(
        uid: uid,
        userdata: userDoc.data() as Map<String, dynamic>,
        providerData: doc.data() as Map<String, dynamic>,
      );
    });
  }

  /// Check if current user is a provider
  static Future<bool> isCurrentUserProvider() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'] as String?;
      
      return role == 'doctor' || 
             role == 'docteur' || 
             role == 'infirmier' ||
             role == 'nurse' ||
             role == 'professional';
    } catch (e) {
      print('❌ Error checking provider status: $e');
      return false;
    }
  }

  /// Provider login with role validation
  static Future<Map<String, dynamic>> providerLogin(String email, String password) async {
    try {
      print('🔐 Provider login attempt: $email');
      
      // Authenticate user
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return {
          'success': false,
          'message': 'Échec de l\'authentification',
        };
      }

      final uid = credential.user!.uid;
      
      // Check if user is a provider
      final isProvider = await isCurrentUserProvider();
      if (!isProvider) {
        // Sign out non-provider users
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Accès refusé. Ce compte n\'est pas un compte professionnel.',
        };
      }

      // Get or create provider profile
      final profile = await getCurrentProviderProfile();
      if (profile == null) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Erreur lors du chargement du profil professionnel.',
        };
      }

      print('✅ Provider login successful: ${profile.fullName}');
      return {
        'success': true,
        'profile': profile,
        'message': 'Connexion réussie',
      };
      
    } catch (e) {
      print('❌ Provider login error: $e');
      
      String message = 'Erreur de connexion';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            message = 'Aucun compte trouvé avec cet email';
            break;
          case 'wrong-password':
            message = 'Mot de passe incorrect';
            break;
          case 'invalid-email':
            message = 'Format d\'email invalide';
            break;
          case 'user-disabled':
            message = 'Ce compte a été désactivé';
            break;
          default:
            message = 'Erreur d\'authentification: ${e.message}';
        }
      }
      
      return {
        'success': false,
        'message': message,
      };
    }
  }
}

/// Provider profile data model
class ProviderProfile {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String? tel;
  final String? adresse;
  final String? photoProfile;
  final String bio;
  final bool disponible;
  final String idpro;
  final String login;
  final String profession;
  final String rating;
  final String service;
  final String specialite;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProviderProfile({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    this.tel,
    this.adresse,
    this.photoProfile,
    required this.bio,
    required this.disponible,
    required this.idpro,
    required this.login,
    required this.profession,
    required this.rating,
    required this.service,
    required this.specialite,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$prenom $nom'.trim();
  
  String get displaySpeciality => specialite.isNotEmpty ? specialite : 'Généraliste';
  
  String get displayRating => double.tryParse(rating)?.toStringAsFixed(1) ?? '0.0';

  factory ProviderProfile.fromFirestore({
    required String uid,
    required Map<String, dynamic> userdata,
    required Map<String, dynamic> providerData,
  }) {
    return ProviderProfile(
      uid: uid,
      email: userdata['email'] ?? '',
      nom: userdata['nom'] ?? '',
      prenom: userdata['prenom'] ?? '',
      tel: userdata['tel'],
      adresse: userdata['adresse'],
      photoProfile: userdata['photo_profile'],
      bio: providerData['bio'] ?? '',
      disponible: providerData['disponible'] ?? false,
      idpro: providerData['idpro'] ?? '',
      login: providerData['login'] ?? '',
      profession: providerData['profession'] ?? '',
      rating: providerData['rating']?.toString() ?? '0.0',
      service: providerData['service'] ?? '',
      specialite: providerData['specialite'] ?? '',
      photoUrl: providerData['photo_url'],
      createdAt: providerData['created_at']?.toDate(),
      updatedAt: providerData['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'tel': tel,
      'adresse': adresse,
      'photo_profile': photoProfile,
      'bio': bio,
      'disponible': disponible,
      'idpro': idpro,
      'login': login,
      'profession': profession,
      'rating': rating,
      'service': service,
      'specialite': specialite,
      'photo_url': photoUrl,
    };
  }
}