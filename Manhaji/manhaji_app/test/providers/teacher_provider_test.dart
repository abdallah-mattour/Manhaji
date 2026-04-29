import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';

/// Minimal LocalStorageService fake
class FakeLocalStorage extends Fake implements LocalStorageService {}

/// Manual mock for TeacherService
class MockTeacherService extends TeacherService {
  TeacherDashboard? dashboardResult;
  List<ClassStudentSummary>? studentsResult;
  StudentDetail? studentDetailResult;
  Exception? errorToThrow;

  MockTeacherService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<TeacherDashboard> getDashboard() async {
    if (errorToThrow != null) throw errorToThrow!;
    return dashboardResult!;
  }

  @override
  Future<List<ClassStudentSummary>> getStudents() async {
    if (errorToThrow != null) throw errorToThrow!;
    return studentsResult!;
  }

  @override
  Future<StudentDetail> getStudentDetail(int studentId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return studentDetailResult!;
  }
}

void main() {
  late MockTeacherService mockService;
  late TeacherProvider provider;

  setUp(() {
    mockService = MockTeacherService();
    provider = TeacherProvider(mockService);
  });

  group('TeacherProvider', () {
    group('loadDashboard()', () {
      test('should load dashboard successfully', () async {
        mockService.dashboardResult = TeacherDashboard(
          teacherId: 10,
          fullName: 'أستاذ أحمد',
          department: 'اللغة العربية',
          assignedGrade: 1,
          totalStudents: 25,
          activeThisWeek: 18,
          lessonsCompletedTotal: 120,
          averageMasteryAcrossClass: 72.5,
          topStudents: [],
        );

        await provider.loadDashboard();

        expect(provider.dashboard, isNotNull);
        expect(provider.dashboard!.teacherId, 10);
        expect(provider.dashboard!.fullName, 'أستاذ أحمد');
        expect(provider.dashboard!.totalStudents, 25);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error on failure', () async {
        mockService.errorToThrow = Exception('Network error');

        await provider.loadDashboard();

        expect(provider.dashboard, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
        expect(provider.isLoading, false);
      });
    });

    group('loadStudents()', () {
      test('should load students list', () async {
        mockService.studentsResult = [
          ClassStudentSummary(
            studentId: 1,
            fullName: 'طالب واحد',
            gradeLevel: 1,
            totalPoints: 100,
            currentStreak: 3,
            lessonsCompleted: 5,
            lessonsInProgress: 2,
            averageMastery: 78.0,
          ),
          ClassStudentSummary(
            studentId: 2,
            fullName: 'طالب اثنان',
            gradeLevel: 1,
            totalPoints: 50,
            currentStreak: 1,
            lessonsCompleted: 3,
            lessonsInProgress: 1,
            averageMastery: 60.0,
          ),
        ];

        await provider.loadStudents();

        expect(provider.students, hasLength(2));
        expect(provider.students!.first.fullName, 'طالب واحد');
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error when loading students fails', () async {
        mockService.errorToThrow = Exception('Server error');

        await provider.loadStudents();

        expect(provider.students, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
      });
    });

    group('loadStudentDetail()', () {
      test('should load student detail', () async {
        mockService.studentDetailResult = StudentDetail(
          studentId: 1,
          fullName: 'طالب مفصل',
          gradeLevel: 1,
          totalPoints: 300,
          currentStreak: 4,
          lessonsCompleted: 12,
          lessonsInProgress: 3,
          overallMastery: 75.5,
          totalAttempts: 15,
          averageScore: 82.3,
          subjectBreakdown: [],
        );

        await provider.loadStudentDetail(1);

        expect(provider.studentDetail, isNotNull);
        expect(provider.studentDetail!.studentId, 1);
        expect(provider.studentDetail!.overallMastery, 75.5);
        expect(provider.isLoading, false);
      });

      test('should clear previous detail before loading', () async {
        // First load
        mockService.studentDetailResult = StudentDetail(
          studentId: 1,
          fullName: 'First',
          gradeLevel: 1,
          totalPoints: 0,
          currentStreak: 0,
          lessonsCompleted: 0,
          lessonsInProgress: 0,
          overallMastery: 0,
          totalAttempts: 0,
          averageScore: 0,
          subjectBreakdown: [],
        );
        await provider.loadStudentDetail(1);

        // Second load should clear first
        mockService.studentDetailResult = StudentDetail(
          studentId: 2,
          fullName: 'Second',
          gradeLevel: 1,
          totalPoints: 100,
          currentStreak: 0,
          lessonsCompleted: 0,
          lessonsInProgress: 0,
          overallMastery: 0,
          totalAttempts: 0,
          averageScore: 0,
          subjectBreakdown: [],
        );
        await provider.loadStudentDetail(2);

        expect(provider.studentDetail!.studentId, 2);
        expect(provider.studentDetail!.fullName, 'Second');
      });
    });
  });
}
