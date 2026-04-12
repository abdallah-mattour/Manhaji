// lib/screens/learning/learning_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/learning_step.dart';
import '../../models/quiz.dart';
import '../../providers/learning_provider.dart';
import '../../routing/app_routes.dart';
import '../../services/audio_service.dart';
import '../../services/tts_service.dart';

import '../../widgets/progress_dots_bar.dart';
import '../../widgets/teaching_card_widget.dart';

import '../../widgets/question_widgets/mcq_widget.dart';
import '../../widgets/question_widgets/true_false_widget.dart';
import '../../widgets/question_widgets/short_answer_widget.dart';
import '../../widgets/question_widgets/fill_blank_widget.dart';
import '../../widgets/question_widgets/ordering_widget.dart';
import 'widgets/learning_sections.dart';

class LearningScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;

  const LearningScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  String? _selectedAnswer;
  final _textController = TextEditingController();
  bool _didNavigateToCompletion = false;

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late ConfettiController _confettiController;

  String? _currentHint;
  int _hintLevel = 0;
  bool _isLoadingHint = false;

  TtsService? _ttsService;
  int _lastSpokenStepIndex = -1;

  @override
  void initState() {
    super.initState();

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -10, end: 6), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 25),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().startLesson(widget.lessonId);
      _initTts();
    });
  }

  Future<void> _initTts() async {
    _ttsService = TtsService(context.read<AudioApiService>());
    await _ttsService!.init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _feedbackController.dispose();
    _shakeController.dispose();
    _confettiController.dispose();
    _ttsService?.dispose();
    super.dispose();
  }

  void _autoSpeak(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null || _ttsService == null) return;

    final idx = provider.isInRetryRound ? -99 : provider.currentStepIndex;
    if (idx == _lastSpokenStepIndex) return;
    _lastSpokenStepIndex = idx;

    if (step.isTeaching && step.teachingData != null) {
      _ttsService!.speakText(step.teachingData!.content);
    } else if (step.isQuestion && step.question != null) {
      _ttsService!.speakQuestion(
        step.question!.id,
        step.question!.questionText,
      );
    }
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
                if (provider.phase == LearningPhase.loading) {
                  return _buildLoading();
                }
                if (provider.phase == LearningPhase.error) {
                  return _buildError(provider.errorMessage ?? 'حدث خطأ');
                }
                if (provider.phase == LearningPhase.completing) {
                  return _buildLoading(message: 'جاري حساب النتائج...');
                }

                if (provider.phase == LearningPhase.completed) {
                  if (!_didNavigateToCompletion) {
                    _didNavigateToCompletion = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        context.push(
                          AppRoutes.lessonComplete(widget.lessonId),
                          extra: {'lessonTitle': widget.lessonTitle},
                        );
                      }
                    });
                  }
                  return _buildLoading(message: 'ممتاز! 🎉');
                }

                if (provider.phase == LearningPhase.stepActive ||
                    provider.phase == LearningPhase.teachingIntro) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _autoSpeak(provider);
                  });
                }

                return SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(provider),
                      ProgressDotsBar(
                        steps: provider.steps,
                        currentIndex: provider.currentStepIndex,
                        isRetryRound: provider.isInRetryRound,
                      ),
                      Expanded(child: _buildContent(provider)),
                      _buildBottomBar(provider),
                    ],
                  ),
                );
              },
            ),

            // Confetti
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 20,
                  maxBlastForce: 15,
                  minBlastForce: 5,
                  emissionFrequency: 0.06,
                  gravity: 0.2,
                  colors: const [
                    AppColors.primary,
                    AppColors.warning,
                    AppColors.accent,
                    AppColors.secondary,
                    AppColors.accent2,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading({String message = 'جاري تحضير الدرس...'}) {
    return LearningLoadingSection(
      message: message,
    );
  }

  Widget _buildError(String message) {
    return LearningErrorSection(
      message: message,
      onBack: () => context.pop(),
    );
  }

  Widget _buildTopBar(LearningProvider provider) {
    return LearningTopBarSection(
      lessonTitle: widget.lessonTitle,
      totalStars: provider.totalStars,
      onClose: _showExitDialog,
    );
  }

  Widget _buildContent(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null) return const SizedBox();

    if (step.isTeaching && step.teachingData != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: TeachingCardWidget(
          key: ValueKey('teaching-${provider.currentStepIndex}'),
          data: step.teachingData!,
          isIntro: step.type == LearningStepType.teachingIntro,
          onNext: () => provider.advanceFromTeaching(),
        ),
      );
    }

    if (step.isQuestion && step.question != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.15, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          key: ValueKey(
            'question-${step.question!.id}-${provider.isInRetryRound}',
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuestionCard(provider, step.question!),
              const SizedBox(height: 20),
              _buildAnswerArea(provider, step.question!),
              if (_shouldShowFeedback(provider)) ...[
                const SizedBox(height: 16),
                _buildFeedback(provider),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox();
  }

  bool _shouldShowFeedback(LearningProvider provider) {
    return provider.phase == LearningPhase.stepFeedback ||
        provider.phase == LearningPhase.stepRetry;
  }

  Color _getQuestionBorderColor(LearningProvider provider) {
    final tracker = provider.currentTracker;
    if (tracker?.lastResult == null) return Colors.transparent;
    if (provider.phase == LearningPhase.stepRetry) {
      return AppColors.accent;
    }
    return tracker!.lastResult!.isCorrect ? Colors.green : Colors.red;
  }

  bool _isAnswered(LearningProvider provider) {
    return provider.phase == LearningPhase.stepFeedback;
  }

  Widget _buildQuestionCard(LearningProvider provider, Question question) {
    final isRetry = provider.phase == LearningPhase.stepRetry;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: LearningQuestionCardSection(
        question: question,
        isRetry: isRetry,
        showFeedback: _shouldShowFeedback(provider),
        borderColor: _getQuestionBorderColor(provider),
        currentHint: _currentHint,
        hintLevel: _hintLevel,
        isLoadingHint: _isLoadingHint,
        getTypeColor: _getTypeColor,
        getTypeLabel: _getTypeLabel,
        onRequestHint: _isLoadingHint ? null : () => _requestHint(question.id),
      ),
    );
  }

  Widget _buildAnswerArea(LearningProvider provider, Question question) {
    final tracker = provider.currentTracker;
    final isAnswered = _isAnswered(provider);
    final isCorrect = tracker?.lastResult?.isCorrect ?? false;
    final correctAnswer = tracker?.lastResult?.correctAnswer;

    if (question.isMCQ) {
      return McqWidget(
        question: question,
        selectedAnswer: _selectedAnswer,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        correctAnswer: correctAnswer,
        onSelect: (v) => setState(() => _selectedAnswer = v),
      );
    } else if (question.isTrueFalse) {
      return TrueFalseWidget(
        selectedAnswer: _selectedAnswer,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        correctAnswer: correctAnswer,
        onSelect: (v) => setState(() => _selectedAnswer = v),
      );
    } else if (question.isFillBlank) {
      return FillBlankWidget(
        questionText: question.questionText,
        controller: _textController,
        selectedAnswer: _selectedAnswer,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        onChanged: (v) => setState(() => _selectedAnswer = v),
      );
    } else if (question.isOrdering) {
      return OrderingWidget(
        key: ValueKey('ordering-${question.id}-${provider.isInRetryRound}'),
        question: question,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        onOrderChanged: (v) => setState(() => _selectedAnswer = v),
      );
    } else {
      return ShortAnswerWidget(
        controller: _textController,
        isAnswered: isAnswered,
        onChanged: (v) => setState(() => _selectedAnswer = v),
        onVoiceComplete: (audioPath) => _handleVoiceAnswer(provider, audioPath),
      );
    }
  }

  Future<void> _handleVoiceAnswer(
    LearningProvider provider,
    String audioPath,
  ) async {
    final attemptId = provider.currentAttemptId;
    final question = provider.currentStep?.question;
    if (attemptId == null || question == null) return;

    try {
      final audioService = context.read<AudioApiService>();
      final result = await audioService.submitVoiceAnswer(
        attemptId: attemptId,
        questionId: question.id,
        audioFilePath: audioPath,
      );
      final transcription = result['feedback']?.toString() ?? '';
      if (transcription.isNotEmpty) {
        _textController.text = transcription;
        setState(() => _selectedAnswer = transcription);
      }
      await provider.submitAnswer(
        result['correctAnswer']?.toString() ?? _selectedAnswer ?? '',
      );
      _onAnswerSubmitted(provider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في معالجة الصوت')),
        );
      }
    }
  }

  Widget _buildFeedback(LearningProvider provider) {
    final tracker = provider.currentTracker;
    final result = tracker?.lastResult;
    if (result == null) return const SizedBox();

    final isRetryPrompt = provider.phase == LearningPhase.stepRetry;
    return LearningFeedbackSection(
      result: result,
      isRetryPrompt: isRetryPrompt,
      starsEarned: tracker?.starsEarned ?? 0,
      animation: _feedbackAnimation,
    );
  }

  Widget _buildBottomBar(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null || step.isTeaching) return const SizedBox();

    final phase = provider.phase;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildActionButton(provider, phase),
    );
  }

  Widget _buildActionButton(LearningProvider provider, LearningPhase phase) {
    return LearningActionButtonSection(
      phase: phase,
      canSubmit: _selectedAnswer != null,
      isLastMainStep: provider.isLastMainStep,
      isInRetryRound: provider.isInRetryRound,
      onRetry: () {
        setState(() {
          _selectedAnswer = null;
          _textController.clear();
        });
        provider.retryCurrentQuestion();
      },
      onNext: () => _goNext(provider),
      onSubmit: () => _submitAnswer(provider),
    );
  }

  Future<void> _submitAnswer(LearningProvider provider) async {
    if (_selectedAnswer == null) return;
    _ttsService?.stop();

    await provider.submitAnswer(_selectedAnswer!);

    if (!mounted) return;

    final tracker = provider.currentTracker;
    if (tracker?.lastResult?.isCorrect == true) {
      _confettiController.play();
      _feedbackController.forward(from: 0);
    } else if (provider.phase == LearningPhase.stepRetry) {
      _shakeController.forward(from: 0);
      _feedbackController.forward(from: 0);
    } else {
      _feedbackController.forward(from: 0);
    }
  }

  void _onAnswerSubmitted(LearningProvider provider) {
    final tracker = provider.currentTracker;
    if (tracker?.lastResult?.isCorrect == true) {
      _confettiController.play();
    }
    _feedbackController.forward(from: 0);
  }

  void _goNext(LearningProvider provider) {
    _ttsService?.stop();
    setState(() {
      _selectedAnswer = null;
      _textController.clear();
      _currentHint = null;
      _hintLevel = 0;
      _lastSpokenStepIndex = -1;
    });
    provider.nextStep();
  }

  Future<void> _requestHint(int questionId) async {
    if (_hintLevel >= 3) return;
    setState(() => _isLoadingHint = true);
    try {
      final audioService = context.read<AudioApiService>();
      final result = await audioService.getHint(
        questionId,
        level: _hintLevel + 1,
      );
      setState(() {
        _currentHint = result['hint']?.toString();
        _hintLevel = (result['hintLevel'] as num?)?.toInt() ?? _hintLevel + 1;
      });
    } catch (_) {
      setState(() {
        _hintLevel++;
        _currentHint = 'فكّر جيداً في السؤال 🤔';
      });
    } finally {
      setState(() => _isLoadingHint = false);
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('الخروج من الدرس'),
          content: const Text('هل تريد الخروج؟ سيتم فقدان تقدمك.'),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('متابعة')),
            ElevatedButton(
              onPressed: () {
                _ttsService?.stop();
                ctx.pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MCQ':
        return AppColors.secondary;
      case 'TRUE_FALSE':
        return AppColors.accent2;
      case 'SHORT_ANSWER':
        return AppColors.accent;
      case 'FILL_BLANK':
        return const Color(0xFF00897B);
      case 'ORDERING':
        return const Color(0xFF7B1FA2);
      default:
        return AppColors.primary;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'MCQ':
        return 'اختيار من متعدد';
      case 'TRUE_FALSE':
        return 'صح أو خطأ';
      case 'SHORT_ANSWER':
        return 'إجابة قصيرة';
      case 'FILL_BLANK':
        return 'أكمل الفراغ';
      case 'ORDERING':
        return 'رتّب العناصر';
      default:
        return '';
    }
  }
}
