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
      userId: 121,
      fullName: 'أم ليان',
      email: 'parent@example.com',
      role: 'PARENT',
    );
  }
}

Widget _wrap(FakeLocalStorage storage) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(FakeAuthService(storage), storage),
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
    'renders profile, disabled actions, and logs out to login safely',
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
      expect(find.text('تغيير كلمة المرور'), findsOneWidget);
      expect(find.text('قريبًا'), findsNWidgets(2));

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
}
