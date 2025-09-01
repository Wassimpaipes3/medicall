import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnhancedAppTheme {
  // Enhanced Color Palette
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color neutralGray = Color(0xFF64748B);
  
  // Secondary Colors
  static const Color cyanBlue = Color(0xFF06B6D4);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color pinkRose = Color(0xFFEC4899);
  static const Color violetPurple = Color(0xFF7C3AED);
  
  // Background Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFFAFBFC),
    ],
  );
  
  // Enhanced Primary Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, primaryPurple],
  );
  
  static const LinearGradient blueGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF10B981)], // Blue to Green
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successGreen, Color(0xFF059669)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warningOrange, Color(0xFFD97706)],
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dangerRed, Color(0xFFDC2626)],
  );
  
  // Multi-color gradients for special effects
  static const LinearGradient rainbowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryIndigo,
      primaryPurple,
      accentAmber,
    ],
    stops: [0.0, 0.6, 1.0],
  );
  
  static const LinearGradient cyberpunkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cyanBlue,
      primaryPurple,
      pinkRose,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Enhanced Shadow System
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 6),
      spreadRadius: -3,
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 30,
      offset: const Offset(0, 15),
      spreadRadius: -8,
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 25,
      offset: const Offset(0, 10),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 40,
      offset: const Offset(0, 20),
      spreadRadius: -10,
    ),
  ];
  
  // Colored Shadows
  static List<BoxShadow> coloredShadow(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 25,
      offset: const Offset(0, 8),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: color.withOpacity(opacity * 0.5),
      blurRadius: 40,
      offset: const Offset(0, 20),
      spreadRadius: -8,
    ),
  ];
  
  // Blue-Green Button Shadow
  static List<BoxShadow> get blueGreenShadow => [
    BoxShadow(
      color: const Color(0xFF3B82F6).withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: const Color(0xFF10B981).withOpacity(0.3),
      blurRadius: 30,
      offset: const Offset(0, 15),
      spreadRadius: -8,
    ),
  ];
  
  // Enhanced Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.1,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  // Enhanced Button Styles
  static ButtonStyle get enhancedElevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
  
  // Enhanced Input Decoration
  static InputDecoration enhancedInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Color color = primaryIndigo,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                prefixIcon,
                color: color.withOpacity(0.7),
                size: 20,
              ),
            )
          : null,
      labelStyle: TextStyle(
        color: color.withOpacity(0.8),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontWeight: FontWeight.w400,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.all(16),
    );
  }
  
  // Enhanced Container Decorations
  static BoxDecoration enhancedCardDecoration({
    bool isSelected = false,
    Color primaryColor = primaryIndigo,
    Color secondaryColor = primaryPurple,
    Color tertiaryColor = accentAmber,
  }) {
    return BoxDecoration(
      gradient: isSelected 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.9),
                secondaryColor.withOpacity(0.8),
                tertiaryColor.withOpacity(0.7),
              ],
              stops: const [0.0, 0.6, 1.0],
            )
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
                primaryColor.withOpacity(0.05),
              ],
            ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isSelected 
            ? Colors.white.withOpacity(0.3)
            : primaryColor.withOpacity(0.2),
        width: 2,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: secondaryColor.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
    );
  }
  
  // Consistent Booking Button Decoration
  static BoxDecoration bookingButtonDecoration({
    bool enabled = true,
    bool isLoading = false,
  }) {
    return BoxDecoration(
      gradient: enabled && !isLoading
          ? blueGreenGradient
          : LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade400,
              ],
            ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: enabled && !isLoading
          ? blueGreenShadow
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }
  
  static BoxDecoration glassmorphicDecoration({
    double opacity = 0.15,
    Color borderColor = Colors.white,
    double borderOpacity = 0.2,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(opacity * 0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor.withOpacity(borderOpacity),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  
  // Enhanced Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        brightness: Brightness.light,
      ),
      fontFamily: 'Inter', // Assuming Inter font is available
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF0F172A),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: enhancedElevatedButtonStyle,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryIndigo.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primaryIndigo.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryIndigo,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: dangerRed,
            width: 1.5,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelSmall: caption,
      ),
    );
  }
  
  // Dark theme variant (future enhancement)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
    );
  }
}

// Utility Classes for Enhanced Animations
class EnhancedAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration longDuration = Duration(milliseconds: 600);
  
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve elasticOut = Curves.elasticOut;
}

// Utility for creating enhanced widgets
class EnhancedWidgets {
  static Widget gradientText(
    String text, {
    required Gradient gradient,
    TextStyle? style,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
  
  static Widget floatingParticle({
    double size = 6.0,
    Color color = Colors.white,
    double opacity = 0.8,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
  
  static Widget enhancedIcon({
    required IconData icon,
    required bool isSelected,
    Color primaryColor = EnhancedAppTheme.primaryIndigo,
    double size = 28.0,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isSelected
            ? RadialGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                ],
              )
            : RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.15),
                  primaryColor.withOpacity(0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.black.withOpacity(0.1)
                : primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: size,
      ),
    );
  }
}
