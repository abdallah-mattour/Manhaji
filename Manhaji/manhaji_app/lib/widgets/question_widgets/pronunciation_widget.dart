import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/pronunciation_score.dart';
import '../../models/quiz.dart';
import '../../utils/arabic_numerals.dart';
import '../../utils/text_direction.dart';
import '../voice_recorder_widget.dart';

class PronunciationWidget extends StatelessWidget {
  final Question question;
  final PronunciationScore? lastScore;
  final bool isAnswered;
  final bool isProcessing;
  final Future<void> Function(String audioPath) onRecordingComplete;
  final VoidCallback? onPlayTarget;

  /// Full English experience (2026-07-03): English-subject lessons show the
  /// chrome (instruction, processing, transcript label) in English.
  final bool english;

  const PronunciationWidget({
    super.key,
    required this.question,
    required this.lastScore,
    required this.isAnswered,
    required this.isProcessing,
    required this.onRecordingComplete,
    this.onPlayTarget,
    this.english = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TargetCard(
          text: question.questionText,
          onPlay: onPlayTarget,
        ),
        const SizedBox(height: 20),
        if (!isAnswered) ...[
          Text(
            english
                ? 'Tap and repeat in a clear voice'
                : 'اضغط وكرر بصوت واضح',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: AppTheme.textGray,
            ),
          ),
          VoiceRecorderWidget(
            enabled: !isProcessing,
            onRecordingComplete: onRecordingComplete,
            english: english,
          ),
        ],
        if (isAnswered && lastScore == null) ...[
          const SizedBox(height: 20),
          _ProcessingIndicator(english: english),
        ],
        if (lastScore != null) ...[
          const SizedBox(height: 20),
          _ScoreCard(score: lastScore!, english: english),
        ],
      ],
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  final bool english;

  const _ProcessingIndicator({this.english = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            english ? 'Checking your pronunciation...' : 'جاري تقييم النطق...',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final String text;
  final VoidCallback? onPlay;

  const _TargetCard({required this.text, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            AppTheme.primaryPurple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          if (onPlay != null)
            IconButton(
              onPressed: onPlay,
              icon: const Icon(Icons.volume_up_rounded,
                  size: 36, color: AppTheme.primaryBlue),
              tooltip: 'استمع',
            ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              // English pronunciation prompts (G3/G4 sentence reads) flow LTR.
              textDirection: directionOf(text),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final PronunciationScore score;
  final bool english;

  const _ScoreCard({required this.score, this.english = false});

  Color _color() {
    if (score.score >= 90) return AppTheme.primaryGreen;
    if (score.score >= 75) return AppTheme.primaryBlue;
    if (score.score >= 60) return AppTheme.primaryOrange;
    return AppTheme.primaryRed;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Column(
        children: [
          // Audit-3 fix (2026-05-15): display in Arabic-Indic digits to
          // match the rest of the (Arabic-first) UI. Was previously
          // "89 / 100" which mixed scripts inside an Arabic context.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                arabicInt(score.score),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
              Text(
                ' / ١٠٠',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: c.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            score.rating,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
          if (score.transcribedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    english ? 'What we heard:' : 'ما سمعناه:',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.transcribedText,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (score.feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              score.feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
          ],
          // Feature B (2026-04-29): phoneme-level coaching from Gemini.
          // Only renders when the backend supplied a non-blank guidance string,
          // so the legacy zero-AI path stays clean.
          if (score.guidance != null && score.guidance!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CoachingCard(
              guidance: score.guidance!,
              phonemeErrors: score.phonemeErrors,
              english: english,
            ),
          ],
        ],
      ),
    );
  }
}

class _CoachingCard extends StatelessWidget {
  final String guidance;
  final List<String> phonemeErrors;
  final bool english;

  const _CoachingCard({
    required this.guidance,
    required this.phonemeErrors,
    this.english = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.primaryYellow.withValues(alpha: 0.45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                english ? "Teacher's tip" : 'تلميح المعلم',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            guidance,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
          if (phonemeErrors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: phonemeErrors
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.primaryRed
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          p,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
