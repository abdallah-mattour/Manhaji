import 'package:flutter/material.dart';
import '../models/ai_report.dart';
import '../services/report_service.dart';
import '../utils/error_handler.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  ReportProvider(this._service);

  List<ProgressReportModel>? _reports;
  LearningPathModel? _learningPath;
  PerformanceStats? _stats;
  bool _isLoading = false;
  bool _isGenerating = false;
  int _activeLoads = 0;
  String? _error;

  List<ProgressReportModel>? get reports => _reports;
  LearningPathModel? get learningPath => _learningPath;
  PerformanceStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> loadReports() async {
    _beginLoading();
    try {
      _reports = await _service.getReports();
      await _refreshStatsSafely();
    } catch (e) {
      _error = extractError(e);
      _stats = null;
    } finally {
      _endLoading();
    }
  }

  Future<void> generateReport() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final report = await _service.generateReport();
      _reports = [report, ...(_reports ?? [])];
      await _refreshStatsSafely();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> loadLearningPath() async {
    _beginLoading();
    try {
      _learningPath = await _service.getLearningPath();
    } catch (e) {
      _learningPath = null;
    } finally {
      _endLoading();
    }
  }

  Future<void> generateLearningPath() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      _learningPath = await _service.generateLearningPath();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _beginLoading() {
    _activeLoads += 1;
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading() {
    if (_activeLoads > 0) _activeLoads -= 1;
    _isLoading = _activeLoads > 0;
    notifyListeners();
  }

  Future<void> _refreshStatsSafely() async {
    try {
      _stats = await _service.getStats();
    } catch (_) {
      // Stats are best-effort; reports should remain usable if this optional
      // endpoint is unavailable or an older backend is running.
      _stats = null;
    }
  }
}
