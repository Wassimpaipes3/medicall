import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:firstv/core/theme.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                                  label: 'Full Name',
                                  keyboardType: TextInputType.name,
                                  icon: Icons.person_outlined,
                                  controller: _nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    if (value.split(' ').length < 2) {
                                      return 'Please enter your first and last name';
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
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Password',
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
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'Confirm Password',
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
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
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
                                    onPressed: _acceptTerms ? () {
                                      if (_formKey.currentState!.validate()) {
                                        Navigator.pushReplacementNamed(context, '/home');
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
