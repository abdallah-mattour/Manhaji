import '../models/progress.dart';
import 'api_service.dart';

class ProgressApiService {
  final ApiService _api;

  ProgressApiService(this._api);

  Future<ProgressSummary> getProgressSummary() async {
    final response = await _api.get('/progress/summary');
    return ProgressSummary.fromJson(response['data'] ?? {});
  }

  /// Tier 3: persist the chosen avatar id (rewards screen).
  Future<void> updateAvatar(String avatarId) async {
    await _api.put('/student/avatar', data: {'avatarId': avatarId});
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int? gradeLevel}) async {
    final response = await _api.get(
      '/progress/leaderboard',
      queryParams: {
        if (gradeLevel != null) 'gradeLevel': gradeLevel, // ignore: use_null_aware_elements
      },
    );
    final data = response['data'];
    if (data is! List) return [];
    return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
  }
}
