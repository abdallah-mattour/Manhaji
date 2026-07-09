import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/pronunciation_score.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';
import '../voice_recorder_widget.dart';

/// Tier 4 — READING: the child reads the passage aloud; the backend
/// transcribes the recording and scores it word-by-word. After scoring,
/// every passage word is colored in place: green = read correctly,
/// red = missed/misread.
///
/// Same callback contract as [PronunciationWidget] — the learning screen
/// reuses the entire pronunciation submission pipeline unchanged.
class ReadingWidget extends StatelessWidget {
  final Question question;
  final PronunciationScore? lastScore;
  final bool isAnswered;
  final bool isProcessing;
  final Future<void> Function(String audioPath) onRecordingComplete;
  final VoidCallback? onPlayTarget;

  /// Full English experience (2026-07-03): English-subject lessons show all
  /// chrome (instruction, processing, listen button, result line) in English.
  final bool english;

  const ReadingWidget({
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
        _PassageCard(
          passage: question.questionText,
          wordResults: lastScore?.wordResults ?? const [],
          onPlay: onPlayTarget,
          english: english,
        ),
        const SizedBox(height: 20),
        if (!isAnswered) ...[
          Text(
            english
                ? 'Read the sentence out loud 📖'
                : 'اقرأ الجملة بصوتٍ واضح 📖',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                  english
                      ? 'Checking your reading...'
                      : 'جاري تقييم القراءة...',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (lastScore != null) ...[
          const SizedBox(height: 16),
          _ReadingResultCard(score: lastScore!, english: english),
        ],
      ],
    );
  }
}

/// The passage rendered word-by-word. Before scoring all words are neutral;
/// after scoring each word takes its result color.
class _PassageCard extends StatelessWidget {
  final String passage;
  final List<WordScore> wordResults;
  final VoidCallback? onPlay;
  final bool english;

  const _PassageCard({
    required this.passage,
    required this.wordResults,
    this.onPlay,
    this.english = false,
  });

  @override
  Widget build(BuildContext context) {
    final scored = wordResults.isNotEmpty;
    // Fall back to splitting the passage when unscored so both states render
    // through the same chip layout (no jarring relayout after scoring).
    final words = scored
        ? wordResults
        : passage
            .split(RegExp(r'\s+'))
            .where((w) => w.trim().isNotEmpty)
            .map((w) => WordScore(word: w, correct: true))
            .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: directionOf(passage),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final w in words)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !scored
                          ? Colors.transparent
                          : w.correct
                              ? AppTheme.primaryGreen.withValues(alpha: 0.14)
                              : AppTheme.primaryRed.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      w.word,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.6,
                        color: !scored
                            ? AppTheme.textDark
                            : w.correct
                                ? AppTheme.primaryGreenDeep
                                : AppTheme.primaryRedDeep,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onPlay != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.volume_up_rounded,
                  color: AppTheme.primaryBlue),
              label: Text(
                english ? 'Listen to the sentence' : 'استمع للجملة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Accuracy + rating summary shown under the colored passage.
class _ReadingResultCard extends StatelessWidget {
  final PronunciationScore score;
  final bool english;

  const _ReadingResultCard({required this.score, this.english = false});

  @override
  Widget build(BuildContext context) {
    final color = score.score >= 75
        ? AppTheme.primaryGreen
        : score.score >= 60
            ? AppTheme.primaryOrange
            : AppTheme.primaryRed;
    final correctCount =
        score.wordResults.where((w) => w.correct).length;
    final totalWords = score.wordResults.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.score}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                score.rating,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (totalWords > 0) ...[
            const SizedBox(height: 6),
            Text(
              english
                  ? 'You read $correctCount of $totalWords words correctly'
                  : 'قرأت $correctCount من $totalWords كلمات بشكل صحيح',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
              ),
            ),
          ],
          if (score.feedback.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              score.feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
