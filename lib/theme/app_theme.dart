import 'package:flutter/material.dart';

class AppTheme {
  // Modern Color Palette
  static const Color primaryEmerald = Color(0xFF00A36C);
  static const Color secondaryTeal = Color(0xFF008080);
  static const Color deepIndigo = Color(0xFF1A1A2E);
  static const Color softGrey = Color(0xFFF8F9FA);
  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color modernBlack = Color(0xFF121212);

  // Compatibility colors (Modernized)
  static const Color sageGreen = primaryEmerald;
  static const Color deepBrown = deepIndigo;
  static const Color vintageBeige = softGrey;
  static const Color accentGold = Color(0xFFFFD700);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryEmerald,
      primary: primaryEmerald,
      secondary: secondaryTeal,
      surface: Colors.white,
      background: softGrey,
    ),
    scaffoldBackgroundColor: softGrey,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: deepIndigo,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      displayMedium: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      displaySmall: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      headlineLarge: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      headlineMedium: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      headlineSmall: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      titleLarge: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      titleMedium: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      titleSmall: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      bodyLarge: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      bodyMedium: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
      bodySmall: TextStyle(color: deepIndigo, fontFamily: 'Cairo'),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryEmerald,
      unselectedItemColor: Colors.grey,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryEmerald,
      brightness: Brightness.dark,
      primary: primaryEmerald,
      secondary: secondaryTeal,
      surface: const Color(0xFF161625),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E2C),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF161625), // Deeper input color
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      counterStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: AppTheme.primaryEmerald,
      suffixIconColor: AppTheme.primaryEmerald,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      displayMedium: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      displaySmall: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      headlineLarge: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      headlineMedium: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      headlineSmall: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      titleLarge: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      titleMedium: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      titleSmall: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      bodySmall: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161625),
      selectedItemColor: primaryEmerald,
      unselectedItemColor: Colors.grey,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
