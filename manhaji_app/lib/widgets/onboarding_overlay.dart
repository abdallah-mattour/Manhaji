import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Simple one-time instruction overlay for novel question types.
///
/// Shown on first PRONUNCIATION / TRACING question so young learners know
/// what to do without an adult hovering. Persistence lives in
/// `LocalStorageService.seenPronunciationTip` / `seenTracingTip`.
///
/// Usage: show with `showDialog`, dismiss on tap anywhere.
class OnboardingOverlay extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  final Color accentColor;

  const OnboardingOverlay({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    required this.accentColor,
  });

  static Future<void> showPronunciation(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const OnboardingOverlay(
        emoji: '🎤',
        title: 'سؤال نطق!',
        body:
            'اضغط على زر الميكروفون واقرأ الكلمة بصوت واضح.\nيمكنك الاستماع للنموذج أولاً بالضغط على 🔊',
        accentColor: AppTheme.primaryPurple,
      ),
    );
  }

  static Future<void> showTracing(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const OnboardingOverlay(
        emoji: '✍️',
        title: 'سؤال تتبّع!',
        body:
            'اتبع شكل الحرف بإصبعك على الشاشة.\nعندما تنتهي اضغط زر "تحقق" للحصول على نجومك.',
        accentColor: AppTheme.primaryOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: AppTheme.textDark,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'فهمت!',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
