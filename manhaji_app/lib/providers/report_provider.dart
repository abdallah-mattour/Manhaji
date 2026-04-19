import 'package:flutter/material.dart';
import '../models/ai_report.dart';
import '../services/report_service.dart';
import '../utils/error_handler.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service;

  ReportProvider(this._service);

  List<ProgressReportModel>? _reports;
  LearningPathModel? _learningPath;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<ProgressReportModel>? get reports => _reports;
  LearningPathModel? get learningPath => _learningPath;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> loadReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _service.getReports();
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateReport() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final report = await _service.generateReport();
      _reports = [report, ...(_reports ?? [])];
    } catch (e) {
      _error = extractError(e);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> loadLearningPath() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _learningPath = await _service.getLearningPath();
    } catch (e) {
      _learningPath = null;
    } finally {
      _isLoading = false;
      notifyListeners();
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
}
