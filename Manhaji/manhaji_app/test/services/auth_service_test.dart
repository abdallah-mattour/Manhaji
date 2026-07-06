import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/config/api_config.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeApiService extends ApiService {
  final Map<String, Map<String, dynamic>> getResponses = {};
  final Map<String, Map<String, dynamic>> postResponses = {};
  final Map<String, Map<String, dynamic>> patchResponses = {};
  final List<Map<String, dynamic>> patchPayloads = [];
  final List<String> putCalls = [];

  FakeApiService() : super(FakeLocalStorage());

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    return getResponses[path] ?? const {'data': null};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return postResponses[path] ?? const {'data': null};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    patchPayloads.add({'path': path, 'data': data ?? const {}});
    return patchResponses[path] ?? const {'data': null};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    putCalls.add(path);
    return const {'data': null};
  }
}

void main() {
  late FakeApiService api;
  late AuthService service;

  setUp(() {
    api = FakeApiService();
    service = AuthService(api);
  });

  group('AuthService', () {
    test('loginWithEmail returns a typed auth response', () async {
      api.postResponses[ApiConfig.login] = {
        'data': {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'userId': '9',
          'fullName': 'طالب',
          'role': 'student',
          'gradeLevel': '2',
        },
      };

      final response = await service.loginWithEmail(
        email: 'student@test.com',
        password: 'password',
      );

      expect(response.accessToken, 'access');
      expect(response.refreshToken, 'refresh');
      expect(response.userId, 9);
      expect(response.role, 'STUDENT');
      expect(response.gradeLevel, 2);
    });

    test('loginWithEmail rejects auth payloads without valid tokens', () {
      api.postResponses[ApiConfig.login] = {
        'data': {'userId': 9, 'fullName': 'طالب', 'role': 'STUDENT'},
      };

      expect(
        service.loginWithEmail(email: 'student@test.com', password: 'password'),
        throwsA(isA<ApiException>()),
      );
    });

    test(
      'getCurrentUser parses profile payloads without requiring tokens',
      () async {
        api.getResponses[ApiConfig.me] = {
          'data': {
            'userId': '9',
            'fullName': 'طالب',
            'email': 'student@test.com',
            'role': 'STUDENT',
            'avatarId': 'avatar-book',
          },
        };

        final response = await service.getCurrentUser();

        expect(response.hasTokens, false);
        expect(response.userId, 9);
        expect(response.email, 'student@test.com');
        expect(response.avatarId, 'avatar-book');
      },
    );

    test('updateProfile returns the updated typed profile', () async {
      api.patchResponses[ApiConfig.updateProfile] = {
        'data': {
          'userId': 9,
          'fullName': 'اسم جديد',
          'phone': '0590000000',
          'role': 'STUDENT',
          'avatarId': 'avatar-star',
        },
      };

      final response = await service.updateProfile(
        fullName: 'اسم جديد',
        phone: '0590000000',
        avatarId: 'avatar-star',
      );

      expect(response.fullName, 'اسم جديد');
      expect(response.phone, '0590000000');
      expect(response.avatarId, 'avatar-star');
      expect(api.patchPayloads, [
        {
          'path': ApiConfig.updateProfile,
          'data': {
            'fullName': 'اسم جديد',
            'phone': '0590000000',
            'avatarId': 'avatar-star',
          },
        },
      ]);
    });

    test('changePassword calls the configured endpoint', () async {
      await service.changePassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
      );

      expect(api.putCalls, [ApiConfig.changePassword]);
    });
  });
}
