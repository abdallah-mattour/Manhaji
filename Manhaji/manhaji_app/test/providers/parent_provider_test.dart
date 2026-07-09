import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/parent_dashboard.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/providers/parent_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/parent_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class MockParentService extends ParentApiService {
  MockParentService() : super(ApiService(FakeLocalStorage()));

  ParentDashboard? dashboardResult;
  StudentDetail? childDetailResult;
  Exception? errorToThrow;

  @override
  Future<ParentDashboard> getDashboard() async {
    if (errorToThrow != null) throw errorToThrow!;
    return dashboardResult!;
  }

  @override
  Future<StudentDetail> getChildDetail(int childId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return childDetailResult!;
  }
}

ParentDashboard _dashboard() {
  return ParentDashboard(
    parentId: 121,
    fullName: 'أم ليان',
    children: const [],
    recentActivityAcrossChildren: const [],
    alerts: const [],
    recommendations: const [],
  );
}

StudentDetail _childDetail() {
  return StudentDetail(
    studentId: 131,
    fullName: 'ليان أحمد',
    gradeLevel: 1,
    totalPoints: 460,
    currentStreak: 3,
    lessonsCompleted: 12,
    lessonsInProgress: 2,
    overallMastery: 82.5,
    totalAttempts: 8,
    averageScore: 79.4,
    subjectBreakdown: const [],
  );
}

void main() {
  late MockParentService service;
  late ParentProvider provider;

  setUp(() {
    service = MockParentService();
    provider = ParentProvider(service);
  });

  group('ParentProvider', () {
    test('loadDashboard success updates dashboard state only', () async {
      service.dashboardResult = _dashboard();

      await provider.loadDashboard();

      expect(provider.dashboard, isNotNull);
      expect(provider.dashboard!.parentId, 121);
      expect(provider.dashboard!.fullName, 'أم ليان');
      expect(provider.isDashboardLoading, isFalse);
      expect(provider.dashboardError, isNull);
      expect(provider.isChildDetailLoading, isFalse);
      expect(provider.childDetailError, isNull);
    });

    test('loadDashboard error updates dashboard error state only', () async {
      service.errorToThrow = Exception('Network error');

      await provider.loadDashboard();

      expect(provider.dashboard, isNull);
      expect(provider.isDashboardLoading, isFalse);
      expect(provider.dashboardError, 'حدث خطأ غير متوقع');
      expect(provider.childDetail, isNull);
      expect(provider.isChildDetailLoading, isFalse);
      expect(provider.childDetailError, isNull);
    });

    test('loadChildDetail success updates child-detail state only', () async {
      service.childDetailResult = _childDetail();

      await provider.loadChildDetail(131);

      expect(provider.childDetail, isNotNull);
      expect(provider.childDetail!.studentId, 131);
      expect(provider.childDetail!.overallMastery, 82.5);
      expect(provider.isChildDetailLoading, isFalse);
      expect(provider.childDetailError, isNull);
      expect(provider.dashboard, isNull);
      expect(provider.isDashboardLoading, isFalse);
      expect(provider.dashboardError, isNull);
    });

    test(
      'loadChildDetail error updates child-detail error state only',
      () async {
        service.errorToThrow = Exception('Server error');

        await provider.loadChildDetail(131);

        expect(provider.childDetail, isNull);
        expect(provider.isChildDetailLoading, isFalse);
        expect(provider.childDetailError, 'حدث خطأ غير متوقع');
        expect(provider.dashboard, isNull);
        expect(provider.isDashboardLoading, isFalse);
        expect(provider.dashboardError, isNull);
      },
    );
  });
}
