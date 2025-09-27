import 'package:flutter/material.dart';

/// Custom theme extension for decorative properties
@immutable
class AppDecor extends ThemeExtension<AppDecor> {
  const AppDecor({
    required this.cardRadius,
    required this.chipRadius,
    required this.softShadows,
    required this.primaryGradient,
    required this.subtleGradient,
    required this.cardElevation,
  });

  final BorderRadius cardRadius;
  final BorderRadius chipRadius;
  final List<BoxShadow> softShadows;
  final LinearGradient primaryGradient;
  final LinearGradient subtleGradient;
  final double cardElevation;

  @override
  AppDecor copyWith({
    BorderRadius? cardRadius,
    BorderRadius? chipRadius,
    List<BoxShadow>? softShadows,
    LinearGradient? primaryGradient,
    LinearGradient? subtleGradient,
    double? cardElevation,
  }) {
    return AppDecor(
      cardRadius: cardRadius ?? this.cardRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      softShadows: softShadows ?? this.softShadows,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      subtleGradient: subtleGradient ?? this.subtleGradient,
      cardElevation: cardElevation ?? this.cardElevation,
    );
  }

  @override
  AppDecor lerp(AppDecor? other, double t) {
    if (other is! AppDecor) {
      return this;
    }
    return AppDecor(
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t) ?? cardRadius,
      chipRadius: BorderRadius.lerp(chipRadius, other.chipRadius, t) ?? chipRadius,
      softShadows: BoxShadow.lerpList(softShadows, other.softShadows, t) ?? softShadows,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ?? primaryGradient,
      subtleGradient: LinearGradient.lerp(subtleGradient, other.subtleGradient, t) ?? subtleGradient,
      cardElevation: (cardElevation * (1.0 - t)) + (other.cardElevation * t),
    );
  }
}

class AppTheme {
  // Enhanced Color Palette (matching EnhancedAppTheme)
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryLightColor = Color(0xFF8B5CF6); // Purple
  static const Color primaryDarkColor = Color(0xFF4338CA); // Dark Indigo
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFF10B981); // Success Green
  static const Color secondaryLightColor = Color(0xFF34D399);
  static const Color secondaryDarkColor = Color(0xFF059669);
  
  // Accent Colors
  static const Color accentColor = Color(0xFFF59E0B); // Amber
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Color(0xFFFAFBFC);
  
  // Text Colors
  static const Color textPrimaryColor = Color(0xFF1E293B);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color textLightColor = Color(0xFF94A3B8);
  
  // Border Colors
  static const Color borderColor = Color(0xFFE2E8F0);
  
  // Medical Specific Colors
  static const Color medicalRed = Color(0xFFEF4444);
  static const Color medicalOrange = Color(0xFFF59E0B);
  static const Color medicalYellow = Color(0xFFFBBF24);
  static const Color medicalPurple = Color(0xFF8B5CF6);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLightColor],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, cardColor],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundColor, Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
  );

  // Typography Constants
  static const String fontFamily = 'Inter'; // Modern, clean font
  
  // Font Sizes
  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 20.0;
  static const double fontSize3XLarge = 24.0;
  static const double fontSize4XLarge = 28.0;
  static const double fontSize5XLarge = 32.0;
  
  // Shadows
  static List<BoxShadow> get softShadows => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 6),
      spreadRadius: -3,
    ),
  ];
  
  static List<BoxShadow> get cardShadows => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    
    // Color Scheme - Material Design 3
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: backgroundColor,
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: fontSizeXXLarge,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        fontFamily: fontFamily,
      ),
      iconTheme: IconThemeData(color: primaryColor),
    ),
    
    // Text Theme with consistent fonts and sizes
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSize5XLarge,
        fontWeight: FontWeight.w900,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: fontSize4XLarge,
        fontWeight: FontWeight.w800,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: fontSize3XLarge,
        fontWeight: FontWeight.w700,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontSize: fontSizeXXLarge,
        fontWeight: FontWeight.w700,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: fontSizeXLarge,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: fontSizeLarge,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeLarge,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeLarge,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        fontFamily: fontFamily,
        height: 1.6,
      ),
      labelLarge: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: fontSizeXSmall,
        fontWeight: FontWeight.w500,
        color: textLightColor,
        fontFamily: fontFamily,
        height: 1.5,
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Tajawal',
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Tajawal',
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Tajawal',
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: textLightColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: textLightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: textLightColor,
        fontSize: 16,
        fontFamily: 'Tajawal',
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Tajawal',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        fontFamily: 'Tajawal',
      ),
    ),
    
    // Navigation Bar Theme (Material Design 3)
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: 0,
      indicatorColor: primaryColor.withOpacity(0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            fontFamily: 'Tajawal',
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          fontFamily: 'Tajawal',
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: primaryColor,
            size: 24,
          );
        }
        return IconThemeData(
          color: textSecondaryColor,
          size: 24,
        );
      }),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: textPrimaryColor,
      size: 24,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: textLightColor,
      thickness: 1,
      space: 1,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withValues(alpha: 0.1),
      selectedColor: primaryColor,
      disabledColor: textLightColor.withValues(alpha: 0.1),
      labelStyle: const TextStyle(
        color: primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Tajawal',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Extensions (decorative primitives)
    extensions: <ThemeExtension<dynamic>>[
      const AppDecor(
        cardRadius: BorderRadius.all(Radius.circular(16)),
        chipRadius: BorderRadius.all(Radius.circular(20)),
        softShadows: <BoxShadow>[
          BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
        primaryGradient: LinearGradient(
          colors: <Color>[primaryColor, primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        subtleGradient: LinearGradient(
          colors: <Color>[Color(0xFFE3F2FD), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        cardElevation: 4.0,
      ),
    ],
  );
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: Colors.black,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800]!,
        selectedColor: primaryColor,
        disabledColor: Colors.grey[700],
        secondarySelectedColor: secondaryColor,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }


}

