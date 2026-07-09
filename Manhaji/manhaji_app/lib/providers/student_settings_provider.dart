import 'package:flutter/foundation.dart';

import '../services/local_storage_service.dart';

/// Student-scoped local preferences (no backend dependency).
///
/// Phase 8A: currently holds only "الوضع الصامت" (Silent / Quiet Study
/// Mode). The flag gates AUTOMATIC audio only — manual speaker buttons,
/// pronunciation target playback, and voice answers stay available.
class StudentSettingsProvider extends ChangeNotifier {
  final LocalStorageService _storage;

  StudentSettingsProvider(this._storage)
      : _silentMode = _storage.isSilentModeEnabled;

  bool _silentMode;

  /// True when الوضع الصامت is ON.
  bool get silentMode => _silentMode;

  /// Whether learning screens may auto-play audio (TTS on step change,
  /// verdict sounds). Manual playback is never gated by this.
  bool get autoAudioEnabled => !_silentMode;

  Future<void> setSilentMode(bool enabled) async {
    if (_silentMode == enabled) return;
    _silentMode = enabled;
    notifyListeners();
    await _storage.setSilentModeEnabled(enabled);
  }
}
