import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/account_profile_actions.dart';
import '../../widgets/vibrant_background.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات ولي الأمر'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _ProfileCard(auth: auth),
                  const SizedBox(height: AppTheme.space4),
                  AccountSettingsActions(
                    keyPrefix: 'parent-settings',
                    decoration: _cardDecoration(),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  _LogoutCard(isLoggingOut: _isLoggingOut, onLogout: _logout),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final name = _fieldOrFallback(auth.userName);
    final email = _fieldOrFallback(auth.userEmail);
    final role = _parentRoleLabel(auth.userRole);

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AccountAvatar(
                avatarId: auth.userAvatarId,
                fallbackLabel: name == _fallbackText ? 'ولي أمر' : name,
                fallbackColor: AppTheme.primaryGreen,
              ),
              const SizedBox(width: AppTheme.space4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الملف الشخصي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: AppTheme.space1),
                    Text(
                      'بيانات حساب ولي الأمر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
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
            value: role,
          ),
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
          width: 76,
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

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.isLoggingOut, required this.onLogout});

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إجراءات الحساب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          const Text(
            'تسجيل الخروج من حساب ولي الأمر',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          ElevatedButton.icon(
            key: const ValueKey('parent-settings-logout-button'),
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
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: AppTheme.surfaceMuted),
    boxShadow: AppTheme.elevationLow,
  );
}

const _fallbackText = 'غير متوفر';

String _fieldOrFallback(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? _fallbackText : text;
}

String _parentRoleLabel(String? role) {
  return role?.trim().toUpperCase() == 'PARENT' ? 'ولي أمر' : _fallbackText;
}
