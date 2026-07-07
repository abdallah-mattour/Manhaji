import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../config/gamification.dart';
import '../../models/progress.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/avatar_picker_card.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/vibrant_background.dart';

/// Tier 3 — "مكافآتي": level + XP arc, daily streak, achievement badges and
/// the point-unlockable avatar collection. All figures come from the
/// existing progress summary; only the avatar choice writes back.
///
/// [earnedPoints] > 0 means we arrived from a quiz-completion screen — the
/// screen then diffs (total - earned) → total to celebrate avatars that were
/// unlocked by THIS quiz with staggered golden snackbars.
class RewardsScreen extends StatefulWidget {
  final int earnedPoints;

  const RewardsScreen({super.key, this.earnedPoints = 0});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arcCtrl;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressProvider>();
      final lessons = context.read<LessonProvider>();
      progress.loadProgress().then((_) {
        if (!mounted) return;
        _arcCtrl.forward();
        _maybeCelebrateUnlocks(progress.summary);
      });
      if (lessons.dashboard == null) lessons.loadDashboard();
    });
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    super.dispose();
  }

  /// Staggered golden snackbars for avatars unlocked by the quiz we just
  /// finished (no-op on plain visits from the home screen).
  void _maybeCelebrateUnlocks(ProgressSummary? summary) {
    if (_celebrated || widget.earnedPoints <= 0 || summary == null) return;
    _celebrated = true;
    final fresh = Avatars.newlyUnlocked(
        summary.totalPoints - widget.earnedPoints, summary.totalPoints);
    for (var i = 0; i < fresh.length; i++) {
      final av = fresh[i];
      Future.delayed(Duration(milliseconds: 700 + i * 1600), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 فتحت شخصية جديدة: ${av.name} ${av.emoji}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
            backgroundColor: AppTheme.primaryYellow,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        );
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
      // Refresh the dashboard so the home header shows the new avatar.
      await lessons.loadDashboard();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'أصبحت ${av.name} ${av.emoji}',
            style: const TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'تعذر حفظ الشخصية. حاول مرة أخرى.',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
    }
  }

  void _showLockedHint(AvatarDef av) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${av.name} يحتاج ${av.unlockPoints} نقطة 🔒',
          style:
              const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.textGray,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مكافآتي 🏆'),
          backgroundColor: AppTheme.primaryTerracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: Consumer2<ProgressProvider, LessonProvider>(
            builder: (context, progress, lessons, _) {
              if (progress.isLoadingProgress && progress.summary == null) {
                return const LoadingState();
              }
              if (progress.summary == null && progress.errorMessage != null) {
                return ErrorState(
                  message: progress.errorMessage!,
                  onRetry: progress.loadProgress,
                );
              }

              final summary = progress.summary;
              final pts = summary?.totalPoints ?? 0;
              final streak = summary?.currentStreak ?? 0;
              final lv = levelOf(pts);
              final badges = buildBadges(summary);
              final unlockedBadges = badges.where((b) => b.unlocked).length;
              final dashboard = lessons.dashboard;
              final av = Avatars.resolve(dashboard?.avatarId);
              final name = dashboard?.fullName ?? 'بطلنا الصغير';

              return RefreshIndicator(
                onRefresh: () => progress.loadProgress(),
                color: AppTheme.primaryTerracotta,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StudentCard(
                      avatar: av,
                      name: name,
                      lv: lv,
                      pts: pts,
                      unlockedBadges: unlockedBadges,
                      totalBadges: badges.length,
                    ),
                    const SizedBox(height: 16),
                    _LevelCard(lv: lv, pts: pts, arcAnim: _arcCtrl),
                    const SizedBox(height: 16),
                    _StreakCard(streak: streak),
                    const SizedBox(height: 20),
                    _BadgesSection(badges: badges),
                    const SizedBox(height: 20),
                    AvatarPickerCard(
                      currentId: av.id,
                      pts: pts,
                      onSelect: (a) => _selectAvatar(a, av.id),
                      onLockedTap: _showLockedHint,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Student profile card — flat terracotta, 3D bottom edge.
// ─────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final AvatarDef avatar;
  final String name;
  final LevelDef lv;
  final int pts;
  final int unlockedBadges;
  final int totalBadges;

  const _StudentCard({
    required this.avatar,
    required this.name,
    required this.lv,
    required this.pts,
    required this.unlockedBadges,
    required this.totalBadges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryTerracotta,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: const Border(
          bottom: BorderSide(color: AppTheme.primaryTerracottaDeep, width: 5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(avatar.emoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lv.emoji} ${lv.title}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill('⭐ $pts نقطة'),
                    _pill('🏅 $unlockedBadges/$totalBadges شارة'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Level card — animated 270° arc + linear bar.
// ─────────────────────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final LevelDef lv;
  final int pts;
  final AnimationController arcAnim;

  const _LevelCard({required this.lv, required this.pts, required this.arcAnim});

  @override
  Widget build(BuildContext context) {
    final prog = lv.progress(pts);
    final anim = CurvedAnimation(parent: arcAnim, curve: Curves.easeOutCubic);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceMuted, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 مستوى التقدم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AnimatedBuilder(
                animation: anim,
                builder: (context, _) {
                  final v = prog * anim.value;
                  return SizedBox(
                    width: 104,
                    height: 104,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(104, 104),
                          painter: _ArcPainter(progress: v),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(lv.emoji,
                                style: const TextStyle(fontSize: 28)),
                            Text(
                              '${(v * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المستوى ${lv.level}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryTerracotta,
                      ),
                    ),
                    Text(
                      lv.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: anim,
                      builder: (context, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        child: LinearProgressIndicator(
                          value: prog * anim.value,
                          minHeight: 12,
                          backgroundColor: AppTheme.surfaceMuted,
                          color: AppTheme.primaryYellow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lv.isMax
                          ? '🎉 وصلت لأعلى مستوى!'
                          : '${lv.remaining(pts)} نقطة للمستوى التالي',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;

  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 9;
    const sw = 11.0;
    // 270° sweep starting at ~7:30, gap at the bottom.
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..color = AppTheme.surfaceMuted
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep * progress,
        false,
        Paint()
          ..color = AppTheme.primaryTerracotta
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
// Streak card — flat orange, 3D bottom edge.
// ─────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  String get _motivation {
    if (streak == 0) return 'ابدأ اليوم! 💪';
    if (streak < 3) return 'بداية رائعة! 🌟';
    if (streak < 7) return 'أنت تتقدم بشكل رائع!';
    if (streak < 14) return 'حافظ على هذا الإيقاع!';
    return 'لا يمكن إيقافك! 🏆';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: const Border(
          bottom: BorderSide(color: AppTheme.primaryOrangeDeep, width: 5),
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 46)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak يوم متتالي',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _motivation,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
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

// ─────────────────────────────────────────────────────────────
// Achievement badges — 2-column grid.
// ─────────────────────────────────────────────────────────────
class _BadgesSection extends StatelessWidget {
  final List<GamBadge> badges;

  const _BadgesSection({required this.badges});

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🏅 شاراتي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Text(
              '$unlocked/${badges.length}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final b in badges)
                  SizedBox(width: w, child: _BadgeCard(badge: b)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final GamBadge badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final ok = badge.unlocked;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? AppTheme.cardWhite : AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: ok ? AppTheme.primaryYellow : AppTheme.surfaceMuted,
          width: ok ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok
                  ? AppTheme.primaryYellow.withValues(alpha: 0.18)
                  : AppTheme.surfaceMuted,
            ),
            alignment: Alignment.center,
            child: Text(
              ok ? badge.emoji : '🔒',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ok ? AppTheme.textDark : AppTheme.textGray,
                  ),
                ),
                Text(
                  badge.desc,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ok ? AppTheme.textGray : AppTheme.textLight,
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

