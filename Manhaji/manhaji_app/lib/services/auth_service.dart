import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required int gradeLevel,
  }) async {
    final response = await _api.post(ApiConfig.register, data: {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'STUDENT',
      'gradeLevel': gradeLevel,
    });
    return AuthResponse.fromJson(response['data'] ?? {});
  }

  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiConfig.login, data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(response['data'] ?? {});
  }

  Future<AuthResponse> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _api.post(ApiConfig.loginPhone, data: {
      'phone': phone,
      'password': password,
    });
    return AuthResponse.fromJson(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _api.get(ApiConfig.me);
    return (response['data'] as Map<String, dynamic>?) ?? {};
  }
}
