import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_settings_provider.dart';
import '../../widgets/account_profile_actions.dart';
import '../../widgets/student_bottom_nav.dart';
import '../../widgets/vibrant_background.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/duolingo_card.dart';
import 'about_screen.dart';
import 'change_password_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        bottomNavigationBar: const StudentBottomNav(currentIndex: 2),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile card
              DuolingoCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppTheme.primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Row(
                  children: [
                    AccountAvatar(
                      avatarId: auth.userAvatarId,
                      fallbackLabel: auth.userName ?? 'طالب',
                      size: 60,
                      fallbackColor: AppTheme.primaryGreen,
                      borderRadius: AppTheme.radiusPill,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName ?? 'طالب',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            auth.userRole == 'STUDENT'
                                ? 'طالب'
                                : auth.userRole ?? '',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.textGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Phase 8A — الوضع الصامت: gates automatic audio only.
              _SilentModeTile(),

              _buildSettingTile(
                icon: Icons.lock_outline_rounded,
                title: 'تغيير كلمة المرور',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'عن التطبيق',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              const SizedBox(height: 32),

              // Logout
              DuolingoButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                },
                color: AppTheme.primaryRed,
                text: 'تسجيل الخروج',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DuolingoCard(
        padding: EdgeInsets.zero,
        borderRadius: AppTheme.radiusM,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryGreen),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: const Icon(Icons.arrow_back_ios, size: 16),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Phase 8A — "الوضع الصامت" toggle. ON disables automatic audio in the
/// learning flow (auto-TTS on step change + verdict sounds). Manual speaker
/// buttons and voice answers stay fully available.
class _SilentModeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<StudentSettingsProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DuolingoCard(
        padding: EdgeInsets.zero,
        borderRadius: AppTheme.radiusM,
        child: SwitchListTile(
          key: const ValueKey('student-silent-mode-switch'),
          secondary: Icon(
            settings.silentMode
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            color: AppTheme.primaryGreen,
          ),
          title: const Text(
            'الوضع الصامت',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'إيقاف التشغيل التلقائي للصوت أثناء الدراسة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
          value: settings.silentMode,
          activeThumbColor: AppTheme.primaryGreen,
          onChanged: (enabled) =>
              context.read<StudentSettingsProvider>().setSilentMode(enabled),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
