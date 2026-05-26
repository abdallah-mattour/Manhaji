import 'package:flutter/foundation.dart';

/// Tiny tagged logger so the Flutter console actually narrates what the
/// app is doing, instead of being drowned by Android platform noise.
///
/// ### Why this exists
///
/// A cold-boot `flutter run` produces a few hundred lines of Android system
/// logs — Choreographer frame-skip warnings, GC events, hidden-API
/// reflection notices from Flutter's accessibility plumbing, etc. None of
/// it tells you what *the app* is doing. Every line that ours emits goes
/// through `print()` / `debugPrint`, which the Android log shows under the
/// `I/flutter` tag. By prefixing every one of our lines with `[tag]`, you
/// can filter the console down to exactly the subsystem you care about:
///
/// ```bash
/// # PowerShell — only our app's lines, dropping Android noise:
/// flutter run | Select-String "I/flutter"
///
/// # Only TTS-subsystem lines:
/// flutter run | Select-String "I/flutter.*\[tts\]"
///
/// # Only warnings and errors from anywhere in the app:
/// flutter run | Select-String "I/flutter.*(WARN|ERROR)"
/// ```
///
/// ### Conventions
///
/// * One tag per subsystem (`tts`, `api`, `auth`, `quiz`, …). Stays short —
///   readable in the grep pattern, recognisable at a glance.
/// * `i()` for normal lifecycle / decision-point breadcrumbs.
/// * `w()` for "something is off but we recovered" (cache miss, fallback
///   path, retry).
/// * `e()` for "we failed, the user will probably notice." Optional
///   `error` argument is appended on the same line.
///
/// ### Release-build behaviour
///
/// Every call is gated on [kDebugMode]. In a release APK the logger
/// compiles to a no-op — no PII or token snippets ever ship to a real
/// device's logcat.
class AppLog {
  AppLog._(this._tag);

  /// Returns a logger bound to [tag]. Cache the result in a static field on
  /// the consuming class so we don't allocate per call.
  factory AppLog.tag(String tag) => AppLog._(tag);

  final String _tag;

  /// Informational breadcrumb — "this happened, here's the outcome."
  void i(String msg) {
    if (kDebugMode) debugPrint('[$_tag] $msg');
  }

  /// Recoverable anomaly — "expected one thing, got another, used the
  /// fallback path." Caller is still working.
  void w(String msg) {
    if (kDebugMode) debugPrint('[$_tag] WARN $msg');
  }

  /// Hard failure — "we couldn't do the thing the user asked for." If an
  /// [error] object is passed, it's appended on the same line so a console
  /// scroll-up can see the cause inline with the symptom.
  void e(String msg, [Object? error]) {
    if (kDebugMode) {
      final suffix = error != null ? ' — $error' : '';
      debugPrint('[$_tag] ERROR $msg$suffix');
    }
  }
}
