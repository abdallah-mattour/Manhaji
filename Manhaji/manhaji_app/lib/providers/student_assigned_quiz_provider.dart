import 'package:flutter/material.dart';

import '../models/student_assigned_quiz.dart';
import '../services/quiz_service.dart';
import '../utils/error_handler.dart';

class StudentAssignedQuizProvider extends ChangeNotifier {
  final QuizApiService _quizService;

  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _errorMessage;
  String? _detailErrorMessage;
  List<StudentAssignedQuizSummary> _assignedQuizzes = const [];

  StudentAssignedQuizProvider(this._quizService);

  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;
  List<StudentAssignedQuizSummary> get assignedQuizzes => _assignedQuizzes;

  Future<void> loadAssignedQuizzes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assignedQuizzes = await _quizService.getAssignedQuizzes();
    } catch (e) {
      _errorMessage = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StudentAssignedQuizDetail?> loadAssignedQuizDetail(
    int assignmentId,
  ) async {
    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      return await _quizService.getAssignedQuizDetail(assignmentId);
    } catch (e) {
      _detailErrorMessage = extractError(e);
      return null;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }
}
