import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../config/gamification.dart';

/// The point-unlockable avatar collection card. Extracted verbatim from
/// rewards_screen.dart so both "مكافآتي" and the profile screen reuse the same
/// unlock logic and visuals. Callers own the select/locked-tap behaviour
/// (snackbars, persistence) — this widget is presentation only.
class AvatarPickerCard extends StatelessWidget {
  final String currentId;
  final int pts;
  final ValueChanged<AvatarDef> onSelect;
  final ValueChanged<AvatarDef> onLockedTap;

  const AvatarPickerCard({
    super.key,
    required this.currentId,
    required this.pts,
    required this.onSelect,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
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
            '🎭 مجموعة الشخصيات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'اجمع النقاط لفتح شخصيات جديدة، واضغط لاختيار شخصيتك',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final av in Avatars.all)
                _AvatarTile(
                  av: av,
                  unlocked: av.isUnlocked(pts),
                  isCurrent: av.id == currentId,
                  onTap: () =>
                      av.isUnlocked(pts) ? onSelect(av) : onLockedTap(av),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final AvatarDef av;
  final bool unlocked;
  final bool isCurrent;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.av,
    required this.unlocked,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppTheme.motionFast,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? (isCurrent
                        ? AppTheme.primaryTerracotta.withValues(alpha: 0.15)
                        : AppTheme.surfaceSubtle)
                    : AppTheme.surfaceMuted,
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.primaryTerracotta
                      : (unlocked ? AppTheme.surfaceMuted : AppTheme.textLight),
                  width: isCurrent ? 2.5 : 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? Text(av.emoji, style: const TextStyle(fontSize: 26))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 0.25,
                          child: Text(av.emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text('🔒', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 3),
            Text(
              unlocked ? av.name : '${av.unlockPoints} نقطة',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: unlocked
                    ? (isCurrent
                        ? AppTheme.primaryTerracotta
                        : AppTheme.textGray)
                    : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
