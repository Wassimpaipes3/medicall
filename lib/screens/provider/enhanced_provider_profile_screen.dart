import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/provider/provider_service.dart';
import '../../services/provider_auth_service.dart' as ProviderAuth;
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
  ProviderUser? _currentProvider; // Legacy provider data
  ProviderAuth.ProviderProfile? _currentProviderProfile; // New professionals collection data
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
    _loadAllProviderData(); // Load both legacy and professional data
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

  Future<void> _loadAllProviderData() async {
    setState(() => _isLoading = true);
    
    print('🚀 Starting to load provider data (prioritizing professionals collection)...');
    
    try {
      // First, try to load from professionals collection
      await _loadProviderProfileInternal();
      
      if (_currentProviderProfile != null) {
        print('✅ Using professionals collection data');
        _populateFormFieldsFromProfile();
      } else {
        print('⚠️ No professionals collection data found, trying legacy provider service...');
        // Only load legacy data if professionals collection has no data
        await _loadProviderDataInternal();
        
        if (_currentProvider != null) {
          print('✅ Using legacy provider data');
          _populateFormFields();
        } else {
          print('❌ No data found in either collection - creating default provider profile');
          await _createDefaultProviderProfile();
        }
      }
      
      _debugCurrentDataState();
      
    } catch (e) {
      print('❌ Error loading provider data: $e');
      _showErrorSnackbar('Failed to load provider data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProviderDataInternal() async {
    try {
      print('🔄 Loading legacy provider data...');
      final provider = await _providerService.getCurrentProvider();
      if (provider != null) {
        setState(() {
          _currentProvider = provider;
        });
        print('✅ Legacy provider data loaded: ${provider.fullName}');
      } else {
        print('⚠️ No legacy provider data found');
      }
    } catch (e) {
      print('❌ Error loading legacy provider data: $e');
      throw e;
    }
  }

  Future<void> _loadProviderProfileInternal() async {
    try {
      print('🔄 Loading provider profile from professionals collection...');
      
      final providerProfile = await ProviderAuth.ProviderAuthService.getCurrentProviderProfile();
      
      if (providerProfile != null) {
        setState(() {
          _currentProviderProfile = providerProfile;
        });
        print('✅ Provider profile loaded successfully: ${providerProfile.login}');
        print('📊 Profile data: ${providerProfile.profession} - ${providerProfile.specialite}');
      } else {
        print('⚠️ No provider profile found in professionals collection');
      }
    } catch (e) {
      print('❌ Error loading provider profile: $e');
      throw e;
    }
  }
  
  Future<void> _createDefaultProviderProfile() async {
    try {
      print('🔄 Creating default provider profile from current user...');
      
      // Get current user info from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      // Create a basic profile with user info
      setState(() {
        _currentProviderProfile = ProviderAuth.ProviderProfile(
          uid: currentUser.uid,
          email: currentUser.email ?? 'provider@example.com',
          nom: currentUser.displayName?.split(' ').last ?? 'Provider',
          prenom: currentUser.displayName?.split(' ').first ?? 'Dr.',
          bio: 'Healthcare professional - please update your profile',
          disponible: true,
          idpro: 'PRO_${currentUser.uid.substring(0, 8)}',
          login: currentUser.displayName ?? currentUser.email ?? 'Provider',
          profession: 'Médecin généraliste',
          rating: '4.0',
          service: 'Consultation générale',
          specialite: 'Please set your specialization',
          tel: 'Please add your phone number',
          adresse: 'Please add your address',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        _populateFormFieldsFromProfile();
      });
      
      print('✅ Default provider profile created for: ${currentUser.displayName ?? currentUser.email}');
      
    } catch (e) {
      print('❌ Error creating default provider profile: $e');
      // Create basic fallback
      setState(() {
        _nameController.text = 'Provider Name - Please Update';
        _emailController.text = 'provider@example.com';
        _bioController.text = 'Please update your profile information';
        _specializationController.text = 'General Medicine';
      });
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

  void _populateFormFieldsFromProfile() {
    if (_currentProviderProfile != null) {
      // Use professionals collection data to populate form fields
      _nameController.text = _currentProviderProfile!.login; // Use login as name
      _emailController.text = _currentProviderProfile!.login; // Email from login
      _bioController.text = _currentProviderProfile!.bio;
      _specializationController.text = _currentProviderProfile!.specialite;
      
      // Map profession to experience (basic mapping)
      if (_currentProviderProfile!.profession.toLowerCase().contains('spécialiste')) {
        _experienceController.text = '10'; // Default for specialists
      } else {
        _experienceController.text = '5'; // Default for general practitioners
      }
      
      // Use rating as base consultation fee (convert to price)
      double rating = double.tryParse(_currentProviderProfile!.rating) ?? 4.0;
      double baseRate = rating * 20; // Rating * 20 = price in DZD
      _consultationFeeController.text = baseRate.toString();
      
      print('📝 Form populated with professionals collection data');
      print('   - Name: ${_nameController.text}');
      print('   - Specialization: ${_specializationController.text}');
      print('   - Bio: ${_bioController.text}');
    }
  }
  
  void _debugCurrentDataState() {
    print('🔍 === DEBUG: Current Data State ===');
    print('📊 Loading state: $_isLoading');
    print('👤 Legacy Provider: ${_currentProvider != null ? "✅ Loaded" : "❌ null"}');
    print('🏥 Professional Profile: ${_currentProviderProfile != null ? "✅ Loaded" : "❌ null"}');
    
    if (_currentProvider != null) {
      print('   Legacy data: ${_currentProvider!.fullName} - ${_currentProvider!.specialty}');
    }
    
    if (_currentProviderProfile != null) {
      print('   Professional data: ${_currentProviderProfile!.login} - ${_currentProviderProfile!.specialite}');
    }
    
    print('📝 Form Controllers:');
    print('   Name: "${_nameController.text}"');
    print('   Email: "${_emailController.text}"');
    print('   Specialization: "${_specializationController.text}"');
    print('   Bio: "${_bioController.text}"');
    
    print('🎯 Display Values:');
    print('   Display Name: "${_getDisplayName()}"');
    print('   Display Specialty: "${_getDisplaySpecialty()}"');
    print('   Display Rating: "${_getDisplayRating()}"');
    print('🔍 === END DEBUG ===');
  }
  
  void _loadTestData() {
    print('🧪 Loading test data for debugging...');
    setState(() {
      // Create test professional profile
      _currentProviderProfile = ProviderAuth.ProviderProfile(
        uid: 'test-uid-123',
        email: 'test.provider@example.com',
        nom: 'Doe',
        prenom: 'Dr. John',
        bio: 'Experienced healthcare professional with 10+ years of experience.',
        disponible: true,
        idpro: 'PRO123456',
        login: 'Dr. John Doe',
        profession: 'Médecin généraliste',
        rating: '4.8',
        service: 'Consultation générale',
        specialite: 'Médecine générale',
        tel: '+213555123456',
        adresse: '123 Medical Street, Algiers',
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
      
      _populateFormFieldsFromProfile();
      _isLoading = false;
    });
    
    print('✅ Test data loaded successfully');
    _debugCurrentDataState();
  }
  
  String _getDisplayName() {
    String name;
    String source;
    
    if (_currentProviderProfile != null) {
      name = _currentProviderProfile!.login.isNotEmpty ? _currentProviderProfile!.login : '${_currentProviderProfile!.prenom} ${_currentProviderProfile!.nom}';
      source = "professionals collection";
    } else if (_currentProvider != null) {
      name = _currentProvider!.fullName;
      source = "legacy provider data";
    } else {
      name = 'No Provider Data Available (Long press avatar to load test data)';
      source = "fallback default";
    }
    
    print('🏷️ Getting display name: "$name" (from $source)');
    return name;
  }
  
  String _getDisplaySpecialty() {
    String specialty;
    String source;
    
    if (_currentProviderProfile != null) {
      specialty = _currentProviderProfile!.specialite.isNotEmpty ? _currentProviderProfile!.specialite : 'No specialty set';
      source = "professionals collection";
    } else if (_currentProvider != null) {
      specialty = _currentProvider!.specialty;
      source = "legacy provider data";
    } else {
      specialty = 'Please set your specialization';
      source = "fallback default";
    }
    
    print('🎯 Getting display specialty: "$specialty" (from $source)');
    return specialty;
  }
  
  String _getDisplayRating() {
    String rating;
    String source;
    
    if (_currentProviderProfile != null) {
      rating = _currentProviderProfile!.rating.isNotEmpty ? _currentProviderProfile!.rating : '4.0';
      source = "professionals collection";
    } else if (_currentProvider != null) {
      rating = _currentProvider!.rating.toString();
      source = "legacy provider data";
    } else {
      rating = '0.0';
      source = "fallback default";
    }
    
    print('⭐ Getting display rating: "$rating" (from $source)');
    return rating;
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
      
      // Also update professionals collection if profile exists
      if (_currentProviderProfile != null) {
        final updatedProfessionalProfile = ProviderAuth.ProviderProfile(
          uid: _currentProviderProfile!.uid,
          email: _currentProviderProfile!.email,
          nom: _currentProviderProfile!.nom,
          prenom: _currentProviderProfile!.prenom,
          tel: _currentProviderProfile!.tel,
          adresse: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : _currentProviderProfile!.adresse,
          photoProfile: _currentProviderProfile!.photoProfile,
          bio: _bioController.text.trim(),
          disponible: true, // Keep availability status
          idpro: _currentProviderProfile!.idpro,
          login: _emailController.text.trim(), // Keep email as login
          profession: _currentProviderProfile!.profession, // Keep existing profession
          rating: ((double.tryParse(_consultationFeeController.text) ?? 80.0) / 20).toStringAsFixed(1), // Convert price back to rating
          service: _currentProviderProfile!.service, // Keep existing service
          specialite: _specializationController.text.trim(),
          photoUrl: _currentProviderProfile!.photoUrl,
          createdAt: _currentProviderProfile!.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await ProviderAuth.ProviderAuthService.updateProviderProfile(
          uid: _currentProviderProfile!.uid,
          bio: _bioController.text.trim(),
          specialite: _specializationController.text.trim(),
          disponible: true,
        );
        setState(() => _currentProviderProfile = updatedProfessionalProfile);
        
        print('✅ Updated both legacy and professionals collection profiles');
      }
      
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
          GestureDetector(
            onLongPress: _loadTestData, // Long press to load test data for debugging
            child: Container(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplaySpecialty(),
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
                      '${_getDisplayRating()} Rating',
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

  // Logout method temporarily disabled
  // TODO: Implement logout functionality if needed
}
