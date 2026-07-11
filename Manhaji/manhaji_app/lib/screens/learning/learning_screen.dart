import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../app/theme.dart';
import '../../constants/strings.dart';
import '../../models/learning_step.dart';
import '../../models/quiz.dart';
import '../../models/student_assigned_quiz.dart';
import '../../providers/learning_provider.dart';
import '../../providers/student_settings_provider.dart';
import '../../services/audio_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/tts_service.dart';
import '../../utils/app_log.dart';
import '../../widgets/onboarding_overlay.dart';
import '../../widgets/quiz_question_view.dart';
import '../../widgets/vibrant_background.dart';
import '../../widgets/teaching_card_widget.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/question_widgets/mcq_widget.dart';
import '../../widgets/question_widgets/image_mcq_widget.dart';
import '../../widgets/question_widgets/listen_choose_widget.dart';
import '../../widgets/question_widgets/image_match_widget.dart';
import '../../widgets/question_widgets/drag_drop_widget.dart';
import '../../widgets/question_widgets/true_false_widget.dart';
import '../../widgets/question_widgets/short_answer_widget.dart';
import '../../widgets/question_widgets/fill_blank_widget.dart';
import '../../widgets/question_widgets/ordering_widget.dart';
import '../../widgets/question_widgets/pronunciation_widget.dart';
import '../../widgets/question_widgets/reading_widget.dart';
import '../../widgets/question_widgets/tracing_widget.dart';
import 'learning_completion_screen.dart';

class LearningScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;

  /// Tier A / A1 (2026-05-15): when true, the screen launches Practice Mode
  /// — questions are reordered by the backend's adaptive selector based on
  /// the student's past performance in this lesson. Defaults to false so
  /// the standard lesson flow is unchanged.
  final bool practiceMode;

  /// Knowledge Tracing "Challenge Me": when set, the screen plays this
  /// already-generated personalized quiz instead of a lesson's quiz. The
  /// quiz spans a subject (no single lesson), so [lessonId] is unused in
  /// this mode and the teaching-intro phase is skipped.
  final Quiz? personalizedQuiz;

  /// Teacher-assigned quiz detail loaded through the assignment endpoint.
  /// Starts through assignmentId authorization and uses question-only steps.
  final StudentAssignedQuizDetail? assignedQuiz;

  /// Full English experience (2026-07-03): true when this lesson belongs to
  /// the English subject — all in-lesson UI chrome (instructions, buttons,
  /// feedback, hints, onboarding, TTS phrases) renders in English instead of
  /// Arabic. Set by the caller (subject screens know their subject name).
  final bool englishMode;

  const LearningScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    this.practiceMode = false,
    this.personalizedQuiz,
    this.assignedQuiz,
    this.englishMode = false,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  static final AppLog _sttLog = AppLog.tag('stt');

  String? _selectedAnswer;
  final _textController = TextEditingController();

  /// Shorthand for the bilingual in-lesson UI (see [LearningScreen.englishMode]).
  bool get _english => widget.englishMode;
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
      final provider = context.read<LearningProvider>();
      if (widget.assignedQuiz != null) {
        provider.startAssignedQuiz(widget.assignedQuiz!);
      } else if (widget.personalizedQuiz != null) {
        // Challenge Me: play the already-generated cross-subject quiz.
        provider.startPersonalizedQuiz(widget.personalizedQuiz!);
      } else {
        // Audit / A1: hand the flag to the provider before kicking off the
        // lesson so startLesson() picks the adaptive endpoint when appropriate.
        provider.practiceMode = widget.practiceMode;
        provider.startLesson(widget.lessonId);
      }
      _initTts();
    });
  }

  Future<void> _initTts() async {
    // TtsService needs LocalStorageService so it can attach the JWT bearer
    // header to /uploads/audio/** playback requests (the endpoint is gated
    // as authenticated() — audit fix S4). Without the header, ExoPlayer
    // gets a 401 and surfaces it as a generic "Source error".
    final tts = TtsService(
      context.read<AudioApiService>(),
      context.read<LocalStorageService>(),
    );
    _ttsService = tts;
    await tts.init();
  }

  @override
  void dispose() {
    _textController.dispose();
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

    // Phase 8A — الوضع الصامت gates AUTOMATIC playback only. The manual
    // speaker button and pronunciation target playback stay untouched.
    final autoAudio = context.read<StudentSettingsProvider>().autoAudioEnabled;

    final teaching = step.teachingData;
    final question = step.question;
    if (step.isTeaching && teaching != null) {
      if (autoAudio) tts.speakText(teaching.content);
    } else if (step.isQuestion && question != null) {
      // Show a first-time tip for novel AI question types before TTS kicks in.
      _maybeShowOnboarding(question.type);
      if (autoAudio) tts.speakQuestion(question.id, question.questionText);
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
      await OnboardingOverlay.showPronunciation(context, english: _english);
    } else if (type == 'TRACING' && !storage.seenTracingTip) {
      await storage.markTracingTipSeen();
      if (!mounted) return;
      await OnboardingOverlay.showTracing(context, english: _english);
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
                            mode: widget.assignedQuiz != null
                                ? LearningCompletionMode.assignedQuiz
                                : widget.personalizedQuiz != null
                                ? LearningCompletionMode.personalized
                                : LearningCompletionMode.lesson,
                          ),
                        ),
                      );
                    }
                  });
                  return _buildLoading(message: 'ممتاز!');
                }

                return SafeArea(
                  child: VibrantBackground(
                    backgroundColor: AppTheme.backgroundLight,
                    pattern: BackgroundPattern.none,
                    child: Column(
                      children: [
                        _buildTopBar(provider),
                        Expanded(child: _buildContent(provider)),
                        _buildBottomBar(provider),
                      ],
                    ),
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
          const CircularProgressIndicator(color: AppTheme.primaryTerracotta),
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppTheme.textGray,
              ),
            ),
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
    // Duolingo-style thin progress bar at the very top
    final progress = provider.steps.isEmpty
        ? 0.0
        : provider.currentStepIndex / provider.steps.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close, color: AppTheme.textLight, size: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceSubtle,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                minHeight: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                '${provider.totalStars}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null) {
      // Past the last question with nothing to show — finish the lesson so
      // the celebration screen appears instead of a blank page.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) provider.finishIfStranded();
      });
      return _buildLoading(message: _english ? 'Great job!' : 'أحسنت!');
    }

    final teaching = step.teachingData;
    final question = step.question;

    // Teaching cards
    if (step.isTeaching && teaching != null) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
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
        child: SingleChildScrollView(
          key: ValueKey('question-${question.id}-${provider.isInRetryRound}'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuestionCard(provider, question),
              const SizedBox(height: 32),
              _buildAnswerArea(provider, question),
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
    // Pronunciation/tracing/reading render their own target card with a
    // dedicated speaker, so we only surface the prompt-level speaker for the
    // read-to-solve question types.
    final needsSpeaker = question.type != 'PRONUNCIATION' &&
        question.type != 'TRACING' &&
        question.type != 'READING';
    // Tier 4: the READING widget renders the passage itself (word-by-word
    // coloring), so the prompt card shows a short instruction instead of
    // duplicating the passage.
    final displayQuestion = question.isReading
        ? Question(
            id: question.id,
            type: question.type,
            questionText: _english
                ? 'Read the sentence out loud 📖'
                : 'اقرأ الجملة التالية بصوتٍ واضح 📖',
            difficultyLevel: question.difficultyLevel,
            subSkill: question.subSkill,
          )
        : question;
    return QuizQuestionView(
      question: displayQuestion,
      english: _english,
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
        isProcessing:
            provider.phase == LearningPhase.stepFeedback &&
            tracker?.lastPronunciationScore == null,
        onRecordingComplete: (audioPath) =>
            _handlePronunciationAnswer(provider, audioPath),
        onPlayTarget: () => _ttsService?.speakText(question.questionText),
        english: _english,
      );
    }

    if (question.isReading) {
      // Tier 4: read-aloud passage. Reuses the entire pronunciation
      // submission pipeline; the response additionally carries per-word
      // results which the widget uses to color the passage.
      return ReadingWidget(
        question: question,
        lastScore: tracker?.lastPronunciationScore,
        isAnswered: isAnswered,
        isProcessing: provider.phase == LearningPhase.stepFeedback &&
            tracker?.lastPronunciationScore == null,
        onRecordingComplete: (audioPath) =>
            _handlePronunciationAnswer(provider, audioPath),
        onPlayTarget: () => _ttsService?.speakText(question.questionText),
        english: _english,
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
        english: _english,
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
    } else if (question.isImageMcq) {
      // Same selection flow as MCQ — options are pictures.
      return ImageMcqWidget(
        question: question,
        selectedAnswer: _selectedAnswer,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        correctAnswer: correctAnswer,
        onSelect: (v) => setState(() => _selectedAnswer = v),
      );
    } else if (question.isListenChoose) {
      // Auto-plays the question audio; same selection flow as MCQ.
      return ListenChooseWidget(
        question: question,
        selectedAnswer: _selectedAnswer,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        correctAnswer: correctAnswer,
        onSelect: (v) => setState(() => _selectedAnswer = v),
        onReplay: () => _ttsService?.speakQuestion(
            question.id, question.questionText),
        english: _english,
      );
    } else if (question.isImageMatch) {
      // Tap-to-pair; submits the "left=right,…" mapping into _selectedAnswer.
      return ImageMatchWidget(
        key: ValueKey('match-${question.id}-${provider.isInRetryRound}'),
        question: question,
        isAnswered: isAnswered,
        onChanged: (v) => setState(() => _selectedAnswer = v),
        english: _english,
      );
    } else if (question.isDragDrop) {
      // Tier 2: sort tokens into groups. onChanged delivers the full
      // "target=token,…" mapping only when every token is placed (null while
      // incomplete), so the check button stays disabled mid-sort.
      return DragDropWidget(
        key: ValueKey('dragdrop-${question.id}-${provider.isInRetryRound}'),
        question: question,
        isAnswered: isAnswered,
        onChanged: (v) => setState(() => _selectedAnswer = v),
        english: _english,
      );
    } else if (question.isTrueFalse) {
      return TrueFalseWidget(
        selectedAnswer: _selectedAnswer,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        correctAnswer: correctAnswer,
        questionText: question.questionText,
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
        english: _english,
      );
    } else if (question.isOrdering) {
      return OrderingWidget(
        key: ValueKey('ordering-${question.id}-${provider.isInRetryRound}'),
        question: question,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        onOrderChanged: (v) => setState(() => _selectedAnswer = v),
        english: _english,
      );
    } else {
      // SHORT_ANSWER — and deliberately also the fallback for any type this
      // app version doesn't know (Question.normalizeType maps known aliases
      // first). A free-text box means the child can always answer and move
      // on; an "unsupported" panel would dead-end the quiz.
      return ShortAnswerWidget(
        controller: _textController,
        isAnswered: isAnswered,
        onChanged: (v) => setState(() => _selectedAnswer = v),
        onVoiceComplete: (audioPath) => _handleVoiceAnswer(provider, audioPath),
        english: _english,
      );
    }
  }

  Future<void> _handleTracingResult(
    LearningProvider provider,
    TracingResult result,
  ) async {
    await provider.applyTracingResult(
      score: result.score,
      stars: result.stars,
      feedback: result.feedback,
    );
    if (!mounted) return;
    _onAnswerSubmitted(provider);
  }

  Future<void> _handlePronunciationAnswer(
    LearningProvider provider,
    String audioPath,
  ) async {
    final attemptId = provider.currentAttemptId;
    final question = provider.currentStep?.question;
    if (attemptId == null || question == null) {
      _sttLog.w('handoff: missing attemptId/question — abandoning upload');
      return;
    }

    // Show processing state via tracker (feedback phase without a score yet).
    // The PronunciationWidget reads `provider.phase == stepFeedback` AND
    // `lastPronunciationScore == null` to render its in-card spinner.
    // _buildBottomBar now also gates its red/green colors on `lastResult`
    // being non-null, so flipping phase here no longer flashes red.
    provider.markPhaseFeedback();
    _sttLog.i('handoff: q=${question.id} attempt=$attemptId');

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
      _sttLog.e('handoff: pronunciation pipeline failed', e);
      // Audit-3 fix (2026-05-15): a network blip during the pronunciation
      // upload would leave the screen stuck in stepFeedback (spinner)
      // forever. Revert to active so the child can re-record.
      if (mounted) {
        provider.markPhaseActive();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تقييم النطق. حاول مرة أخرى.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
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
      final data = await audioService.submitVoiceAnswer(
        attemptId: attemptId,
        questionId: question.id,
        audioFilePath: audioPath,
      );
      // `/voice-answer` already transcribed AND graded the audio server-side.
      // Apply THAT verdict directly. We deliberately do NOT:
      //   • write to `_textController` — the text box is the child's typing
      //     area only; the mic's transcription must not appear there.
      //   • call `provider.submitAnswer(...)` again — re-submitting re-graded
      //     the feedback string (not the speech), which is what made a correct
      //     answer score wrong and a random one sometimes score right.
      provider.applyVoiceAnswerResult(SubmitAnswerResult.fromJson(data));
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

  Widget _buildBottomBar(LearningProvider provider) {
    final step = provider.currentStep;
    if (step == null || step.isTeaching) return const SizedBox();

    final phase = provider.phase;
    final tracker = provider.currentTracker;
    final result = tracker?.lastResult;
    // `hasVerdict` is the only safe gate for the success/error colours.
    // Just looking at `phase == stepFeedback` is wrong for pronunciation
    // questions, where `markPhaseFeedback()` flips the phase the moment
    // recording stops — *before* the Gemini transcription + scoring
    // round-trip resolves. Without this gate, the bottom bar painted red
    // for the duration of the network call, then flipped to green when
    // the score arrived. Same root cause as the MCQ flicker, surfaced
    // through a different submit path.
    final hasVerdict = result != null;
    final isAnswered =
        phase == LearningPhase.stepFeedback || phase == LearningPhase.stepRetry;
    final showVerdictColors = isAnswered && hasVerdict;

    // Duolingo-style sliding feedback panel
    return AnimatedContainer(
      duration: AppTheme.motionBase,
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: !showVerdictColors
            ? Colors.white
            : (result.isCorrect
                  ? AppTheme.successContainer
                  : AppTheme.errorContainer),
        border: Border(
          top: BorderSide(
            color: !showVerdictColors
                ? AppTheme.surfaceSubtle
                : (result.isCorrect
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryRed),
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAnswered && result != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    result.isCorrect ? '🎉' : '😔',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  result.isCorrect
                      ? (_english ? 'Well done! Excellent!' : 'أحسنت! ممتاز!')
                      : (_english ? 'The correct answer:' : 'الإجابة الصحيحة:'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: result.isCorrect
                        ? AppTheme.primaryGreenDeep
                        : AppTheme.primaryRedDeep,
                  ),
                ),
              ],
            ),
            if (!result.isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                result.correctAnswer,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryRedDeep,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
          _buildActionButton(provider, phase),
        ],
      ),
    );
  }

  Widget _buildActionButton(LearningProvider provider, LearningPhase phase) {
    if (phase == LearningPhase.stepRetry) {
      return DuolingoButton(
        text: _english ? 'Try again 💪' : AppStrings.actionTryAgain,
        color: AppTheme.primaryOrange,
        onPressed: () {
          setState(() {
            _selectedAnswer = null;
            _textController.clear();
          });
          provider.retryCurrentQuestion();
        },
      );
    }

    if (phase == LearningPhase.stepFeedback) {
      final tracker = provider.currentTracker;
      final result = tracker?.lastResult;

      // During pronunciation processing the phase is stepFeedback but the
      // verdict (lastResult) hasn't arrived yet. Don't paint a red/green
      // Next button preemptively — the in-card processing spinner is the
      // only signal a child should see while we wait on Gemini.
      if (result == null) {
        return const SizedBox.shrink();
      }

      return DuolingoButton(
        text: _english ? 'Next →' : AppStrings.actionNext,
        color: result.isCorrect ? AppTheme.primaryGreen : AppTheme.primaryRed,
        onPressed: () => _goNext(provider),
      );
    }

    // Disable the Confirm button while a submission is in flight so a
    // double-tap can't fire two POST /attempt/answer calls. The provider
    // also keeps `phase = stepActive` during this window, which keeps the
    // answer options painted in their "selected blue" state instead of
    // flashing red against a not-yet-arrived verdict.
    return DuolingoButton(
      text: _english ? 'Check answer' : AppStrings.actionConfirm,
      color: AppTheme.primaryGreen,
      onPressed: (_selectedAnswer != null && !provider.isSubmitting)
          ? () => _submitAnswer(provider)
          : null,
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
    // Phase 8A — الوضع الصامت mutes the automatic verdict voice lines only;
    // haptics, confetti and the shake animation stay (they're not audio).
    final autoAudio = context.read<StudentSettingsProvider>().autoAudioEnabled;

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      _confettiController.play();
      if (autoAudio) _ttsService?.speakText(_english ? 'Well done!' : 'أحسنت!');
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      if (isRetrying && autoAudio) {
        _ttsService?.speakText(_english ? 'Try again' : 'حاول مرة أخرى');
      }
    }
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
    } catch (e) {
      debugPrint('[hint] error: $e');
      setState(() {
        _hintLevel++;
        _currentHint = _english
            ? 'Think carefully about the question 🤔'
            : 'فكّر جيداً في السؤال 🤔';
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
          title: const Text(
            'الخروج من الدرس',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'هل تريد الخروج؟ سيتم فقدان تقدمك.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                AppStrings.actionContinue,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _ttsService?.stop();
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
              ),
              child: const Text(
                AppStrings.actionExit,
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
