import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/pronunciation_score.dart';
import 'package:manhaji_app/models/quiz.dart';
import 'package:manhaji_app/models/learning_step.dart';
import 'package:manhaji_app/providers/learning_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/quiz_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

/// Deterministic in-memory stand-in for the quiz API. No network, no JWT.
class FakeQuizService extends QuizApiService {
  FakeQuizService(this.quiz) : super(ApiService(FakeLocalStorage()));

  Quiz quiz;

  bool throwOnQuiz = false;
  bool throwOnStart = false;
  bool throwOnSubmit = false;
  bool throwOnComplete = false;
  bool throwOnTracing = false;

  /// When true, submitAnswer answers with a fully-defaulted (malformed/empty
  /// JSON) result instead of a verdict-driven one.
  bool returnMalformedResult = false;

  /// questionId -> verdict returned by submitAnswer. Missing id => wrong.
  Map<int, bool> verdicts = {};

  int regularQuizCalls = 0;
  int adaptiveQuizCalls = 0;
  final List<Map<String, Object?>> submittedAnswers = [];
  final List<Map<String, Object?>> tracingSubmissions = [];

  @override
  Future<Quiz> getQuizByLesson(int lessonId) async {
    regularQuizCalls++;
    if (throwOnQuiz) throw Exception('quiz boom');
    return quiz;
  }

  @override
  Future<Quiz> getAdaptiveQuizByLesson(int lessonId) async {
    adaptiveQuizCalls++;
    if (throwOnQuiz) throw Exception('quiz boom');
    return quiz;
  }

  @override
  Future<AttemptResult> startAttempt(int quizId) async {
    if (throwOnStart) throw Exception('start boom');
    return AttemptResult(
      attemptId: 555,
      quizId: quizId,
      status: 'IN_PROGRESS',
      totalQuestions: quiz.questions.length,
      correctAnswers: 0,
      pointsEarned: 0,
      answers: const [],
    );
  }

  @override
  Future<SubmitAnswerResult> submitAnswer(
    int attemptId, {
    required int questionId,
    String? answer,
    String? spokenText,
    String? audioRef,
  }) async {
    if (throwOnSubmit) throw Exception('submit boom');
    submittedAnswers.add({
      'attemptId': attemptId,
      'questionId': questionId,
      'answer': answer,
    });
    if (returnMalformedResult) {
      return SubmitAnswerResult.fromJson(const {});
    }
    final correct = verdicts[questionId] ?? false;
    return SubmitAnswerResult(
      questionId: questionId,
      isCorrect: correct,
      feedback: correct ? 'أحسنت' : 'حاول مرة أخرى',
      correctAnswer: 'الإجابة الصحيحة',
      pointsEarned: correct ? 10 : 0,
    );
  }

  @override
  Future<AttemptResult> completeAttempt(int attemptId) async {
    if (throwOnComplete) throw Exception('complete boom');
    return AttemptResult(
      attemptId: attemptId,
      quizId: quiz.id,
      status: 'GRADED',
      score: 80,
      totalQuestions: quiz.questions.length,
      correctAnswers: quiz.questions.length,
      pointsEarned: quiz.questions.length * 10,
      answers: const [],
    );
  }

  @override
  Future<SubmitAnswerResult> submitTracingResult(
    int attemptId, {
    required int questionId,
    required int score,
    required int stars,
    required bool isCorrect,
    String? feedback,
  }) async {
    if (throwOnTracing) throw Exception('tracing boom');
    tracingSubmissions.add({
      'attemptId': attemptId,
      'questionId': questionId,
      'score': score,
      'stars': stars,
      'isCorrect': isCorrect,
    });
    return SubmitAnswerResult(
      questionId: questionId,
      isCorrect: isCorrect,
      feedback: feedback,
      correctAnswer: '',
      pointsEarned: isCorrect ? 10 : 0,
    );
  }
}

