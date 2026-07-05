import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/admin_stats.dart';
import 'package:manhaji_app/models/admin_teacher_assignment.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/providers/admin_provider.dart';
import 'package:manhaji_app/screens/admin/manage_users_screen.dart';
import 'package:manhaji_app/services/admin_service.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeAdminService extends AdminService {
  FakeAdminService({
    required this.users,
    required this.subjects,
    required this.assignments,
  }) : super(ApiService(FakeLocalStorage()));

  final List<UserSummary> users;
  final List<SubjectSummary> subjects;
  final List<AdminTeacherAssignment> assignments;
  List<TeacherAssignmentPayload>? receivedCreateAssignments;
  List<TeacherAssignmentPayload>? receivedSavedAssignments;
  int createCalls = 0;

  @override
  Future<AdminStats> getStats() async {
    return AdminStats(
      totalStudents: users.where((user) => user.role == 'STUDENT').length,
      totalTeachers: users.where((user) => user.role == 'TEACHER').length,
      totalParents: users.where((user) => user.role == 'PARENT').length,
      totalAdmins: users.where((user) => user.role == 'ADMIN').length,
      totalSubjects: subjects.length,
      totalLessons: 0,
      totalAttempts: 0,
      totalCompletedLessons: 0,
      activeStudentsThisWeek: 0,
    );
  }

  @override
  Future<List<UserSummary>> getUsers({String? role}) async {
    if (role == null) return users;
    return users.where((user) => user.role == role).toList();
  }

  @override
  Future<List<SubjectSummary>> getAllSubjects({int? grade}) async {
    if (grade == null) return subjects;
    return subjects.where((subject) => subject.gradeLevel == grade).toList();
  }

  @override
  Future<UserSummary> createUser({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    required String role,
    int? gradeLevel,
    String? department,
    int? assignedGrade,
    List<TeacherAssignmentPayload>? teacherAssignments,
  }) async {
    createCalls++;
    receivedCreateAssignments = teacherAssignments;
    return UserSummary(
      userId: 99,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      isActive: true,
      gradeLevel: gradeLevel,
      department: department,
      assignedGrade: assignedGrade,
    );
  }

  @override
  Future<List<AdminTeacherAssignment>> getTeacherAssignments(
    int teacherId,
  ) async {
    return assignments;
  }

  @override
  Future<List<AdminTeacherAssignment>> updateTeacherAssignments(
    int teacherId,
    List<TeacherAssignmentPayload> assignments,
  ) async {
    receivedSavedAssignments = assignments;
    return this.assignments;
  }
}

Widget _wrap(FakeAdminService service) {
  return ChangeNotifierProvider(
    create: (_) => AdminProvider(service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.adminDashboard: (_) =>
            const Scaffold(body: Text('لوحة التحكم')),
      },
      home: const ManageUsersScreen(),
    ),
  );
}

FakeAdminService _service() {
  return FakeAdminService(
    users: [
      UserSummary(
        userId: 1,
        fullName: 'سارة أحمد',
        email: 'sara@example.com',
        role: 'STUDENT',
        isActive: true,
        gradeLevel: 2,
      ),
      UserSummary(
        userId: 2,
        fullName: 'أستاذ خالد',
        email: 'teacher@example.com',
        role: 'TEACHER',
        isActive: true,
        assignedGrade: 2,
      ),
      UserSummary(
        userId: 3,
        fullName: 'ولي أمر',
        phone: '0591234567',
        role: 'PARENT',
        isActive: true,
      ),
    ],
    subjects: [
      SubjectSummary(
        id: 5,
        name: 'الرياضيات',
        gradeLevel: 2,
        lessonCount: 4,
        questionCount: 12,
      ),
      SubjectSummary(
        id: 6,
        name: 'اللغة العربية',
        gradeLevel: 1,
        lessonCount: 5,
        questionCount: 20,
      ),
    ],
    assignments: [
      const AdminTeacherAssignment(
        id: 10,
        teacherId: 2,
        subjectId: 5,
        subjectName: 'الرياضيات',
        gradeLevel: 2,
        isActive: true,
      ),
    ],
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Admin users page renders in StaffWebShell', (tester) async {
    setDesktopSize(tester);
    await tester.pumpWidget(_wrap(_service()));
    await tester.pumpAndSettle();

    expect(find.text('مساحة المشرف'), findsOneWidget);
    expect(find.text('المستخدمون'), findsAtLeastNWidgets(1));
    expect(find.text('جدول المستخدمين'), findsAtLeastNWidgets(1));
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('أستاذ خالد'), findsOneWidget);
    expect(find.text('إدارة المواد'), findsOneWidget);
  });

  testWidgets('teacher creation shows assignment picker', (tester) async {
    setDesktopSize(tester);
    await tester.pumpWidget(_wrap(_service()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إضافة معلم'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة معلم جديد'), findsOneWidget);
    expect(find.text('مواد المعلم'), findsOneWidget);
    expect(find.text('الرياضيات - الصف 2'), findsOneWidget);
  });

  testWidgets('student creation hides teacher assignment picker', (
    tester,
  ) async {
    setDesktopSize(tester);
    await tester.pumpWidget(_wrap(_service()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إضافة طالب'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة طالب جديد'), findsOneWidget);
    expect(find.text('مواد المعلم'), findsNothing);
  });

  testWidgets('cannot create teacher without assignments', (tester) async {
    setDesktopSize(tester);
    final service = _service();
    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إضافة معلم'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'معلم جديد');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'new.teacher@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'Teacher123!');
    await tester.tap(find.text('إضافة'));
    await tester.pump();

    expect(find.text('اختر مادة واحدة على الأقل للمعلم'), findsOneWidget);
    expect(service.createCalls, 0);
  });

  testWidgets('existing teacher opens assignment management', (tester) async {
    setDesktopSize(tester);
    await tester.pumpWidget(_wrap(_service()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('إدارة المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إدارة المواد'));
    await tester.pumpAndSettle();

    expect(find.text('إدارة مواد المعلم'), findsOneWidget);
    expect(find.text('المواد المخصصة'), findsOneWidget);
    expect(find.text('الرياضيات - الصف 2'), findsOneWidget);
  });
}
