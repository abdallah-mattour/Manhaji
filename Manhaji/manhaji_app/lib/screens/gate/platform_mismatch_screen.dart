import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/role_platform_policy.dart';

/// Shown when a logged-in user is on the wrong platform.
///
/// Per proposal (Sec37 FR-8.2 / deployment layer): students use the
/// mobile app; teachers and admins use the web portal. This screen
/// explains the mismatch and gives a one-tap logout so they can
/// switch accounts on the correct platform.
///
/// The screen asks RolePlatformPolicy for the current role's expected runtime.
/// If somehow reached on the correct platform, it redirects to the role's home.
class PlatformMismatchScreen extends StatelessWidget {
  const PlatformMismatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.userRole;

    if (auth.isLoggedIn &&
        RolePlatformPolicy.isRoleAllowedOnCurrentPlatform(role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final navigator = Navigator.of(context);
          navigator.pushReplacementNamed(AppRoutes.homeForRole(role));
        }
      });
      return const SizedBox.shrink();
    }

    final mode = _MismatchMode.fromTarget(
      RolePlatformPolicy.targetForRole(role),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        mode._icon,
                        size: 64,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      mode._title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      RolePlatformPolicy.unsupportedMessageForRole(role),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        height: 1.5,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      mode._body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        height: 1.5,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mode._hint,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (_) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MismatchMode {
  mobileAccount(
    icon: Icons.phone_android_rounded,
    title: 'يرجى استخدام تطبيق منهجي على الموبايل',
    body:
        'تطبيق منهجي للطلاب وأولياء الأمور متوفّر على الهواتف الذكية. '
        'لاستخدام حسابك، يرجى تحميل التطبيق على جهاز الموبايل.',
    hint:
        'التطبيق يعمل على نظامَي Android و iOS — سجّل دخولك بنفس الحساب هناك.',
  ),
  webAccount(
    icon: Icons.laptop_rounded,
    title: 'يرجى استخدام بوابة المعلم عبر المتصفّح',
    body:
        'لوحة المعلم والإدارة مخصّصة للمتصفّح على الكمبيوتر. '
        'يرجى فتح البوابة في Chrome أو Edge للاستفادة من جميع المزايا.',
    hint:
        'افتح المتصفّح على الرابط نفسه الذي زوّدتك به إدارة المدرسة ثم سجّل دخولك.',
  ),
  unsupported(
    icon: Icons.info_outline_rounded,
    title: 'تعذّر فتح هذا الحساب هنا',
    body: 'يرجى التأكد من نوع الحساب أو التواصل مع إدارة المدرسة.',
    hint: 'يمكنك تسجيل الخروج ثم الدخول بحساب مدعوم لهذه النسخة.',
  );

  const _MismatchMode({
    required IconData icon,
    required String title,
    required String body,
    required String hint,
  }) : _icon = icon,
       _title = title,
       _body = body,
       _hint = hint;

  final IconData _icon;
  final String _title;
  final String _body;
  final String _hint;

  static _MismatchMode fromTarget(RolePlatformTarget target) {
    return switch (target) {
      RolePlatformTarget.mobile => _MismatchMode.mobileAccount,
      RolePlatformTarget.web => _MismatchMode.webAccount,
      RolePlatformTarget.unsupported => _MismatchMode.unsupported,
    };
  }
}
