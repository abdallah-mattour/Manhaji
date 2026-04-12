class AppConstants {
  static const String appName = 'منهجي';
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String sessionActiveKey = 'session_active';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String gradeKey = 'grade_level';
}

/// App environment configuration.
///
/// Priority:
/// 1. `API_BASE_URL` from `--dart-define` if provided.
/// 2. Fallback URL based on `APP_ENV`.
///
/// Examples:
/// flutter run --dart-define=APP_ENV=dev
/// flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.example.com/api
class AppConfig {
  /// Supported values: `dev`, `staging`, `prod`
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Optional runtime override from dart-define.
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Default URLs per environment.
  /// Use localhost only for local development.
  static const String devBaseUrl = 'http://localhost:8080/api';
  static const String stagingBaseUrl = 'https://staging-api.example.com/api';
  static const String prodBaseUrl = 'https://api.example.com/api';

  static bool get isDev => appEnv == 'dev';
  static bool get isStaging => appEnv == 'staging';
  static bool get isProd => appEnv == 'prod';

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }

    switch (appEnv) {
      case 'staging':
        return stagingBaseUrl;
      case 'prod':
        return prodBaseUrl;
      case 'dev':
      default:
        return devBaseUrl;
    }
  }
}
