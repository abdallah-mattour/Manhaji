import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/config/api_config.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/report_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeApiService extends ApiService {
  final Map<String, Map<String, dynamic>> getResponses = {};
  final Map<String, Map<String, dynamic>> postResponses = {};

  FakeApiService() : super(FakeLocalStorage());

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    return getResponses[path] ?? const {'data': null};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return postResponses[path] ?? const {'data': null};
  }
}

void main() {
  late FakeApiService api;
  late ReportService service;

  setUp(() {
    api = FakeApiService();
    service = ReportService(api);
  });

  group('ReportService', () {
    test('getReports parses valid report arrays', () async {
      api.getResponses[ApiConfig.getReports] = {
        'data': [
          {
            'id': '1',
            'studentId': 10,
            'studentName': 'طالب',
            'summary': 'ملخص',
            'riskLevel': 'LOW',
          },
        ],
      };

      final reports = await service.getReports();

      expect(reports, hasLength(1));
      expect(reports.first.id, 1);
      expect(reports.first.studentName, 'طالب');
    });

    test('getReports rejects invalid response shapes with ApiException', () {
      api.getResponses[ApiConfig.getReports] = {
        'data': {'id': 1},
      };

      expect(service.getReports(), throwsA(isA<ApiException>()));
    });

    test('getStats parses object data', () async {
      api.getResponses[ApiConfig.performanceStats] = {
        'data': {
          'completedLessons': '3',
          'totalLessons': '5',
          'averageMastery': '72.5',
          'hasActivity': true,
        },
      };

      final stats = await service.getStats();

      expect(stats.completedLessons, 3);
      expect(stats.totalLessons, 5);
      expect(stats.averageMastery, 72.5);
      expect(stats.hasActivity, true);
    });

    test('generateReport rejects non-object data with ApiException', () {
      api.postResponses[ApiConfig.generateReport] = {'data': 'bad'};

      expect(service.generateReport(), throwsA(isA<ApiException>()));
    });
  });
}
