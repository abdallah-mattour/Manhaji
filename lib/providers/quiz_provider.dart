import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizApiService _quizService;

  bool _isLoading = false;
  String? _errorMessage;

  Quiz? _currentQuiz;
  int? _currentAttemptId;
  int _currentQuestionIndex = 0;
  SubmitAnswerResult? _lastAnswerResult;
  AttemptResult? _attemptResult;
  int _totalPointsEarned = 0;
  int _totalCorrect = 0;

  // Track which questions have been answered
  final Map<int, SubmitAnswerResult> _answeredQuestions = {};

  QuizProvider(this._quizService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Quiz? get currentQuiz => _currentQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  SubmitAnswerResult? get lastAnswerResult => _lastAnswerResult;
  AttemptResult? get attemptResult => _attemptResult;
  int get totalPointsEarned => _totalPointsEarned;
  int get totalCorrect => _totalCorrect;
  Map<int, SubmitAnswerResult> get answeredQuestions => _answeredQuestions;

  Question? get currentQuestion {
    if (_currentQuiz == null ||
        _currentQuestionIndex >= _currentQuiz!.questions.length) {
      return null;
    }
    return _currentQuiz!.questions[_currentQuestionIndex];
  }

  bool get isLastQuestion =>
      _currentQuiz != null &&
      _currentQuestionIndex >= _currentQuiz!.questions.length - 1;

  bool get hasAnsweredCurrent {
    if (currentQuestion == null) return false;
    return _answeredQuestions.containsKey(currentQuestion!.id);
  }

  // Load quiz and start attempt
  Future<void> startQuiz(int lessonId) async {
    _isLoading = true;
    _errorMessage = null;
    _resetState();
    notifyListeners();

    try {
      _currentQuiz = await _quizService.getQuizByLesson(lessonId);
      final attempt = await _quizService.startAttempt(_currentQuiz!.id);
      _currentAttemptId = attempt.attemptId;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit answer for current question
  Future<void> submitAnswer(String answer) async {
    if (_currentAttemptId == null || currentQuestion == null) return;

    _isLoading = true;
    _lastAnswerResult = null;
    notifyListeners();

    try {
      final question = currentQuestion!;
      _lastAnswerResult = await _quizService.submitAnswer(
        _currentAttemptId!,
        questionId: question.id,
        answer: answer,
      );

      _answeredQuestions[question.id] = _lastAnswerResult!;
      _totalPointsEarned += _lastAnswerResult!.pointsEarned;
      if (_lastAnswerResult!.isCorrect) {
        _totalCorrect++;
      }
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Move to next question
  void nextQuestion() {
    if (!isLastQuestion) {
      _currentQuestionIndex++;
      _lastAnswerResult = null;
      notifyListeners();
    }
  }

  // Complete the quiz and get results
  Future<void> completeQuiz() async {
    if (_currentAttemptId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _attemptResult = await _quizService.completeAttempt(_currentAttemptId!);
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetState() {
    _currentQuiz = null;
    _currentAttemptId = null;
    _currentQuestionIndex = 0;
    _lastAnswerResult = null;
    _attemptResult = null;
    _totalPointsEarned = 0;
    _totalCorrect = 0;
    _answeredQuestions.clear();
  }

  String _extractError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return e.response!.data['message'] ?? 'حدث خطأ';
    }
    return 'حدث خطأ في الاتصال';
  }
}
