/// Centralized Arabic UI strings that appear in multiple places.
///
/// Scope (intentionally narrow for this pass):
/// * Error messages returned from `extractError` fallbacks.
/// * Action labels ("retry", "continue", "exit", …) that are repeated across
///   screens.
///
/// One-off screen titles and descriptive text stay inline with the screens
/// until we adopt a real i18n library.
class AppStrings {
  AppStrings._();

  // Generic error messages
  static const String errorGeneric = 'حدث خطأ غير متوقع';
  static const String errorTimeout = 'انتهت مهلة الاتصال. تأكد من اتصالك بالإنترنت';
  static const String errorConnection = 'لا يمكن الاتصال بالخادم. تأكد من اتصالك بالإنترنت';

  // Action labels
  static const String actionRetry = 'إعادة المحاولة';
  static const String actionNext = 'التالي ←';
  static const String actionConfirm = 'تأكيد الإجابة';
  static const String actionTryAgain = 'حاول مرة أخرى 💪';
  static const String actionExit = 'الخروج';
  static const String actionContinue = 'متابعة';
}
