import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../app/theme.dart';
import '../../providers/learning_provider.dart';
import '../../providers/student_assigned_quiz_provider.dart';
import '../../screens/rewards/rewards_screen.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/mascot.dart';
import '../../widgets/vibrant_background.dart';

enum LearningCompletionMode { lesson, personalized, assignedQuiz }

class LearningCompletionScreen extends StatefulWidget {
  final String lessonTitle;
  final int lessonId;
  final LearningCompletionMode mode;

  const LearningCompletionScreen({
    super.key,
    required this.lessonTitle,
    required this.lessonId,
    this.mode = LearningCompletionMode.lesson,
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
          curve: Interval(i * 0.15, 0.5 + i * 0.15, curve: Curves.bounceOut),
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

  Future<void> _handlePrimaryAction() async {
    if (widget.mode == LearningCompletionMode.assignedQuiz) {
      try {
        await context.read<StudentAssignedQuizProvider>().loadAssignedQuizzes();
      } on ProviderNotFoundException {
        // Some focused widget tests instantiate the completion screen alone.
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundMint,
          pattern: BackgroundPattern.none,
          child: Stack(
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

                  // Pick a mood that matches the score so the mascot's mood
                  // tracks the kid's performance, not a one-size-fits-all face.
                  final mascotMood = score >= 70
                      ? MascotMood.celebrating
                      : score >= 50
                      ? MascotMood.happy
                      : MascotMood.sad;
                  final title =
                      widget.mode == LearningCompletionMode.assignedQuiz
                      ? _getAssignedQuizMessage(score.toDouble())
                      : _getMessage(score.toDouble());

                  return SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Hero mascot — bigger than usual; this is the
                          // celebratory moment.
                          AnimatedMascot(mood: mascotMood, size: 180),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.lessonTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              color: AppTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Stars — Modern bubbly stars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              final earned = i < displayStars;
                              return ScaleTransition(
                                scale: _starAnimations[i],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 84,
                                    color: earned
                                        ? AppTheme.primaryYellow
                                        : AppTheme.surfaceMuted,
                                    shadows: earned
                                        ? [
                                            const Shadow(
                                              color: AppTheme.primaryYellowDeep,
                                              offset: Offset(0, 6),
                                            ),
                                          ]
                                        : null,
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
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Stats grid
                          Row(
                            children: [
                              Expanded(
                                child: DuolingoCard(
                                  padding: const EdgeInsets.all(16),
                                  borderColor: AppTheme.primaryGreen,
                                  child: _buildStatItem(
                                    '$score%',
                                    'النتيجة',
                                    AppTheme.primaryGreen,
                                    Icons.emoji_events_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DuolingoCard(
                                  padding: const EdgeInsets.all(16),
                                  borderColor: AppTheme.primaryBlue,
                                  child: _buildStatItem(
                                    '$correctCount/$questionCount',
                                    'إجابات صحيحة',
                                    AppTheme.primaryBlue,
                                    Icons.check_circle_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DuolingoCard(
                                  padding: const EdgeInsets.all(16),
                                  borderColor: AppTheme.primaryOrange,
                                  child: _buildStatItem(
                                    '+$points',
                                    'نقاط مكتسبة',
                                    AppTheme.primaryOrange,
                                    Icons.bolt_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DuolingoCard(
                                  padding: const EdgeInsets.all(16),
                                  borderColor: AppTheme.primaryYellow,
                                  child: _buildStatItem(
                                    '$totalStars',
                                    'نجوم مجموعة',
                                    AppTheme.primaryYellow,
                                    Icons.star_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Buttons
                          DuolingoButton(
                            text: _primaryActionText(),
                            color: AppTheme.primaryGreen,
                            onPressed: _handlePrimaryAction,
                          ),
                          const SizedBox(height: 16),
                          // Tier 3: jump to the rewards screen with the freshly
                          // earned points so it can celebrate new avatar unlocks.
                          DuolingoButton(
                            text: 'مكافآتي 🏆',
                            color: AppTheme.primaryTerracotta,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RewardsScreen(earnedPoints: points),
                              ),
                            ),
                          ),
                          if (score < 50) ...[
                            const SizedBox(height: 16),
                            DuolingoButton(
                              text: 'أعد المحاولة 🔄',
                              color: AppTheme.primaryOrange,
                              onPressed: () => Navigator.pop(context),
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
                    AppTheme.primaryGreen,
                    AppTheme.primaryYellow,
                    AppTheme.primaryOrange,
                    AppTheme.primaryBlue,
                    AppTheme.primaryPurple,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }

  String _getMessage(double score) {
    if (score >= 90) return 'ممتاز! أنت نجم! 🌟';
    if (score >= 70) return 'أحسنت! عمل رائع! 👏';
    if (score >= 50) return 'جيد! استمر بالمحاولة! 💪';
    return 'لا بأس! حاول مرة أخرى! 🤗';
  }

  String _getAssignedQuizMessage(double score) {
    if (score >= 90) return 'ممتاز في الاختبار! 🌟';
    if (score >= 70) return 'أحسنت في الاختبار! 👏';
    if (score >= 50) return 'اكتمل الاختبار، استمر بالتدريب! 💪';
    return 'اكتمل الاختبار، حاول مرة أخرى! 🤗';
  }

  String _primaryActionText() {
    if (widget.mode == LearningCompletionMode.assignedQuiz) {
      return 'العودة إلى الاختبارات';
    }
    return 'العودة للدروس 📚';
  }
}