Question _question(int id) => Question(
  id: id,
  type: 'MCQ',
  questionText: 'سؤال رقم $id',
  options: const ['أ', 'ب', 'ج'],
  difficultyLevel: 1,
);

/// Empty lessonContent => no woven teaching cards => deterministic steps:
/// [teachingIntro, q1, q2].
Quiz _quiz({int questionCount = 2}) => Quiz(
  id: 42,
  title: 'اختبار: حرف الراء',
  gamified: true,
  totalQuestions: questionCount,
  questions: [for (var i = 1; i <= questionCount; i++) _question(i)],
  lessonContent: '',
  lessonObjectives: 'نتعرف على حرف الراء',
);

PronunciationScore _pronunciation({
  required int questionId,
  required int score,
  String feedback = 'ممتاز',
}) => PronunciationScore(
  questionId: questionId,
  expectedText: 'رمان',
  transcribedText: 'رمان',
  score: score,
  rating: 'ممتاز',
  feedback: feedback,
  isCorrect: score >= 60,
  pointsEarned: score >= 60 ? 10 : 0,
);

/// Flush pending microtasks/futures (completeAttempt runs async off nextStep).
Future<void> _flush() => Future<void>.delayed(Duration.zero);

/// Starts a lesson and advances past the teaching intro to the first question.
Future<LearningProvider> _atFirstQuestion(FakeQuizService service) async {
  final provider = LearningProvider(service);
  await provider.startLesson(7);
  provider.advanceFromTeaching();
  return provider;
}

