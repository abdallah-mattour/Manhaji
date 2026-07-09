import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../config/gamification.dart';
import '../../models/progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/vibrant_background.dart';

/// Leaderboard: a gold podium for the top three, then a simple ranked list of
/// every student with their score below it. Both scroll together. Robust for
/// any student count — the list always shows everyone, so it's never blank.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() {
    final grade = context.read<LocalStorageService>().getGradeLevel();
    return context.read<ProgressProvider>().loadLeaderboard(gradeLevel: grade);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المتصدرين'),
          backgroundColor: AppTheme.primaryYellow,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundGold,
          pattern: BackgroundPattern.none,
          child: Consumer<ProgressProvider>(
            builder: (context, provider, _) {
              final entries = provider.leaderboard;

              if (provider.isLoadingLeaderboard && entries.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (entries.isEmpty) {
                return _EmptyState(message: provider.errorMessage);
              }

              final podium = entries.take(math.min(3, entries.length)).toList();

              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppTheme.primaryOrange,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  // podium header + section header + one row per student
                  itemCount: entries.length + 2,
                  itemBuilder: (context, i) {
                    if (i == 0) return _PodiumHeader(podium: podium);
                    if (i == 1) return _SectionHeader(count: entries.length);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _RankRow(entry: entries[i - 2]),
                    );
                  },
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
// Podium — top three (or fewer) on a gold gradient hero.
// ─────────────────────────────────────────────────────────────
class _PodiumHeader extends StatelessWidget {
  final List<LeaderboardEntry> podium;
  const _PodiumHeader({required this.podium});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryYellow.withValues(alpha: 0.55),
            AppTheme.primaryYellow.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (podium.length > 1) _PodiumColumn(entry: podium[1], place: 2),
          if (podium.length > 1) const SizedBox(width: 12),
          _PodiumColumn(entry: podium[0], place: 1),
          if (podium.length > 2) const SizedBox(width: 12),
          if (podium.length > 2) _PodiumColumn(entry: podium[2], place: 3),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final int place;
  const _PodiumColumn({required this.entry, required this.place});

  static const _ring = {
    1: AppTheme.primaryOrange,
    2: Color(0xFFAFAFAF),
    3: Color(0xFFCD7F32),
  };
  static const _blockH = {1: 74.0, 2: 56.0, 3: 44.0};

  @override
  Widget build(BuildContext context) {
    final ring = _ring[place]!;
    final isFirst = place == 1;
    final name = entry.isCurrentUser ? 'أنت' : entry.studentName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          child:
              isFirst ? const Text('👑', style: TextStyle(fontSize: 26)) : null,
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: ring, width: 3),
            boxShadow: [
              BoxShadow(
                color: ring.withValues(alpha: isFirst ? 0.45 : 0.22),
                blurRadius: isFirst ? 16 : 8,
                spreadRadius: isFirst ? 1 : 0,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 34 : 27,
            backgroundColor: ring.withValues(alpha: 0.14),
            child: Text(
              Avatars.resolve(entry.avatarId).emoji,
              style: TextStyle(fontSize: isFirst ? 34 : 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 96,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isFirst ? 15 : 13,
              fontWeight: FontWeight.w800,
              color:
                  entry.isCurrentUser ? AppTheme.primaryGreen : AppTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_fmtPoints(entry.totalPoints)} ⭐',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 8),
        // Podium block: big rank number, height ranked by place.
        Container(
          width: isFirst ? 84 : 72,
          height: _blockH[place],
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ring.withValues(alpha: 0.32),
                ring.withValues(alpha: 0.16),
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(
              top: BorderSide(color: ring.withValues(alpha: 0.6), width: 1.5),
              left: BorderSide(color: ring.withValues(alpha: 0.4)),
              right: BorderSide(color: ring.withValues(alpha: 0.4)),
              bottom: BorderSide(color: ring, width: 4),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$place',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isFirst ? 28 : 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// "الترتيب" section header above the full list.
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final int count;
  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          const Text(
            'الترتيب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          Text(
            '$count طالب',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// One student row: rank badge, avatar, name, score.
// ─────────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _RankRow({required this.entry});

  static const _medal = {
    1: Color(0xFFEEA307),
    2: Color(0xFFAFAFAF),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final me = entry.isCurrentUser;
    final medal = _medal[entry.rank];
    final avatar = Avatars.resolve(entry.avatarId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: me
            ? AppTheme.primaryYellow.withValues(alpha: 0.16)
            : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: me
              ? AppTheme.primaryYellow
              : (medal != null
                  ? medal.withValues(alpha: 0.55)
                  : AppTheme.surfaceMuted),
          width: me ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          _rankBadge(medal),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor:
                (medal ?? AppTheme.primaryBlue).withValues(alpha: 0.12),
            child: Text(avatar.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    me ? 'أنت' : entry.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: me ? AppTheme.primaryGreen : AppTheme.textDark,
                    ),
                  ),
                ),
                if (me) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: const Text(
                      'أنت',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmtPoints(entry.totalPoints),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 3),
              const Text('⭐', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(Color? medal) {
    final filled = medal != null;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? medal : AppTheme.surfaceSubtle,
        border: Border.all(
          color: filled ? medal : AppTheme.surfaceMuted,
          width: 1.5,
        ),
      ),
      child: Text(
        '${entry.rank}',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: filled ? Colors.white : AppTheme.textGray,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              message ?? 'لا يوجد متصدرون بعد\nكن أول من يحقق نقاطاً!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thousands separator: 1250 → "1,250".
String _fmtPoints(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
