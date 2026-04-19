import '../config/api_config.dart';
import '../models/parent_dashboard.dart';
import '../models/teacher_dashboard.dart';
import 'api_service.dart';

class ParentApiService {
  final ApiService _api;

  ParentApiService(this._api);

  Future<ParentDashboard> getDashboard() async {
    final response = await _api.get(ApiConfig.parentDashboard);
    return ParentDashboard.fromJson(response['data'] ?? {});
  }

  Future<StudentDetail> getChildDetail(int childId) async {
    final response =
        await _api.get('${ApiConfig.parentChildren}/$childId');
    return StudentDetail.fromJson(response['data'] ?? {});
  }
}
