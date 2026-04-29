import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/admin_stats.dart';
import 'package:manhaji_app/providers/admin_provider.dart';
import 'package:manhaji_app/services/admin_service.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

/// Manual mock for AdminService
class MockAdminService extends AdminService {
  AdminStats? statsResult;
  List<UserSummary>? usersResult;
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
  });
}
