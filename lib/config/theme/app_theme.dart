import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Ubuntu',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D6A4F), // Forest green
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      surface: const Color(0xFF242424), // Lighter surface for better contrast with background
    ),
    scaffoldBackgroundColor: const Color(0xFF141414), // Dark gray background
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF242424), // Nice medium gray
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'Ubuntu',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D), // Medium-light gray for excellent contrast
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white),
      displayMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white),
      headlineMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white),
      headlineSmall: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white),
      titleLarge: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white),
      titleMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white),
      titleSmall: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE8E8E8)),
      bodyLarge: TextStyle(
          fontFamily: 'Ubuntu', fontSize: 16, color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(
          fontFamily: 'Ubuntu', fontSize: 14, color: Color(0xFFC0C0C0)),
      bodySmall: TextStyle(
          fontFamily: 'Ubuntu', fontSize: 12, color: Color(0xFFA0A0A0)),
      labelLarge: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white),
      labelMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFC0C0C0)),
      labelSmall: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFA0A0A0)),
    ),
    iconTheme: const IconThemeData(color: Colors.white, size: 24),
    dividerColor: const Color(0xFF383838), // Lighter gray divider for better contrast
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A4F),
        side: const BorderSide(color: Color(0xFF2D6A4F), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Ubuntu',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D6A4F), // Forest green
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      surface: const Color(0xFFFAFAFA), // Off-white for better contrast
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1B1B)),
      iconTheme: const IconThemeData(color: Color(0xFF1B1B1B)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B1B1B)),
      displayMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B1B1B)),
      headlineMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1B1B)),
      headlineSmall: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1B1B)),
      titleLarge: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1B1B)),
      titleMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2B2B2B)),
      titleSmall: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF3B3B3B)),
      bodyLarge: TextStyle(
          fontFamily: 'Ubuntu', fontSize: 16, color: Color(0xFF404040)),
      bodyMedium: TextStyle(
          fontFamily: 'Ubuntu', fontSize: 14, color: Color(0xFF616161)),
      bodySmall: TextStyle(
          fontFamily: 'Ubuntu', fontSize: 12, color: Color(0xFF757575)),
      labelLarge: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1B1B1B)),
      labelMedium: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF616161)),
      labelSmall: TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575)),
    ),
    dividerColor: const Color(0xFFE8E8E8),
    iconTheme: const IconThemeData(color: Color(0xFF1B1B1B), size: 24),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D6A4F),
        side: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static ThemeData systemTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }
}

class AppColors {
  // Primary colors
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color forestGreenDark = Color(0xFF1B4332);
  static const Color forestGreenLight = Color(0xFF52B788);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF2D6A4F);

  // Dark theme - Pitch black optimized for OLED
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkCardBg = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFC0C0C0);
  static const Color darkTextTertiary = Color(0xFFA0A0A0);
  static const Color darkBorder = Color(0xFF303030);

  // Light theme - Better contrast
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightCardBg = Colors.white;
  static const Color lightText = Color(0xFF1B1B1B);
  static const Color lightTextSecondary = Color(0xFF616161);
  static const Color lightTextTertiary = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE8E8E8);

  // Category colors
  static const Color categoryPdf = Color(0xFFE53935);
  static const Color categoryDoc = Color(0xFF2196F3);
  static const Color categorySheet = Color(0xFF43A047);
  static const Color categoryData = Color(0xFFFB8C00);
  static const Color categorySlide = Color(0xFFD32F2F);
  static const Color categoryDefault = Color(0xFF90A4AE);

  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static Color textTertiaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextTertiary
        : lightTextTertiary;
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  static Color bgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBg : lightBg;
  }

  static Color cardBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBg
        : lightCardBg;
  }
}
