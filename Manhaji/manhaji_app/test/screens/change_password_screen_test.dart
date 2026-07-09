import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/screens/settings/change_password_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/widgets/duolingo_button.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
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
}

class MockAuthService extends AuthService {
  int changeCalls = 0;
  String? lastCurrent;
  String? lastNew;

  MockAuthService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changeCalls++;
    lastCurrent = currentPassword;
    lastNew = newPassword;
  }
}

Widget _wrap(AuthProvider provider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      // Push the screen so the success-path pop has a route to return to.
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen()),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, AuthProvider provider) async {
  await tester.pumpWidget(_wrap(provider));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

/// The submit button label ("تغيير كلمة المرور") also appears in the AppBar
/// title, so target the button by type instead of by text.
Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(find.byType(DuolingoButton));
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthService service;
  late AuthProvider provider;

  setUp(() {
    service = MockAuthService();
    provider = AuthProvider(service, FakeLocalStorage());
  });

  testWidgets('shows required-field validators on empty submit',
      (tester) async {
    await _open(tester, provider);
    await _tapSubmit(tester);

    expect(find.text('أدخل كلمة المرور الحالية'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور الجديدة'), findsOneWidget);
    expect(service.changeCalls, 0);
  });

  testWidgets('rejects a mismatched confirmation', (tester) async {
    await _open(tester, provider);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass');
    await tester.enterText(fields.at(1), 'newpass');
    await tester.enterText(fields.at(2), 'different');
    await _tapSubmit(tester);

    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
    expect(service.changeCalls, 0);
  });

  testWidgets('rejects a too-short new password', (tester) async {
    await _open(tester, provider);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass');
    await tester.enterText(fields.at(1), 'abc');
    await tester.enterText(fields.at(2), 'abc');
    await _tapSubmit(tester);

    expect(find.text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
        findsOneWidget);
    expect(service.changeCalls, 0);
  });

  testWidgets('valid input calls the provider once', (tester) async {
    await _open(tester, provider);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'oldpass');
    await tester.enterText(fields.at(1), 'newpass');
    await tester.enterText(fields.at(2), 'newpass');
    await _tapSubmit(tester);

    expect(service.changeCalls, 1);
    expect(service.lastCurrent, 'oldpass');
    expect(service.lastNew, 'newpass');
  });
}
