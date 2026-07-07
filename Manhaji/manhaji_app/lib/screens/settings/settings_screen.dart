import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../config/gamification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/vibrant_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.userRole == 'STUDENT';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Tappable profile card → profile screen.
              DuolingoCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppTheme.primaryGreen,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.profile),
                child: Row(
                  children: [
                    _avatar(isStudent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.userName ?? 'مستخدم',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            _roleLabel(auth.userRole),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppTheme.textGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back_ios,
                        size: 16, color: AppTheme.textGray),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SettingsTile(
                icon: Icons.person_outline,
                title: 'الملف الشخصي',
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'تغيير كلمة المرور',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.changePassword),
              ),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'عن التطبيق',
                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              ),
              const SizedBox(height: 32),

              DuolingoButton(
                onPressed: () => _confirmLogout(context),
                color: AppTheme.primaryRed,
                text: 'تسجيل الخروج',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(bool isStudent) {
    if (!isStudent) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
        child: const Icon(Icons.person, size: 35, color: AppTheme.primaryGreen),
      );
    }
    // Students: show their chosen avatar emoji from the dashboard.
    return Consumer<LessonProvider>(
      builder: (context, lessons, _) {
        final emoji = Avatars.resolve(lessons.dashboard?.avatarId).emoji;
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 34)),
        );
      },
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'STUDENT':
        return 'طالب';
      case 'PARENT':
        return 'ولي أمر';
      case 'TEACHER':
        return 'معلم';
      case 'ADMIN':
        return 'مشرف';
      default:
        return '';
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'هل تريد بالتأكيد تسجيل الخروج من حسابك؟',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textGray),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'خروج',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryRed),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    await auth.logout();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }
}
