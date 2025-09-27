import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:firstv/core/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isProviderMode = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    bool isObscure = false,
    TextInputType? keyboardType,
    IconData? icon,
    TextEditingController? controller,
    VoidCallback? onSuffixIconPressed,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          if (label == 'Password' && value.length < 6) {
            return 'Password must be at least 6 characters';
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
          // Handle social login
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
                                        Icons.local_hospital,
                                        size: 40,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Welcome Back',
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
                                      _isProviderMode 
                                          ? 'Access your healthcare provider dashboard'
                                          : 'Sign in to continue with MediCall',
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
                                const SizedBox(height: 24),

                                // Provider/Patient Toggle
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isProviderMode = false;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: !_isProviderMode
                                                  ? AppTheme.primaryColor.withOpacity(0.2)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: !_isProviderMode
                                                    ? AppTheme.primaryColor.withOpacity(0.3)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  color: !_isProviderMode
                                                      ? AppTheme.primaryColor
                                                      : Colors.white.withOpacity(0.7),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Patient',
                                                  style: TextStyle(
                                                    color: !_isProviderMode
                                                        ? AppTheme.primaryColor
                                                        : Colors.white.withOpacity(0.7),
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: AppTheme.fontFamily,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isProviderMode = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _isProviderMode
                                                  ? AppTheme.primaryColor.withOpacity(0.2)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _isProviderMode
                                                    ? AppTheme.primaryColor.withOpacity(0.3)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.local_hospital,
                                                  color: _isProviderMode
                                                      ? AppTheme.primaryColor
                                                      : Colors.white.withOpacity(0.7),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Provider',
                                                  style: TextStyle(
                                                    color: _isProviderMode
                                                        ? AppTheme.primaryColor
                                                        : Colors.white.withOpacity(0.7),
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: AppTheme.fontFamily,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Demo Info for Provider Mode
                                if (_isProviderMode)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Provider Demo Access',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                            fontFamily: AppTheme.fontFamily,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Use any email and password (min 6 characters) to access the provider dashboard with appointment management, navigation, and earnings tracking.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                            fontFamily: AppTheme.fontFamily,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // Form Fields
                                _buildTextField(
                                  label: 'Email',
                                  keyboardType: TextInputType.emailAddress,
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                ),
                                const SizedBox(height: 20),
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
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: AppTheme.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
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
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        // Show loading indicator
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );

                                        try {
                                          // Authenticate using Firebase Auth
                                          final authService = AuthService();
                                          final result = await authService.signIn(
                                            _emailController.text.trim(),
                                            _passwordController.text,
                                          );

                                          // Hide loading dialog
                                          Navigator.of(context).pop();

                                          if (result['success'] == true) {
                                            // Success - navigate based on user role
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Login successful!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            
                                            // Navigate to the route returned by role redirect service
                                            final redirectRoute = result['redirectRoute'] ?? '/home';
                                            Navigator.pushReplacementNamed(context, redirectRoute);
                                          } else {
                                            // Login failed
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(result['error'] ?? 'Invalid email or password'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          // Hide loading dialog
                                          Navigator.of(context).pop();
                                          
                                          // Show error message
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Login failed: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Text(
                                      _isProviderMode ? 'Sign In as Provider' : 'Sign In as Patient',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeLarge,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: AppTheme.fontFamily,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Forgot Password
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/forget-password');
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeMedium,
                                        color: AppTheme.primaryColor,
                                        fontFamily: AppTheme.fontFamily,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Social Login
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: AppTheme.textLightColor.withOpacity(0.3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Or continue with',
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

                                // Sign Up Link
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeMedium,
                                          color: AppTheme.textSecondaryColor,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/signup');
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                        ),
                                        child: Text(
                                          'Sign Up',
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