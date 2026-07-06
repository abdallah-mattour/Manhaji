import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/student_reward.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/student_rewards_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/vibrant_background.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<LessonProvider>();
      if (provider.dashboard == null && !provider.isLoading) {
        provider.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متجر المكافآت'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: Consumer<LessonProvider>(
            builder: (context, lessonProvider, _) {
              final dashboard = lessonProvider.dashboard;
              if (dashboard == null && lessonProvider.isLoading) {
                return const LoadingState();
              }
              if (dashboard == null && lessonProvider.errorMessage != null) {
                return ErrorState(
                  message: lessonProvider.errorMessage!,
                  retryLabel: 'إعادة المحاولة',
                  onRetry: lessonProvider.loadDashboard,
                );
              }

              final stars = dashboard?.totalPoints ?? 0;
              final streak = dashboard?.currentStreak ?? 0;

              return RefreshIndicator(
                color: AppTheme.primaryTerracotta,
                onRefresh: lessonProvider.loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    const _RewardsHeader(),
                    const SizedBox(height: AppTheme.space4),
                    _RewardsSummaryCard(stars: stars, streak: streak),
                    const SizedBox(height: AppTheme.space4),
                    const _ActiveRewardCard(),
                    const SizedBox(height: AppTheme.space4),
                    for (final category in StudentRewardCategory.values) ...[
                      _RewardCategorySection(category: category, stars: stars),
                      const SizedBox(height: AppTheme.space4),
                    ],
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

class _RewardsHeader extends StatelessWidget {
  const _RewardsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(AppTheme.primaryTerracotta),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'متجر المكافآت',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: AppTheme.space1),
          Text(
            'استخدم إنجازاتك لفتح مكافآت شكلية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsSummaryCard extends StatelessWidget {
  const _RewardsSummaryCard({required this.stars, required this.streak});

  final int stars;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(AppTheme.primaryYellowDeep),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryPill(
                  icon: Icons.star_rounded,
                  label: 'النجوم',
                  value: '$stars',
                  color: AppTheme.primaryYellowDeep,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: _SummaryPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'سلسلة الأيام',
                  value: '$streak',
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          const Text(
            'المكافآت شكلية فقط ولا تؤثر على الدرجات أو الإجابات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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

class _ActiveRewardCard extends StatelessWidget {
  const _ActiveRewardCard();

  @override
  Widget build(BuildContext context) {
    final selectedId = context.watch<StudentRewardsProvider>().selectedRewardId;
    final selectedReward = selectedId == null
        ? null
        : studentRewardCatalog.cast<StudentRewardDefinition?>().firstWhere(
            (reward) => reward?.id == selectedId,
            orElse: () => null,
          );

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(AppTheme.primaryGreen),
      child: Row(
        children: [
          _RewardIcon(reward: selectedReward, unlocked: true, selected: true),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المكافأة المختارة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  selectedReward?.name ?? 'لم تختر مكافأة بعد',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  selectedReward == null
                      ? 'اختر مكافأة شكلية من القائمة'
                      : 'محفوظة وستظهر في أماكن مدعومة لاحقًا',
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
    );
  }
}

class _RewardCategorySection extends StatelessWidget {
  const _RewardCategorySection({required this.category, required this.stars});

  final StudentRewardCategory category;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final rewards = rewardsForCategory(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          rewardCategoryLabel(category),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        ...rewards.map(
          (reward) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: StudentRewardCard(reward: reward, stars: stars),
          ),
        ),
      ],
    );
  }
}

class StudentRewardCard extends StatelessWidget {
  const StudentRewardCard({
    super.key,
    required this.reward,
    required this.stars,
  });

  final StudentRewardDefinition reward;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentRewardsProvider>();
    final unlocked = reward.isUnlocked(stars);
    final selected = provider.selectedRewardId == reward.id;
    final remaining = reward.remainingStars(stars);

    return Container(
      key: ValueKey('reward-card-${reward.id}'),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: selected
              ? AppTheme.primaryGreen
              : unlocked
              ? AppTheme.surfaceMuted
              : AppTheme.surfaceStrong.withValues(alpha: 0.45),
          width: selected ? 2 : 1,
        ),
        boxShadow: AppTheme.elevationLow,
      ),
      child: Row(
        children: [
          _RewardIcon(reward: reward, unlocked: unlocked, selected: selected),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  reward.description,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  '${reward.requiredStars} نجمة',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryYellowDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          SizedBox(
            width: 118,
            child: ElevatedButton(
              key: ValueKey('reward-action-${reward.id}'),
              onPressed: unlocked && !selected
                  ? () => context.read<StudentRewardsProvider>().selectReward(
                      reward.id,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                disabledBackgroundColor: selected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.55)
                    : AppTheme.surfaceMuted,
                disabledForegroundColor: selected
                    ? Colors.white
                    : AppTheme.textGray,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: Text(
                selected
                    ? 'مفتوح'
                    : unlocked
                    ? 'استخدم'
                    : 'يحتاج $remaining نجمة',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardIcon extends StatelessWidget {
  const _RewardIcon({
    required this.reward,
    required this.unlocked,
    required this.selected,
  });

  final StudentRewardDefinition? reward;
  final bool unlocked;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = reward == null
        ? AppTheme.textLight
        : selected
        ? AppTheme.primaryGreen
        : unlocked
        ? _rewardColor(reward!)
        : AppTheme.textLight;

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Icon(
        reward == null ? Icons.auto_awesome_rounded : _rewardIcon(reward!),
        color: color,
        size: 30,
      ),
    );
  }
}

IconData _rewardIcon(StudentRewardDefinition reward) {
  return switch (reward.category) {
    StudentRewardCategory.avatar => Icons.account_circle_rounded,
    StudentRewardCategory.frame => Icons.filter_frames_rounded,
    StudentRewardCategory.badge => Icons.workspace_premium_rounded,
    StudentRewardCategory.garden => switch (reward.id) {
      'garden-reading-chair' => Icons.chair_rounded,
      'garden-glow-star' => Icons.auto_awesome_rounded,
      'garden-tree' => Icons.park_rounded,
      _ => Icons.local_florist_rounded,
    },
  };
}

Color _rewardColor(StudentRewardDefinition reward) {
  return switch (reward.category) {
    StudentRewardCategory.avatar => AppTheme.primaryBlue,
    StudentRewardCategory.frame => AppTheme.primaryPurpleDeep,
    StudentRewardCategory.badge => AppTheme.primaryYellowDeep,
    StudentRewardCategory.garden => AppTheme.primaryGreen,
  };
}

BoxDecoration _cardDecoration(Color color) {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: color.withValues(alpha: 0.24)),
    boxShadow: AppTheme.elevationLow,
  );
}
