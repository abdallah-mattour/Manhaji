import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/pronunciation_score.dart';
import '../models/quiz.dart';
import '../models/learning_step.dart';
import '../services/quiz_service.dart';
import '../utils/error_handler.dart';

enum LearningPhase {
  loading,
  teachingIntro,
  stepActive,
  stepFeedback,
  stepRetry,
  retryRound,
  completing,
  completed,
  error,
}

class QuestionTracker {
  final int questionId;
  int attemptCount;
  bool everCorrect;
  int starsEarned;
  bool inRetryRound;
  SubmitAnswerResult? lastResult;
  PronunciationScore? lastPronunciationScore;
  int? lastTracingScore;

  QuestionTracker({required this.questionId})
      : attemptCount = 0,
        everCorrect = false,
        starsEarned = 0,
        inRetryRound = false;
}

class LearningProvider extends ChangeNotifier {
  final QuizApiService _quizService;

  LearningPhase _phase = LearningPhase.loading;
  String? _errorMessage;

  Quiz? _currentQuiz;
  int? _currentAttemptId;
  List<LearningStep> _steps = [];
  int _currentStepIndex = 0;

  // Question tracking
  final Map<int, QuestionTracker> _trackers = {};
  final List<int> _retryQueue = [];
  int _retryIndex = 0;

  // Results
  AttemptResult? _attemptResult;
  int _totalStars = 0;
  int _maxPossibleStars = 0;

  LearningProvider(this._quizService);

  // Getters
  LearningPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  Quiz? get currentQuiz => _currentQuiz;
  int? get currentAttemptId => _currentAttemptId;
  List<LearningStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _steps.length;
  AttemptResult? get attemptResult => _attemptResult;
  int get totalStars => _totalStars;
  int get maxPossibleStars => _maxPossibleStars;
  Map<int, QuestionTracker> get trackers => _trackers;
  bool get isInRetryRound => _phase == LearningPhase.retryRound;
  int get retryQueueLength => _retryQueue.length;

  LearningStep? get currentStep {
    if (_phase == LearningPhase.retryRound) {
      if (_retryIndex < _retryQueue.length && _currentQuiz != null) {
        final qId = _retryQueue[_retryIndex];
        final question = _currentQuiz!.questions.cast<Question?>().firstWhere(
              (q) => q!.id == qId,
              orElse: () => null,
            );
        if (question == null) return null;
        return LearningStep(
          type: LearningStepType.question,
          question: question,
          stepIndex: -1,
        );
      }
      return null;
    }
    if (_currentStepIndex < _steps.length) {
      return _steps[_currentStepIndex];
    }
    return null;
  }

  bool get isLastMainStep => _currentStepIndex >= _steps.length - 1;

  int get questionCount =>
      _steps.where((s) => s.type == LearningStepType.question).length;

  int get answeredQuestionCount =>
      _trackers.values.where((t) => t.attemptCount > 0).length;

  QuestionTracker? get currentTracker {
    final step = currentStep;
    if (step?.question != null) {
      return _trackers[step!.question!.id];
    }
    return null;
  }

  // Start lesson
  Future<void> startLesson(int lessonId) async {
    _phase = LearningPhase.loading;
    _errorMessage = null;
    _resetState();
    notifyListeners();

    try {
      _currentQuiz = await _quizService.getQuizByLesson(lessonId);
      final attempt = await _quizService.startAttempt(_currentQuiz!.id);
      _currentAttemptId = attempt.attemptId;

      _buildSteps();
      _maxPossibleStars = _currentQuiz!.questions.length * 3;

      // Init trackers for every question
      for (final q in _currentQuiz!.questions) {
        _trackers[q.id] = QuestionTracker(questionId: q.id);
      }

      _phase = LearningPhase.teachingIntro;
    } catch (e) {
      _errorMessage = extractError(e);
      _phase = LearningPhase.error;
    }
    notifyListeners();
  }

  // Move past intro / teaching card
  void advanceFromTeaching() {
    _currentStepIndex++;
    _phase = LearningPhase.stepActive;
    notifyListeners();
  }

  // Submit answer
  Future<void> submitAnswer(String answer) async {
    final step = currentStep;
    if (step?.question == null || _currentAttemptId == null) return;

    final question = step!.question!;
    final tracker = _trackers[question.id];
    if (tracker == null) return;
    tracker.attemptCount++;

    _phase = LearningPhase.stepFeedback;
    notifyListeners();

    try {
      final result = await _quizService.submitAnswer(
        _currentAttemptId!,
        questionId: question.id,
        answer: answer,
      );
      tracker.lastResult = result;

      if (result.isCorrect) {
        tracker.everCorrect = true;
        if (tracker.inRetryRound) {
          tracker.starsEarned = 1;
        } else if (tracker.attemptCount == 1) {
          tracker.starsEarned = 3;
        } else {
          tracker.starsEarned = 2;
        }
        _recalcStars();
      } else if (!tracker.inRetryRound && tracker.attemptCount == 1) {
        // First wrong — allow retry
        _phase = LearningPhase.stepRetry;
        notifyListeners();
        return;
      } else {
        // Second wrong in main round or wrong in retry round
        if (tracker.inRetryRound) {
          tracker.starsEarned = 1;
          _recalcStars();
        } else if (!tracker.everCorrect) {
          // Failed both attempts in main round → queue for retry round
          _retryQueue.add(question.id);
        }
      }
    } catch (e) {
      _errorMessage = extractError(e);
      _phase = LearningPhase.stepActive;
    }
    notifyListeners();
  }

