import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/pronunciation_score.dart';
import '../../models/quiz.dart';
import '../voice_recorder_widget.dart';

class PronunciationWidget extends StatelessWidget {
  final Question question;
  final PronunciationScore? lastScore;
  final bool isAnswered;
  final bool isProcessing;
  final Future<void> Function(String audioPath) onRecordingComplete;
  final VoidCallback? onPlayTarget;

  const PronunciationWidget({
    super.key,
    required this.question,
    required this.lastScore,
    required this.isAnswered,
    required this.isProcessing,
    required this.onRecordingComplete,
    this.onPlayTarget,
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
          const Text(
            'اضغط وكرر بصوت واضح',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: AppTheme.textGray,
            ),
          ),
          VoiceRecorderWidget(
            enabled: !isProcessing,
            onRecordingComplete: onRecordingComplete,
          ),
        ],
        if (isAnswered && lastScore == null) ...[
          const SizedBox(height: 20),
          const _ProcessingIndicator(),
        ],
        if (lastScore != null) ...[
          const SizedBox(height: 20),
          _ScoreCard(score: lastScore!),
        ],
      ],
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryPurple,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'جاري تقييم النطق...',
            style: TextStyle(
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

  const _ScoreCard({required this.score});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.score}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
              Text(
                ' / 100',
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
                  const Text(
                    'ما سمعناه:',
                    style: TextStyle(
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
        ],
      ),
    );
  }
}
