import 'package:flutter/material.dart';
import '../models/teacher_dashboard.dart';
import '../services/teacher_service.dart';
import '../utils/error_handler.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherService _service;

  TeacherProvider(this._service);

  TeacherDashboard? _dashboard;
  List<ClassStudentSummary>? _students;
  StudentDetail? _studentDetail;
  bool _isLoading = false;
  String? _error;

  TeacherDashboard? get dashboard => _dashboard;
  List<ClassStudentSummary>? get students => _students;
  StudentDetail? get studentDetail => _studentDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
}
