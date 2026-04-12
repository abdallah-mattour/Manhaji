import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../core//theme/app_colors.dart';
import '../../providers/learning_provider.dart';

class LearningCompletionScreen extends StatefulWidget {
  final String lessonTitle;
  final int lessonId;

  const LearningCompletionScreen({
    super.key,
    required this.lessonTitle,
    required this.lessonId,
  });

  @override
  State<LearningCompletionScreen> createState() =>
      _LearningCompletionScreenState();
}

class _LearningCompletionScreenState extends State<LearningCompletionScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _starsController;
  late List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _starAnimations = List.generate(3, (i) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 1.3), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
      ]).animate(
        CurvedAnimation(
          parent: _starsController,
          curve: Interval(i * 0.15, 0.5 + i * 0.15, curve: Curves.elasticOut),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      _starsController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Consumer<LearningProvider>(
              builder: (context, provider, _) {
                final result = provider.attemptResult;
                final totalStars = provider.totalStars;
                final maxStars = provider.maxPossibleStars;
                final questionCount = provider.questionCount;
                final correctCount = result?.correctAnswers ?? 0;
                final score = result?.score?.round() ?? 0;
                final points = result?.pointsEarned ?? 0;

                // Star rating out of 3 for display
                final starRatio = maxStars > 0 ? totalStars / maxStars : 0.0;
                final displayStars = starRatio >= 0.8
                    ? 3
                    : starRatio >= 0.5
                    ? 2
                    : 1;

                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          _getMessage(score.toDouble()),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.lessonTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Animated stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final earned = i < displayStars;
                            return ScaleTransition(
                              scale: _starAnimations[i],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Icon(
                                  earned
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 64,
                                  color: earned
                                      ? AppColors.warning
                                      : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalStars ⭐',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Stats grid
                        Row(
                          children: [
                            _buildStatCard(
                              '$score%',
                              'النتيجة',
                              AppColors.primary,
                              Icons.emoji_events_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              '$correctCount/$questionCount',
                              'إجابات صحيحة',
                              AppColors.secondary,
                              Icons.check_circle_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatCard(
                              '+$points',
                              'نقاط مكتسبة',
                              AppColors.accent,
                              Icons.bolt_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              '$totalStars',
                              'نجوم مجموعة',
                              AppColors.warning,
                              Icons.star_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/home'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'العودة للدروس 📚',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (score < 50) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                context.pop();
                                // The subject_lessons_screen will allow re-entering
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                side: const BorderSide(
                                  color: AppColors.accent,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'أعد المحاولة 🔄',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                gravity: 0.15,
                colors: const [
                  AppColors.primary,
                  AppColors.warning,
                  AppColors.accent,
                  AppColors.secondary,
                  AppColors.accent2,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessage(double score) {
    if (score >= 90) return 'ممتاز! أنت نجم! 🌟';
    if (score >= 70) return 'أحسنت! عمل رائع! 👏';
    if (score >= 50) return 'جيد! استمر بالمحاولة! 💪';
    return 'لا بأس! حاول مرة أخرى! 🤗';
  }
}
