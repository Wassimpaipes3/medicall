import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/enhanced_theme.dart';

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
  final _nameController = TextEditingController(text: 'Wassim Ahmed');
  final _emailController = TextEditingController(text: 'wassim@healthcare.com');
  final _phoneController = TextEditingController(text: '+1 (555) 123-4567');
  final _addressController = TextEditingController(text: '123 Healthcare St, Medical City');
  final _emergencyContactController = TextEditingController(text: '+1 (555) 987-6543');
  
  String _selectedGender = 'Male';
  String _selectedBloodType = 'O+';
  DateTime _selectedBirthDate = DateTime(1990, 5, 15);
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
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

  void _saveInformation() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      
      // Save information logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Personal information updated successfully! ⚡'),
            ],
          ),
          backgroundColor: EnhancedAppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 100, // Increased from 74 to 100 for much lower positioning from top
        leading: IconButton(
          iconSize: 24, // Added icon size
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
            onPressed: () {
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
          label: 'Full Name',
          icon: Icons.badge_rounded,
          enabled: _isEditing,
          validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Gender',
          icon: Icons.wc_rounded,
          value: _selectedGender,
          items: ['Male', 'Female', 'Other'],
          onChanged: _isEditing ? (value) => setState(() => _selectedGender = value!) : null,
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
          value: _selectedBloodType,
          items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
          onChanged: _isEditing ? (value) => setState(() => _selectedBloodType = value!) : null,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveInformation,
        style: ElevatedButton.styleFrom(
          backgroundColor: EnhancedAppTheme.primaryIndigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: const Text(
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
