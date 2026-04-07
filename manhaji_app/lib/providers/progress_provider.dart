import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../services/progress_service.dart';

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
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع';
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
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
    } catch (_) {
      _errorMessage = 'حدث خطأ غير متوقع';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return e.response!.data['message'] ?? 'حدث خطأ';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'انتهت مهلة الاتصال';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'لا يمكن الاتصال بالخادم';
    }
    return 'حدث خطأ في الاتصال';
  }
}
