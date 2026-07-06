import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/parent_dashboard.dart';
import 'package:manhaji_app/providers/auth_provider.dart';
import 'package:manhaji_app/providers/parent_provider.dart';
import 'package:manhaji_app/screens/parent/parent_dashboard_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/auth_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/parent_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  @override
  bool get isLoggedIn => true;

  @override
  String? getUserName() => 'ولي الأمر';

  @override
  String? getUserRole() => 'PARENT';

  @override
  int? getUserId() => 121;

  @override
  int? getGradeLevel() => null;

  @override
  String? getUserAvatarId() => null;
}

class FakeParentService extends ParentApiService {
  FakeParentService(this.dashboard) : super(ApiService(FakeLocalStorage()));

  final ParentDashboard dashboard;

  @override
  Future<ParentDashboard> getDashboard() async => dashboard;
}

ParentDashboard _dashboard({bool withChildren = true}) {
  return ParentDashboard(
    parentId: 121,
    fullName: 'أم ليان',
    children: withChildren
        ? [
            ChildSummary(
              studentId: 131,
              fullName: 'ليان أحمد',
              gradeLevel: 1,
              totalPoints: 460,
              currentStreak: 3,
              lessonsCompleted: 12,
              totalLessons: 24,
              overallMastery: 88.0,
            ),
            ChildSummary(
              studentId: 138,
              fullName: 'كريم حسن',
              gradeLevel: 1,
              totalPoints: 90,
              currentStreak: 0,
              lessonsCompleted: 4,
              totalLessons: 24,
              overallMastery: 42.0,
            ),
          ]
        : const [],
    recentActivityAcrossChildren: withChildren
        ? [
            QuizAttemptSummary(
              attemptId: 900,
              quizTitle: 'اختبار حرف الراء',
              subjectName: 'اللغة العربية',
              lessonTitle: 'حرف الراء',
              score: 85,
              status: 'GRADED',
            ),
          ]
        : const [],
    alerts: withChildren
        ? [
            ParentAlert(
              studentId: 138,
              alertType: 'LOW_MASTERY',
              message: 'كريم يحتاج دعماً: متوسط الإتقان 42%',
              severity: 'HIGH',
              studentName: 'كريم حسن',
            ),
          ]
        : const [],
    recommendations: withChildren
        ? [
            ParentRecommendation(
              type: 'PRACTICE',
              title: 'تدريب يومي قصير',
              message: 'خصص 10 دقائق يومياً لمراجعة دروس الرياضيات مع كريم.',
              priority: 'HIGH',
              studentName: 'كريم حسن',
            ),
          ]
        : const [],
  );
}

Widget _wrap(FakeParentService service) {
  final storage = FakeLocalStorage();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(AuthService(ApiService(storage)), storage),
      ),
      ChangeNotifierProvider(create: (_) => ParentProvider(service)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.childProgress: (_) =>
            const Scaffold(body: Text('تفاصيل الطفل — صفحة')),
        AppRoutes.parentSettings: (_) =>
            const Scaffold(body: Text('إعدادات ولي الأمر — صفحة')),
      },
      home: const ParentDashboardScreen(),
    ),
  );
}

void _useMobile(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The dashboard ListView builds lazily, so below-the-fold sections must be
/// scrolled into view before they exist in the element tree.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('parent dashboard renders children, analytics, unified follow-up '
      'and recommendations without duplicated alert sections', (tester) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap(FakeParentService(_dashboard())));
    await tester.pumpAndSettle();

    // Children cards from provider data (first card is above the fold).
    expect(find.text('ليان أحمد'), findsOneWidget);
    expect(find.text('عرض التفاصيل'), findsAtLeastNWidgets(1));

    // Analytics summary renders.
    await _scrollTo(tester, find.text('لمحة تحليلية'));
    expect(find.text('عدد الأطفال'), findsOneWidget);

    // Unified follow-up section: the alert message appears exactly once.
    await _scrollTo(tester, find.text('متابعة وتنبيهات'));
    await _scrollTo(tester, find.text('كريم يحتاج دعماً: متوسط الإتقان 42%'));
    expect(find.text('كريم يحتاج دعماً: متوسط الإتقان 42%'), findsOneWidget);
    expect(find.text('عاجل'), findsOneWidget);

    // Old duplicated sections are gone.
    expect(find.text('أطفال يحتاجون متابعة'), findsNothing);
    expect(find.text('الإشعارات والتنبيهات'), findsNothing);

    // Backend-driven recommendation renders.
    await _scrollTo(tester, find.text('توصيات منزلية'));
    await _scrollTo(tester, find.text('تدريب يومي قصير'));
    expect(find.text('تدريب يومي قصير'), findsOneWidget);
  });

  testWidgets('parent dashboard renders empty children state', (tester) async {
    _useMobile(tester);

    await tester.pumpWidget(
      _wrap(FakeParentService(_dashboard(withChildren: false))),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد أطفال مرتبطين بحسابك بعد'), findsOneWidget);
    expect(find.text('متابعة وتنبيهات'), findsNothing);
  });

  testWidgets('child card «عرض التفاصيل» navigates to child progress', (
    tester,
  ) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap(FakeParentService(_dashboard())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('عرض التفاصيل').first);
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الطفل — صفحة'), findsOneWidget);
  });

  testWidgets('settings icon replaces logout in dashboard AppBar', (
    tester,
  ) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap(FakeParentService(_dashboard())));
    await tester.pumpAndSettle();

    expect(find.byTooltip('الإعدادات'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byTooltip('تسجيل الخروج'), findsNothing);
    expect(find.byIcon(Icons.logout_rounded), findsNothing);

    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('إعدادات ولي الأمر — صفحة'), findsOneWidget);
  });
}