  // Flip into feedback phase to show a spinner while pronunciation request is in flight.
  void markPhaseFeedback() {
    _phase = LearningPhase.stepFeedback;
    notifyListeners();
  }

  // Apply pronunciation scoring result from backend.
  // Treats score >= 60 as correct; uses PronunciationScoringService's star logic.
  void applyPronunciationResult(PronunciationScore score) {
    final step = currentStep;
    if (step?.question == null) return;
    final question = step!.question!;
    final tracker = _trackers[question.id];
    if (tracker == null) return;

    tracker.attemptCount++;
    tracker.lastPronunciationScore = score;
    tracker.lastResult = SubmitAnswerResult(
      questionId: question.id,
      isCorrect: score.isCorrect,
      feedback: score.feedback,
      correctAnswer: score.expectedText,
      pointsEarned: score.pointsEarned,
    );

    if (score.isCorrect) {
      tracker.everCorrect = true;
      final baseStars = score.stars;
      if (tracker.inRetryRound) {
        tracker.starsEarned = 1;
      } else if (tracker.attemptCount == 1) {
        tracker.starsEarned = baseStars;
      } else {
        tracker.starsEarned = baseStars > 2 ? 2 : baseStars;
      }
      _recalcStars();
    } else if (!tracker.inRetryRound && tracker.attemptCount == 1) {
      _phase = LearningPhase.stepRetry;
      notifyListeners();
      return;
    } else {
      if (tracker.inRetryRound) {
        tracker.starsEarned = 1;
        _recalcStars();
      } else if (!tracker.everCorrect) {
        _retryQueue.add(question.id);
      }
    }

    _phase = LearningPhase.stepFeedback;
    notifyListeners();
  }

  // Apply tracing result (client-side scored).
  void applyTracingResult({
    required int score,
    required int stars,
    required String feedback,
  }) {
    final step = currentStep;
    if (step?.question == null) return;
    final question = step!.question!;
    final tracker = _trackers[question.id];
    if (tracker == null) return;

    tracker.attemptCount++;
    tracker.lastTracingScore = score;
    final isCorrect = score >= 60;
    tracker.lastResult = SubmitAnswerResult(
      questionId: question.id,
      isCorrect: isCorrect,
      feedback: feedback,
      correctAnswer: question.questionText,
      pointsEarned: isCorrect ? 10 : 0,
    );

    if (isCorrect) {
      tracker.everCorrect = true;
      if (tracker.inRetryRound) {
        tracker.starsEarned = 1;
      } else if (tracker.attemptCount == 1) {
        tracker.starsEarned = stars;
      } else {
        tracker.starsEarned = stars > 2 ? 2 : stars;
      }
      _recalcStars();
    } else if (!tracker.inRetryRound && tracker.attemptCount == 1) {
      _phase = LearningPhase.stepRetry;
      notifyListeners();
      return;
    } else {
      if (tracker.inRetryRound) {
        tracker.starsEarned = 1;
        _recalcStars();
      } else if (!tracker.everCorrect) {
        _retryQueue.add(question.id);
      }
    }

    _phase = LearningPhase.stepFeedback;
    notifyListeners();
  }

  // Retry current question (after first wrong)
  void retryCurrentQuestion() {
    _phase = LearningPhase.stepActive;
    notifyListeners();
  }

  // Move to next step
  void nextStep() {
    if (_phase == LearningPhase.retryRound) {
      _retryIndex++;
      if (_retryIndex >= _retryQueue.length) {
        _completeLesson();
      } else {
        _phase = LearningPhase.stepActive;
      }
      notifyListeners();
      return;
    }

    _currentStepIndex++;
    if (_currentStepIndex >= _steps.length) {
      // Main round done — check for retry queue
      if (_retryQueue.isNotEmpty) {
        _phase = LearningPhase.retryRound;
        _retryIndex = 0;
        for (final qId in _retryQueue) {
          _trackers[qId]?.inRetryRound = true;
          _trackers[qId]?.attemptCount = 0;
        }
      } else {
        _completeLesson();
      }
    } else {
      _phase = LearningPhase.stepActive;
    }
    notifyListeners();
  }

