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

  // Profile fields — populated by fetchProfile() via GET /auth/me.
  String? _userEmail;
  String? _userPhone;
  String? _userAvatarId;
  bool _isProfileLoading = false;
  String? _profileError;

  AuthProvider(this._authService, this._storage) {
    _isLoggedIn = _storage.isLoggedIn;
    _userName = _storage.getUserName();
    _userRole = _storage.getUserRole();
    _userId = _storage.getUserId();
    _userAvatarId = _storage.getUserAvatarId();
  }

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  String? get userRole => _userRole;
  int? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get userAvatarId => _userAvatarId;
  int? get userGradeLevel => _storage.getGradeLevel();
  bool get isProfileLoading => _isProfileLoading;
  String? get profileError => _profileError;

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
    _userEmail = null;
    _userPhone = null;
    _userAvatarId = null;
    notifyListeners();
  }

  Future<void> _handleAuthSuccess(AuthResponse response) async {
    await _storage.saveTokens(response.accessToken, response.refreshToken);
    await _storage.saveUserInfo(
      userId: response.userId,
      role: response.role,
      name: response.fullName,
      gradeLevel: response.gradeLevel,
      avatarId: response.avatarId,
    );
    _isLoggedIn = true;
    _userName = response.fullName;
    _userRole = response.role;
    _userId = response.userId;
    _userEmail = response.email;
    _userPhone = response.phone;
    _userAvatarId = response.avatarId;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = extractError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    String? email,
    String? phone,
    String? avatarId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.updateProfile(
        fullName: fullName,
        email: email,
        phone: phone,
        avatarId: avatarId,
      );
      _applyProfile(response);
      _userName ??= fullName;
      await _persistLocalUserInfo(fallbackName: fullName);
      return true;
    } catch (e) {
      _errorMessage = extractError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches supplemental profile fields (email, phone) from GET /auth/me.
  /// Name, role, and gradeLevel are already available locally without a call.
  Future<void> fetchProfile() async {
    if (_isProfileLoading) return;
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      final response = await _authService.getCurrentUser();
      _applyProfile(response);
      await _persistLocalUserInfo();
      _profileError = null;
    } catch (e) {
      _profileError = extractError(e);
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  void _applyProfile(AuthResponse response) {
    _userId = response.userId == 0 ? _userId : response.userId;
    _userName = response.fullName.isEmpty ? _userName : response.fullName;
    _userRole = response.role.isEmpty ? _userRole : response.role;
    _userEmail = response.email;
    _userPhone = response.phone;
    _userAvatarId = response.avatarId;
  }

  Future<void> _persistLocalUserInfo({String? fallbackName}) async {
    if (_userId == null || _userRole == null) return;
    final name = _userName?.trim().isNotEmpty == true
        ? _userName!
        : fallbackName;
    if (name == null || name.trim().isEmpty) return;
    await _storage.saveUserInfo(
      userId: _userId!,
      role: _userRole!,
      name: name,
      gradeLevel: _storage.getGradeLevel(),
      avatarId: _userAvatarId,
    );
  }
}
