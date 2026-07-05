import '../config/api_config.dart';
import '../models/question_bank.dart';
import '../models/teacher_dashboard.dart';
import '../models/teacher_mistake_analytics.dart';
import '../models/teacher_quiz.dart';
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

  Future<TeacherMistakeAnalytics> getMistakeAnalytics({
    int? subjectId,
    int? lessonId,
    int? studentId,
    int? limit,
  }) async {
    final params = <String, dynamic>{};
    if (subjectId != null) params['subjectId'] = subjectId;
    if (lessonId != null) params['lessonId'] = lessonId;
    if (studentId != null) params['studentId'] = studentId;
    if (limit != null) params['limit'] = limit;
    final response = await _api.get(
      ApiConfig.teacherMistakes,
      queryParams: params.isEmpty ? null : params,
    );
    return TeacherMistakeAnalytics.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
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

  // ===== Teacher Quizzes (Phase 8D) =====

  Future<List<TeacherQuizSummary>> getTeacherQuizzes() async {
    final response = await _api.get(ApiConfig.teacherQuizzes);
    final list = response['data'] as List? ?? [];
    return list
        .map((q) => TeacherQuizSummary.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherQuizDetail> getTeacherQuiz(int quizId) async {
    final response = await _api.get('${ApiConfig.teacherQuizzes}/$quizId');
    return TeacherQuizDetail.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<TeacherQuizDetail> createTeacherQuiz({
    required String title,
    required int subjectId,
    int? lessonId,
    required List<int> questionIds,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'subjectId': subjectId,
      'questionIds': questionIds,
    };
    if (lessonId != null) {
      data['lessonId'] = lessonId;
    }
    final response = await _api.post(ApiConfig.teacherQuizzes, data: data);
    return TeacherQuizDetail.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
