import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/route_args.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/parent_dashboard.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/providers/parent_provider.dart';
import 'package:manhaji_app/screens/parent/child_progress_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/parent_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeParentService extends ParentApiService {
  FakeParentService(this.detail, {this.detailError})
    : super(ApiService(FakeLocalStorage()));

  final StudentDetail detail;
  final Object? detailError;

  @override
  Future<StudentDetail> getChildDetail(int childId) async {
    if (detailError != null) throw detailError!;
    return detail;
  }
}

StudentDetail _detail({bool withData = true}) {
  return StudentDetail(
    studentId: 131,
    fullName: 'ليان أحمد',
    gradeLevel: 1,
    totalPoints: 460,
    currentStreak: 3,
    lastLoginAt: '2026-07-04T10:00:00',
    lessonsCompleted: 16,
    lessonsInProgress: 5,
    overallMastery: 74.5,
    totalAttempts: withData ? 9 : 0,
    averageScore: 78.2,
    subjectBreakdown: withData
        ? [
            SubjectMasterySummary(
              subjectId: 1,
              subjectName: 'اللغة العربية',
              totalLessons: 24,
              lessonsCompleted: 12,
              averageMastery: 88, // strength chip (>= 75)
            ),
            SubjectMasterySummary(
              subjectId: 5,
              subjectName: 'الرياضيات',
              totalLessons: 24,
              lessonsCompleted: 4,
              averageMastery: 52, // review chip (< 65)
            ),
            SubjectMasterySummary(
              subjectId: 3,
              subjectName: 'English',
              totalLessons: 24,
              lessonsCompleted: 24, // completed state
              averageMastery: 76, // strength chip (>= 75)
            ),
          ]
        : const [],
    recentAttempts: withData
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
    recommendations: withData
        ? [
            ParentRecommendation(
              type: 'PRACTICE',
              title: 'تدريب يومي قصير',
              message: 'خصص 10 دقائق يومياً لمراجعة دروس الرياضيات.',
              priority: 'HIGH',
              studentName: 'ليان أحمد',
            ),
          ]
        : const [],
    reports: withData
        ? [
            ParentReportSummary(
              id: 55,
              periodStart: '2026-06-01',
              periodEnd: '2026-06-30',
              summary: 'تقدم جيد خلال الشهر مع حاجة لدعم الرياضيات.',
              riskLevel: 'LOW',
            ),
          ]
        : const [],
  );
}

Widget _wrap({required FakeParentService service, Object? args}) {
  return ChangeNotifierProvider(
    create: (_) => ParentProvider(service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: RouteSettings(arguments: args),
          builder: (_) => const ChildProgressScreen(),
        );
      },
    ),
  );
}

void _useMobile(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The details ListView builds lazily, so below-the-fold sections must be
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
  testWidgets(
    'child progress renders the 4-group structure with merged subject chips',
    (tester) async {
      _useMobile(tester);

      await tester.pumpWidget(
        _wrap(
          service: FakeParentService(_detail()),
          args: const ChildProgressArgs(131),
        ),
      );
      await tester.pumpAndSettle();

      // ① ملخص الطفل — profile + overall progress.
      expect(find.text('ملخص الطفل'), findsOneWidget);
      expect(find.text('ليان أحمد'), findsOneWidget);

      // ② المواد والتقدم — subject cards carry remaining + chips.
      // Each card is asserted right after scrolling to it: the lazy
      // ListView disposes cards that leave the viewport.
      await _scrollTo(tester, find.text('المواد والتقدم'));
      await _scrollTo(tester, find.text('متبقي 12')); // العربية 12/24
      expect(find.text('نقطة قوة'), findsAtLeastNWidgets(1)); // 88%
      await _scrollTo(tester, find.text('متبقي 20')); // الرياضيات 4/24
      expect(find.text('تحتاج مراجعة'), findsOneWidget); // 52%
      await _scrollTo(tester, find.text('مكتمل')); // English 24/24
      expect(find.text('مكتمل'), findsOneWidget);

      // Old duplicated standalone sections are gone.
      expect(find.text('قائمة إنجاز الدروس'), findsNothing);
      expect(find.text('نقاط القوة'), findsNothing);
      expect(find.text('نقاط تحتاج مراجعة'), findsNothing);

      // ③ النشاط — quiz performance from provider data.
      await _scrollTo(tester, find.text('النشاط'));
      await _scrollTo(tester, find.text('اختبار حرف الراء'));
      expect(find.text('اختبار حرف الراء'), findsOneWidget);

      // ④ اقتراحات المتابعة — recommendations + reports under one group.
      await _scrollTo(tester, find.text('اقتراحات مبنية على البيانات'));
      expect(find.text('مؤشرات مساعدة وليست حكمًا نهائيًا'), findsOneWidget);
      await _scrollTo(tester, find.text('تدريب يومي قصير'));
      expect(find.text('تدريب يومي قصير'), findsOneWidget);
      await _scrollTo(tester, find.text('وضع جيد'));
      expect(find.text('وضع جيد'), findsOneWidget);
    },
  );

  testWidgets('invalid route args render a safe Arabic error state', (
    tester,
  ) async {
    _useMobile(tester);

    await tester.pumpWidget(
      _wrap(service: FakeParentService(_detail()), args: null),
    );
    await tester.pumpAndSettle();

    expect(find.text('لم يتم تحديد الطفل بشكل صحيح'), findsOneWidget);
    expect(find.text('رجوع'), findsOneWidget);
  });

  testWidgets('unlinked child detail failure renders a safe error state', (
    tester,
  ) async {
    _useMobile(tester);

    await tester.pumpWidget(
      _wrap(
        service: FakeParentService(
          _detail(),
          detailError: ApiException(
            'هذا الطفل غير مرتبط بحسابك',
            statusCode: 403,
          ),
        ),
        args: const ChildProgressArgs(999),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('هذا الطفل غير مرتبط بحسابك'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('ليان أحمد'), findsNothing);
  });

  testWidgets('empty subjects/recommendations/reports render Arabic states', (
    tester,
  ) async {
    _useMobile(tester);

    await tester.pumpWidget(
      _wrap(
        service: FakeParentService(_detail(withData: false)),
        args: const ChildProgressArgs(131),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('لا توجد بيانات مواد حتى الآن'));
    expect(find.text('لا توجد بيانات مواد حتى الآن'), findsOneWidget);

    await _scrollTo(tester, find.text('لا توجد اختبارات حديثة بعد'));
    expect(find.text('لا توجد اختبارات حديثة بعد'), findsOneWidget);

    await _scrollTo(tester, find.text('لا توجد اقتراحات حالياً'));
    expect(find.text('لا توجد اقتراحات حالياً'), findsOneWidget);

    await _scrollTo(tester, find.text('لا توجد تقارير بعد'));
    expect(find.text('لا توجد تقارير بعد'), findsOneWidget);
  });
}
