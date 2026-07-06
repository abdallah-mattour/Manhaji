import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/account_profile_actions.dart';
import '../../widgets/staff_web_shell.dart';
import 'teacher_shell_navigation.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().fetchProfile();
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تسجيل الخروج حالياً. حاول مرة أخرى.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'الإعدادات',
        subtitle: 'بيانات الحساب وإجراءات الدخول',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.teacherSettings,
        items: teacherShellItems(context),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return _SettingsBody(
              auth: auth,
              isLoggingOut: _isLoggingOut,
              onLogout: _logout,
            );
          },
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.auth,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final AuthProvider auth;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 640
            ? AppTheme.space4
            : AppTheme.space6;
        final minHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - padding * 2).clamp(0.0, double.infinity)
            : 0.0;
        final bodyWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - padding * 2)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : 980.0;
        final contentWidth = bodyWidth.clamp(0.0, 980.0).toDouble();

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            width: bodyWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfilePanel(auth: auth),
                      const SizedBox(height: AppTheme.space5),
                      AccountSettingsActions(
                        keyPrefix: 'teacher-settings',
                        padding: const EdgeInsets.all(AppTheme.space6),
                        decoration: _panelDecoration(),
                      ),
                      const SizedBox(height: AppTheme.space5),
                      _LogoutPanel(
                        isLoggingOut: isLoggingOut,
                        onLogout: onLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final name = auth.userName?.trim().isNotEmpty == true
        ? auth.userName!.trim()
        : 'المعلم';
    final email = auth.userEmail?.trim().isNotEmpty == true
        ? auth.userEmail!.trim()
        : auth.isProfileLoading
        ? 'جاري تحديث البريد...'
        : 'غير متوفر';

    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AccountAvatar(
                avatarId: auth.userAvatarId,
                fallbackLabel: name,
                fallbackColor: AppTheme.primaryBlue,
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الملف الشخصي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      'بيانات حساب المعلم الحالية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: auth.profileError == null
                            ? AppTheme.textGray
                            : AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          _ProfileRow(icon: Icons.person_rounded, label: 'الاسم', value: name),
          const Divider(height: AppTheme.space5, color: AppTheme.surfaceMuted),
          _ProfileRow(icon: Icons.email_rounded, label: 'البريد', value: email),
          const Divider(height: AppTheme.space5, color: AppTheme.surfaceMuted),
          _ProfileRow(
            icon: Icons.verified_user_rounded,
            label: 'الدور',
            value: _roleLabel(auth.userRole),
          ),
          if (auth.profileError != null) ...[
            const SizedBox(height: AppTheme.space4),
            Text(
              auth.profileError!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textGray, size: 22),
        const SizedBox(width: AppTheme.space3),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoutPanel extends StatelessWidget {
  const _LogoutPanel({required this.isLoggingOut, required this.onLogout});

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('teacher-settings-logout-panel'),
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final description = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'إجراءات الحساب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: AppTheme.space1),
              Text(
                'تسجيل الخروج من مساحة المعلم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          );
          final button = ElevatedButton.icon(
            key: const ValueKey('teacher-settings-logout-button'),
            onPressed: isLoggingOut ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(
              isLoggingOut ? 'جاري الخروج' : 'تسجيل الخروج',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              disabledBackgroundColor: AppTheme.primaryRed.withValues(
                alpha: 0.62,
              ),
              disabledForegroundColor: Colors.white,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space5,
                vertical: AppTheme.space4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                description,
                const SizedBox(height: AppTheme.space4),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: description),
              const SizedBox(width: AppTheme.space4),
              button,
            ],
          );
        },
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: AppTheme.surfaceMuted),
    boxShadow: AppTheme.elevationLow,
  );
}

String _roleLabel(String? role) {
  return switch (role) {
    'TEACHER' => 'معلم',
    'ADMIN' => 'مدير',
    'PARENT' => 'ولي أمر',
    'STUDENT' => 'طالب',
    _ => role?.trim().isNotEmpty == true ? role!.trim() : 'معلم',
  };
}
