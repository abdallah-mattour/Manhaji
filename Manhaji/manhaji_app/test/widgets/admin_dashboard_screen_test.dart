import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/admin_stats.dart';
import 'package:manhaji_app/providers/admin_provider.dart';
import 'package:manhaji_app/screens/admin/admin_dashboard_screen.dart';
import 'package:manhaji_app/services/admin_service.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeAdminService extends AdminService {
  FakeAdminService({required this.stats, required this.users})
    : super(ApiService(FakeLocalStorage()));

  final AdminStats stats;
  final List<UserSummary> users;

  @override
  Future<AdminStats> getStats() async => stats;

  @override
  Future<List<UserSummary>> getUsers({String? role}) async => users;
}

FakeAdminService _service() {
  return FakeAdminService(
    stats: AdminStats(
      totalStudents: 12,
      totalTeachers: 3,
      totalParents: 5,
      totalAdmins: 1,
      totalSubjects: 4,
      totalLessons: 22,
      totalAttempts: 37,
      totalCompletedLessons: 18,
      activeStudentsThisWeek: 9,
    ),
    users: [
      UserSummary(
        userId: 1,
        fullName: 'سارة أحمد',
        email: 'sara@example.com',
        role: 'STUDENT',
        isActive: true,
        parentId: 3,
        lastLoginAt: '2026-07-04T09:15:00',
        createdAt: '2026-07-01T09:15:00',
      ),
      UserSummary(
        userId: 2,
        fullName: 'أستاذ خالد',
        email: 'teacher@example.com',
        role: 'TEACHER',
        isActive: false,
        createdAt: '2026-07-02T10:30:00',
      ),
      UserSummary(
        userId: 3,
        fullName: 'أم سارة',
        email: 'parent@example.com',
        role: 'PARENT',
        isActive: true,
        createdAt: '2026-07-03T08:00:00',
      ),
      UserSummary(
        userId: 4,
        fullName: 'ولي بلا أبناء',
        email: 'orphan-parent@example.com',
        role: 'PARENT',
        isActive: true,
        createdAt: '2026-07-05T08:00:00',
      ),
      UserSummary(
        userId: 5,
        fullName: 'طالب بلا ولي',
        email: 'student-no-parent@example.com',
        role: 'STUDENT',
        isActive: true,
        createdAt: '2026-07-06T08:00:00',
      ),
    ],
  );
}

Widget _wrap(FakeAdminService service) {
  return ChangeNotifierProvider(
    create: (_) => AdminProvider(service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.adminManageUsers: (_) =>
            const Scaffold(body: Text('إدارة المستخدمين — صفحة')),
        AppRoutes.adminSettings: (_) =>
            const Scaffold(body: Text('إعدادات المشرف — صفحة')),
      },
      home: const AdminDashboardScreen(),
    ),
  );
}

void main() {
  testWidgets('AdminDashboardScreen renders shell metrics from provider data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_service()));
    await tester.pumpAndSettle();

    expect(find.text('مساحة المشرف'), findsOneWidget);
    expect(find.text('لوحة التحكم'), findsAtLeastNWidgets(1));
    expect(find.text('المستخدمون'), findsAtLeastNWidgets(1));
    expect(find.text('بنك الأسئلة'), findsAtLeastNWidgets(1));

    // Sidebar settings item is real now — no "coming soon" left anywhere.
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('قريبًا'), findsNothing);

    expect(find.text('إجمالي المستخدمين'), findsAtLeastNWidgets(1));
    expect(find.text('21'), findsAtLeastNWidgets(1));
    expect(find.text('الطلاب'), findsAtLeastNWidgets(1));
    expect(find.text('12'), findsAtLeastNWidgets(1));
    expect(find.text('المعلمون'), findsAtLeastNWidgets(1));
    expect(find.text('3'), findsAtLeastNWidgets(1));
    expect(find.text('أولياء الأمور'), findsAtLeastNWidgets(1));
    expect(find.text('5'), findsAtLeastNWidgets(1));
    expect(find.text('المواد'), findsAtLeastNWidgets(1));
    expect(find.text('4'), findsAtLeastNWidgets(1));
    expect(find.text('الدروس'), findsAtLeastNWidgets(1));
    expect(find.text('22'), findsAtLeastNWidgets(1));
    expect(find.text('محاولات الاختبار'), findsAtLeastNWidgets(1));
    expect(find.text('37'), findsAtLeastNWidgets(1));

    // Phase 5E.2: the quick-actions panel is gone — the sidebar is the
    // primary navigation and refresh lives as a compact header action.
    expect(find.text('إجراءات سريعة'), findsNothing);
    expect(find.byTooltip('تحديث البيانات'), findsOneWidget);

    // Data-quality panels are derived from loaded users only.
    expect(find.text('جودة البيانات'), findsOneWidget);
    expect(find.text('أولياء بلا أبناء'), findsOneWidget);
    expect(find.text('طلاب بلا ولي أمر'), findsOneWidget);
    expect(find.text('معلمون بلا مواد'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('admin-quality-parents-without-children'),
        ),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('admin-quality-students-without-parent')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('admin-quality-teachers-without-materials'),
        ),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    // Recent users table with view-all footer.
    expect(find.text('آخر المستخدمين المضافين'), findsOneWidget);
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('sara@example.com'), findsOneWidget);
    expect(find.text('أستاذ خالد'), findsOneWidget);
    expect(find.text('موقوف'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('admin-dashboard-view-all-users')),
      findsOneWidget,
    );

    // Insight panels.
    expect(find.text('توزيع المستخدمين حسب الدور'), findsOneWidget);
    expect(find.text('حالة الحسابات'), findsOneWidget);
    expect(find.text('نسبة الحسابات النشطة'), findsOneWidget);
    expect(find.text('ملخص المحتوى والتفاعل'), findsOneWidget);
  });

  testWidgets('header refresh action reloads dashboard data without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_service()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تحديث البيانات'));
    await tester.pumpAndSettle();

    // Data is still rendered after the reload round-trip.
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('حالة الحسابات'), findsOneWidget);
  });

  testWidgets(
    '«عرض كل المستخدمين» footer navigates to the manage users route',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_service()));
      await tester.pumpAndSettle();

      final viewAll = find.byKey(
        const ValueKey('admin-dashboard-view-all-users'),
      );
      await tester.ensureVisible(viewAll);
      await tester.pumpAndSettle();
      await tester.tap(viewAll);
      await tester.pumpAndSettle();

      expect(find.text('إدارة المستخدمين — صفحة'), findsOneWidget);
    },
  );
}
