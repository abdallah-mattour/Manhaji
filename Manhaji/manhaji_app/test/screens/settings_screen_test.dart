import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/providers/student_settings_provider.dart';
import 'package:manhaji_app/screens/settings/settings_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  bool cleared = false;

  @override
  bool get isLoggedIn => true;
  @override
  String? getUserName() => 'طالب';
  @override
  String? getUserRole() => 'STUDENT';
  @override
  int? getUserId() => 1;
  @override
  int? getGradeLevel() => 1;
  @override
  String? getUserAvatarId() => null;
  @override
  bool get isSilentModeEnabled => false;
  @override
  Future<void> setSilentModeEnabled(bool enabled) async {}
  @override
  Future<void> clearAll() async {
    cleared = true;
  }
}

class MockAuthService extends AuthService {
  MockAuthService() : super(ApiService(FakeLocalStorage()));
}

Widget _wrap(AuthProvider auth, StudentSettingsProvider settings) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<StudentSettingsProvider>.value(value: settings),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SettingsScreen(),
      routes: {
        '/login': (_) => const Scaffold(body: Text('LOGIN SCREEN')),
      },
    ),
  );
}

void main() {
  late FakeLocalStorage storage;
  late AuthProvider auth;
  late StudentSettingsProvider settings;

  setUp(() {
    storage = FakeLocalStorage();
    auth = AuthProvider(MockAuthService(), storage);
    settings = StudentSettingsProvider(storage);
  });

  // The settings screen is a scrolling ListView under a bottom nav bar; the
  // logout button sits below the default 800×600 fold and a ListView won't
  // build off-screen children. Give the test a tall viewport so everything
  // renders.
  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows the student settings rows', (tester) async {
    tallViewport(tester);
    await tester.pumpWidget(_wrap(auth, settings));
    await tester.pump();

    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('عن التطبيق'), findsOneWidget);
    expect(find.text('الوضع الصامت'), findsOneWidget); // silent-mode toggle
    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });

  testWidgets('logout clears the session and navigates to login',
      (tester) async {
    tallViewport(tester);
    await tester.pumpWidget(_wrap(auth, settings));
    await tester.pump();

    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(storage.cleared, isTrue);
    expect(find.text('LOGIN SCREEN'), findsOneWidget);
  });
}
