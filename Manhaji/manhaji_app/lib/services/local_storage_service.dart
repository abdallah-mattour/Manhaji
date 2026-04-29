import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LocalStorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _prefs?.setString(AppConstants.tokenKey, accessToken);
    await _prefs?.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  Future<String?> getToken() async {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _prefs?.getString(AppConstants.refreshTokenKey);
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
    await _prefs?.clear();
  }

  bool get isLoggedIn => _prefs?.getString(AppConstants.tokenKey) != null;

  // Onboarding flags — one-time tips per AI question type.
  static const _kSeenPronunciationTip = 'seen_pronunciation_tip';
  static const _kSeenTracingTip = 'seen_tracing_tip';

  bool get seenPronunciationTip =>
      _prefs?.getBool(_kSeenPronunciationTip) ?? false;
  bool get seenTracingTip => _prefs?.getBool(_kSeenTracingTip) ?? false;

  Future<void> markPronunciationTipSeen() async =>
      _prefs?.setBool(_kSeenPronunciationTip, true);
  Future<void> markTracingTipSeen() async =>
      _prefs?.setBool(_kSeenTracingTip, true);
}
