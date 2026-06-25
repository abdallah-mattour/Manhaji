import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/vibrant_background.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/duolingo_card.dart';

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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(Icons.person,
                          size: 35, color: AppTheme.primaryGreen),
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
                            auth.userRole == 'STUDENT' ? 'طالب' : auth.userRole ?? '',
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

              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'عن التطبيق',
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // Logout
              DuolingoButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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
          title: Text(title,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_back_ios, size: 16),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
