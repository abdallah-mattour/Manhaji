import 'package:flutter/material.dart';
import '../models/parent_dashboard.dart';
import '../models/teacher_dashboard.dart';
import '../services/parent_service.dart';
import '../utils/error_handler.dart';

class ParentProvider extends ChangeNotifier {
  final ParentApiService _service;

  ParentProvider(this._service);

  ParentDashboard? _dashboard;
  StudentDetail? _childDetail;
  bool _isDashboardLoading = false;
  bool _isChildDetailLoading = false;
  String? _dashboardError;
  String? _childDetailError;

  ParentDashboard? get dashboard => _dashboard;
  StudentDetail? get childDetail => _childDetail;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get isChildDetailLoading => _isChildDetailLoading;
  String? get dashboardError => _dashboardError;
  String? get childDetailError => _childDetailError;

  Future<void> loadDashboard() async {
    _isDashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.getDashboard();
    } catch (e) {
      _dashboardError = extractError(e);
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChildDetail(int childId) async {
    _isChildDetailLoading = true;
    _childDetailError = null;
    _childDetail = null;
    notifyListeners();
    try {
      _childDetail = await _service.getChildDetail(childId);
    } catch (e) {
      _childDetailError = extractError(e);
    } finally {
      _isChildDetailLoading = false;
      notifyListeners();
    }
  }
}
