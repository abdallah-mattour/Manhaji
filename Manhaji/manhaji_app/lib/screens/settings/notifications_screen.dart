import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/vibrant_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.shapes,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 52,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'الإشعارات غير مفعّلة حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                DuolingoCard(
                  padding: const EdgeInsets.all(18),
                  child: const Text(
                    'سيتم إضافة نظام الإشعارات في إصدار قادم من التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
