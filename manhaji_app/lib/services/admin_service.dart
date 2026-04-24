import '../config/api_config.dart';
import '../models/admin_stats.dart';
import '../models/question_bank.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _api;

  AdminService(this._api);

  Future<AdminStats> getStats() async {
    final response = await _api.get(ApiConfig.adminStats);
    return AdminStats.fromJson(response['data'] ?? {});
  }

  Future<List<UserSummary>> getUsers({String? role}) async {
    final Map<String, dynamic>? params =
        role != null ? {'role': role} : null;
    final response = await _api.get(ApiConfig.adminUsers, queryParams: params);
    final list = response['data'] as List? ?? [];
    return list.map((u) => UserSummary.fromJson(u)).toList();
  }

  // ===== Question Bank (FR-9, unrestricted) =====

  Future<List<SubjectSummary>> getAllSubjects({int? grade}) async {
    final params = grade != null ? <String, dynamic>{'grade': grade} : null;
    final response = await _api.get(
      ApiConfig.adminSubjects,
      queryParams: params,
    );
    final list = response['data'] as List? ?? [];
    return list
        .map((s) => SubjectSummary.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<QuestionBankResponse> getQuestionsForSubject(
    int subjectId, {
    int? difficulty,
    int? lessonId,
  }) async {
    final params = <String, dynamic>{};
    if (difficulty != null) params['difficulty'] = difficulty;
    if (lessonId != null) params['lessonId'] = lessonId;
    final response = await _api.get(
      '${ApiConfig.adminSubjects}/$subjectId/questions',
      queryParams: params.isEmpty ? null : params,
    );
    return QuestionBankResponse.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