  Future<void> _completeLesson() async {
    if (_currentAttemptId == null) return;

    _phase = LearningPhase.completing;
    notifyListeners();

    try {
      _attemptResult = await _quizService.completeAttempt(_currentAttemptId!);

      // Ensure every question has at least 1 star
      for (final tracker in _trackers.values) {
        if (tracker.starsEarned == 0) {
          tracker.starsEarned = 1;
        }
      }
      _recalcStars();

      _phase = LearningPhase.completed;
    } catch (e) {
      _errorMessage = extractError(e);
      _phase = LearningPhase.completed; // Still show results even if API fails
    }
    notifyListeners();
  }

  void _recalcStars() {
    _totalStars = _trackers.values.fold(0, (sum, t) => sum + t.starsEarned);
  }

  // Build the step list with teaching cards woven between questions
  void _buildSteps() {
    _steps = [];
    int stepIdx = 0;

    final content = _currentQuiz?.lessonContent ?? '';
    final objectives = _currentQuiz?.lessonObjectives ?? '';
    final title = _currentQuiz?.title ?? '';
    final lessonImages = _currentQuiz?.lessonImageUrls ?? const <String>[];
    int imgCursor = 0;
    String? nextImage() {
      if (lessonImages.isEmpty) return null;
      final url = lessonImages[imgCursor % lessonImages.length];
      imgCursor++;
      return url;
    }

    // Step 0: Teaching intro
    final introContent = objectives.isNotEmpty ? objectives : content;
    _steps.add(LearningStep(
      type: LearningStepType.teachingIntro,
      teachingData: TeachingCardData(
        title: title.replaceFirst('اختبار: ', ''),
        content: introContent,
        emoji: '📚',
        accentColor: AppTheme.primaryBlue,
        imageUrl: nextImage(),
      ),
      stepIndex: stepIdx++,
    ));

    // Split content into sentences for teaching cards
    final sentences = _splitIntoSentences(content);
    final questions = _currentQuiz?.questions ?? [];

    // Match sentences to questions and weave teaching cards
    final usedSentences = <int>{};
    int teachingCardsInserted = 0;

    final cardTitles = ['هل تعلم؟', 'تعلّم معنا!', 'معلومة جديدة!'];
    final cardEmojis = ['💡', '⭐', '✨'];
    final cardColors = [
      AppTheme.primaryBlue,
      AppTheme.primaryOrange,
      AppTheme.primaryPurple,
    ];

    for (int qi = 0; qi < questions.length; qi++) {
      // Try to insert a teaching card before this question (max 3)
      if (teachingCardsInserted < 3) {
        final matchIdx = _findMatchingSentence(
          sentences,
          questions[qi].questionText,
          usedSentences,
        );
        if (matchIdx != -1) {
          usedSentences.add(matchIdx);
          final ci = teachingCardsInserted % 3;
          _steps.add(LearningStep(
            type: LearningStepType.teachingCard,
            teachingData: TeachingCardData(
              title: cardTitles[ci],
              content: sentences[matchIdx],
              emoji: cardEmojis[ci],
              accentColor: cardColors[ci],
              imageUrl: nextImage(),
            ),
            stepIndex: stepIdx++,
          ));
          teachingCardsInserted++;
        }
      }

      // Add the question step
      _steps.add(LearningStep(
        type: LearningStepType.question,
        question: questions[qi],
        stepIndex: stepIdx++,
      ));
    }
  }

  List<String> _splitIntoSentences(String text) {
    if (text.isEmpty) return [];
    // Split on Arabic period or newline
    return text
        .split(RegExp(r'[.。\n]'))
        .map((s) => s.trim())
        .where((s) => s.length > 5)
        .toList();
  }

  int _findMatchingSentence(
    List<String> sentences,
    String questionText,
    Set<int> used,
  ) {
    // Arabic stop words to skip during matching
    const stopWords = {
      'من', 'في', 'هل', 'ما', 'أي', 'هو', 'هي', 'إلى', 'على',
      'عن', 'لا', 'أن', 'هذا', 'هذه', 'ذلك', 'تلك', 'كل', 'بعض',
      'كان', 'يكون', 'الذي', 'التي', 'التالية', 'يلي', 'مما',
    };

    final qWords = questionText
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();

    int bestIdx = -1;
    int bestOverlap = 0;

    for (int i = 0; i < sentences.length; i++) {
      if (used.contains(i)) continue;
      final sWords = sentences[i]
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2 && !stopWords.contains(w))
          .toSet();

      final overlap = qWords.intersection(sWords).length;
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        bestIdx = i;
      }
    }

    return bestOverlap >= 1 ? bestIdx : -1;
  }

  void _resetState() {
    _currentQuiz = null;
    _currentAttemptId = null;
    _steps = [];
    _currentStepIndex = 0;
    _trackers.clear();
    _retryQueue.clear();
    _retryIndex = 0;
    _attemptResult = null;
    _totalStars = 0;
    _maxPossibleStars = 0;
  }
}
