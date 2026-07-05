import 'package:flutter/material.dart';
import '../models/question_bank.dart';
import '../models/teacher_dashboard.dart';
import '../models/teacher_mistake_analytics.dart';
import '../models/teacher_quiz.dart';
import '../services/teacher_service.dart';
import '../utils/error_handler.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherService _service;

  TeacherProvider(this._service);

  TeacherDashboard? _dashboard;
  List<ClassStudentSummary>? _students;
  List<SubjectSummary>? _assignedSubjects;
  StudentDetail? _studentDetail;
  TeacherMistakeAnalytics? _mistakeAnalytics;
  List<TeacherQuizSummary>? _teacherQuizzes;
  QuestionBankResponse? _quizQuestionBank;
  bool _isLoading = false;
  bool _isMistakeAnalyticsLoading = false;
  bool _isTeacherQuizzesLoading = false;
  bool _isQuizQuestionBankLoading = false;
  bool _isCreatingTeacherQuiz = false;
  String? _error;
  String? _mistakeAnalyticsError;
  String? _teacherQuizzesError;
  String? _quizQuestionBankError;
  String? _createTeacherQuizError;

  TeacherDashboard? get dashboard => _dashboard;
  List<ClassStudentSummary>? get students => _students;
  List<SubjectSummary>? get assignedSubjects => _assignedSubjects;
  StudentDetail? get studentDetail => _studentDetail;
  TeacherMistakeAnalytics? get mistakeAnalytics => _mistakeAnalytics;
  List<TeacherQuizSummary>? get teacherQuizzes => _teacherQuizzes;
  QuestionBankResponse? get quizQuestionBank => _quizQuestionBank;
  bool get isLoading => _isLoading;
  bool get isMistakeAnalyticsLoading => _isMistakeAnalyticsLoading;
  bool get isTeacherQuizzesLoading => _isTeacherQuizzesLoading;
  bool get isQuizQuestionBankLoading => _isQuizQuestionBankLoading;
  bool get isCreatingTeacherQuiz => _isCreatingTeacherQuiz;
  String? get error => _error;
  String? get mistakeAnalyticsError => _mistakeAnalyticsError;
  String? get teacherQuizzesError => _teacherQuizzesError;
  String? get quizQuestionBankError => _quizQuestionBankError;
  String? get createTeacherQuizError => _createTeacherQuizError;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await _service.getDashboard();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _students = await _service.getStudents();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssignedSubjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _assignedSubjects = await _service.getAssignedSubjects();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentDetail(int studentId) async {
    _isLoading = true;
    _error = null;
    _studentDetail = null;
    notifyListeners();
    try {
      _studentDetail = await _service.getStudentDetail(studentId);
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMistakeAnalytics({
    int? subjectId,
    int? lessonId,
    int? studentId,
    int? limit,
  }) async {
    _isMistakeAnalyticsLoading = true;
    _mistakeAnalyticsError = null;
    notifyListeners();
    try {
      _mistakeAnalytics = await _service.getMistakeAnalytics(
        subjectId: subjectId,
        lessonId: lessonId,
        studentId: studentId,
        limit: limit,
      );
    } catch (e) {
      _mistakeAnalyticsError = extractError(e);
    } finally {
      _isMistakeAnalyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeacherQuizzes() async {
    _isTeacherQuizzesLoading = true;
    _teacherQuizzesError = null;
    notifyListeners();
    try {
      _teacherQuizzes = await _service.getTeacherQuizzes();
    } catch (e) {
      _teacherQuizzesError = extractError(e);
    } finally {
      _isTeacherQuizzesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuizQuestionBank(int subjectId) async {
    _isQuizQuestionBankLoading = true;
    _quizQuestionBankError = null;
    _quizQuestionBank = null;
    notifyListeners();
    try {
      _quizQuestionBank = await _service.getQuestionsForSubject(subjectId);
    } catch (e) {
      _quizQuestionBankError = extractError(e);
    } finally {
      _isQuizQuestionBankLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTeacherQuiz({
    required String title,
    required int subjectId,
    int? lessonId,
    required List<int> questionIds,
  }) async {
    _isCreatingTeacherQuiz = true;
    _createTeacherQuizError = null;
    notifyListeners();
    try {
      final created = await _service.createTeacherQuiz(
        title: title,
        subjectId: subjectId,
        lessonId: lessonId,
        questionIds: questionIds,
      );
      final current = _teacherQuizzes ?? const <TeacherQuizSummary>[];
      _teacherQuizzes = [
        created,
        ...current.where((quiz) => quiz.id != created.id),
      ];
      return true;
    } catch (e) {
      _createTeacherQuizError = extractError(e);
      return false;
    } finally {
      _isCreatingTeacherQuiz = false;
      notifyListeners();
    }
  }
}
