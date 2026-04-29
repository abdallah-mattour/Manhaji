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
  String? _error;

  AdminStats? get stats => _stats;
  List<UserSummary>? get users => _users;
  bool get isLoading => _isLoading;
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
}
