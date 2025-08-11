import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Theme Colors
  static const Color primaryBlue = Color(0xFF5B67FD);
  static const Color accentRed = Color(0xFFFE6D6D);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentOrange = Color(0xFFF2994A);
  static const Color lightGrey = Color(0xFFF6F8FF);
  static const Color darkText = Color(0xFF333333);
  static const Color lightText = Color(0xFF828282);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Background Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B67FD),
      Color(0xFFFE6D6D),
    ],
  );
  
  static final TextTheme _textTheme = GoogleFonts.poppinsTextTheme(
    const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 24, color: darkText),
      headlineMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: darkText),
      headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: darkText),
      bodyLarge: TextStyle(fontWeight: FontWeight.normal, fontSize: 16, color: darkText),
      bodyMedium: TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: lightText),
      titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: lightText),
    )
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentRed,
      surface: cardBackground,
      onPrimary: white,
      onSecondary: white,
      onSurface: darkText,
    ),
    textTheme: _textTheme,
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Dark Theme (using light theme for now as per design)
  static ThemeData darkTheme = lightTheme;
} 