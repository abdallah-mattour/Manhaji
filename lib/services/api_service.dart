import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/constants.dart';
import 'local_storage_service.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiService {
  late final Dio _dio;
  final LocalStorageService _storage;
  UnauthorizedHandler? _onUnauthorized;

  ApiService(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    debugPrint('🚀 API Base URL: ${ApiConfig.baseUrl}');
    debugPrint('📱 App Environment: ${AppConfig.appEnv}');

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final alreadyRetried =
                error.requestOptions.extra['auth_retry'] == true;

            if (!alreadyRetried) {
              final refreshed = await _tryRefreshToken();
              if (refreshed) {
                final retryResponse = await _retry(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            }

            await _handleUnauthorized();
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setUnauthorizedHandler(UnauthorizedHandler handler) {
    _onUnauthorized = handler;
  }

  Future<void> _handleUnauthorized() async {
    if (_onUnauthorized != null) {
      await _onUnauthorized!.call();
      return;
    }
    await _storage.clearAll();
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
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.getToken();
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $token'},
      extra: {...requestOptions.extra, 'auth_retry': true},
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
    final response = await _dio.get(path, queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    final response = await _dio.post(path, data: formData);
    return response.data;
  }
}
