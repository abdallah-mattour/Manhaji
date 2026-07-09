import '../config/api_config.dart';
import '../models/ai_report.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _api;

  ReportService(this._api);

  Future<ProgressReportModel> generateReport() async {
    final response = await _api.post(ApiConfig.generateReport);
    return ProgressReportModel.fromJson(_readObject(response, 'report'));
  }

  Future<List<ProgressReportModel>> getReports() async {
    final response = await _api.get(ApiConfig.getReports);
    return _readObjectList(
      response,
      'reports',
    ).map(ProgressReportModel.fromJson).toList(growable: false);
  }

  Future<PerformanceStats> getStats() async {
    final response = await _api.get(ApiConfig.performanceStats);
    return PerformanceStats.fromJson(
      _readObject(response, 'performance stats'),
    );
  }

  Future<LearningPathModel> generateLearningPath() async {
    final response = await _api.post(ApiConfig.generateLearningPath);
    return LearningPathModel.fromJson(_readObject(response, 'learning path'));
  }

  Future<LearningPathModel> getLearningPath() async {
    final response = await _api.get(ApiConfig.getLearningPath);
    return LearningPathModel.fromJson(_readObject(response, 'learning path'));
  }

  Map<String, dynamic> _readObject(
    Map<String, dynamic> response,
    String context,
  ) {
    final data = response['data'];
    if (data == null) return const {};

    final object = _asStringMap(data);
    if (object != null) return object;

    throw ApiException('استجابة $context من الخادم غير صالحة.');
  }

  List<Map<String, dynamic>> _readObjectList(
    Map<String, dynamic> response,
    String context,
  ) {
    final data = response['data'];
    if (data == null) return const [];
    if (data is! List) {
      throw ApiException('استجابة $context من الخادم غير صالحة.');
    }

    final objects = <Map<String, dynamic>>[];
    for (final item in data) {
      final object = _asStringMap(item);
      if (object == null) {
        throw ApiException('استجابة $context من الخادم غير صالحة.');
      }
      objects.add(object);
    }
    return objects;
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
