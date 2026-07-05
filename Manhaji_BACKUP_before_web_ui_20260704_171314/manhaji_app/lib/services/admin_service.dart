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

  /// Create a STUDENT or TEACHER. Pass only the fields relevant to the role:
  /// `gradeLevel` for students, `department` + `assignedGrade` for teachers.
  Future<UserSummary> createUser({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    required String role,
    int? gradeLevel,
    String? department,
    int? assignedGrade,
  }) async {
    final Map<String, dynamic> body = {
      'fullName': fullName,
      'password': password,
      'role': role,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'gradeLevel': ?gradeLevel,
      if (department != null && department.isNotEmpty) 'department': department,
      'assignedGrade': ?assignedGrade,
    };
    final response = await _api.post(ApiConfig.adminUsers, data: body);
    return UserSummary.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// PATCH semantics: only fields provided are applied. Password is rehashed
  /// only if non-null and non-empty.
  Future<UserSummary> updateUser(
    int userId, {
    String? fullName,
    String? email,
    String? phone,
    String? password,
    bool? isActive,
    int? gradeLevel,
    String? department,
    int? assignedGrade,
  }) async {
    final Map<String, dynamic> body = {
      if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (password != null && password.isNotEmpty) 'password': password,
      'isActive': ?isActive,
      'gradeLevel': ?gradeLevel,
      'department': ?department,
      'assignedGrade': ?assignedGrade,
    };
    final response =
        await _api.put('${ApiConfig.adminUsers}/$userId', data: body);
    return UserSummary.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<void> deleteUser(int userId) async {
    await _api.delete('${ApiConfig.adminUsers}/$userId');
  }

  Future<UserSummary> linkStudentToParent(int studentId, int? parentId) async {
    final response = await _api.put(
      ApiConfig.adminLinkParent(studentId),
      data: {'parentId': parentId},
    );
    return UserSummary.fromJson(
      (response['data'] as Map<String, dynamic>?) ?? const {},
    );
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
