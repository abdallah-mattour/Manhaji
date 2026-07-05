import 'package:flutter/material.dart';
import '../models/question_bank.dart';
import '../models/teacher_dashboard.dart';
import '../models/teacher_mistake_analytics.dart';
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
  bool _isLoading = false;
  bool _isMistakeAnalyticsLoading = false;
  String? _error;
  String? _mistakeAnalyticsError;

  TeacherDashboard? get dashboard => _dashboard;
  List<ClassStudentSummary>? get students => _students;
  List<SubjectSummary>? get assignedSubjects => _assignedSubjects;
  StudentDetail? get studentDetail => _studentDetail;
  TeacherMistakeAnalytics? get mistakeAnalytics => _mistakeAnalytics;
  bool get isLoading => _isLoading;
  bool get isMistakeAnalyticsLoading => _isMistakeAnalyticsLoading;
  String? get error => _error;
  String? get mistakeAnalyticsError => _mistakeAnalyticsError;

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
}
