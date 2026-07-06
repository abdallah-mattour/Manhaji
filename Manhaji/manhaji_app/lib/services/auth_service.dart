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
    final response = await _api.post(
      ApiConfig.register,
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'STUDENT',
        'gradeLevel': gradeLevel,
      },
    );
    return _readAuthResponse(response, requireTokens: true);
  }

  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.login,
      data: {'email': email, 'password': password},
    );
    return _readAuthResponse(response, requireTokens: true);
  }

  Future<AuthResponse> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.loginPhone,
      data: {'phone': phone, 'password': password},
    );
    return _readAuthResponse(response, requireTokens: true);
  }

  Future<AuthResponse> getCurrentUser() async {
    final response = await _api.get(ApiConfig.me);
    return _readAuthResponse(response);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put(
      ApiConfig.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<AuthResponse> updateProfile({
    required String fullName,
    String? email,
    String? phone,
    String? avatarId,
  }) async {
    final body = <String, dynamic>{'fullName': fullName};
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (avatarId != null) body['avatarId'] = avatarId;
    final response = await _api.patch(ApiConfig.updateProfile, data: body);
    return _readAuthResponse(response);
  }

  AuthResponse _readAuthResponse(
    Map<String, dynamic> response, {
    bool requireTokens = false,
  }) {
    final data = response['data'];
    final object = _asStringMap(data);
    if (object == null) {
      throw ApiException('استجابة تسجيل الدخول من الخادم غير صالحة.');
    }

    final auth = AuthResponse.fromJson(object);
    if (requireTokens && !auth.hasTokens) {
      throw ApiException('استجابة تسجيل الدخول لا تحتوي على رموز دخول صالحة.');
    }
    return auth;
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
