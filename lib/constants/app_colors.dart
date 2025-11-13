import 'package:flutter/material.dart';

/// Centralized color definitions for the CyGuardian app
/// All colors used throughout the app should be imported from this file
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF2A76C9);

  // Background Colors
  static const Color scaffoldBackgroundLight =
      Color(0xFFF5F5F5); // Colors.grey[50]
  static const Color scaffoldBackgroundDark = Color(0xFF1A202C);

  // Card Colors
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF2D3748);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF4A5568);
  static const Color borderFocused = Color(0xFF2A76C9);

  // Text Colors (Light Theme)
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF4A5568);
  static const Color textTertiaryLight = Color(0xFF718096);

  // Text Colors (Dark Theme)
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFE2E8F0);
  static const Color textTertiaryDark = Color(0xFFA0AEC0);

  // Risk Assessment Colors
  static const Color riskLow = Colors.green;
  static const Color riskMedium = Colors.orange;
  static const Color riskHigh = Colors.red;

  // Status Colors
  static const Color error = Colors.red;

  // Semantic Colors
  static const Color blue = Colors.blue;
  static const Color green = Colors.green;
  static const Color red = Colors.red;
  static const Color orange = Colors.orange;
  static const Color blueGrey = Colors.blueGrey;

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Grey Shades (for convenience)
  static Color grey200 = Colors.grey[200]!;

  // Navigation Bar
  static const Color navBarBackgroundLight = Colors.white;
  static const Color navBarBackgroundDark = Color(0xFF1A202C);
  static const Color navBarIndicator = Color.fromARGB(51, 42, 118, 201);
  static const Color navBarLabelLight = Color(0xFF2A4365);
  static const Color navBarLabelDark = Colors.white;

  // Input Field Colors
  static const Color inputFillLight = Colors.white;
  static const Color inputFillDark = Color(0xFF2D3748);

  // Helper method to get risk color based on score
  static Color getRiskColor(double riskScore) {
    if (riskScore < 30) {
      return riskLow;
    } else if (riskScore < 70) {
      return riskMedium;
    } else {
      return riskHigh;
    }
  }

  // Helper method to get text color based on theme
  static Color getTextColor(BuildContext context,
      {bool isSecondary = false, bool isTertiary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isTertiary) {
      return isDark ? textTertiaryDark : textTertiaryLight;
    } else if (isSecondary) {
      return isDark ? textSecondaryDark : textSecondaryLight;
    } else {
      return isDark ? textPrimaryDark : textPrimaryLight;
    }
  }
}
