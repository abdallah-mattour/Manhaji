import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// Storage for tokens (secure) and user profile / onboarding flags (plain prefs).
///
/// Audit fix (post-review 2026-05-24): JWT access + refresh tokens used to live
/// in `SharedPreferences`, which on Android is a plaintext XML file under
/// `/data/data/<pkg>/shared_prefs/`. That's readable on rooted devices and via
/// `adb backup` on debuggable builds — fine for emulator, not fine for a real
/// device. Tokens now live in `FlutterSecureStorage` (Android Keystore /
/// iOS Keychain); non-secret prefs (userId, role, name, gradeLevel, onboarding
/// flags) stay in `SharedPreferences` so synchronous getters keep working.
///
/// Token presence is cached as a sync field after `init()` so `isLoggedIn`
/// remains a sync getter (used by `SplashScreen` and `AuthProvider`'s constructor
/// to decide the start route without an async await).
class LocalStorageService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SharedPreferences? _prefs;
  bool _hasToken = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Migrate any legacy plaintext tokens that survived from before this change
    // so existing dev installs don't lose their login on first boot of the new
    // version. The old keys are removed after the move.
    await _migrateLegacyTokens();
    _hasToken = (await _secureStorage.read(key: AppConstants.tokenKey)) != null;
  }

  Future<void> _migrateLegacyTokens() async {
    final legacyAccess = _prefs?.getString(AppConstants.tokenKey);
    final legacyRefresh = _prefs?.getString(AppConstants.refreshTokenKey);
    if (legacyAccess == null && legacyRefresh == null) return;
    if (legacyAccess != null) {
      await _secureStorage.write(
        key: AppConstants.tokenKey,
        value: legacyAccess,
      );
    }
    if (legacyRefresh != null) {
      await _secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: legacyRefresh,
      );
    }
    await _prefs?.remove(AppConstants.tokenKey);
    await _prefs?.remove(AppConstants.refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: accessToken);
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
    _hasToken = true;
  }

  Future<String?> getToken() {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() {
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveUserInfo({
    required int userId,
    required String role,
    required String name,
    int? gradeLevel,
    String? avatarId,
  }) async {
    await _prefs?.setInt(AppConstants.userIdKey, userId);
    await _prefs?.setString(AppConstants.userRoleKey, role);
    await _prefs?.setString(AppConstants.userNameKey, name);
    if (gradeLevel != null) {
      await _prefs?.setInt(AppConstants.gradeKey, gradeLevel);
    }
    final normalizedAvatar = avatarId?.trim();
    if (normalizedAvatar != null && normalizedAvatar.isNotEmpty) {
      await _prefs?.setString(AppConstants.avatarIdKey, normalizedAvatar);
    } else {
      await _prefs?.remove(AppConstants.avatarIdKey);
    }
  }

  int? getUserId() => _prefs?.getInt(AppConstants.userIdKey);
  String? getUserRole() => _prefs?.getString(AppConstants.userRoleKey);
  String? getUserName() => _prefs?.getString(AppConstants.userNameKey);
  int? getGradeLevel() => _prefs?.getInt(AppConstants.gradeKey);
  String? getUserAvatarId() => _prefs?.getString(AppConstants.avatarIdKey);
  String? getSelectedRewardId() =>
      _prefs?.getString(AppConstants.selectedRewardIdKey);

  Future<void> setSelectedRewardId(String rewardId) async {
    final normalized = rewardId.trim();
    if (normalized.isEmpty) {
      await _prefs?.remove(AppConstants.selectedRewardIdKey);
      return;
    }
    await _prefs?.setString(AppConstants.selectedRewardIdKey, normalized);
  }

  /// Wipe auth state on logout. Onboarding tip flags survive — there's no
  /// reason to re-show "اضغط الميكروفون" every time a kid logs out.
  Future<void> clearAll() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _prefs?.remove(AppConstants.userIdKey);
    await _prefs?.remove(AppConstants.userRoleKey);
    await _prefs?.remove(AppConstants.userNameKey);
    await _prefs?.remove(AppConstants.gradeKey);
    await _prefs?.remove(AppConstants.avatarIdKey);
    await _prefs?.remove(AppConstants.selectedRewardIdKey);
    _hasToken = false;
  }

  bool get isLoggedIn => _hasToken;

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

  // Phase 8A — Student "الوضع الصامت": when true, learning screens skip
  // AUTOMATIC audio playback (TTS on step change, verdict sounds). Manual
  // speaker buttons and voice answers are never affected. Defaults to OFF.
  static const _kStudentSilentMode = 'student_silent_mode';

  bool get isSilentModeEnabled => _prefs?.getBool(_kStudentSilentMode) ?? false;

  Future<void> setSilentModeEnabled(bool enabled) async =>
      _prefs?.setBool(_kStudentSilentMode, enabled);

  // Backend origin override (set via the login-screen "server address" dialog)
  // so the app can point at a new laptop IP without a rebuild. Full origin, e.g.
  // `http://192.168.1.104:8080`. Loaded into ApiConfig.runtimeOrigin at startup.
  static const _kServerBaseUrl = 'server_base_url';

  String? getServerBaseUrl() => _prefs?.getString(_kServerBaseUrl);

  Future<void> setServerBaseUrl(String? origin) async {
    if (origin == null || origin.isEmpty) {
      await _prefs?.remove(_kServerBaseUrl);
    } else {
      await _prefs?.setString(_kServerBaseUrl, origin);
    }
  }
}
