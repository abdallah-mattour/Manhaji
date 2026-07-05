import 'package:flutter/material.dart';
import '../models/admin_stats.dart';
import '../models/admin_teacher_assignment.dart';
import '../models/question_bank.dart';
import '../services/admin_service.dart';
import '../utils/error_handler.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service;

  AdminProvider(this._service);

  AdminStats? _stats;
  List<UserSummary>? _users;
  List<SubjectSummary>? _assignmentSubjects;
  List<AdminTeacherAssignment>? _teacherAssignments;
  bool _isLoading = false;
  bool _isMutating = false;
  bool _isLoadingAssignments = false;
  String? _error;
  String? _assignmentError;

  AdminStats? get stats => _stats;
  List<UserSummary>? get users => _users;
  List<SubjectSummary>? get assignmentSubjects => _assignmentSubjects;
  List<AdminTeacherAssignment>? get teacherAssignments => _teacherAssignments;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get isLoadingAssignments => _isLoadingAssignments;
  String? get error => _error;
  String? get assignmentError => _assignmentError;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _service.getStats();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _service.getUsers(role: role);
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns true on success. On failure, [error] holds the message.
  Future<bool> createUser({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    required String role,
    int? gradeLevel,
    String? department,
    int? assignedGrade,
    List<TeacherAssignmentPayload>? teacherAssignments,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _service.createUser(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
        gradeLevel: gradeLevel,
        department: department,
        assignedGrade: assignedGrade,
        teacherAssignments: teacherAssignments,
      );
      _users = [...?_users, created];
      return true;
    } catch (e) {
      _error = extractError(e);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(
    int userId, {
    String? fullName,
    String? email,
    String? phone,
    String? password,
    bool? isActive,
    int? gradeLevel,
    String? department,
    int? assignedGrade,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateUser(
        userId,
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        isActive: isActive,
        gradeLevel: gradeLevel,
        department: department,
        assignedGrade: assignedGrade,
      );
      if (_users != null) {
        _users = _users!
            .map((u) => u.userId == userId ? updated : u)
            .toList(growable: false);
      }
      return true;
    } catch (e) {
      _error = extractError(e);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int userId) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteUser(userId);
      if (_users != null) {
        _users = _users!
            .where((u) => u.userId != userId)
            .toList(growable: false);
      }
      return true;
    } catch (e) {
      _error = extractError(e);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> linkStudentToParent(int studentId, int? parentId) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.linkStudentToParent(studentId, parentId);
      if (_users != null) {
        _users = _users!
            .map((u) => u.userId == studentId ? updated : u)
            .toList(growable: false);
      }
      return true;
    } catch (e) {
      _error = extractError(e);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> loadAssignmentSubjects() async {
    if (_assignmentSubjects != null) return;
    _isLoadingAssignments = true;
    _assignmentError = null;
    notifyListeners();
    try {
      _assignmentSubjects = await _service.getAllSubjects();
    } catch (e) {
      _assignmentError = extractError(e);
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }

  Future<void> loadTeacherAssignments(int teacherId) async {
    _isLoadingAssignments = true;
    _assignmentError = null;
    _teacherAssignments = null;
    notifyListeners();
    try {
      _teacherAssignments = await _service.getTeacherAssignments(teacherId);
    } catch (e) {
      _assignmentError = extractError(e);
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }

  Future<bool> saveTeacherAssignments(
    int teacherId,
    List<TeacherAssignmentPayload> assignments,
  ) async {
    _isMutating = true;
    _assignmentError = null;
    notifyListeners();
    try {
      _teacherAssignments = await _service.updateTeacherAssignments(
        teacherId,
        assignments,
      );
      return true;
    } catch (e) {
      _assignmentError = extractError(e);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
