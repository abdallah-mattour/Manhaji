import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/vibrant_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عن التطبيق'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // App icon + name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 56,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'منهجي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الإصدار $_version',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Description
              DuolingoCard(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'منهجي منصة تعليمية ذكية تساعد الطلاب على التعلم بطريقة شخصية، وتوفر متابعة للتقدم، وتقارير، وتجربة تعليمية تفاعلية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