void main() {
  group('LearningProvider', () {
    group('initial state', () {
      test('starts idle with no attempt, no error, nothing loaded', () {
        final provider = LearningProvider(FakeQuizService(_quiz()));

        expect(provider.phase, LearningPhase.loading);
        expect(provider.currentQuiz, isNull);
        expect(provider.currentAttemptId, isNull);
        expect(provider.errorMessage, isNull);
        expect(provider.isSubmitting, false);
        expect(provider.steps, isEmpty);
        expect(provider.totalStars, 0);
        expect(provider.maxPossibleStars, 0);
        expect(provider.retryQueueLength, 0);
        expect(provider.attemptResult, isNull);
      });
    });

    group('startLesson', () {
      test('success loads quiz, starts attempt, builds steps and trackers',
          () async {
        final service = FakeQuizService(_quiz());
        final provider = LearningProvider(service);

        await provider.startLesson(7);

        expect(provider.phase, LearningPhase.teachingIntro);
        expect(provider.currentQuiz!.id, 42);
        expect(provider.currentAttemptId, 555);
        // Empty lessonContent => intro + 2 questions, no woven cards.
        expect(provider.totalSteps, 3);
        expect(provider.steps.first.type, LearningStepType.teachingIntro);
        expect(provider.questionCount, 2);
        expect(provider.trackers.length, 2);
        expect(provider.maxPossibleStars, 6); // 2 questions x 3 stars
        expect(service.regularQuizCalls, 1);
        expect(service.adaptiveQuizCalls, 0);
        expect(provider.errorMessage, isNull);
      });

      test('practice mode fetches the adaptive quiz endpoint', () async {
        final service = FakeQuizService(_quiz());
        final provider = LearningProvider(service);
        provider.practiceMode = true;

        await provider.startLesson(7);

        expect(service.adaptiveQuizCalls, 1);
        expect(service.regularQuizCalls, 0);
        expect(provider.phase, LearningPhase.teachingIntro);
      });

      test('quiz fetch failure sets error phase and message', () async {
        final service = FakeQuizService(_quiz())..throwOnQuiz = true;
        final provider = LearningProvider(service);

        await provider.startLesson(7);

        expect(provider.phase, LearningPhase.error);
        expect(provider.errorMessage, 'حدث خطأ غير متوقع');
        expect(provider.currentAttemptId, isNull);
      });

      test('attempt start failure sets error phase', () async {
        final service = FakeQuizService(_quiz())..throwOnStart = true;
        final provider = LearningProvider(service);

        await provider.startLesson(7);

        expect(provider.phase, LearningPhase.error);
        expect(provider.errorMessage, isNotNull);
      });

      test('restarting resets previous state', () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);
        service.verdicts = {1: true};
        await provider.submitAnswer('أ');
        expect(provider.totalStars, 3);

        await provider.startLesson(7);

        expect(provider.totalStars, 0);
        expect(provider.phase, LearningPhase.teachingIntro);
        expect(provider.retryQueueLength, 0);
        expect(provider.currentStepIndex, 0);
      });
    });

    group('startPersonalizedQuiz', () {
      test('skips teaching intro and builds question-only steps', () async {
        final service = FakeQuizService(_quiz());
        final provider = LearningProvider(service);

        await provider.startPersonalizedQuiz(_quiz());

        expect(provider.phase, LearningPhase.stepActive);
        expect(provider.totalSteps, 2);
        expect(
          provider.steps.every((s) => s.type == LearningStepType.question),
          isTrue,
        );
        expect(provider.currentStep!.question!.id, 1);
        expect(provider.maxPossibleStars, 6);
      });

      test('failure sets error phase', () async {
        final service = FakeQuizService(_quiz())..throwOnStart = true;
        final provider = LearningProvider(service);

        await provider.startPersonalizedQuiz(_quiz());

        expect(provider.phase, LearningPhase.error);
        expect(provider.errorMessage, isNotNull);
      });
    });

    group('submitAnswer', () {
      test('correct on first attempt earns 3 stars and enters feedback',
          () async {
        final service = FakeQuizService(_quiz())..verdicts = {1: true};
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('أ');

        final tracker = provider.trackers[1]!;
        expect(tracker.attemptCount, 1);
        expect(tracker.everCorrect, isTrue);
        expect(tracker.starsEarned, 3);
        expect(tracker.lastResult!.isCorrect, isTrue);
        expect(provider.totalStars, 3);
        expect(provider.phase, LearningPhase.stepFeedback);
        expect(provider.isSubmitting, false);
        expect(service.submittedAnswers.single['questionId'], 1);
        expect(service.submittedAnswers.single['attemptId'], 555);
      });

      test('first wrong answer opens the retry phase without stars', () async {
        final service = FakeQuizService(_quiz()); // all verdicts wrong
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('ب');

        final tracker = provider.trackers[1]!;
        expect(tracker.attemptCount, 1);
        expect(tracker.starsEarned, 0);
        expect(provider.phase, LearningPhase.stepRetry);
        expect(provider.retryQueueLength, 0); // not queued yet
      });

      test('wrong then correct earns 2 stars', () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('ب'); // wrong
        provider.retryCurrentQuestion();
        expect(provider.phase, LearningPhase.stepActive);

        service.verdicts = {1: true};
        await provider.submitAnswer('أ'); // correct on 2nd try

        final tracker = provider.trackers[1]!;
        expect(tracker.attemptCount, 2);
        expect(tracker.starsEarned, 2);
        expect(provider.totalStars, 2);
        expect(provider.phase, LearningPhase.stepFeedback);
      });

      test('wrong twice queues the question for the retry round', () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('ب');
        provider.retryCurrentQuestion();
        await provider.submitAnswer('ج');

        expect(provider.retryQueueLength, 1);
        expect(provider.trackers[1]!.starsEarned, 0);
        expect(provider.phase, LearningPhase.stepFeedback);
      });

      test('service failure keeps the step active with an error message',
          () async {
        final service = FakeQuizService(_quiz())..throwOnSubmit = true;
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('أ');

        expect(provider.phase, LearningPhase.stepActive);
        expect(provider.errorMessage, 'حدث خطأ غير متوقع');
        expect(provider.isSubmitting, false);
        expect(provider.trackers[1]!.lastResult, isNull);
      });

      test('malformed/empty backend payload is treated as a safe wrong answer',
          () async {
        final service = FakeQuizService(_quiz())..returnMalformedResult = true;
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('أ');

        // SubmitAnswerResult.fromJson({}) defaults to isCorrect=false.
        expect(provider.phase, LearningPhase.stepRetry);
        expect(provider.trackers[1]!.lastResult, isNotNull);
        expect(provider.trackers[1]!.lastResult!.isCorrect, isFalse);
        expect(provider.errorMessage, isNull);
      });
    });

    group('retry round', () {
      test(
        'failed questions replay in queue order, earn 1 star, then complete',
        () async {
          final service = FakeQuizService(_quiz()); // everything wrong
          final provider = await _atFirstQuestion(service);

          // Q1: wrong twice -> queued.
          await provider.submitAnswer('x');
          provider.retryCurrentQuestion();
          await provider.submitAnswer('x');
          provider.nextStep(); // to Q2

          // Q2: wrong twice -> queued.
          await provider.submitAnswer('x');
          provider.retryCurrentQuestion();
          await provider.submitAnswer('x');
          provider.nextStep(); // main round done -> retry round

          expect(provider.phase, LearningPhase.retryRound);
          expect(provider.isInRetryRound, isTrue);
          expect(provider.retryQueueLength, 2);
          // Consumed in the order they were queued.
          expect(provider.currentStep!.question!.id, 1);
          expect(provider.trackers[1]!.inRetryRound, isTrue);
          expect(provider.trackers[1]!.attemptCount, 0); // reset for retry

          // Retry Q1 correctly -> exactly 1 star in retry round.
          service.verdicts = {1: true};
          await provider.submitAnswer('أ');
          expect(provider.trackers[1]!.starsEarned, 1);

          provider.nextStep();
          expect(provider.currentStep!.question!.id, 2);

          // Retry Q2 wrong -> still 1 star (retry-round floor).
          service.verdicts = {};
          await provider.submitAnswer('x');
          expect(provider.trackers[2]!.starsEarned, 1);

          provider.nextStep(); // retry queue consumed -> completion
          await _flush();

          expect(provider.phase, LearningPhase.completed);
          expect(provider.attemptResult, isNotNull);
          expect(provider.totalStars, 2); // 1 + 1
        },
      );
    });

    group('completion', () {
      test('all-correct run completes with full stars and result data',
          () async {
        final service = FakeQuizService(_quiz())
          ..verdicts = {1: true, 2: true};
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('أ');
        provider.nextStep();
        await provider.submitAnswer('أ');
        provider.nextStep(); // last step -> completes
        await _flush();

        expect(provider.phase, LearningPhase.completed);
        expect(provider.totalStars, 6);
        expect(provider.attemptResult, isNotNull);
        expect(provider.attemptResult!.status, 'GRADED');
        expect(provider.attemptResult!.attemptId, 555);
      });

      test('every question gets at least one star at completion', () async {
        // Q1 correct, Q2 wrong twice then wrong again in retry round would
        // earn 1 explicitly; instead complete with Q2 unanswered-star=0 via
        // the retry round to exercise the >=1 star floor at completion.
        final service = FakeQuizService(_quiz())..verdicts = {1: true};
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('أ'); // Q1: 3 stars
        provider.nextStep();
        await provider.submitAnswer('x'); // Q2 wrong
        provider.retryCurrentQuestion();
        await provider.submitAnswer('x'); // Q2 wrong again -> queued
        provider.nextStep(); // -> retry round
        service.verdicts = {};
        await provider.submitAnswer('x'); // retry wrong -> 1 star
        provider.nextStep();
        await _flush();

        expect(provider.phase, LearningPhase.completed);
        for (final tracker in provider.trackers.values) {
          expect(tracker.starsEarned, greaterThanOrEqualTo(1));
        }
        expect(provider.totalStars, 4); // 3 + 1
      });

      test('completeAttempt failure still lands on completed with an error',
          () async {
        final service = FakeQuizService(_quiz())
          ..verdicts = {1: true, 2: true}
          ..throwOnComplete = true;
        final provider = await _atFirstQuestion(service);

        await provider.submitAnswer('أ');
        provider.nextStep();
        await provider.submitAnswer('أ');
        provider.nextStep();
        await _flush();

        expect(provider.phase, LearningPhase.completed);
        expect(provider.errorMessage, isNotNull);
        expect(provider.attemptResult, isNull);
        expect(provider.totalStars, 6); // state not corrupted
      });
    });

    group('pronunciation', () {
      test('high score on first attempt earns its own star rating', () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        provider.markPhaseFeedback(); // spinner while uploading
        expect(provider.phase, LearningPhase.stepFeedback);

        provider.applyPronunciationResult(
          _pronunciation(questionId: 1, score: 92),
        );

        final tracker = provider.trackers[1]!;
        expect(tracker.starsEarned, 3); // score>=90 => 3 stars
        expect(tracker.everCorrect, isTrue);
        expect(tracker.lastPronunciationScore!.score, 92);
        expect(tracker.lastResult!.isCorrect, isTrue);
        expect(provider.phase, LearningPhase.stepFeedback);
      });

      test('second-attempt correct pronunciation is capped at 2 stars',
          () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        provider.applyPronunciationResult(
          _pronunciation(questionId: 1, score: 40, feedback: 'حاول مرة أخرى'),
        );
        expect(provider.phase, LearningPhase.stepRetry);

        provider.retryCurrentQuestion();
        provider.applyPronunciationResult(
          _pronunciation(questionId: 1, score: 95),
        );

        expect(provider.trackers[1]!.starsEarned, 2); // capped
        expect(provider.phase, LearningPhase.stepFeedback);
      });

      test('unavailable-service zero score degrades to the retry path without '
          'crashing', () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        provider.applyPronunciationResult(
          _pronunciation(
            questionId: 1,
            score: 0,
            feedback: 'خدمة النطق غير متاحة الآن',
          ),
        );

        expect(provider.phase, LearningPhase.stepRetry);
        expect(
          provider.trackers[1]!.lastResult!.feedback,
          'خدمة النطق غير متاحة الآن',
        );
        expect(provider.errorMessage, isNull);
      });

      test('markPhaseActive recovers from an in-flight upload failure', () {
        final provider = LearningProvider(FakeQuizService(_quiz()));
        provider.markPhaseFeedback();
        provider.markPhaseActive();
        expect(provider.phase, LearningPhase.stepActive);
      });
    });

    group('tracing', () {
      test('successful tracing persists to backend and earns given stars',
          () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        await provider.applyTracingResult(
          score: 85,
          stars: 3,
          feedback: 'ممتاز',
        );

        final tracker = provider.trackers[1]!;
        expect(tracker.starsEarned, 3);
        expect(tracker.lastTracingScore, 85);
        expect(tracker.lastResult!.isCorrect, isTrue);
        expect(provider.phase, LearningPhase.stepFeedback);
        expect(service.tracingSubmissions.single['questionId'], 1);
        expect(service.tracingSubmissions.single['score'], 85);
      });

      test('tracing persistence failure is non-fatal and keeps the flow',
          () async {
        final service = FakeQuizService(_quiz())..throwOnTracing = true;
        final provider = await _atFirstQuestion(service);

        await provider.applyTracingResult(
          score: 85,
          stars: 3,
          feedback: 'ممتاز',
        );

        expect(provider.phase, LearningPhase.stepFeedback);
        expect(provider.trackers[1]!.starsEarned, 3);
        expect(provider.errorMessage, isNull);
      });

      test('low tracing score follows the retry path', () async {
        final service = FakeQuizService(_quiz());
        final provider = await _atFirstQuestion(service);

        await provider.applyTracingResult(
          score: 40,
          stars: 0,
          feedback: 'حاول مرة أخرى',
        );

        expect(provider.phase, LearningPhase.stepRetry);
        expect(provider.trackers[1]!.lastResult!.isCorrect, isFalse);
      });
    });
  });
}
