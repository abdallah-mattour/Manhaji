import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/duolingo_card.dart';

/// Shared building blocks for the privacy-policy and terms pages: an intro
/// paragraph, emoji-headed sections, and a Palestine-flag footer. Keeps both
/// legal screens visually consistent and RTL-correct.

class LegalIntro extends StatelessWidget {
  final String text;
  const LegalIntro({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.7,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}

class LegalSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const LegalSection({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DuolingoCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.8,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'صنع بحب في فلسطين 🇵🇸',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.textGray,
        ),
      ),
    );
  }
}
