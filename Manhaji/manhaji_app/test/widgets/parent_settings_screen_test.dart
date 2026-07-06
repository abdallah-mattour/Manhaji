import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/auth_response.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/screens/parent/parent_settings_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  bool cleared = false;
  String? savedAvatarId;

  @override
  bool get isLoggedIn => !cleared;

  @override
  String? getUserName() => 'أم ليان';

  @override
  String? getUserRole() => 'PARENT';

  @override
  int? getUserId() => 121;

  @override
  int? getGradeLevel() => null;

  @override
  String? getUserAvatarId() => 'avatar-book';

  @override
  Future<void> saveUserInfo({
    required int userId,
    required String role,
    required String name,
    int? gradeLevel,
    String? avatarId,
  }) async {
    savedAvatarId = avatarId;
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
  }
}

class FakeAuthService extends AuthService {
  FakeAuthService(LocalStorageService storage) : super(ApiService(storage));

  String? updatedName;
  String? updatedAvatarId;
  int passwordChangeCalls = 0;

  @override
  Future<AuthResponse> getCurrentUser() async {
    return AuthResponse(
      accessToken: '',
      refreshToken: '',
      userId: 121,
      fullName: 'أم ليان',
      email: 'parent@example.com',
      role: 'PARENT',
      avatarId: 'avatar-book',
    );
  }

  @override
  Future<AuthResponse> updateProfile({
    required String fullName,
    String? email,
    String? phone,
    String? avatarId,
  }) async {
    updatedName = fullName;
    updatedAvatarId = avatarId;
    return AuthResponse(
      accessToken: '',
      refreshToken: '',
      userId: 121,
      fullName: fullName,
      email: 'parent@example.com',
      role: 'PARENT',
      avatarId: avatarId,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordChangeCalls++;
  }
}

Widget _wrap(FakeLocalStorage storage, {FakeAuthService? authService}) {
  return ChangeNotifierProvider(
    create: (_) =>
        AuthProvider(authService ?? FakeAuthService(storage), storage),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login page')),
      },
      home: const ParentSettingsScreen(),
    ),
  );
}

void _useMobile(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'renders profile, account actions, and logs out to login safely',
    (tester) async {
      _useMobile(tester);
      final storage = FakeLocalStorage();

      await tester.pumpWidget(_wrap(storage));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('أم ليان'), findsOneWidget);
      expect(find.text('parent@example.com'), findsOneWidget);
      expect(find.text('ولي أمر'), findsOneWidget);
      expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
      expect(find.text('الصورة الرمزية'), findsOneWidget);
      expect(find.text('تغيير كلمة المرور'), findsOneWidget);
      expect(find.text('قريبًا'), findsNothing);
      expect(
        find.byKey(const ValueKey('account-avatar-avatar-book')),
        findsOneWidget,
      );

      final logoutButton = find.byKey(
        const ValueKey('parent-settings-logout-button'),
      );
      expect(logoutButton, findsOneWidget);
      await tester.ensureVisible(logoutButton);
      await tester.pumpAndSettle();
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(storage.cleared, isTrue);
      expect(find.text('Login page'), findsOneWidget);
    },
  );

  testWidgets('profile dialog saves selected avatar', (tester) async {
    _useMobile(tester);
    final storage = FakeLocalStorage();
    final service = FakeAuthService(storage);

    await tester.pumpWidget(_wrap(storage, authService: service));
    await tester.pump();
    await tester.pumpAndSettle();

    final avatarAction = find.byKey(
      const ValueKey('parent-settings-avatar-action'),
    );
    await tester.ensureVisible(avatarAction);
    await tester.tap(avatarAction);
    await tester.pumpAndSettle();

    expect(find.text('اختر صورة رمزية'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('avatar-option-avatar-star')));
    await tester.tap(find.byKey(const ValueKey('account-profile-save-button')));
    await tester.pumpAndSettle();

    expect(service.updatedName, 'أم ليان');
    expect(service.updatedAvatarId, 'avatar-star');
    expect(storage.savedAvatarId, 'avatar-star');
    expect(find.text('تم تحديث الصورة الرمزية'), findsOneWidget);
  });

  testWidgets('password dialog validates mismatched confirmation', (
    tester,
  ) async {
    _useMobile(tester);
    final storage = FakeLocalStorage();
    final service = FakeAuthService(storage);

    await tester.pumpWidget(_wrap(storage, authService: service));
    await tester.pump();
    await tester.pumpAndSettle();

    final passwordAction = find.byKey(
      const ValueKey('parent-settings-change-password-action'),
    );
    await tester.ensureVisible(passwordAction);
    await tester.tap(passwordAction);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('account-current-password-field')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-new-password-field')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-confirm-password-field')),
      'different',
    );
    await tester.tap(
      find.byKey(const ValueKey('account-password-save-button')),
    );
    await tester.pump();

    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
    expect(service.passwordChangeCalls, 0);
  });
}
