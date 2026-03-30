import '../models/progress.dart';
import 'api_service.dart';

class ProgressApiService {
  final ApiService _api;

  ProgressApiService(this._api);

  Future<ProgressSummary> getProgressSummary() async {
    final response = await _api.get('/progress/summary');
    return ProgressSummary.fromJson(response['data']);
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int? gradeLevel}) async {
    final response = await _api.get(
      '/progress/leaderboard',
      queryParams: {
        if (gradeLevel != null) 'gradeLevel': gradeLevel, // ignore: use_null_aware_elements
      },
    );
    final list = response['data'] as List;
    return list.map((e) => LeaderboardEntry.fromJson(e)).toList();
  }
}
