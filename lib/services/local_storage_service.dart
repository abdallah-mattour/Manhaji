import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LocalStorageService {
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    final hasActiveSession = token != null && token.isNotEmpty;
    await _prefs?.setBool(AppConstants.sessionActiveKey, hasActiveSession);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: accessToken);
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
    await _prefs?.setBool(AppConstants.sessionActiveKey, true);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveUserInfo({
    required int userId,
    required String role,
    required String name,
    int? gradeLevel,
  }) async {
    await _prefs?.setInt(AppConstants.userIdKey, userId);
    await _prefs?.setString(AppConstants.userRoleKey, role);
    await _prefs?.setString(AppConstants.userNameKey, name);
    if (gradeLevel != null) {
      await _prefs?.setInt(AppConstants.gradeKey, gradeLevel);
    }
  }

  int? getUserId() => _prefs?.getInt(AppConstants.userIdKey);
  String? getUserRole() => _prefs?.getString(AppConstants.userRoleKey);
  String? getUserName() => _prefs?.getString(AppConstants.userNameKey);
  int? getGradeLevel() => _prefs?.getInt(AppConstants.gradeKey);

  Future<void> clearAll() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _prefs?.clear();
  }

  bool get isLoggedIn => _prefs?.getBool(AppConstants.sessionActiveKey) ?? false;
}
