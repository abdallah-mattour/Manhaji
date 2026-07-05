import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../app/routes.dart';
import 'preview_banner.dart';

/// Landing page shown as the initial route when SCREENSHOT_MODE=true.
/// Provides one-tap navigation to each role's preview screen.
/// Never reachable in normal builds.
class PreviewMenuScreen extends StatelessWidget {
  const PreviewMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('معاينة الشاشات'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(28),
            child: PreviewBanner(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'اختر دور المعاينة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هذه الشاشة مرئية فقط في وضع المعاينة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 40),
                _PreviewButton(
                  label: 'معاينة المشرف',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppTheme.primaryPurple,
                  route: AppRoutes.previewAdmin,
                ),
                const SizedBox(height: 14),
                _PreviewButton(
                  label: 'معاينة المعلم',
                  icon: Icons.school_rounded,
                  color: AppTheme.primaryGreen,
                  route: AppRoutes.previewTeacher,
                ),
                const SizedBox(height: 14),
                _PreviewButton(
                  label: 'معاينة ولي الأمر',
                  icon: Icons.family_restroom_rounded,
                  color: AppTheme.primaryOrange,
                  route: AppRoutes.previewParent,
                ),
                const SizedBox(height: 14),
                _PreviewButton(
                  label: 'معاينة الطالب',
                  icon: Icons.person_rounded,
                  color: AppTheme.primaryBlue,
                  route: AppRoutes.previewStudent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _PreviewButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
