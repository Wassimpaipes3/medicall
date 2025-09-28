import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';
import '../../services/provider/provider_service.dart';
import '../../services/provider_auth_service.dart' as ProviderAuth;
import '../../widgets/provider/provider_navigation_bar.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  ProviderProfile? _profile; // Legacy profile data
  ProviderAuth.ProviderProfile? _currentProviderProfile; // Professional collection data
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isOnline = false;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();

  final List<String> _specializations = [
    'General Practice',
    'Emergency Medicine',
    'Pediatrics',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Psychiatry',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProfile();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _loadProfile() async {
    try {
      print('🚀 Loading profile data (prioritizing professionals collection)...');
      
      // Try to load from professionals collection first
      final providerProfile = await ProviderAuth.ProviderAuthService.getCurrentProviderProfile();
      
      if (providerProfile != null) {
        print('✅ Using professionals collection data: ${providerProfile.login}');
        setState(() {
          _currentProviderProfile = providerProfile;
          _isOnline = providerProfile.disponible;
          _isLoading = false;
        });
        _populateControllersFromProfessionals();
      } else {
        print('⚠️ No professionals data found, trying legacy provider service...');
        // Fallback to legacy service
        await _providerService.initialize();
        final profile = await _providerService.getProfile();
        final status = await _providerService.getAvailabilityStatus();
        
        print('✅ Using legacy provider data');
        setState(() {
          _profile = profile;
          _isOnline = status == ProviderAvailabilityStatus.online;
          _isLoading = false;
        });
        _populateControllers();
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load profile: $e');
      }
    }
  }

  void _populateControllers() {
    if (_profile != null) {
      _nameController.text = _profile!.name;
      _phoneController.text = _profile!.phone;
      _emailController.text = _profile!.email;
      _addressController.text = _profile!.address;
      _bioController.text = _profile!.bio;
      _experienceController.text = _profile!.experience.toString();
      _feeController.text = '100'; // Default fee since ProviderProfile doesn't have fee field
    }
  }
  
  void _populateControllersFromProfessionals() {
    if (_currentProviderProfile != null) {
      _nameController.text = _getProviderFullName();
      _phoneController.text = _currentProviderProfile!.tel ?? '';
      _emailController.text = _currentProviderProfile!.email;
      _addressController.text = _currentProviderProfile!.adresse ?? '';
      _bioController.text = _currentProviderProfile!.bio;
      _experienceController.text = _currentProviderProfile!.profession.toLowerCase().contains('spécialiste') ? '10' : '5';
      
      // Convert rating to fee (rating * 20 = fee in DZD)
      double rating = double.tryParse(_currentProviderProfile!.rating) ?? 4.0;
      _feeController.text = (rating * 20).toString();
      
      print('📝 Form populated with professionals collection data');
      print('🖼️ Photo URLs - photoUrl: ${_currentProviderProfile!.photoUrl}, photoProfile: ${_currentProviderProfile!.photoProfile}');
    }
  }
  
  Future<void> _createDefaultProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _nameController.text = currentUser.displayName ?? currentUser.email ?? 'Provider Name';
          _emailController.text = currentUser.email ?? '';
          _phoneController.text = 'Please add your phone number';
          _addressController.text = 'Please add your address';
          _bioController.text = 'Please update your professional bio';
          _experienceController.text = '5';
          _feeController.text = '100';
          _isLoading = false;
        });
        print('✅ Default profile created for: ${currentUser.displayName ?? currentUser.email}');
      }
    } catch (e) {
      print('❌ Error creating default profile: $e');
      setState(() => _isLoading = false);
    }
  }

  // Photo Upload Methods
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfilePhoto(File imageFile) async {
    try {
      setState(() => _isUploadingPhoto = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ Error uploading photo: $e');
      _showErrorSnackBar('Failed to upload photo: $e');
      return null;
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  // Save Profile Methods
  Future<void> _saveProfile() async {
    if (!_validateForm()) return;
    
    try {
      setState(() => _isSaving = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      String? photoUrl;
      
      // Upload photo if selected
      if (_selectedImage != null) {
        photoUrl = await _uploadProfilePhoto(_selectedImage!);
        if (photoUrl == null) return; // Upload failed
      }

      // Update personal info (users collection)
      final nameParts = _nameController.text.trim().split(' ');
      final prenom = nameParts.isNotEmpty ? nameParts[0] : '';
      final nom = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      final personalInfoUpdated = await ProviderAuth.ProviderAuthService.updateProviderPersonalInfo(
        uid: user.uid,
        nom: nom,
        prenom: prenom,
        tel: _phoneController.text.trim(),
        adresse: _addressController.text.trim(),
        photoProfile: photoUrl,
      );

      // Update professional info (professionals collection)  
      final professionalInfoUpdated = await ProviderAuth.ProviderAuthService.updateProviderProfile(
        uid: user.uid,
        bio: _bioController.text.trim(),
        disponible: _isOnline,
        photoUrl: photoUrl,
      );

      if (personalInfoUpdated && professionalInfoUpdated) {
        // Reload profile data
        await _loadProfile();
        
        setState(() {
          _isEditing = false;
          _selectedImage = null;
        });
        
        _showSuccessSnackBar('Profile updated successfully!');
        print('✅ Profile saved successfully');
      } else {
        _showErrorSnackBar('Failed to update profile');
      }
      
    } catch (e) {
      print('❌ Error saving profile: $e');
      _showErrorSnackBar('Failed to save profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Name is required');
      return false;
    }
    
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email is required');
      return false;
    }
    
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return false;
    }
    
    return true;
  }

  // Delete Profile Methods
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    try {
      setState(() => _isSaving = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      
      // Delete professional document
      await FirebaseFirestore.instance.collection('professionals').doc(user.uid).delete();
      
      // Delete user account
      await user.delete();
      
      _showSuccessSnackBar('Account deleted successfully');
      
      // Navigate to login
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      
    } catch (e) {
      print('❌ Error deleting account: $e');
      _showErrorSnackBar('Failed to delete account: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedImage = null;
    });
    
    // Restore original values
    if (_currentProviderProfile != null) {
      _populateControllersFromProfessionals();
    } else if (_profile != null) {
      _populateControllers();
    }
    
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(106),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          toolbarHeight: 106,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.9),
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your professional details',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          leading: Container(
            margin: const EdgeInsets.only(left: 16),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: _buildEditButton(),
            ),
          ],
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: 3,
        onTap: (index) => _handleNavigation(index),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildEditButton(),
            ],
          ),
          if (_profile != null) ...[
            const SizedBox(height: 24),
            _buildProfileHeader(),
          ],
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    if (_isEditing) {
      return Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(8),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _isSaving ? null : _cancelEditing,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () {
          setState(() => _isEditing = true);
          HapticFeedback.lightImpact();
        },
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white70],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  (_currentProviderProfile?.login ?? _profile?.name ?? 'P').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _isOnline ? Icons.check : Icons.pause,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getProviderFullName(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentProviderProfile?.profession ?? _profile?.specialization ?? 'Medical Professional',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusToggle(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return GestureDetector(
      onTap: _toggleOnlineStatus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.green : Colors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOnline ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading Profile...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fetching your professional details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Check if we have any profile data (professionals or legacy)
    if (_currentProviderProfile == null && _profile == null) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                height: 100, // Account for AppBar height
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMainProfileDisplay(),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildPersonalInfo(),
                  const SizedBox(height: 24),
                  _buildProfessionalInfo(),
                  const SizedBox(height: 24),
                  _buildPreferences(),
                  const SizedBox(height: 24),
                  _buildActions(),
                  const SizedBox(height: 120), // Extra space for bottom nav
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profile Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load your profile information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainProfileDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _showPhotoSourceDialog : null,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: _selectedImage != null 
                          ? FileImage(_selectedImage!) as ImageProvider
                          : _getProfileImage(),
                        child: _selectedImage == null && _getProfileImage() == null 
                          ? Text(
                              _getProfileInitials(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                      ),
                      if (_isEditing)
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      if (_isUploadingPhoto)
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _toggleOnlineStatus,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Icon(
                      _isOnline ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getProviderFullName(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentProviderProfile?.profession ?? _profile?.specialization ?? 'Medical Professional',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isOnline ? Icons.circle : Icons.pause_circle_filled,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? 'Available' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentProviderProfile?.rating ?? '4.5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    // Get data from professionals collection or fallback to legacy
    String rating = _currentProviderProfile?.rating ?? 
                   (_profile != null ? _profile!.rating.toStringAsFixed(1) : '4.5');
    String experience = _currentProviderProfile != null 
        ? (_currentProviderProfile!.profession.toLowerCase().contains('spécialiste') ? '10' : '5')
        : (_profile != null ? _profile!.experience.toString() : '5');
    String patients = _currentProviderProfile?.service ?? 
                     (_profile != null ? _profile!.totalPatients.toString() : '50');
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Rating',
            '$rating ⭐',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Experience',
            '$experience years',
            Icons.work,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Service',
            patients,
            Icons.medical_services,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      'Personal Information',
      [
        _buildInfoField('Full Name', _nameController, Icons.person),
        _buildInfoField('Phone', _phoneController, Icons.phone),
        _buildInfoField('Email', _emailController, Icons.email),
        _buildInfoField('Address', _addressController, Icons.location_on, maxLines: 2),
      ],
    );
  }

  Widget _buildProfessionalInfo() {
    return _buildSection(
      'Professional Information',
      [
        _buildSpecializationField(),
        _buildInfoField('Experience (Years)', _experienceController, Icons.work),
        _buildInfoField('Consultation Fee (DA)', _feeController, Icons.attach_money),
        _buildInfoField('Bio', _bioController, Icons.description, maxLines: 3),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: _isEditing,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              filled: true,
              fillColor: _isEditing ? Colors.white : Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specialization',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _profile?.specialization,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.medical_services, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: _isEditing ? Colors.white : Colors.grey.withOpacity(0.1),
            ),
            items: _specializations.map((spec) => DropdownMenuItem(
              value: spec,
              child: Text(spec),
            )).toList(),
            onChanged: _isEditing ? (value) {
              if (value != null && _profile != null) {
                setState(() {
                  _profile = _profile!.copyWith(specialization: value);
                });
              }
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return _buildSection(
      'Preferences',
      [
        _buildSwitchTile(
          'Emergency Notifications',
          'Receive notifications for emergency cases',
          Icons.local_hospital,
          _profile?.emergencyNotifications ?? false,
          (value) => _updateEmergencyNotifications(value),
        ),
        _buildSwitchTile(
          'SMS Notifications',
          'Receive appointment updates via SMS',
          Icons.sms,
          _profile?.smsNotifications ?? false,
          (value) => _updateSmsNotifications(value),
        ),
        _buildSwitchTile(
          'Auto Accept',
          'Automatically accept non-emergency appointments',
          Icons.auto_mode,
          _profile?.autoAccept ?? false,
          (value) => _updateAutoAccept(value),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_isEditing) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        _buildActionButton(
          'Account Settings',
          'Manage account preferences and security',
          Icons.settings,
          AppTheme.primaryColor,
          _openAccountSettings,
        ),
        
        const SizedBox(height: 12),
        
        _buildActionButton(
          'Help & Support',
          'Get help or contact support team',
          Icons.help,
          Colors.blue,
          _openHelpSupport,
        ),
        
        const SizedBox(height: 12),
        
        _buildActionButton(
          'Delete Account',
          'Permanently delete your account and data',
          Icons.delete_forever,
          Colors.red.shade600,
          _showDeleteConfirmation,
        ),
        
        const SizedBox(height: 12),
        
        _buildActionButton(
          'Sign Out',
          'Sign out of your account',
          Icons.logout,
          Colors.orange,
          _signOut,
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      final newStatus = _isOnline 
          ? ProviderAvailabilityStatus.offline 
          : ProviderAvailabilityStatus.online;
      
      await _providerService.updateAvailabilityStatus(newStatus);
      
      setState(() {
        _isOnline = !_isOnline;
      });
      
      HapticFeedback.lightImpact();
      _showSuccessSnackBar('Status updated to ${_isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
    }
  }

  void _updateEmergencyNotifications(bool value) {
    if (_profile != null) {
      setState(() {
        _profile = _profile!.copyWith(emergencyNotifications: value);
      });
    }
  }

  void _updateSmsNotifications(bool value) {
    if (_profile != null) {
      setState(() {
        _profile = _profile!.copyWith(smsNotifications: value);
      });
    }
  }

  void _updateAutoAccept(bool value) {
    if (_profile != null) {
      setState(() {
        _profile = _profile!.copyWith(autoAccept: value);
      });
    }
  }



  void _openAccountSettings() {
    HapticFeedback.lightImpact();
    _showInfoSnackBar('Opening account settings...');
    // Implement account settings screen
  }

  void _openHelpSupport() {
    HapticFeedback.lightImpact();
    _showInfoSnackBar('Opening help & support...');
    // Implement help & support screen
  }

  void _signOut() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1: // Messages
        Navigator.pushReplacementNamed(context, AppRoutes.providerMessages);
        break;
      case 2: // Appointments
        Navigator.pushReplacementNamed(context, AppRoutes.providerAppointments);
        break;
      case 3: // Profile
        // Already on profile - do nothing
        break;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getProviderFullName() {
    if (_currentProviderProfile != null) {
      String fullName = '';
      if (_currentProviderProfile!.prenom.isNotEmpty) {
        fullName += _currentProviderProfile!.prenom;
      }
      if (_currentProviderProfile!.nom.isNotEmpty) {
        if (fullName.isNotEmpty) fullName += ' ';
        fullName += _currentProviderProfile!.nom;
      }
      if (fullName.isNotEmpty) {
        return fullName;
      }
      // Fallback to email if no nom/prenom
      return _currentProviderProfile!.email.split('@')[0];
    }
    // Legacy fallback
    return _profile?.name ?? 'Provider';
  }

  String _getProfileInitials() {
    if (_currentProviderProfile != null) {
      String initials = '';
      if (_currentProviderProfile!.prenom.isNotEmpty) {
        initials += _currentProviderProfile!.prenom[0].toUpperCase();
      }
      if (_currentProviderProfile!.nom.isNotEmpty) {
        initials += _currentProviderProfile!.nom[0].toUpperCase();
      }
      if (initials.isNotEmpty) {
        return initials;
      }
      // Fallback to first letter of email
      return _currentProviderProfile!.email[0].toUpperCase();
    }
    // Legacy fallback
    return (_profile?.name != null && _profile!.name.isNotEmpty) 
        ? _profile!.name.substring(0, 1).toUpperCase() 
        : 'Dr';
  }

  ImageProvider? _getProfileImage() {
    if (_currentProviderProfile != null) {
      // Check photoUrl field first
      String? photoUrl = _currentProviderProfile!.photoUrl;
      if (photoUrl != null && photoUrl.isNotEmpty && photoUrl != 'null') {
        try {
          return NetworkImage(photoUrl);
        } catch (e) {
          print('Failed to load photoUrl: $e');
        }
      }
      
      // Check photoProfile field as fallback
      String? photoProfile = _currentProviderProfile!.photoProfile;
      if (photoProfile != null && photoProfile.isNotEmpty && photoProfile != 'null') {
        try {
          return NetworkImage(photoProfile);
        } catch (e) {
          print('Failed to load photoProfile: $e');
        }
      }
    }
    
    // If no valid image found, return null to show initials
    return null;
  }

  void _debugCurrentDataState() {
    print('\n🔍 DEBUG: Current Data State');
    print('=' * 50);
    
    // Check current user
    final currentUser = FirebaseAuth.instance.currentUser;
    print('👤 Current Firebase Auth User:');
    print('  UID: ${currentUser?.uid}');
    print('  Email: ${currentUser?.email}');
    print('  Display Name: ${currentUser?.displayName}');
    
    // Check professionals collection data
    print('\n🏥 Professionals Collection Data:');
    if (_currentProviderProfile != null) {
      print('  Login: ${_currentProviderProfile!.login}');
      print('  Email: ${_currentProviderProfile!.email}');
      print('  Profession: ${_currentProviderProfile!.profession}');
      print('  Rating: ${_currentProviderProfile!.rating}');
      print('  Bio: ${_currentProviderProfile!.bio}');
      print('  Service: ${_currentProviderProfile!.service}');
      print('  Available: ${_currentProviderProfile!.disponible}');
    } else {
      print('  ❌ No professionals collection data loaded');
    }
    
    // Check legacy provider service data
    print('\n💼 Legacy Provider Service Data:');
    if (_profile != null) {
      print('  Name: ${_profile!.name}');
      print('  Email: ${_profile!.email}');
      print('  Phone: ${_profile!.phone}');
    } else {
      print('  ❌ No legacy provider data loaded');
    }
    
    print('\n📊 Current Display State:');
    print('  Is Loading: $_isLoading');
    print('  Is Online: $_isOnline');
    print('=' * 50);
    
    // Show popup to user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${currentUser?.email ?? "Not logged in"}'),
            SizedBox(height: 8),
            Text('Professionals Data: ${_currentProviderProfile != null ? "✅ Found" : "❌ Missing"}'),
            SizedBox(height: 8),
            Text('Legacy Data: ${_profile != null ? "✅ Found" : "❌ Missing"}'),
            SizedBox(height: 8),
            Text('Status: ${_isOnline ? "Online" : "Offline"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
