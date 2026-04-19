import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../services/progress_service.dart';
import '../utils/error_handler.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressApiService _progressService;

  bool _isLoading = false;
  String? _errorMessage;

  ProgressSummary? _summary;
  List<LeaderboardEntry> _leaderboard = [];

  ProgressProvider(this._progressService);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProgressSummary? get summary => _summary;
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  Future<void> loadProgress() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _progressService.getProgressSummary();
    } catch (e) {
      _errorMessage = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard({int? gradeLevel}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _leaderboard = await _progressService.getLeaderboard(gradeLevel: gradeLevel);
    } catch (e) {
      _errorMessage = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
