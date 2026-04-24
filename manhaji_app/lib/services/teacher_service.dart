import '../config/api_config.dart';
import '../models/question_bank.dart';
import '../models/teacher_dashboard.dart';
import 'api_service.dart';

class TeacherService {
  final ApiService _api;

  TeacherService(this._api);

  Future<TeacherDashboard> getDashboard() async {
    final response = await _api.get(ApiConfig.teacherDashboard);
    return TeacherDashboard.fromJson(response['data'] ?? {});
  }

  Future<List<ClassStudentSummary>> getStudents() async {
    final response = await _api.get(ApiConfig.teacherStudents);
    final list = response['data'] as List? ?? [];
    return list.map((s) => ClassStudentSummary.fromJson(s)).toList();
  }

  Future<StudentDetail> getStudentDetail(int studentId) async {
    final response = await _api.get('${ApiConfig.teacherStudents}/$studentId');
    return StudentDetail.fromJson(response['data'] ?? {});
  }

  // ===== Question Bank (FR-9) =====

  Future<List<SubjectSummary>> getAssignedSubjects() async {
    final response = await _api.get(ApiConfig.teacherSubjects);
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
      '${ApiConfig.teacherSubjects}/$subjectId/questions',
      queryParams: params.isEmpty ? null : params,
    );
    return QuestionBankResponse.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
