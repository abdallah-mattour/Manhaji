import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/auth_response.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

/// Minimal in-memory storage stub. AuthProvider's constructor reads a handful
/// of sync getters (including [getUserAvatarId]); `gradeLevel` delegates to
/// [getGradeLevel].
class FakeLocalStorage extends Fake implements LocalStorageService {
  int? grade;

  @override
  bool get isLoggedIn => false;
  @override
  String? getUserName() => null;
  @override
  String? getUserRole() => null;
  @override
  int? getUserId() => null;
  @override
  int? getGradeLevel() => grade;
  @override
  String? getUserAvatarId() => null;
  @override
  Future<void> saveUserInfo({
    required int userId,
    required String role,
    required String name,
    int? gradeLevel,
    String? avatarId,
  }) async {}
}

class MockAuthService extends AuthService {
  Object? errorToThrow;
  AuthResponse profileResult = AuthResponse(
    accessToken: '',
    refreshToken: '',
    userId: 0,
    fullName: '',
    role: '',
  );
  Completer<void>? changeGate; // lets a test observe the in-flight loading state

  MockAuthService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (changeGate != null) await changeGate!.future;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<AuthResponse> getCurrentUser() async {
    if (errorToThrow != null) throw errorToThrow!;
    return profileResult;
  }
}

void main() {
  late MockAuthService service;
  late FakeLocalStorage storage;
  late AuthProvider provider;

  setUp(() {
    service = MockAuthService();
    storage = FakeLocalStorage();
    provider = AuthProvider(service, storage);
  });

  group('AuthProvider.changePassword()', () {
    test('returns true and leaves no error on success', () async {
      final ok = await provider.changePassword(
        currentPassword: 'old',
        newPassword: 'newpass',
      );

      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('returns false and surfaces the Arabic message on failure', () async {
      service.errorToThrow =
          ApiException('كلمة المرور الحالية غير صحيحة', statusCode: 400);

      final ok = await provider.changePassword(
        currentPassword: 'wrong',
        newPassword: 'newpass',
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, 'كلمة المرور الحالية غير صحيحة');
      expect(provider.isLoading, isFalse);
    });

    test('toggles isLoading while the request is in flight', () async {
      service.changeGate = Completer<void>();

      final future = provider.changePassword(
        currentPassword: 'old',
        newPassword: 'newpass',
      );

      expect(provider.isLoading, isTrue);
      service.changeGate!.complete();
      await future;
      expect(provider.isLoading, isFalse);
    });
  });

  group('AuthProvider.clearError()', () {
    test('clears a previously set error', () async {
      service.errorToThrow = ApiException('خطأ');
      await provider.changePassword(currentPassword: 'x', newPassword: 'yyyyyy');
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });

  group('AuthProvider.fetchProfile()', () {
    test('populates the email/phone getters on success', () async {
      service.profileResult = AuthResponse(
        accessToken: '',
        refreshToken: '',
        userId: 0,
        fullName: '',
        role: '',
        email: 'a@b.com',
        phone: '0591234567',
      );

      await provider.fetchProfile();

      expect(provider.userEmail, 'a@b.com');
      expect(provider.userPhone, '0591234567');
      expect(provider.profileError, isNull);
    });

    test('sets profileError and leaves email null on failure', () async {
      service.errorToThrow = ApiException('تعذّر الاتصال بالخادم.');

      await provider.fetchProfile();

      expect(provider.profileError, 'تعذّر الاتصال بالخادم.');
      expect(provider.userEmail, isNull);
    });
  });

  group('AuthProvider.gradeLevel', () {
    test('delegates to local storage', () {
      storage.grade = 3;
      expect(provider.gradeLevel, 3);
    });
  });
}
