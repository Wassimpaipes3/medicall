import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/theme.dart';
import '../../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  String _userEmail = 'user@email.com';
  String? _userPhotoPath;
  String _userPhone = '';
  String _userAddress = '';
  String _userGenre = '';
  String _userBloodType = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserProfileService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          _userName = userData['fullName'] ?? 'User';
          _userEmail = userData['email'] ?? 'user@email.com';
          _userPhotoPath = userData['photo_profile'];
          _userPhone = userData['tel'] ?? '';
          _userAddress = userData['adresse'] ?? '';
          _userGenre = userData['genre'] ?? '';
          _userBloodType = userData['groupe_sanguin'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Photo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _userPhotoPath != null && File(_userPhotoPath!).existsSync()
                          ? Image.file(
                              File(_userPhotoPath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // User Email
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_userPhone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _userPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Additional User Info
            if (_userAddress.isNotEmpty || _userGenre.isNotEmpty || _userBloodType.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_userGenre.isNotEmpty) ...[
                      _buildInfoRow('Genre', _userGenre),
                      const SizedBox(height: 12),
                    ],
                    if (_userBloodType.isNotEmpty) ...[
                      _buildInfoRow('Groupe sanguin', _userBloodType),
                      const SizedBox(height: 12),
                    ],
                    if (_userAddress.isNotEmpty) ...[
                      _buildInfoRow('Adresse', _userAddress),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // Show logout dialog
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
