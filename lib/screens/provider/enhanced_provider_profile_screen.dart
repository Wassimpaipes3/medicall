import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/provider/provider_service.dart';
import '../../models/provider/provider_model.dart';
import '../../data/models/location_models.dart';
import '../../utils/responsive_button_layout.dart';
import '../../widgets/provider/provider_navigation_bar.dart';
import '../../routes/app_routes.dart';

class EnhancedProviderProfileScreen extends StatefulWidget {
  const EnhancedProviderProfileScreen({super.key});

  @override
  State<EnhancedProviderProfileScreen> createState() => _EnhancedProviderProfileScreenState();
}

class _EnhancedProviderProfileScreenState extends State<EnhancedProviderProfileScreen>
    with TickerProviderStateMixin {
  
  final ProviderService _providerService = ProviderService();
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Data
  ProviderUser? _currentProvider;
  bool _isLoading = true;
  bool _isSaving = false;
  int _selectedIndex = 3; // Profile tab
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  
  // Form Key
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProviderData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
        
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadProviderData() async {
    try {
      setState(() => _isLoading = true);
      
      final provider = await _providerService.getCurrentProvider();
      if (provider != null) {
        setState(() {
          _currentProvider = provider;
          _populateFormFields();
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to load provider data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFormFields() {
    if (_currentProvider != null) {
      _nameController.text = _currentProvider!.fullName;
      _phoneController.text = _currentProvider!.phoneNumber;
      _emailController.text = _currentProvider!.email;
      _bioController.text = _currentProvider!.bio;
      _addressController.text = _currentProvider!.currentLocation?.address ?? '';
      _specializationController.text = _currentProvider!.specialty;
      _experienceController.text = _currentProvider!.yearsOfExperience.toString();
      _consultationFeeController.text = _currentProvider!.pricingConfig.baseRate.toString();
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isSaving = true);
      
      // Create updated location if address is provided
      UserLocation? updatedLocation;
      if (_addressController.text.trim().isNotEmpty) {
        updatedLocation = UserLocation(
          latitude: _currentProvider?.currentLocation?.latitude ?? 36.7538,
          longitude: _currentProvider?.currentLocation?.longitude ?? 3.0588,
          address: _addressController.text.trim(),
          timestamp: DateTime.now(),
        );
      }
      
      // Create updated pricing config
      final updatedPricingConfig = PricingConfig(
        baseRate: double.tryParse(_consultationFeeController.text) ?? _currentProvider!.pricingConfig.baseRate,
        emergencyRate: _currentProvider!.pricingConfig.emergencyRate,
        nightRate: _currentProvider!.pricingConfig.nightRate,
        weekendRate: _currentProvider!.pricingConfig.weekendRate,
        acceptsInsurance: _currentProvider!.pricingConfig.acceptsInsurance,
        acceptedPaymentMethods: _currentProvider!.pricingConfig.acceptedPaymentMethods,
      );
      
      final updatedProvider = _currentProvider!.copyWith(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
        currentLocation: updatedLocation,
        specialty: _specializationController.text.trim(),
        yearsOfExperience: int.tryParse(_experienceController.text) ?? _currentProvider!.yearsOfExperience,
        pricingConfig: updatedPricingConfig,
      );
      
      await _providerService.updateProviderProfile(updatedProvider);
      
      setState(() => _currentProvider = updatedProvider);
      
      _showSuccessSnackbar('Profile updated successfully!');
      HapticFeedback.lightImpact();
      
    } catch (e) {
      _showErrorSnackbar('Failed to update profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Provider Profile',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildProfileContent(),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleNavigation(index);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading profile...'),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(),
                const SizedBox(height: 24),
                _buildProfessionalInfoSection(),
                const SizedBox(height: 24),
                _buildAdditionalInfoSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentProvider?.fullName ?? 'Provider Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentProvider?.specialty ?? 'Specialization',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentProvider?.rating.toStringAsFixed(1) ?? '0.0'} Rating',
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty == true ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty == true) return 'Email is required';
            if (!value!.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter your address',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoSection() {
    return _buildSection(
      title: 'Professional Information',
      icon: Icons.work_outline,
      children: [
        _buildTextField(
          controller: _specializationController,
          label: 'Specialization',
          hint: 'Enter your specialization',
          validator: (value) => value?.isEmpty == true ? 'Specialization is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _experienceController,
          label: 'Years of Experience',
          hint: 'Enter years of experience',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Experience is required';
            if (int.tryParse(value!) == null) return 'Enter a valid number';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _consultationFeeController,
          label: 'Consultation Fee (DZD)',
          hint: 'Enter consultation fee',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Fee is required';
            if (double.tryParse(value!) == null) return 'Enter a valid amount';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildSection(
      title: 'Additional Information',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: _bioController,
          label: 'Bio/Description',
          hint: 'Tell patients about yourself and your practice',
          maxLines: 4,
          validator: (value) => value?.isEmpty == true ? 'Bio is required' : null,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildActionButtons() {
    return ResponsiveButtonLayout.adaptiveButtonRow(
      buttons: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
      spacing: 12.0,
      minButtonWidth: 120.0,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.providerMessages);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.providerAppointments);
        break;
      case 3:
        // Already in enhanced profile
        break;
    }
  }

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout from your provider account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
