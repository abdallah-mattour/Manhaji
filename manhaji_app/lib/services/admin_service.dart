import '../config/api_config.dart';
import '../models/admin_stats.dart';
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
}
