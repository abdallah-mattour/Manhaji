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
  final Map<int, List<TeacherQuizAssignment>> _quizAssignments = {};
  final Map<int, String> _quizAssignmentsErrors = {};
  final Set<int> _loadingQuizAssignments = {};
  final Map<int, TeacherAssignmentResults> _assignmentResults = {};
  final Map<int, String> _assignmentResultsErrors = {};
  final Set<int> _loadingAssignmentResults = {};
  bool _isLoading = false;
  bool _isMistakeAnalyticsLoading = false;
  bool _isTeacherQuizzesLoading = false;
  bool _isQuizQuestionBankLoading = false;
  bool _isCreatingTeacherQuiz = false;
  bool _isPublishingTeacherQuiz = false;
  int? _publishingQuizId;
  String? _error;
  String? _mistakeAnalyticsError;
  String? _teacherQuizzesError;
  String? _quizQuestionBankError;
  String? _createTeacherQuizError;
  String? _publishTeacherQuizError;

  TeacherDashboard? get dashboard => _dashboard;
  List<ClassStudentSummary>? get students => _students;
  List<SubjectSummary>? get assignedSubjects => _assignedSubjects;
  StudentDetail? get studentDetail => _studentDetail;
  TeacherMistakeAnalytics? get mistakeAnalytics => _mistakeAnalytics;
  List<TeacherQuizSummary>? get teacherQuizzes => _teacherQuizzes;
  QuestionBankResponse? get quizQuestionBank => _quizQuestionBank;
  Map<int, List<TeacherQuizAssignment>> get quizAssignments =>
      Map.unmodifiable(_quizAssignments);
  Map<int, TeacherAssignmentResults> get assignmentResults =>
      Map.unmodifiable(_assignmentResults);
  bool get isLoading => _isLoading;
  bool get isMistakeAnalyticsLoading => _isMistakeAnalyticsLoading;
  bool get isTeacherQuizzesLoading => _isTeacherQuizzesLoading;
  bool get isQuizQuestionBankLoading => _isQuizQuestionBankLoading;
  bool get isCreatingTeacherQuiz => _isCreatingTeacherQuiz;
  bool get isPublishingTeacherQuiz => _isPublishingTeacherQuiz;
  int? get publishingQuizId => _publishingQuizId;
  String? get error => _error;
  String? get mistakeAnalyticsError => _mistakeAnalyticsError;
  String? get teacherQuizzesError => _teacherQuizzesError;
  String? get quizQuestionBankError => _quizQuestionBankError;
  String? get createTeacherQuizError => _createTeacherQuizError;
  String? get publishTeacherQuizError => _publishTeacherQuizError;

  List<TeacherQuizAssignment>? quizAssignmentsFor(int quizId) {
    return _quizAssignments[quizId];
  }

  String? quizAssignmentsErrorFor(int quizId) {
    return _quizAssignmentsErrors[quizId];
  }

  bool isLoadingQuizAssignments(int quizId) {
    return _loadingQuizAssignments.contains(quizId);
  }

  TeacherAssignmentResults? assignmentResultsFor(int assignmentId) {
    return _assignmentResults[assignmentId];
  }

  String? assignmentResultsErrorFor(int assignmentId) {
    return _assignmentResultsErrors[assignmentId];
  }

  bool isLoadingAssignmentResults(int assignmentId) {
    return _loadingAssignmentResults.contains(assignmentId);
  }

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

  Future<bool> publishTeacherQuiz({
    required int quizId,
    required int gradeLevel,
    DateTime? dueAt,
    required int maxAttempts,
    List<int>? studentIds,
  }) async {
    _isPublishingTeacherQuiz = true;
    _publishingQuizId = quizId;
    _publishTeacherQuizError = null;
    notifyListeners();
    try {
      final assignment = await _service.publishQuizAssignment(
        quizId: quizId,
        gradeLevel: gradeLevel,
        dueAt: dueAt,
        maxAttempts: maxAttempts,
        studentIds: studentIds,
      );
      final current =
          _quizAssignments[quizId] ?? const <TeacherQuizAssignment>[];
      _quizAssignments[quizId] = [
        assignment,
        ...current.where(
          (item) => item.assignmentId != assignment.assignmentId,
        ),
      ];
      _teacherQuizzes = await _service.getTeacherQuizzes();
      return true;
    } catch (e) {
      _publishTeacherQuizError = extractError(e);
      return false;
    } finally {
      _isPublishingTeacherQuiz = false;
      _publishingQuizId = null;
      notifyListeners();
    }
  }

  Future<void> loadQuizAssignments(int quizId) async {
    _loadingQuizAssignments.add(quizId);
    _quizAssignmentsErrors.remove(quizId);
    notifyListeners();
    try {
      _quizAssignments[quizId] = await _service.getQuizAssignments(quizId);
    } catch (e) {
      _quizAssignmentsErrors[quizId] = extractError(e);
    } finally {
      _loadingQuizAssignments.remove(quizId);
      notifyListeners();
    }
  }

  Future<void> loadAssignmentResults(int assignmentId) async {
    _loadingAssignmentResults.add(assignmentId);
    _assignmentResultsErrors.remove(assignmentId);
    notifyListeners();
    try {
      _assignmentResults[assignmentId] = await _service.getAssignmentResults(
        assignmentId,
      );
    } catch (e) {
      _assignmentResultsErrors[assignmentId] = extractError(e);
    } finally {
      _loadingAssignmentResults.remove(assignmentId);
      notifyListeners();
    }
  }
}
