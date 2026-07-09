import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/app_log.dart';
import 'local_storage_service.dart';

/// Thrown by [ApiService] when a request fails in a way the UI should
/// surface with a friendly Arabic message (network down, timeout, 5xx).
///
/// Catching a single type avoids dumping raw `DioException` stack traces
/// into SnackBars during the graduation demo. All non-auth errors funnel
/// through here so providers can `catch (ApiException e)` uniformly.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final AppLog _log = AppLog.tag('api');

  late final Dio _dio;
  final LocalStorageService _storage;

  ApiService(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: kIsWeb ? null : const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // A 401 on the credential endpoints (login / phone login / register /
        // refresh) is a *business* response — wrong password or a dead refresh
        // token — NOT an expired access token. Refreshing/clearing there is
        // pointless and, worse, makes a bad-password login surface the
        // "session expired" copy. Let those flow straight through so the real
        // server message (e.g. "wrong email or password") reaches the UI.
        const noRefreshPaths = [
          ApiConfig.login,
          ApiConfig.loginPhone,
          ApiConfig.register,
          ApiConfig.refreshToken,
        ];
        final isCredentialCall =
            noRefreshPaths.contains(error.requestOptions.path);
        if (error.response?.statusCode == 401 && !isCredentialCall) {
          _log.w('401 on ${error.requestOptions.path} — attempting refresh');
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            _log.i('refresh ok — retrying ${error.requestOptions.path}');
            try {
              final retryResponse = await _retry(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (retryErr) {
              _log.e('retry after refresh failed', retryErr);
            }
          } else {
            // Token refresh failed — clear stale auth data
            _log.w('refresh failed — clearing stored auth, user must re-login');
            await _storage.clearAll();
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Translate any raw [DioException] into a user-facing [ApiException].
  ///
  /// Keeps Arabic copy short and child-friendly — parents/teachers watching
  /// the demo will see these. The console still gets the raw exception via
  /// [debugPrint] for us to diagnose post-demo.
  Never _throwFriendly(DioException err) {
    _log.e(
      '${err.requestOptions.method} ${err.requestOptions.path} '
      '[${err.type.name}] status=${err.response?.statusCode} ${err.message}',
    );
    final status = err.response?.statusCode;
    String msg;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        msg = 'انتهت مهلة الاتصال. حاول مرة أخرى.';
        break;
      case DioExceptionType.connectionError:
        msg = 'تعذّر الاتصال بالخادم. تحقّق من الإنترنت.';
        break;
      case DioExceptionType.badResponse:
        // Server-supplied Arabic message wins whenever present — it's the most
        // specific ("wrong email or password", "current password is wrong", …).
        final data = err.response?.data;
        final serverMsg = (data is Map && data['message'] is String)
            ? (data['message'] as String).trim()
            : null;
        if (status != null && status >= 500) {
          msg = 'حدث خطأ في الخادم. نحاول إصلاحه.';
        } else if (serverMsg != null && serverMsg.isNotEmpty) {
          msg = serverMsg;
        } else if (status == 401) {
          msg = 'تحتاج لتسجيل الدخول من جديد.';
        } else if (status == 403) {
          msg = 'ليس لديك صلاحية للوصول إلى هذا المورد.';
        } else {
          msg = 'طلب غير صالح.';
        }
        break;
      case DioExceptionType.cancel:
        msg = 'تم إلغاء الطلب.';
        break;
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        msg = 'حدث خطأ غير متوقع.';
        break;
    }
    throw ApiException(msg, statusCode: status);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(
        BaseOptions(baseUrl: ApiConfig.baseUrl),
      ).post(ApiConfig.refreshToken, data: {'refreshToken': refreshToken});

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map &&
            data['accessToken'] != null &&
            data['refreshToken'] != null) {
          await _storage.saveTokens(data['accessToken'], data['refreshToken']);
          return true;
        }
      }
      return false;
    } catch (e) {
      _log.e('token refresh request itself failed', e);
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.getToken();
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
    );
    return _dio.request(
      requestOptions.path,
      options: options,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> putRaw(String path, {Object? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    try {
      final response = await _dio.post(path, data: formData);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  /// Defensive cast — backend should always return a JSON object, but if a
  /// proxy/loadbalancer serves plain text or HTML we don't want a demo crash.
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    _log.w('non-map payload from backend: ${data.runtimeType}');
    return {'success': false, 'message': 'ردّ غير متوقّع من الخادم'};
  }
}
