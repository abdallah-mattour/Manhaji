import '../config/api_config.dart';
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
}
