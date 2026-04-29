import '../config/api_config.dart';
import '../models/ai_report.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _api;

  ReportService(this._api);

  Future<ProgressReportModel> generateReport() async {
    final response = await _api.post(ApiConfig.generateReport);
    return ProgressReportModel.fromJson(response['data'] ?? {});
  }

  Future<List<ProgressReportModel>> getReports() async {
    final response = await _api.get(ApiConfig.getReports);
    final list = response['data'] as List? ?? [];
    return list.map((r) => ProgressReportModel.fromJson(r)).toList();
  }

  Future<LearningPathModel> generateLearningPath() async {
    final response = await _api.post(ApiConfig.generateLearningPath);
    return LearningPathModel.fromJson(response['data'] ?? {});
  }

  Future<LearningPathModel> getLearningPath() async {
    final response = await _api.get(ApiConfig.getLearningPath);
    return LearningPathModel.fromJson(response['data'] ?? {});
  }
}
