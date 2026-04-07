import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../app/theme.dart';
import '../../models/learning_step.dart';
import '../../models/quiz.dart';
import '../../providers/learning_provider.dart';
import '../../services/audio_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/progress_dots_bar.dart';
import '../../widgets/teaching_card_widget.dart';
import '../../widgets/star_display_widget.dart';
import '../../widgets/question_widgets/mcq_widget.dart';
import '../../widgets/question_widgets/true_false_widget.dart';
import '../../widgets/question_widgets/short_answer_widget.dart';
import '../../widgets/question_widgets/fill_blank_widget.dart';
import '../../widgets/question_widgets/ordering_widget.dart';
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
      _ttsService!.speakQuestion(step.question!.id, step.question!.questionText);
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

    // Teaching cards
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

    // Question steps
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
          key: ValueKey('question-${step.question!.id}-${provider.isInRetryRound}'),
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getQuestionBorderColor(provider),
            width: _shouldShowFeedback(provider) ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Question type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(question.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTypeLabel(question.type),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(question.type),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Question text
            Text(
              question.questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
                height: 1.6,
              ),
            ),
            // Retry banner
            if (isRetry)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'لا بأس! حاول مرة أخرى 💪',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            // Hint section
            if (!_isAnswered(provider) && !isRetry) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoadingHint
                    ? null
                    : () => _requestHint(question.id),
                icon: _isLoadingHint
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('💡', style: TextStyle(fontSize: 18)),
                label: Text(
                  _hintLevel >= 3 ? 'لا مزيد من التلميحات' : 'مساعدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: _hintLevel >= 3
                        ? AppTheme.textLight
                        : AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
            if (_currentHint != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentHint!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
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

  Color _getQuestionBorderColor(LearningProvider provider) {
    final tracker = provider.currentTracker;
    if (tracker?.lastResult == null) return Colors.transparent;
    if (provider.phase == LearningPhase.stepRetry) {
      return AppTheme.primaryOrange;
    }
    return tracker!.lastResult!.isCorrect ? Colors.green : Colors.red;
  }

  bool _isAnswered(LearningProvider provider) {
    return provider.phase == LearningPhase.stepFeedback;
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

    return ScaleTransition(
      scale: _feedbackAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: result.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: result.isCorrect ? Colors.green : Colors.red,
            width: 1.5,
          ),
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
                      color: result.isCorrect
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  if (!result.isCorrect)
                    Text(
                      result.correctAnswer,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  if (result.isCorrect)
                    Text(
                      '+${tracker!.starsEarned} ⭐',
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
          'حاول مرة أخرى 💪',
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
        child: Text(
          'التالي ←',
          style: const TextStyle(
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
        'تأكيد الإجابة',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 18, color: Colors.white),
      ),
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
      final result =
          await audioService.getHint(questionId, level: _hintLevel + 1);
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
              child: const Text('متابعة',
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
              child: const Text('الخروج',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MCQ':
        return AppTheme.primaryBlue;
      case 'TRUE_FALSE':
        return AppTheme.primaryPurple;
      case 'SHORT_ANSWER':
        return AppTheme.primaryOrange;
      case 'FILL_BLANK':
        return const Color(0xFF00897B);
      case 'ORDERING':
        return const Color(0xFF7B1FA2);
      default:
        return AppTheme.primaryGreen;
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
