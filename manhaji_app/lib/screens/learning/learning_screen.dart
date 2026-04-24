import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../app/theme.dart';
import '../../constants/strings.dart';
import '../../models/learning_step.dart';
import '../../models/quiz.dart';
import '../../providers/learning_provider.dart';
import '../../services/audio_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/onboarding_overlay.dart';
import '../../widgets/learning/quiz_question_view.dart';
import '../../widgets/progress_dots_bar.dart';
import '../../widgets/teaching_card_widget.dart';
import '../../widgets/star_display_widget.dart';
import '../../widgets/question_widgets/mcq_widget.dart';
import '../../widgets/question_widgets/true_false_widget.dart';
import '../../widgets/question_widgets/short_answer_widget.dart';
import '../../widgets/question_widgets/fill_blank_widget.dart';
import '../../widgets/question_widgets/ordering_widget.dart';
import '../../widgets/question_widgets/pronunciation_widget.dart';
import '../../widgets/question_widgets/tracing_widget.dart';
import 'learning_completion_screen.dart';

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
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -10, end: 6), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LearningProvider>();
      provider.startLesson(widget.lessonId);
      _initTts();
    });
  }

  Future<void> _initTts() async {
    final tts = TtsService(context.read<AudioApiService>());
    _ttsService = tts;
    await tts.init();
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
    final tts = _ttsService;
    if (step == null || tts == null) return;

    final idx = provider.isInRetryRound ? -99 : provider.currentStepIndex;
    if (idx == _lastSpokenStepIndex) return;
    _lastSpokenStepIndex = idx;

    final teaching = step.teachingData;
    final question = step.question;
    if (step.isTeaching && teaching != null) {
      tts.speakText(teaching.content);
    } else if (step.isQuestion && question != null) {
      // Show a first-time tip for novel AI question types before TTS kicks in.
      _maybeShowOnboarding(question.type);
      tts.speakQuestion(question.id, question.questionText);
    }
  }

  /// Shows a one-time onboarding overlay the first time a learner meets a
  /// PRONUNCIATION or TRACING question. The seen-flag persists via
  /// SharedPreferences so subsequent sessions don't interrupt the flow.
  Future<void> _maybeShowOnboarding(String type) async {
    final storage = context.read<LocalStorageService>();
    if (type == 'PRONUNCIATION' && !storage.seenPronunciationTip) {
      await storage.markPronunciationTipSeen();
      if (!mounted) return;
      await OnboardingOverlay.showPronunciation(context);
    } else if (type == 'TRACING' && !storage.seenTracingTip) {
      await storage.markTracingTipSeen();
      if (!mounted) return;
      await OnboardingOverlay.showTracing(context);
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
                // Auto-speak on step change
                if (provider.phase == LearningPhase.stepActive ||
                    provider.phase == LearningPhase.teachingIntro) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _autoSpeak(provider);
                  });
                }

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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LearningCompletionScreen(
                            lessonTitle: widget.lessonTitle,
                            lessonId: widget.lessonId,
                          ),
                        ),
                      );
                    }
                  });
                  return _buildLoading(message: 'ممتاز!');
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
            // Confetti overlay
            Align(
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
    );
  }

  Widget _buildLoading({String message = 'جاري تحضير الدرس...'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontFamily: 'Cairo', color: AppTheme.textGray)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(LearningProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close, color: AppTheme.textGray),
          ),
          Expanded(
            child: Text(
              widget.lessonTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          StarDisplayWidget(totalStars: provider.totalStars),
        ],
      ),
    );
  }

  Widget _buildContent(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null) return const SizedBox();

    final teaching = step.teachingData;
    final question = step.question;

    // Teaching cards
    if (step.isTeaching && teaching != null) {
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
          data: teaching,
          isIntro: step.type == LearningStepType.teachingIntro,
          onNext: () => provider.advanceFromTeaching(),
        ),
      );
    }

    // Question steps
    if (step.isQuestion && question != null) {
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
          key: ValueKey('question-${question.id}-${provider.isInRetryRound}'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuestionCard(provider, question),
              const SizedBox(height: 20),
              _buildAnswerArea(provider, question),
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

  Widget _buildQuestionCard(LearningProvider provider, Question question) {
    // Pronunciation/tracing render their own target card with a dedicated
    // speaker, so we only surface the prompt-level speaker for the
    // read-to-solve question types.
    final needsSpeaker =
        question.type != 'PRONUNCIATION' && question.type != 'TRACING';
    return QuizQuestionView(
      question: question,
      isRetry: provider.phase == LearningPhase.stepRetry,
      showFeedbackBorder: _shouldShowFeedback(provider),
      borderColor: _getQuestionBorderColor(provider),
      isAnswered: _isAnswered(provider),
      shakeAnimation: _shakeAnimation,
      hintLevel: _hintLevel,
      currentHint: _currentHint,
      isLoadingHint: _isLoadingHint,
      onRequestHint: () => _requestHint(question.id),
      onSpeak: needsSpeaker
          ? () => _ttsService?.speakQuestion(question.id, question.questionText)
          : null,
    );
  }

  Color _getQuestionBorderColor(LearningProvider provider) {
    final result = provider.currentTracker?.lastResult;
    if (result == null) return Colors.transparent;
    if (provider.phase == LearningPhase.stepRetry) {
      return AppTheme.primaryOrange;
    }
    return result.isCorrect ? AppTheme.primaryGreen : AppTheme.primaryRed;
  }

  bool _isAnswered(LearningProvider provider) {
    return provider.phase == LearningPhase.stepFeedback;
  }

  Widget _buildAnswerArea(LearningProvider provider, Question question) {
    final tracker = provider.currentTracker;
    final isAnswered = _isAnswered(provider);
    final isCorrect = tracker?.lastResult?.isCorrect ?? false;
    final correctAnswer = tracker?.lastResult?.correctAnswer;

    if (question.isPronunciation) {
      return PronunciationWidget(
        question: question,
        lastScore: tracker?.lastPronunciationScore,
        isAnswered: isAnswered,
        isProcessing: provider.phase == LearningPhase.stepFeedback &&
            tracker?.lastPronunciationScore == null,
        onRecordingComplete: (audioPath) =>
            _handlePronunciationAnswer(provider, audioPath),
        onPlayTarget: () => _ttsService?.speakText(question.questionText),
      );
    }

    if (question.isTracing) {
      final lastScore = tracker?.lastTracingScore;
      final lastResult = lastScore == null
          ? null
          : TracingResult(
              score: lastScore,
              stars: lastScore >= 90
                  ? 3
                  : lastScore >= 75
                      ? 2
                      : lastScore >= 60
                          ? 1
                          : 0,
              rating: tracker?.lastResult?.feedback ?? '',
              feedback: tracker?.lastResult?.feedback ?? '',
            );
      return TracingWidget(
        key: ValueKey('tracing-${question.id}-${provider.isInRetryRound}'),
        question: question,
        isAnswered: isAnswered,
        lastResult: lastResult,
        onComplete: (result) => _handleTracingResult(provider, result),
      );
    }

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

  Future<void> _handleTracingResult(
      LearningProvider provider, TracingResult result) async {
    await provider.applyTracingResult(
      score: result.score,
      stars: result.stars,
      feedback: result.feedback,
    );
    if (!mounted) return;
    _onAnswerSubmitted(provider);
  }

  Future<void> _handlePronunciationAnswer(
      LearningProvider provider, String audioPath) async {
    final attemptId = provider.currentAttemptId;
    final question = provider.currentStep?.question;
    if (attemptId == null || question == null) return;

    // Show processing state via tracker (feedback phase without a score yet)
    provider.markPhaseFeedback();

    try {
      final audioService = context.read<AudioApiService>();
      final score = await audioService.submitPronunciation(
        attemptId: attemptId,
        questionId: question.id,
        audioFilePath: audioPath,
      );
      provider.applyPronunciationResult(score);
      _onAnswerSubmitted(provider);
    } catch (e) {
      debugPrint('[pronunciation] error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في تقييم النطق')),
        );
      }
    }
  }

  Future<void> _handleVoiceAnswer(
      LearningProvider provider, String audioPath) async {
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
        transcription.isNotEmpty ? transcription : (_selectedAnswer ?? ''),
      );
      _onAnswerSubmitted(provider);
    } catch (e) {
      debugPrint('[voice-answer] error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في معالجة الصوت')),
        );
      }
    }
  }

  Widget _buildFeedback(LearningProvider provider) {
    final tracker = provider.currentTracker;
    if (tracker == null) return const SizedBox();
    final result = tracker.lastResult;
    if (result == null) return const SizedBox();

    final isRetryPrompt = provider.phase == LearningPhase.stepRetry;

    if (isRetryPrompt) {
      return ScaleTransition(
        scale: _feedbackAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryOrange, width: 1.5),
          ),
          child: const Row(
            children: [
              Text('💪', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لا بأس! حاول مرة أخرى',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final accentColor =
        result.isCorrect ? AppTheme.primaryGreen : AppTheme.primaryRed;
    return ScaleTransition(
      scale: _feedbackAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor, width: 1.5),
        ),
        child: Row(
          children: [
            Text(
              result.isCorrect ? '🎉' : '😔',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.isCorrect
                        ? 'أحسنت! ممتاز!'
                        : 'الإجابة الصحيحة:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  if (!result.isCorrect)
                    Text(
                      result.correctAnswer,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  if (result.isCorrect)
                    Text(
                      '+${tracker.starsEarned} ⭐',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null || step.isTeaching) return const SizedBox();

    final phase = provider.phase;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
    // During step retry — show "retry" button
    if (phase == LearningPhase.stepRetry) {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedAnswer = null;
            _textController.clear();
          });
          provider.retryCurrentQuestion();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          AppStrings.actionTryAgain,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.white),
        ),
      );
    }

    // After feedback — show "next" button
    if (phase == LearningPhase.stepFeedback) {
      final isLast = provider.isInRetryRound
          ? false // retry round handles its own "last"
          : provider.isLastMainStep;

      return ElevatedButton(
        onPressed: () => _goNext(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLast ? AppTheme.primaryGreen : AppTheme.primaryBlue,
          minimumSize: const Size(double.infinity, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          AppStrings.actionNext,
          style: TextStyle(
              fontFamily: 'Cairo', fontSize: 18, color: Colors.white),
        ),
      );
    }

    // Active question — show "confirm" button
    return ElevatedButton(
      onPressed:
          _selectedAnswer != null ? () => _submitAnswer(provider) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryOrange,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        AppStrings.actionConfirm,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.white),
      ),
    );
  }

  Future<void> _submitAnswer(LearningProvider provider) async {
    if (_selectedAnswer == null) return;
    _ttsService?.stop();

    await provider.submitAnswer(_selectedAnswer!);

    if (!mounted) return;
    _playFeedbackEffects(provider);
  }

  void _onAnswerSubmitted(LearningProvider provider) {
    _playFeedbackEffects(provider);
  }

  /// Unified post-answer feedback: confetti/shake animation, haptic buzz,
  /// and a short TTS "أحسنت" / "حاول مرة أخرى". Called after every question
  /// type (MCQ, TF, short, fill, ordering, pronunciation, tracing).
  void _playFeedbackEffects(LearningProvider provider) {
    final tracker = provider.currentTracker;
    final isCorrect = tracker?.lastResult?.isCorrect == true;
    final isRetrying = provider.phase == LearningPhase.stepRetry;

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      _confettiController.play();
      _ttsService?.speakText('أحسنت!');
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      if (isRetrying) {
        _ttsService?.speakText('حاول مرة أخرى');
      }
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
      final result =
          await audioService.getHint(questionId, level: _hintLevel + 1);
      setState(() {
        _currentHint = result['hint']?.toString();
        _hintLevel = (result['hintLevel'] as num?)?.toInt() ?? _hintLevel + 1;
      });
    } catch (e) {
      debugPrint('[hint] error: $e');
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('الخروج من الدرس',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: const Text('هل تريد الخروج؟ سيتم فقدان تقدمك.',
              style: TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.actionContinue,
                  style: TextStyle(
                      fontFamily: 'Cairo', color: AppTheme.primaryGreen)),
            ),
            ElevatedButton(
              onPressed: () {
                _ttsService?.stop();
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed),
              child: const Text(AppStrings.actionExit,
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

}
