import 'package:flutter/material.dart';

// Restored and updated color constants for HanapRaket theme
const Color secondary = Color(0xFF27548A); // Updated to warm yellow/gold
const Color primary = Color(0xFF27548A); // Updated to vibrant blue
const Color secondaryPrimary = Color(0xFFDDA853); // Updated to lively red

const Color cloudWhite = Color(0xFFF5F5F5); // Updated to light neutral
const Color textBlack = Color(0xFF212121); // Kept as is

const Color ashGray = Color(0xFFB0BEC5); // Kept as is
const Color jetBlack = Color(0xFF000000); // Kept as is
const Color plainWhite = Color.fromARGB(255, 255, 255, 255); // Kept as is
const backgroundColor = Color(0xFFF5F5F5); // Updated to match background

class AppColors {
  static const MaterialColor primary = MaterialColor(
    0xFF1565C0, // Vibrant blue
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );
  static const Color secondary = Color(0xFFFFC107); // Warm yellow/gold
  static const Color accent = Color(0xFFD32F2F); // Lively red
  static const Color background = Color(0xFFF5F5F5); // Light neutral
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onAccent = Colors.white;
}
