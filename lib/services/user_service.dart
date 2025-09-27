import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user data after signup
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = jsonEncode(userData);
      await prefs.setString(_userKey, userDataJson);
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString(_userKey);
      if (userDataJson != null) {
        return jsonDecode(userDataJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Update user data
  static Future<bool> updateUserData(Map<String, dynamic> userData) async {
    return await saveUserData(userData);
  }

  // Logout user
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user full name (combining nom and prenom)
  static Future<String> getUserFullName() async {
    final userData = await getUserData();
    if (userData != null) {
      final nom = userData['nom'] ?? '';
      final prenom = userData['prenom'] ?? '';
      return '$prenom $nom'.trim();
    }
    return 'User';
  }

  // Get user profile photo path
  static Future<String?> getUserPhotoPath() async {
    final userData = await getUserData();
    return userData?['photo_profile'];
  }
}