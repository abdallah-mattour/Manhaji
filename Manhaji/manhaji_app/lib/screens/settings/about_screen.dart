import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../config/constants.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/vibrant_background.dart';
import 'legal_section.dart';

/// "عن التطبيق" — app identity, links to the legal pages, and the OpenMoji
/// attribution required by its CC BY-SA 4.0 license (the emoji assets ship with
/// an ATTRIBUTION.txt but were credited nowhere in-app until now).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عن التطبيق'),
          backgroundColor: AppTheme.backgroundLight,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // App hero
                DuolingoCard(
                  padding: const EdgeInsets.all(24),
                  borderColor: AppTheme.primaryGreen,
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('📚', style: TextStyle(fontSize: 44)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'الإصدار ${AppConstants.appVersion}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تطبيق تعليمي ذكي يساعد طلاب المرحلة الابتدائية على '
                        'التعلّم بطريقة ممتعة ومخصّصة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.7,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'سياسة الخصوصية',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'شروط الاستخدام',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                ),
                const SizedBox(height: 12),

                // OpenMoji license attribution (CC BY-SA 4.0).
                const LegalSection(
                  emoji: '🎨',
                  title: 'حقوق الرموز التعبيرية',
                  body:
                      'تستخدم بعض الرسوم في التطبيق رموز OpenMoji، وهي متاحة '
                      'بموجب رخصة CC BY-SA 4.0. شكراً لمشروع OpenMoji '
                      '(openmoji.org).',
                ),
                const SizedBox(height: 8),
                const LegalFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
