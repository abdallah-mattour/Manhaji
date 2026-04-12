// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// لوحة الألوان الكاملة للتطبيق (Light + Dark Mode)
/// الفائدة: تقدر تغير أي لون في التطبيق كله من هنا بسهولة
class AppColors {
  // ====================== Light Mode ======================
  static const Color primary = Color(0xFF22C55E); // أخضر نعناعي جذاب
  static const Color secondary = Color(0xFF0EA5E9); // أزرق سماوي
  static const Color accent = Color(0xFFF97316); // برتقالي دافئ
  static const Color accent2 = Color(0xFF8B5CF6); // بنفسجي سحري (للإسلاميات)

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E2937);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ====================== Dark Mode ======================
  static const Color primaryDark = Color(0xFF4ADE80);
  static const Color secondaryDark = Color(0xFF38BDF8);
  static const Color accentDark = Color(0xFFFB923C);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E2937);
  static const Color cardDark = Color(0xFF334155);

  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textLightDark = Color(0xFF94A3B8);

  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);

  static const List<Color> subjectColors = [
    Color(0xFF2196F3), // أزرق - اللغة العربية
    Color(0xFF22C55E), // أخضر - الرياضيات
    Color(0xFF9C27B0), // بنفسجي - التربية الإسلامية
    Color(0xFFFF9800), // برتقالي - العلوم
  ];

  static const List<Color> subjectLightColors = [
    Color(0xFFE3F2FD), // أزرق فاتح
    Color(0xFFE8F5E9), // أخضر فاتح
    Color(0xFFF3E5F5), // بنفسجي فاتح
    Color(0xFFFFF3E0), // برتقالي فاتح
  ];
}
