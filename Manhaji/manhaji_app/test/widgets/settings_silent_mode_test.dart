import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/providers/student_settings_provider.dart';
import 'package:manhaji_app/screens/settings/settings_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  bool silent = false;
  int writes = 0;

  @override
  bool get isLoggedIn => true;

  @override
  String? getUserName() => 'ليان أحمد';

  @override
  String? getUserRole() => 'STUDENT';

  @override
  int? getUserId() => 131;

  @override
  int? getGradeLevel() => 1;

  @override
  bool get isSilentModeEnabled => silent;

  @override
  Future<void> setSilentModeEnabled(bool enabled) async {
    silent = enabled;
    writes++;
  }
}

Widget _wrap(FakeLocalStorage storage) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(AuthService(ApiService(storage)), storage),
      ),
      ChangeNotifierProvider(create: (_) => StudentSettingsProvider(storage)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'student settings show الوضع الصامت OFF by default and toggling persists',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = FakeLocalStorage();
      await tester.pumpWidget(_wrap(storage));
      await tester.pumpAndSettle();

      expect(find.text('الوضع الصامت'), findsOneWidget);
      expect(
        find.text('إيقاف التشغيل التلقائي للصوت أثناء الدراسة'),
        findsOneWidget,
      );

      final switchFinder = find.byKey(
        const ValueKey('student-silent-mode-switch'),
      );
      expect(switchFinder, findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(switchFinder).value,
        isFalse, // default OFF
      );

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
      expect(storage.silent, isTrue); // persisted locally
      expect(storage.writes, 1);
    },
  );
}
