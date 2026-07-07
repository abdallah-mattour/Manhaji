import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../config/gamification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/avatar_picker_card.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/vibrant_background.dart';

/// "الملف الشخصي" — read-only account details from `/auth/me` plus, for
/// students, the point-unlockable avatar picker. Account fields (name, email,
/// phone, grade) are not editable in-app; editing goes through the school
/// administration, matching the admin-only user-management model.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<AuthProvider>().fetchProfile();

    // Students get the avatar picker, which needs points (progress) and the
    // current avatar (dashboard). Parents don't — skip the loads for them.
    final auth = context.read<AuthProvider>();
    if (auth.userRole == 'STUDENT') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final progress = context.read<ProgressProvider>();
        final lessons = context.read<LessonProvider>();
        if (progress.summary == null) progress.loadProgress();
        if (lessons.dashboard == null) lessons.loadDashboard();
      });
    }
  }

  Future<void> _selectAvatar(AvatarDef av, String? currentId) async {
    if (av.id == currentId) return;
    final progress = context.read<ProgressProvider>();
    final lessons = context.read<LessonProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await progress.updateAvatar(av.id);
    if (!mounted) return;
    if (ok) {
      await lessons.loadDashboard();
      _snack(messenger, 'أصبحت ${av.name} ${av.emoji}', AppTheme.primaryGreen);
    } else {
      _snack(messenger, 'تعذر حفظ الشخصية. حاول مرة أخرى.', AppTheme.primaryRed);
    }
  }

  void _showLockedHint(AvatarDef av) {
    _snack(ScaffoldMessenger.of(context),
        '${av.name} يحتاج ${av.unlockPoints} نقطة 🔒', AppTheme.textGray);
  }

  void _snack(ScaffoldMessengerState messenger, String text, Color color) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.userRole == 'STUDENT';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          backgroundColor: AppTheme.backgroundLight,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _avatarHeader(isStudent, auth.userName),
                const SizedBox(height: 20),
                _accountCard(auth),
                const SizedBox(height: 12),
                const Text(
                  'لتعديل بيانات الحساب تواصل مع مشرف المدرسة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                  ),
                ),
                if (isStudent) ...[
                  const SizedBox(height: 24),
                  _avatarPicker(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarHeader(bool isStudent, String? name) {
    // For students show their chosen avatar emoji; others get a person icon.
    return Consumer<LessonProvider>(
      builder: (context, lessons, _) {
        final emoji =
            isStudent ? Avatars.resolve(lessons.dashboard?.avatarId).emoji : null;
        return Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                border: Border.all(color: AppTheme.primaryGreen, width: 3),
              ),
              alignment: Alignment.center,
              child: emoji != null
                  ? Text(emoji, style: const TextStyle(fontSize: 52))
                  : const Icon(Icons.person,
                      size: 52, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 12),
            Text(
              name ?? 'مستخدم',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _accountCard(AuthProvider auth) {
    final isStudent = auth.userRole == 'STUDENT';
    final grade = auth.gradeLevel;

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final email = (data['email'] as String?)?.trim();
        final phone = (data['phone'] as String?)?.trim();
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return DuolingoCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            children: [
              _row(Icons.badge_outlined, 'النوع', _roleLabel(auth.userRole)),
              _divider(),
              _row(
                Icons.email_outlined,
                'البريد الإلكتروني',
                loading ? '...' : (email?.isNotEmpty == true ? email! : '—'),
                ltr: true,
              ),
              _divider(),
              _row(
                Icons.phone_outlined,
                'رقم الهاتف',
                loading ? '...' : (phone?.isNotEmpty == true ? phone! : '—'),
                ltr: true,
              ),
              if (isStudent) ...[
                _divider(),
                _row(Icons.school_outlined, 'الصف',
                    grade != null ? 'الصف $grade' : '—'),
              ],
            ],
          ),
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
        return '—';
    }
  }

  Widget _row(IconData icon, String label, String value, {bool ltr = false}) {
    final valueText = Text(
      value,
      textDirection: ltr ? TextDirection.ltr : null,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.textDark,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Align(alignment: Alignment.centerLeft, child: valueText)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: AppTheme.surfaceMuted.withValues(alpha: 0.6));

  Widget _avatarPicker() {
    return Consumer2<ProgressProvider, LessonProvider>(
      builder: (context, progress, lessons, _) {
        final pts = progress.summary?.totalPoints ?? 0;
        final av = Avatars.resolve(lessons.dashboard?.avatarId);
        return AvatarPickerCard(
          currentId: av.id,
          pts: pts,
          onSelect: (a) => _selectAvatar(a, av.id),
          onLockedTap: _showLockedHint,
        );
      },
    );
  }
}
