// Pepper Clinical — Design System & Theme
import 'package:flutter/material.dart';

class PepperColors {
  static const purple     = Color(0xFF7C3AED);
  static const purpleLight= Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF6D28D9);
  static const lavender   = Color(0xFFEDE9FE);
  static const dark       = Color(0xFF2D1B69);
  static const darkMid    = Color(0xFF4C1D95);
  static const gray       = Color(0xFF6B7280);
  static const lightGray  = Color(0xFFF9FAFB);
  static const bgGrad1    = Color(0xFFF0EDF8);
  static const bgGrad2    = Color(0xFFE8E3F4);
  static const green      = Color(0xFF059669);
  static const red        = Color(0xFFDC2626);
  static const gold       = Color(0xFFD97706);
  static const teal       = Color(0xFF0D9488);
  static const sessionBg  = Color(0xFF0D0D1A);
  static const sessionCard= Color(0xFF111128);
}

class PepperTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.fromSeed(
      seedColor: PepperColors.purple,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: PepperColors.bgGrad1,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: PepperColors.dark,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: PepperColors.dark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PepperColors.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F5FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x44A78BFA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x44A78BFA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PepperColors.purple, width: 2),
      ),
    ),
  );
}

// Gradient backgrounds
class PepperGradients {
  static const landing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PepperColors.bgGrad1, PepperColors.bgGrad2, Color(0xFFF4F1FA)],
  );
  static const button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [PepperColors.purpleDark, PepperColors.purple],
  );
  static const session = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PepperColors.sessionBg, Color(0xFF0A0A1E)],
  );
}
