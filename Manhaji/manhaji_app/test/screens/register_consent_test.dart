import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/auth_response.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/screens/auth/register_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  @override
  bool get isLoggedIn => false;
  @override
  String? getUserName() => null;
  @override
  String? getUserRole() => null;
  @override
  int? getUserId() => null;
  @override
  int? getGradeLevel() => null;
  @override
  Future<void> saveTokens(String a, String r) async {}
  @override
  Future<void> saveUserInfo({
    required int userId,
    required String role,
    required String name,
    int? gradeLevel,
  }) async {}
}

class MockAuthService extends AuthService {
  int registerCalls = 0;

  MockAuthService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required int gradeLevel,
  }) async {
    registerCalls++;
    return AuthResponse(
      accessToken: 'a',
      refreshToken: 'r',
      userId: 1,
      fullName: fullName,
      role: 'STUDENT',
      gradeLevel: gradeLevel,
    );
  }
}

Widget _wrap(AuthProvider provider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const RegisterScreen(),
      routes: {
        '/home': (_) => const Scaffold(body: Text('HOME')),
      },
    ),
  );
}

Future<void> _fillValidForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'طالب جديد'); // name
  await tester.enterText(fields.at(1), 'kid@test.com'); // email
  await tester.enterText(fields.at(2), '0591234567'); // phone
  await tester.enterText(fields.at(3), 'pass123'); // password
}

void main() {
  late MockAuthService service;
  late AuthProvider provider;

  setUp(() {
    service = MockAuthService();
    provider = AuthProvider(service, FakeLocalStorage());
  });

  testWidgets('blocks registration until consent is checked', (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await _fillValidForm(tester);

    await tester.ensureVisible(find.text('إنشاء الحساب'));
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();

    expect(find.text('يجب الموافقة على السياسة والشروط للمتابعة'),
        findsOneWidget);
    expect(service.registerCalls, 0);
  });

  testWidgets('proceeds once consent is checked', (tester) async {
    await tester.pumpWidget(_wrap(provider));
    await _fillValidForm(tester);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.ensureVisible(find.text('إنشاء الحساب'));
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();

    expect(service.registerCalls, 1);
  });
}
