import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'package:firstv/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_storage_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adresseController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _telController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedGenre = 'Homme';
  String? _photoProfilePath;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adresseController.dispose();
    _dateNaissanceController.dispose();
    _telController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    bool isObscure = false,
    TextInputType? keyboardType,
    IconData? icon,
    TextEditingController? controller,
    VoidCallback? onSuffixIconPressed,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: AppTheme.fontSizeMedium,
          color: AppTheme.textPrimaryColor,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppTheme.textSecondaryColor,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                )
              : null,
          suffixIcon: onSuffixIconPressed != null
              ? IconButton(
                  onPressed: onSuffixIconPressed,
                  icon: Icon(
                    isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondaryColor,
                    size: 20,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
          ),
          errorStyle: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.errorColor,
            fontFamily: AppTheme.fontFamily,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
            firstDate: DateTime(1900),
            lastDate: DateTime.now().subtract(const Duration(days: 4380)), // 12 years ago (minimum age)
          );
          if (pickedDate != null) {
            controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          }
        },
        style: TextStyle(
          fontSize: AppTheme.fontSizeMedium,
          color: AppTheme.textPrimaryColor,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppTheme.textSecondaryColor,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
          ),
          errorStyle: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.errorColor,
            fontFamily: AppTheme.fontFamily,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedGenre,
        decoration: InputDecoration(
          labelText: 'Genre',
          labelStyle: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppTheme.textSecondaryColor,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            Icons.person_outline,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.errorColor, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: ['Homme', 'Femme', 'Autre'].map((String genre) {
          return DropdownMenuItem<String>(
            value: genre,
            child: Text(
              genre,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textPrimaryColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGenre = newValue!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez sélectionner votre genre';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhotoProfileSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _photoProfilePath != null 
                ? AppTheme.primaryColor 
                : AppTheme.textSecondaryColor.withOpacity(0.3),
            width: _photoProfilePath != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Photo de profil (optionnel)',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textSecondaryColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null) ...[
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _pickImage();
                    },
                    icon: Icon(
                      _selectedImage == null 
                          ? Icons.add_a_photo_outlined
                          : Icons.edit_outlined,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    label: Text(
                      _selectedImage == null 
                          ? 'Choisir une photo' 
                          : 'Modifier la photo',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _photoProfilePath = null;
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choisir une photo de profil',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Caméra',
                        onTap: () => _selectImage(ImageSource.camera),
                      ),
                      _buildImageSourceOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Galerie',
                        onTap: () => _selectImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      Navigator.of(context).pop(); // Close bottom sheet
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _photoProfilePath = pickedFile.path; // Store local path for now
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo sélectionnée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// Validate all form inputs before signup
  String? _validateSignupForm() {
    // Basic validation
    if (_nameController.text.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (_prenomController.text.trim().isEmpty) {
      return 'Le prénom est requis';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'L\'email est requis';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim())) {
      return 'Format d\'email invalide';
    }
    if (_passwordController.text.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    if (_telController.text.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(_telController.text.trim())) {
      return 'Format de téléphone invalide';
    }
    if (!_acceptTerms) {
      return 'Veuillez accepter les termes et conditions';
    }
    
    return null; // All validations passed
  }

  Future<void> _handleSignUp() async {
    try {
      // Pre-validation
      String? validationError = _validateSignupForm();
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Complete Patient Signup: Firebase Auth + Firestore Profile
      final authService = AuthService();
      final result = await authService.signUpPatient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nameController.text.trim(),          // Changed from 'name' to 'nom'
        prenom: _prenomController.text.trim(),
        tel: _telController.text.trim(),           // Changed from 'telephone' to 'tel'
        adresse: _adresseController.text.trim(),
        dateNaissance: _dateNaissanceController.text.trim(),
        genre: _selectedGenre,
        photoProfilePath: null, // Photo will be uploaded after account creation
      );
      
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        if (result['success'] == true) {
          // If user selected a photo, upload it now that account is created
          if (_selectedImage != null && _photoProfilePath != null) {
            try {
              // Show uploading message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Téléchargement de la photo...'),
                    ],
                  ),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 10),
                ),
              );

              // Upload to Firebase Storage now that user is authenticated
              final downloadUrl = await FirebaseStorageService.uploadProfilePicture(_selectedImage!);
              
              if (downloadUrl != null) {
                print('✅ Profile picture uploaded successfully: $downloadUrl');
              }
            } catch (uploadError) {
              print('❌ Photo upload error: $uploadError');
              // Continue with navigation even if photo upload fails
            }
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Compte créé avec succès!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Navigate directly to patient home screen (signup is patient-only)
          Navigator.pushReplacementNamed(context, '/patient-navigation');
          
        } else {
          // Show specific error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de la création du compte'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 4),
              action: result['error'] == 'email-already-in-use' 
                  ? SnackBarAction(
                      label: 'Se connecter',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          // Handle social signup
        },
        icon: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pillColors = [
      AppTheme.primaryLightColor.withOpacity(0.85),
      AppTheme.secondaryColor.withOpacity(0.85),
      AppTheme.primaryColor.withOpacity(0.85),
      AppTheme.accentColor.withOpacity(0.85),
    ];
    final pillSize = 28.0;
    final verticalRange = 320.0;
    final horizontalRange = 120.0;
    final randomOffsets = [0.0, 0.3, 0.6, 0.9];
    final perspective = 0.002;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundColor,
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.secondaryColor.withOpacity(0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated pills falling from the sky with bounce and drift
                  ...List.generate(4, (i) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final phase = ((_controller.value + randomOffsets[i]) % 1.0);
                        final t = phase;
                        double y = verticalRange * (1 - (1 - t) * (1 - t));
                        if (t > 0.95) {
                          y += 20 *
                              (1 - (t - 0.95) / 0.05) *
                              sin((t - 0.95) * pi / 0.05);
                        }
                        final x = horizontalRange *
                                sin(2 * pi * (t + i / 4)) *
                                0.3 +
                            (i - 1.5) * 40.0;
                        final rotationY = pi / 6 * sin(2 * pi * t + i);
                        final rotationX = pi / 8 * cos(2 * pi * t + i);
                        final scale =
                            0.85 + 0.25 * (0.5 + 0.5 * cos(2 * pi * t + i));
                        return Positioned(
                          left: 0.0,
                          right: 0.0,
                          top: 0.0,
                          bottom: 0.0,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, perspective)
                              ..translate(x, -verticalRange / 2 + y)
                              ..rotateY(rotationY)
                              ..rotateX(rotationX)
                              ..scale(scale),
                            child: Container(
                              width: pillSize,
                              height: pillSize,
                              decoration: BoxDecoration(
                                color: pillColors[i],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: pillColors[i].withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  // Glassmorphism form
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header Section
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Logo or Icon
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person_add,
                                        size: 40,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSize3XLarge,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimaryColor,
                                        fontFamily: AppTheme.fontFamily,
                                        letterSpacing: -0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sign up to get started with MediCall',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeMedium,
                                        color: AppTheme.textSecondaryColor,
                                        fontFamily: AppTheme.fontFamily,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Form Fields
                                _buildTextField(
                                  label: 'Nom (Last Name)',
                                  keyboardType: TextInputType.name,
                                  icon: Icons.person_outlined,
                                  controller: _nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre nom';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Prénom (First Name)',
                                  keyboardType: TextInputType.name,
                                  icon: Icons.person_outline,
                                  controller: _prenomController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre prénom';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Veuillez entrer une adresse email valide';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Téléphone',
                                  keyboardType: TextInputType.phone,
                                  icon: Icons.phone_outlined,
                                  controller: _telController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre numéro de téléphone';
                                    }
                                    if (value.length < 10) {
                                      return 'Numéro de téléphone invalide';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Adresse',
                                  keyboardType: TextInputType.streetAddress,
                                  icon: Icons.location_on_outlined,
                                  controller: _adresseController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre adresse';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDateField(
                                  label: 'Date de naissance',
                                  controller: _dateNaissanceController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez sélectionner votre date de naissance';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildGenreDropdown(),
                                const SizedBox(height: 16),
                                _buildPhotoProfileSection(),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Mot de passe',
                                  isObscure: _obscurePassword,
                                  icon: Icons.lock_outlined,
                                  controller: _passwordController,
                                  onSuffixIconPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer un mot de passe';
                                    }
                                    if (value.length < 8) {
                                      return 'Le mot de passe doit contenir au moins 8 caractères';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Confirmer le mot de passe',
                                  isObscure: _obscureConfirmPassword,
                                  icon: Icons.lock_outlined,
                                  controller: _confirmPasswordController,
                                  onSuffixIconPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez confirmer votre mot de passe';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Les mots de passe ne correspondent pas';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Terms and Conditions Checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _acceptTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _acceptTerms = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          text: 'I agree to the ',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSmall,
                                            color: AppTheme.textSecondaryColor,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Sign Up Button
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: _acceptTerms ? AppTheme.primaryGradient : null,
                                    color: _acceptTerms ? null : Colors.grey.withOpacity(0.3),
                                    boxShadow: _acceptTerms ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ] : null,
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _acceptTerms ? () async {
                                      if (_formKey.currentState!.validate()) {
                                        await _handleSignUp();
                                      }
                                    } : null,
                                    child: Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeLarge,
                                        fontWeight: FontWeight.w600,
                                        color: _acceptTerms ? Colors.white : Colors.white.withOpacity(0.6),
                                        fontFamily: AppTheme.fontFamily,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Social Signup
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: AppTheme.textLightColor.withOpacity(0.3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Or sign up with',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeSmall,
                                          color: AppTheme.textSecondaryColor,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: AppTheme.textLightColor.withOpacity(0.3))),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildSocialButton(Icons.g_mobiledata, Colors.red),
                                    _buildSocialButton(Icons.facebook, Colors.blue),
                                    _buildSocialButton(Icons.apple, Colors.black),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Sign In Link
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account? ",
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeMedium,
                                          color: AppTheme.textSecondaryColor,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                        ),
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeMedium,
                                            color: AppTheme.primaryColor,
                                            fontFamily: AppTheme.fontFamily,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
