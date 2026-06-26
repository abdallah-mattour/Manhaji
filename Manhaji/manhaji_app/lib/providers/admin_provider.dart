import 'package:flutter/material.dart';
import '../models/admin_stats.dart';
import '../services/admin_service.dart';
import '../utils/error_handler.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service;

  AdminProvider(this._service);

  AdminStats? _stats;
  List<UserSummary>? _users;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  AdminStats? get stats => _stats;
  List<UserSummary>? get users => _users;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;

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
        _users = _users!.where((u) => u.userId != userId).toList(growable: false);
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
}
