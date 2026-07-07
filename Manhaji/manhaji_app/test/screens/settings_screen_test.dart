import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/screens/settings/settings_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  @override
  bool get isLoggedIn => true;
  @override
  String? getUserName() => 'ولي الأمر';
  @override
  String? getUserRole() => 'PARENT'; // non-student → no LessonProvider needed
  @override
  int? getUserId() => 1;
  @override
  int? getGradeLevel() => null;
  @override
  Future<void> clearAll() async {}
}

class MockAuthService extends AuthService {
  MockAuthService() : super(ApiService(FakeLocalStorage()));
}

Widget _wrap(AuthProvider provider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
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
  late AuthProvider provider;

  setUp(() {
    provider = AuthProvider(MockAuthService(), FakeLocalStorage());
  });

  testWidgets('shows the three settings rows and no notifications row',
      (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.text('الملف الشخصي'), findsOneWidget);
    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
    expect(find.text('عن التطبيق'), findsOneWidget);
    // The dead notifications row was removed.
    expect(find.text('الإشعارات'), findsNothing);
  });

  testWidgets('logout asks for confirmation and cancel keeps the session',
      (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    // Confirmation dialog is shown.
    expect(find.text('هل تريد بالتأكيد تسجيل الخروج من حسابك؟'),
        findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Still on settings, never navigated to login.
    expect(find.text('LOGIN SCREEN'), findsNothing);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
