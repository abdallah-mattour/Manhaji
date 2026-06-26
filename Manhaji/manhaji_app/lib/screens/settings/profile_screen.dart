import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/vibrant_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AuthProvider>().fetchProfile();
    });
  }

  String _roleLabel(String? role) => switch (role) {
        'TEACHER' => 'معلم',
        'ADMIN' => 'مدير',
        'PARENT' => 'ولي أمر',
        _ => 'طالب',
      };

  String? _gradeLevelLabel(int? level) {
    if (level == null) return null;
    const labels = [
      '', 'الأول', 'الثاني', 'الثالث', 'الرابع',
      'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
    ];
    if (level >= 1 && level < labels.length) return 'الصف ${labels[level]}';
    return 'الصف $level';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final bool hasDetail = auth.userEmail != null || auth.userPhone != null;
    final bool loading = auth.isProfileLoading && !hasDetail;
    final bool hasError = auth.profileError != null && !hasDetail;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.shapes,
          child: loading
              ? const LoadingState()
              : hasError
                  ? ErrorState(
                      message: auth.profileError!,
                      onRetry: () => auth.fetchProfile(),
                      retryLabel: 'إعادة المحاولة',
                    )
                  : _buildProfile(auth),
        ),
      ),
    );
  }

  Widget _buildProfile(AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Avatar + name header
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                auth.userName ?? '—',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _roleLabel(auth.userRole),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Info card
        DuolingoCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              if (auth.userEmail != null)
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: auth.userEmail!,
                  ltr: true,
                ),
              if (auth.userPhone != null)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  value: auth.userPhone!,
                  ltr: true,
                ),
              if (_gradeLevelLabel(auth.userGradeLevel) != null)
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'الصف الدراسي',
                  value: _gradeLevelLabel(auth.userGradeLevel)!,
                ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'نوع الحساب',
                value: _roleLabel(auth.userRole),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Read-only note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.infoContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'لتعديل معلوماتك، تواصل مع المسؤول.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltr;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryGreen),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  textDirection:
                      ltr ? TextDirection.ltr : TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
