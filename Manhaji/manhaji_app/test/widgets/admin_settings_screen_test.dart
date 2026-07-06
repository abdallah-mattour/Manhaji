import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/auth_response.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/screens/admin/admin_settings_screen.dart';
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
  String? getUserName() => 'مدير النظام';

  @override
  String? getUserRole() => 'ADMIN';

  @override
  int? getUserId() => 101;

  @override
  int? getGradeLevel() => null;

  @override
  String? getUserAvatarId() => 'avatar-palette';

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

  @override
  Future<AuthResponse> getCurrentUser() async {
    return AuthResponse(
      accessToken: '',
      refreshToken: '',
      userId: 101,
      fullName: 'مدير النظام',
      email: 'admin@example.com',
      role: 'ADMIN',
      avatarId: 'avatar-palette',
    );
  }
}

void main() {
  testWidgets('AdminSettingsScreen renders profile actions and logout', (
    tester,
  ) async {
    final storage = FakeLocalStorage();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(FakeAuthService(storage), storage),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('Login page')),
          },
          home: const AdminSettingsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('الملف الشخصي'), findsOneWidget);
    expect(find.text('مدير النظام'), findsAtLeastNWidgets(1));
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('مشرف'), findsOneWidget);
    expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
    expect(find.text('الصورة الرمزية'), findsOneWidget);
    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
    expect(find.text('قريبًا'), findsNothing);
    expect(
      find.byKey(const ValueKey('account-avatar-avatar-palette')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('admin-settings-logout-button')),
      findsOneWidget,
    );

    final logoutButton = find.byKey(
      const ValueKey('admin-settings-logout-button'),
    );
    await tester.ensureVisible(logoutButton);
    await tester.pumpAndSettle();
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(storage.cleared, isTrue);
    expect(find.text('Login page'), findsOneWidget);
  });
}
