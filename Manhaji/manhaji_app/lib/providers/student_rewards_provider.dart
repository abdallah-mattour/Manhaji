import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';

class StudentRewardsProvider extends ChangeNotifier {
  StudentRewardsProvider(this._storage) {
    _selectedRewardId = _storage.getSelectedRewardId();
  }

  final LocalStorageService _storage;

  String? _selectedRewardId;

  String? get selectedRewardId => _selectedRewardId;

  Future<void> selectReward(String rewardId) async {
    if (_selectedRewardId == rewardId) return;
    _selectedRewardId = rewardId;
    await _storage.setSelectedRewardId(rewardId);
    notifyListeners();
  }
}
