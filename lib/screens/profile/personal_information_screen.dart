import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/enhanced_theme.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  String _selectedGender = '';
  String _selectedBloodType = '';
  DateTime _selectedBirthDate = DateTime.now();
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPasswordChange = false;
  bool _isChangingPassword = false;

  // Password change controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserProfileService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          // Load user data from Firestore
          _nameController.text = userData['nom'] ?? '';
          _prenomController.text = userData['prenom'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['tel'] ?? '';
          _addressController.text = userData['adresse'] ?? '';
          _selectedGender = userData['genre'] ?? '';
          _selectedBloodType = userData['groupe_sanguin'] ?? '';
          
          // Handle "Non renseigné" values
          if (_selectedGender == 'Non renseigné') _selectedGender = '';
          if (_selectedBloodType == 'Non renseigné') _selectedBloodType = '';
          
          // Parse date of birth
          if (userData['date_naissance'] != null && userData['date_naissance'].isNotEmpty) {
            try {
              _selectedBirthDate = DateTime.parse(userData['date_naissance']);
            } catch (e) {
              _selectedBirthDate = DateTime.now();
            }
          }
          
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

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: EnhancedAppTheme.primaryIndigo),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Check if email has changed
      final newEmail = _emailController.text.trim();
      final emailChanged = newEmail != user.email;
      
      // Try to update email in Firebase Auth if it changed
      if (emailChanged) {
        await _updateEmailInFirebaseAuth(newEmail);
      }

      // Prepare user data updates
      final userUpdates = {
        'nom': _nameController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': newEmail, // Include email in Firestore update
        'tel': _phoneController.text.trim(),
        'adresse': _addressController.text.trim(),
        'genre': _selectedGender,
        'date_naissance': _selectedBirthDate.toIso8601String().split('T')[0],
      };

      // Prepare medical data updates
      final medicalUpdates = {
        'groupe_sanguin': _selectedBloodType,
      };

      // Update both collections
      await UserProfileService.updateUserInfo(userUpdates);
      await UserProfileService.updateMedicalInfo(medicalUpdates);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal information updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveInformation() {
    _saveChanges();
  }

  Future<void> _updateEmailInFirebaseAuth(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Use verifyBeforeUpdateEmail which sends verification email
      await user.verifyBeforeUpdateEmail(newEmail);
      print('✅ Email verification sent to: $newEmail');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verification sent! Please check your new email and click the verification link to complete the update.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        // If re-authentication is required, show a dialog to the user
        if (mounted) {
          _showReauthDialog(newEmail);
        }
      } else {
        // Handle other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email update failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showReauthDialog(String newEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Update Requires Re-authentication'),
        content: const Text(
          'To update your email address, you need to log out and log back in with your new email address. '
          'Your profile information has been saved with the new email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Sign out the user
              FirebaseAuth.instance.signOut();
              // Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Log Out Now'),
          ),
        ],
      ),
    );
  }

  void _togglePasswordChange() {
    setState(() {
      _showPasswordChange = !_showPasswordChange;
      if (!_showPasswordChange) {
        // Clear password fields when hiding
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.trim().isEmpty ||
        _newPasswordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all password fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final authService = AuthService();
      final result = await authService.updatePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });

        if (result['success'] == true) {
          // Clear form and hide password change section
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _showPasswordChange = false;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Personal Information',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading your information...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 100,
        leading: IconButton(
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: EnhancedAppTheme.primaryIndigo,
            ),
            onPressed: _isSaving ? null : () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 20),
                  _buildContactInfoSection(),
                  const SizedBox(height: 20),
                  _buildMedicalInfoSection(),
                  const SizedBox(height: 40),
                  if (_isEditing) _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.person_rounded,
      children: [
        _buildTextFormField(
          controller: _nameController,
          label: 'Nom (Last Name)',
          icon: Icons.badge_rounded,
          enabled: _isEditing,
          validator: (value) => value?.isEmpty ?? true ? 'Nom is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _prenomController,
          label: 'Prénom (First Name)',
          icon: Icons.badge_rounded,
          enabled: _isEditing,
          validator: (value) => value?.isEmpty ?? true ? 'Prénom is required' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Gender',
          icon: Icons.wc_rounded,
          value: _selectedGender.isEmpty ? 'Non renseigné' : _selectedGender,
          items: ['Non renseigné', 'Homme', 'Femme', 'Autre'],
          onChanged: _isEditing ? (value) => setState(() => _selectedGender = value == 'Non renseigné' ? '' : value!) : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _isEditing ? _selectBirthDate : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: _isEditing ? Colors.white : Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_rounded,
                  color: EnhancedAppTheme.primaryIndigo,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedBirthDate.day}/${_selectedBirthDate.month}/${_selectedBirthDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditing)
                  Icon(
                    Icons.calendar_today_rounded,
                    color: EnhancedAppTheme.primaryIndigo,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone_rounded,
      children: [
        _buildTextFormField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_rounded,
          enabled: _isEditing,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => value?.contains('@') ?? false ? null : 'Valid email required',
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_rounded,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty ?? true ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on_rounded,
          enabled: _isEditing,
          maxLines: 2,
          validator: (value) => value?.isEmpty ?? true ? 'Address is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _emergencyContactController,
          label: 'Emergency Contact',
          icon: Icons.emergency_rounded,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty ?? true ? 'Emergency contact is required' : null,
        ),
        const SizedBox(height: 20),
        _buildPasswordChangeSection(),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
    return _buildSection(
      title: 'Medical Information',
      icon: Icons.medical_services_rounded,
      children: [
        _buildDropdownField(
          label: 'Blood Type',
          icon: Icons.bloodtype_rounded,
          value: _selectedBloodType.isEmpty ? 'Non renseigné' : _selectedBloodType,
          items: ['Non renseigné', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
          onChanged: _isEditing ? (value) => setState(() => _selectedBloodType = value == 'Non renseigné' ? '' : value!) : null,
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
            color: Colors.grey.withOpacity(0.1),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: EnhancedAppTheme.primaryIndigo, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EnhancedAppTheme.primaryIndigo),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: EnhancedAppTheme.primaryIndigo, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EnhancedAppTheme.primaryIndigo),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: onChanged != null ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.all(16),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildPasswordChangeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.indigo,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Password & Security',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _togglePasswordChange,
              icon: Icon(
                _showPasswordChange ? Icons.close_rounded : Icons.edit_rounded,
                size: 18,
              ),
              label: Text(_showPasswordChange ? 'Cancel Password Change' : 'Change Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
          if (_showPasswordChange) ...[
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureCurrentPassword,
              onToggleVisibility: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password',
              icon: Icons.lock_rounded,
              obscureText: _obscureNewPassword,
              onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              icon: Icons.lock_rounded,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isChangingPassword
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Update Password 🔐',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey[600],
            size: 18,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.indigo),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveInformation,
        style: ElevatedButton.styleFrom(
          backgroundColor: EnhancedAppTheme.primaryIndigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Changes ⚡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
