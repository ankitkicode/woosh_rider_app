import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color primaryPinkDark = Color(0xFFD81B60);
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color bodyText = Color(0xFF3D3D3D);
  static const Color lightGray = Color(0xFF757575);
  static const Color hintGray = Color(0xFFAAAAAA);
  static const Color lightPink = Color(0xFFFFF0F5);
  static const Color borderPink = Color(0xFFFFC0CB);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color shadowPink = Color(0x20E91E63);
  static const Color inputBackground = Color(0xFFF8F8F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFFBFBFB);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color cardShadow = Color(0x1A000000);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color onlineGreen = Color(0xFF00C853);
  static const Color offlineGray = Color(0xFF9E9E9E);

  // KYC step colors
  static const Color kycStepActive = Color(0xFFE91E63);
  static const Color kycStepCompleted = Color(0xFF4CAF50);
  static const Color kycStepPending = Color(0xFFE0E0E0);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE8F0), Color(0xFFFFFFFF)],
  );

  static const LinearGradient kycHeaderGradient = LinearGradient(
    colors: [Color(0xFFD81B60), Color(0xFFAD1457)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onlineGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
  );
}
