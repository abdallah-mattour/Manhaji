// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get titleLarge => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get caption => const TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  // Dark Mode versions
  static TextStyle get headlineLargeDark =>
      headlineLarge.copyWith(color: AppColors.textPrimaryDark);

  static TextStyle get bodyLargeDark =>
      bodyLarge.copyWith(color: AppColors.textPrimaryDark);
}
