import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../services/progress_service.dart';
import '../utils/error_handler.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressApiService _progressService;

  bool _loadingProgress = false;
  bool _loadingLeaderboard = false;
  String? _errorMessage;

  ProgressSummary? _summary;
  List<LeaderboardEntry> _leaderboard = [];

  ProgressProvider(this._progressService);

  // Backward-compatible: true while either request is in flight.
  bool get isLoading => _loadingProgress || _loadingLeaderboard;
  bool get isLoadingProgress => _loadingProgress;
  bool get isLoadingLeaderboard => _loadingLeaderboard;
  String? get errorMessage => _errorMessage;
  ProgressSummary? get summary => _summary;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  Future<void> loadProgress() async {
    _loadingProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _progressService.getProgressSummary();
    } catch (e) {
      _errorMessage = extractError(e);
    } finally {
      _loadingProgress = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard({int? gradeLevel}) async {
    _loadingLeaderboard = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _leaderboard = await _progressService.getLeaderboard(gradeLevel: gradeLevel);
    } catch (e) {
      _errorMessage = extractError(e);
    } finally {
      _loadingLeaderboard = false;
      notifyListeners();
    }
  }
}
