import '../config/api_config.dart';
import '../models/dashboard.dart';
import '../models/lesson.dart';
import '../models/subject.dart';
import 'api_service.dart';

class LessonApiService {
  final ApiService _api;

  LessonApiService(this._api);

  Future<List<Subject>> getSubjectsByGrade(int gradeLevel) async {
    final response = await _api.get(
      ApiConfig.subjects,
      queryParams: {'gradeLevel': gradeLevel},
    );
    final data = response['data'];
    if (data is! List) return [];
    return data.map((s) => Subject.fromJson(s)).toList();
  }

  Future<List<LessonSummary>> getLessonsBySubject(int subjectId) async {
    final response = await _api.get('${ApiConfig.lessonsBySubject}/$subjectId');
    final data = response['data'];
    if (data is! List) return [];
    return data.map((l) => LessonSummary.fromJson(l)).toList();
  }

  Future<Lesson> getLessonDetail(int lessonId) async {
    final response = await _api.get('${ApiConfig.lessonDetail}/$lessonId');
    return Lesson.fromJson(response['data'] ?? {});
  }

  Future<Dashboard> getDashboard() async {
    final response = await _api.get(ApiConfig.dashboard);
    return Dashboard.fromJson(response['data'] ?? {});
  }
}
