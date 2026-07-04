/// App-wide single-voice coordinator (2026-07-03).
///
/// The app has more than one audio source — the TTS player in [TtsService]
/// and the authored-clip player in `QuestionMediaHeader` — and nothing used
/// to stop one when the other started, so voices could overlap. Every source
/// now calls [claim] with its own stop-callback right before playing:
/// whoever was playing gets stopped first, guaranteeing at most one voice at
/// any moment, app-wide.
///
/// [stopCurrent] silences everything without claiming — used when the mic
/// starts recording, so TTS playback never bleeds into the child's recording.
class AudioFocus {
  AudioFocus._();

  static Future<void> Function()? _currentStopper;

  /// Stop whichever source currently holds focus, then record [stopper] as
  /// the new holder. A source re-claiming its own focus is a no-op (it stops
  /// its own previous utterance itself).
  static Future<void> claim(Future<void> Function() stopper) async {
    final prev = _currentStopper;
    _currentStopper = stopper;
    if (prev != null && !identical(prev, stopper)) {
      try {
        await prev();
      } catch (_) {
        // A dead widget's stopper may throw — never block the new voice.
      }
    }
  }

  /// Release focus if [stopper] still holds it (call from dispose so a dead
  /// widget's callback is never invoked later).
  static void release(Future<void> Function() stopper) {
    if (identical(_currentStopper, stopper)) {
      _currentStopper = null;
    }
  }

  /// Silence the current holder without claiming focus (mic recording).
  static Future<void> stopCurrent() async {
    final prev = _currentStopper;
    _currentStopper = null;
    if (prev != null) {
      try {
        await prev();
      } catch (_) {}
    }
  }
}
