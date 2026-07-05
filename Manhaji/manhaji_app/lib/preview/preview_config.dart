/// Compile-time flag — true only when:
///   flutter run --dart-define=SCREENSHOT_MODE=true
///
/// In every other build this constant is false and the preview routes are
/// excluded from the route table entirely, so they are unreachable.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
