import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../models/lesson.dart';
import '../models/subject.dart';
import '../services/lesson_service.dart';

class LessonProvider extends ChangeNotifier {
  final LessonApiService _lessonService;

  bool _isLoading = false;
  String? _errorMessage;

  Dashboard? _dashboard;
  List<Subject> _subjects = [];
  List<LessonSummary> _currentLessons = [];
  Lesson? _currentLesson;

  LessonProvider(this._lessonService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Dashboard? get dashboard => _dashboard;
  List<Subject> get subjects => _subjects;
  List<LessonSummary> get currentLessons => _currentLessons;
  Lesson? get currentLesson => _currentLesson;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _lessonService.getDashboard();
      _subjects = _dashboard!.subjects;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubjects(int gradeLevel) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subjects = await _lessonService.getSubjectsByGrade(gradeLevel);
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLessons(int subjectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentLessons = await _lessonService.getLessonsBySubject(subjectId);
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLesson(int lessonId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentLesson = await _lessonService.getLessonDetail(lessonId);
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return e.response!.data['message'] ?? 'حدث خطأ';
    }
    return 'حدث خطأ في الاتصال';
  }
}
