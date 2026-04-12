import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/progress.dart';
import '../../providers/progress_provider.dart';
import '../../services/local_storage_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final grade = context.read<LocalStorageService>().getGradeLevel();
      context.read<ProgressProvider>().loadLeaderboard(gradeLevel: grade);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المتصدرين'),
          backgroundColor: AppColors.warning,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Consumer<ProgressProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.leaderboard.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.leaderboard.isEmpty) {
              return const Center(
                child: Text(
                  'لا يوجد متصدرون بعد\nكن أول من يحقق نقاطاً! 🏆',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Top 3 podium
                if (provider.leaderboard.length >= 3)
                  _buildPodium(provider.leaderboard),
                // Rest of the list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.leaderboard.length,
                    itemBuilder: (context, index) {
                      if (index < 3) return const SizedBox.shrink();
                      return _buildLeaderboardTile(provider.leaderboard[index]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.2),
            AppColors.warning.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (entries.length > 1) _buildPodiumItem(entries[1], 2),
          const SizedBox(width: 12),
          // 1st place
          _buildPodiumItem(entries[0], 1),
          const SizedBox(width: 12),
          // 3rd place
          if (entries.length > 2) _buildPodiumItem(entries[2], 3),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int place) {
    final heights = {1: 100.0, 2: 75.0, 3: 55.0};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final crownColors = {
      1: AppColors.warning,
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medals[place]!, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: place == 1 ? 32 : 26,
          backgroundColor: crownColors[place]!.withValues(alpha: 0.2),
          child: Icon(
            Icons.person,
            size: place == 1 ? 32 : 26,
            color: crownColors[place],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            entry.studentName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: place == 1 ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: entry.isCurrentUser
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.totalPoints} ⭐',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: place == 1 ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        // Podium block
        Container(
          width: place == 1 ? 90 : 75,
          height: heights[place],
          decoration: BoxDecoration(
            color: crownColors[place]!.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$place',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: crownColors[place],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person,
              color: AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: entry.isCurrentUser
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${entry.completedLessons} درس مكتمل',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Points
          Text(
            '${entry.totalPoints} ⭐',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
