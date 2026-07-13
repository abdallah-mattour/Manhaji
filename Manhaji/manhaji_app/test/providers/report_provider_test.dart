import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/ai_report.dart';
import 'package:manhaji_app/providers/report_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/report_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

/// Manual mock for ReportService
class MockReportService extends ReportService {
  List<ProgressReportModel>? reportsResult;
  ProgressReportModel? generateReportResult;
  LearningPathModel? learningPathResult;
  LearningPathModel? generatePathResult;
  PerformanceStats? statsResult;
  Exception? errorToThrow;
  Exception? statsErrorToThrow;
  int statsCallCount = 0;

  MockReportService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<List<ProgressReportModel>> getReports() async {
    if (errorToThrow != null) throw errorToThrow!;
    return reportsResult!;
  }

  @override
  Future<PerformanceStats> getStats() async {
    statsCallCount += 1;
    if (statsErrorToThrow != null) throw statsErrorToThrow!;
    // Stats are best-effort in the provider; return a benign empty snapshot
    // unless a test explicitly sets one.
    return statsResult ??
        PerformanceStats(
          completedLessons: 0,
          totalLessons: 0,
          inProgressLessons: 0,
          averageMastery: 0,
          averageScore: 0,
          totalPoints: 0,
          currentStreak: 0,
          quizzesTaken: 0,
          hasActivity: false,
          subjects: const [],
          focusSkills: const [],
        );
  }

  @override
  Future<ProgressReportModel> generateReport() async {
    if (errorToThrow != null) throw errorToThrow!;
    return generateReportResult!;
  }

  @override
  Future<LearningPathModel> getLearningPath() async {
    if (errorToThrow != null) throw errorToThrow!;
    return learningPathResult!;
  }

  @override
  Future<LearningPathModel> generateLearningPath() async {
    if (errorToThrow != null) throw errorToThrow!;
    return generatePathResult!;
  }
}

void main() {
  late MockReportService mockService;
  late ReportProvider provider;

  setUp(() {
    mockService = MockReportService();
    provider = ReportProvider(mockService);
  });

  group('ReportProvider', () {
    group('loadReports()', () {
      test('should load reports successfully', () async {
        mockService.reportsResult = [
          ProgressReportModel(
            id: 1,
            studentId: 10,
            studentName: 'طالب أحمد',
            periodStart: '2026-03-01',
            periodEnd: '2026-04-01',
            summary: 'أداء جيد',
            riskLevel: 'LOW',
            generatedAt: '2026-04-13',
          ),
        ];

        await provider.loadReports();

        expect(provider.reports, hasLength(1));
        expect(provider.reports!.first.riskLevel, 'LOW');
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should keep reports when stats endpoint fails', () async {
        mockService.reportsResult = [
          ProgressReportModel(
            id: 1,
            studentId: 10,
            studentName: 'طالب أحمد',
            periodStart: '2026-03-01',
            periodEnd: '2026-04-01',
            summary: 'أداء جيد',
            riskLevel: 'LOW',
            generatedAt: '2026-04-13',
          ),
        ];
        mockService.statsErrorToThrow = Exception('Older backend');

        await provider.loadReports();

        expect(provider.reports, hasLength(1));
        expect(provider.stats, isNull);
        expect(provider.error, isNull);
      });

      test('should set error on failure', () async {
        mockService.errorToThrow = Exception('Network error');

        await provider.loadReports();

        expect(provider.reports, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
      });
    });

    group('generateReport()', () {
      test('should generate and prepend new report', () async {
        // Start with one existing report
        mockService.reportsResult = [
          ProgressReportModel(
            id: 1,
            studentId: 10,
            studentName: 'طالب',
            periodStart: '2026-03-01',
            periodEnd: '2026-04-01',
            summary: 'قديم',
            riskLevel: 'LOW',
            generatedAt: '2026-04-01',
          ),
        ];
        mockService.statsResult = PerformanceStats(
          completedLessons: 1,
          totalLessons: 4,
          inProgressLessons: 0,
          averageMastery: 25,
          averageScore: 60,
          totalPoints: 10,
          currentStreak: 1,
          quizzesTaken: 1,
          hasActivity: true,
          subjects: const [],
          focusSkills: const [],
        );
        await provider.loadReports();

        // Now generate a new report
        mockService.generateReportResult = ProgressReportModel(
          id: 2,
          studentId: 10,
          studentName: 'طالب',
          periodStart: '2026-04-01',
          periodEnd: '2026-04-13',
          summary: 'جديد',
          riskLevel: 'MEDIUM',
          generatedAt: '2026-04-13',
        );
        mockService.statsResult = PerformanceStats(
          completedLessons: 2,
          totalLessons: 4,
          inProgressLessons: 0,
          averageMastery: 50,
          averageScore: 80,
          totalPoints: 20,
          currentStreak: 2,
          quizzesTaken: 2,
          hasActivity: true,
          subjects: const [],
          focusSkills: const [],
        );

        await provider.generateReport();

        expect(provider.reports, hasLength(2));
        expect(provider.reports!.first.id, 2); // newest first
        expect(provider.reports!.first.riskLevel, 'MEDIUM');
        expect(provider.stats!.completedLessons, 2);
        expect(mockService.statsCallCount, 2);
        expect(provider.isGenerating, false);
      });

      test('should set error on generation failure', () async {
        mockService.errorToThrow = Exception('AI unavailable');

        await provider.generateReport();

        expect(provider.error, 'حدث خطأ غير متوقع');
        expect(provider.isGenerating, false);
      });
    });

    group('loadLearningPath()', () {
      test('should load learning path successfully', () async {
        mockService.learningPathResult = LearningPathModel(
          id: 1,
          studentId: 10,
          studentName: 'طالب',
          recommendations:
              '{"reviewLessons":["الدرس 1"],"activities":["قراءة"],"tips":["اقرأ يومياً"]}',
          generatedAt: '2026-04-13',
        );

        await provider.loadLearningPath();

        expect(provider.learningPath, isNotNull);
        expect(
          provider.learningPath!.recommendations,
          contains('reviewLessons'),
        );
        expect(provider.isLoading, false);
      });

      test('should set learningPath to null on failure (silent)', () async {
        mockService.errorToThrow = Exception('Not found');

        await provider.loadLearningPath();

        expect(provider.learningPath, isNull);
        expect(provider.isLoading, false);
        // Note: loadLearningPath silently handles errors (no _error set)
      });
    });

    group('generateLearningPath()', () {
      test('should generate learning path', () async {
        mockService.generatePathResult = LearningPathModel(
          id: 1,
          studentId: 10,
          studentName: 'طالب',
          recommendations:
              '{"reviewLessons":[],"activities":["تمرين"],"tips":[]}',
          generatedAt: '2026-04-13',
        );

        await provider.generateLearningPath();

        expect(provider.learningPath, isNotNull);
        expect(provider.isGenerating, false);
        expect(provider.error, isNull);
      });

      test('should set error on generation failure', () async {
        mockService.errorToThrow = Exception('AI error');

        await provider.generateLearningPath();

        expect(provider.error, 'حدث خطأ غير متوقع');
        expect(provider.isGenerating, false);
      });
    });
  });
}
