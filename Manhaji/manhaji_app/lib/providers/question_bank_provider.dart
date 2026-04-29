import 'package:flutter/foundation.dart';
import '../models/question_bank.dart';
import '../services/admin_service.dart';
import '../services/teacher_service.dart';
import '../utils/error_handler.dart';

/// Drives the teacher/admin question-bank viewer.
///
/// The same UI is reused for both roles. Callers pick the data source
/// by invoking [loadSubjectsForTeacher]/[loadSubjectsForAdmin] and
/// [loadQuestionsForTeacher]/[loadQuestionsForAdmin] respectively.
///
/// State held in one place:
///   - [subjects]: the grid view
///   - [currentResponse]: the questions + lessons for the selected subject
///   - [selectedDifficulty] / [selectedLessonId]: the active filters
class QuestionBankProvider extends ChangeNotifier {
  final TeacherService _teacher;
  final AdminService _admin;

  QuestionBankProvider(this._teacher, this._admin);

  // ===== State =====
  bool _loadingSubjects = false;
  bool _loadingQuestions = false;
  String? _error;
  List<SubjectSummary> _subjects = const [];
  QuestionBankResponse? _currentResponse;
  int? _currentSubjectId;
  int? _selectedDifficulty;
  int? _selectedLessonId;
  int? _adminGradeFilter;

  bool get loadingSubjects => _loadingSubjects;
  bool get loadingQuestions => _loadingQuestions;
  String? get error => _error;
  List<SubjectSummary> get subjects => _subjects;
  QuestionBankResponse? get currentResponse => _currentResponse;
  int? get currentSubjectId => _currentSubjectId;
  int? get selectedDifficulty => _selectedDifficulty;
  int? get selectedLessonId => _selectedLessonId;
  int? get adminGradeFilter => _adminGradeFilter;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetForSubject(int subjectId) {
    _currentSubjectId = subjectId;
    _currentResponse = null;
    _selectedDifficulty = null;
    _selectedLessonId = null;
    _error = null;
  }

  // ===== Teacher data source =====

  Future<void> loadSubjectsForTeacher() async {
    _loadingSubjects = true;
    _error = null;
    notifyListeners();
    try {
      _subjects = await _teacher.getAssignedSubjects();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _loadingSubjects = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestionsForTeacher(int subjectId) async {
    _currentSubjectId = subjectId;
    _loadingQuestions = true;
    _error = null;
    notifyListeners();
    try {
      _currentResponse = await _teacher.getQuestionsForSubject(
        subjectId,
        difficulty: _selectedDifficulty,
        lessonId: _selectedLessonId,
      );
    } catch (e) {
      _error = extractError(e);
    } finally {
      _loadingQuestions = false;
      notifyListeners();
    }
  }

  // ===== Admin data source =====

  Future<void> loadSubjectsForAdmin({int? grade}) async {
    _adminGradeFilter = grade;
    _loadingSubjects = true;
    _error = null;
    notifyListeners();
    try {
      _subjects = await _admin.getAllSubjects(grade: grade);
    } catch (e) {
      _error = extractError(e);
    } finally {
      _loadingSubjects = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestionsForAdmin(int subjectId) async {
    _currentSubjectId = subjectId;
    _loadingQuestions = true;
    _error = null;
    notifyListeners();
    try {
      _currentResponse = await _admin.getQuestionsForSubject(
        subjectId,
        difficulty: _selectedDifficulty,
        lessonId: _selectedLessonId,
      );
    } catch (e) {
      _error = extractError(e);
    } finally {
      _loadingQuestions = false;
      notifyListeners();
    }
  }

  // ===== Filters =====

  /// Updates the difficulty filter and re-fetches. Pass null to clear.
  Future<void> setDifficulty(int? difficulty, {required bool asAdmin}) async {
    if (_selectedDifficulty == difficulty) return;
    _selectedDifficulty = difficulty;
    if (_currentSubjectId != null) {
      if (asAdmin) {
        await loadQuestionsForAdmin(_currentSubjectId!);
      } else {
        await loadQuestionsForTeacher(_currentSubjectId!);
      }
    } else {
      notifyListeners();
    }
  }

  /// Updates the lesson filter and re-fetches. Pass null to clear.
  Future<void> setLesson(int? lessonId, {required bool asAdmin}) async {
    if (_selectedLessonId == lessonId) return;
    _selectedLessonId = lessonId;
    if (_currentSubjectId != null) {
      if (asAdmin) {
        await loadQuestionsForAdmin(_currentSubjectId!);
      } else {
        await loadQuestionsForTeacher(_currentSubjectId!);
      }
    } else {
      notifyListeners();
    }
  }
}
