import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
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
  late final Dio _dio;
  final LocalStorageService _storage;

  ApiService(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            try {
              final retryResponse = await _retry(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (retryErr) {
              debugPrint('Retry after refresh failed: $retryErr');
            }
          } else {
            // Token refresh failed — clear stale auth data
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
    debugPrint('API error [${err.type}] ${err.requestOptions.path}: '
        '${err.response?.statusCode} ${err.message}');
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
        if (status != null && status >= 500) {
          msg = 'حدث خطأ في الخادم. نحاول إصلاحه.';
        } else if (status == 401 || status == 403) {
          msg = 'تحتاج لتسجيل الدخول من جديد.';
        } else {
          // Try to pull server message; fall back to generic.
          final data = err.response?.data;
          final serverMsg = (data is Map && data['message'] is String)
              ? data['message'] as String
              : null;
          msg = serverMsg ?? 'طلب غير صالح.';
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

      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map &&
            data['accessToken'] != null &&
            data['refreshToken'] != null) {
          await _storage.saveTokens(
            data['accessToken'],
            data['refreshToken'],
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
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

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _asMap(response.data);
    } on DioException catch (e) {
      _throwFriendly(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart(String path,
      {required FormData formData}) async {
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
    debugPrint('API returned non-map payload: ${data.runtimeType}');
    return {'success': false, 'message': 'ردّ غير متوقّع من الخادم'};
  }
}
