import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload profile picture to Firebase Storage and update user document
  static Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Create a unique filename
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final storageRef = _storage.ref().child('profile_pictures/$fileName');

      // Upload the file
      print('📤 Uploading profile picture to Firebase Storage...');
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Profile picture uploaded successfully: $downloadUrl');

      // Update user document with new profile picture URL
      await _updateUserProfilePicture(downloadUrl);
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      rethrow;
    }
  }



  /// Update user document with new profile picture URL
  static Future<void> _updateUserProfilePicture(String imageUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update the user document in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photo_profile': imageUrl,
        'profile_picture_updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ User document updated with new profile picture URL');
    } catch (e) {
      print('❌ Error updating user document: $e');
      rethrow;
    }
  }

  /// Delete profile picture from Firebase Storage
  static Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      // Extract the file path from the download URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      print('✅ Profile picture deleted from Firebase Storage');

      // Update user document to remove profile picture
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'photo_profile': FieldValue.delete(),
          'profile_picture_updated_at': FieldValue.serverTimestamp(),
        });
        print('✅ User document updated to remove profile picture');
      }
    } catch (e) {
      print('❌ Error deleting profile picture: $e');
      rethrow;
    }
  }

  /// Get current user's profile picture URL from Firestore
  static Future<String?> getCurrentUserProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['photo_profile'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting profile picture URL: $e');
      return null;
    }
  }

  /// Stream of user profile data including profile picture
  static Stream<Map<String, dynamic>?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return {
          'uid': user.uid,
          ...data,
        };
      }
      return null;
    });
  }

  /// Upload any file to Firebase Storage with custom path
  static Future<String?> uploadFile(
    File file,
    String storagePath, {
    Map<String, String>? customMetadata,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final storageRef = _storage.ref().child('$storagePath/$fileName');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(file.path),
          customMetadata: customMetadata,
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
