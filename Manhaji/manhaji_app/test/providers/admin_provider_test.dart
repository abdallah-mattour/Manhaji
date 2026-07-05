import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/admin_stats.dart';
import 'package:manhaji_app/models/admin_teacher_assignment.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/providers/admin_provider.dart';
import 'package:manhaji_app/services/admin_service.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

/// Manual mock for AdminService
class MockAdminService extends AdminService {
  AdminStats? statsResult;
  List<UserSummary>? usersResult;
  List<SubjectSummary>? subjectsResult;
  List<AdminTeacherAssignment>? assignmentsResult;
  List<TeacherAssignmentPayload>? receivedCreateAssignments;
  List<TeacherAssignmentPayload>? receivedSavedAssignments;
  int? receivedAssignmentTeacherId;
  Exception? errorToThrow;

  MockAdminService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<AdminStats> getStats() async {
    if (errorToThrow != null) throw errorToThrow!;
    return statsResult!;
  }

  @override
  Future<List<UserSummary>> getUsers({String? role}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return usersResult!;
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
    if (errorToThrow != null) throw errorToThrow!;
    receivedCreateAssignments = teacherAssignments;
    return UserSummary(
      userId: 9,
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
  Future<List<SubjectSummary>> getAllSubjects({int? grade}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return subjectsResult!;
  }

  @override
  Future<List<AdminTeacherAssignment>> getTeacherAssignments(
    int teacherId,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    receivedAssignmentTeacherId = teacherId;
    return assignmentsResult!;
  }

  @override
  Future<List<AdminTeacherAssignment>> updateTeacherAssignments(
    int teacherId,
    List<TeacherAssignmentPayload> assignments,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    receivedAssignmentTeacherId = teacherId;
    receivedSavedAssignments = assignments;
    return assignmentsResult!;
  }
}

void main() {
  late MockAdminService mockService;
  late AdminProvider provider;

  setUp(() {
    mockService = MockAdminService();
    provider = AdminProvider(mockService);
  });

  group('AdminProvider', () {
    group('loadStats()', () {
      test('should load stats successfully', () async {
        mockService.statsResult = AdminStats(
          totalStudents: 150,
          totalTeachers: 12,
          totalParents: 80,
          totalAdmins: 2,
          totalSubjects: 6,
          totalLessons: 48,
          totalAttempts: 320,
          totalCompletedLessons: 210,
          activeStudentsThisWeek: 95,
        );

        await provider.loadStats();

        expect(provider.stats, isNotNull);
        expect(provider.stats!.totalStudents, 150);
        expect(provider.stats!.totalTeachers, 12);
        expect(provider.stats!.activeStudentsThisWeek, 95);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error on failure', () async {
        mockService.errorToThrow = Exception('Network error');

        await provider.loadStats();

        expect(provider.stats, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
        expect(provider.isLoading, false);
      });
    });

    group('loadUsers()', () {
      test('should load all users', () async {
        mockService.usersResult = [
          UserSummary(
            userId: 1,
            fullName: 'طالب',
            role: 'STUDENT',
            isActive: true,
            gradeLevel: 1,
          ),
          UserSummary(
            userId: 2,
            fullName: 'معلم',
            role: 'TEACHER',
            isActive: true,
          ),
        ];

        await provider.loadUsers();

        expect(provider.users, hasLength(2));
        expect(provider.users!.first.role, 'STUDENT');
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error when loading users fails', () async {
        mockService.errorToThrow = Exception('Server error');

        await provider.loadUsers();

        expect(provider.users, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
      });
    });

    group('teacher assignments', () {
      test('createUser forwards teacher assignments', () async {
        final assignments = [
          const TeacherAssignmentPayload(subjectId: 5, gradeLevel: 2),
        ];

        final ok = await provider.createUser(
          fullName: 'معلم',
          email: 'teacher@test.com',
          password: 'Teacher123!',
          role: 'TEACHER',
          teacherAssignments: assignments,
        );

        expect(ok, true);
        expect(mockService.receivedCreateAssignments, assignments);
        expect(provider.users, hasLength(1));
      });

      test('loadAssignmentSubjects loads real subjects', () async {
        mockService.subjectsResult = [
          SubjectSummary(
            id: 5,
            name: 'الرياضيات',
            gradeLevel: 2,
            lessonCount: 4,
            questionCount: 12,
          ),
        ];

        await provider.loadAssignmentSubjects();

        expect(provider.assignmentSubjects, hasLength(1));
        expect(provider.assignmentSubjects!.first.name, 'الرياضيات');
        expect(provider.assignmentError, isNull);
      });

      test('saveTeacherAssignments sends raw assignment payloads', () async {
        mockService.assignmentsResult = [
          const AdminTeacherAssignment(
            id: 1,
            teacherId: 7,
            subjectId: 5,
            subjectName: 'الرياضيات',
            gradeLevel: 2,
            isActive: true,
          ),
        ];
        const payloads = [
          TeacherAssignmentPayload(subjectId: 5, gradeLevel: 2),
        ];

        final ok = await provider.saveTeacherAssignments(7, payloads);

        expect(ok, true);
        expect(mockService.receivedAssignmentTeacherId, 7);
        expect(mockService.receivedSavedAssignments, payloads);
        expect(provider.teacherAssignments, hasLength(1));
      });
    });
  });
}
