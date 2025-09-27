import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';
import '../../services/provider/provider_service.dart';
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

  ProviderProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isOnline = false;
  
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
      await _providerService.initialize();
      final profile = await _providerService.getProfile();
      final status = await _providerService.getAvailabilityStatus();
      
      setState(() {
        _profile = profile;
        _isOnline = status == ProviderAvailabilityStatus.online;
        _isLoading = false;
      });
      
      _populateControllers();
    } catch (e) {
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
      _feeController.text = _profile!.consultationFee.toString();
    }
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: 4,
        onTap: (index) => _handleNavigation(index),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditing = !_isEditing;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                  _profile!.name.substring(0, 1).toUpperCase(),
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
                _profile!.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profile!.specialization,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_profile == null) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(),
              const SizedBox(height: 24),
              _buildPersonalInfo(),
              const SizedBox(height: 24),
              _buildProfessionalInfo(),
              const SizedBox(height: 24),
              _buildPreferences(),
              const SizedBox(height: 24),
              _buildActions(),
              const SizedBox(height: 100),
            ],
          ),
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

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Rating',
            '${_profile!.rating.toStringAsFixed(1)} ⭐',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Experience',
            '${_profile!.experience} years',
            Icons.work,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Patients',
            '${_profile!.totalPatients}+',
            Icons.people,
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
          'Sign Out',
          'Sign out of your account',
          Icons.logout,
          Colors.red,
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

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _populateControllers();
    HapticFeedback.lightImpact();
  }

  Future<void> _saveProfile() async {
    try {
      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          bio: _bioController.text,
          experience: int.tryParse(_experienceController.text) ?? _profile!.experience,
          consultationFee: double.tryParse(_feeController.text) ?? _profile!.consultationFee,
        );
        
        await _providerService.updateProfile(updatedProfile);
        
        setState(() {
          _profile = updatedProfile;
          _isEditing = false;
        });
        
        HapticFeedback.lightImpact();
        _showSuccessSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
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
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.enhancedAppointmentManagement);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.enhancedMessages);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.enhancedEarnings);
        break;
      case 4:
        // Already on profile
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
}
