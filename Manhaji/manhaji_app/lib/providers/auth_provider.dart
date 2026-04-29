import 'package:flutter/material.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../utils/error_handler.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final LocalStorageService _storage;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? _userName;
  String? _userRole;
  int? _userId;

  AuthProvider(this._authService, this._storage) {
    _isLoggedIn = _storage.isLoggedIn;
    _userName = _storage.getUserName();
    _userRole = _storage.getUserRole();
    _userId = _storage.getUserId();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  String? get userRole => _userRole;
  int? get userId => _userId;

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required int gradeLevel,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        gradeLevel: gradeLevel,
      );
      await _handleAuthSuccess(response);
      return true;
    } catch (e) {
      _errorMessage = extractError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      await _handleAuthSuccess(response);
      return true;
    } catch (e) {
      _errorMessage = extractError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.loginWithPhone(
        phone: phone,
        password: password,
      );
      await _handleAuthSuccess(response);
      return true;
    } catch (e) {
      _errorMessage = extractError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _isLoggedIn = false;
    _userName = null;
    _userRole = null;
    _userId = null;
    notifyListeners();
  }

  Future<void> _handleAuthSuccess(AuthResponse response) async {
    await _storage.saveTokens(response.accessToken, response.refreshToken);
    await _storage.saveUserInfo(
      userId: response.userId,
      role: response.role,
      name: response.fullName,
      gradeLevel: response.gradeLevel,
    );
    _isLoggedIn = true;
    _userName = response.fullName;
    _userRole = response.role;
    _userId = response.userId;
  }

}
