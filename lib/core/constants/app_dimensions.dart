// lib/core/constants/app_dimensions.dart
import 'package:flutter/material.dart';

class AppDimensions {
  // Base unit for scaling
  static const double base = 8.0;

  // Padding & Margin
  static const double paddingXS = base; // 8
  static const double paddingS = base * 1.5; // 12
  static const double paddingM = base * 2; // 16
  static const double paddingL = base * 3; // 24
  static const double paddingXL = base * 4; // 32
  static const double paddingXXL = base * 5; // 40

  // Border Radius (Child-friendly rounded design)
  static const double radiusS = 16.0;
  static const double radiusM = 20.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 28.0;
  static const double radiusXXL = 32.0;

  // Component Heights
  static const double buttonHeight = 56.0;
  static const double largeButtonHeight = 62.0;
  static const double appBarHeight = 70.0;

  // Icon Sizes
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Default Screen Padding
  static EdgeInsets get screenPadding =>
      const EdgeInsets.symmetric(horizontal: paddingL, vertical: paddingM);
}
