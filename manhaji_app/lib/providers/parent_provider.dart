import 'package:flutter/material.dart';
import '../models/parent_dashboard.dart';
import '../models/teacher_dashboard.dart';
import '../services/parent_service.dart';

class ParentProvider extends ChangeNotifier {
  final ParentApiService _service;

  ParentProvider(this._service);

  ParentDashboard? _dashboard;
  StudentDetail? _childDetail;
  bool _isLoading = false;
  String? _error;

  ParentDashboard? get dashboard => _dashboard;
  StudentDetail? get childDetail => _childDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboard = await _service.getDashboard();
    } catch (e) {
      _error = 'فشل تحميل لوحة ولي الأمر';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChildDetail(int childId) async {
    _isLoading = true;
    _error = null;
    _childDetail = null;
    notifyListeners();
    try {
      _childDetail = await _service.getChildDetail(childId);
    } catch (e) {
      _error = 'فشل تحميل بيانات الطفل';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
