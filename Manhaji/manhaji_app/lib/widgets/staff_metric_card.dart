import 'package:flutter/material.dart';

import '../app/theme.dart';

class StaffMetricCard extends StatelessWidget {
  const StaffMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final card = AnimatedContainer(
      duration: AppTheme.motionFast,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: enabled
              ? color.withValues(alpha: 0.26)
              : AppTheme.surfaceMuted,
          width: 1.2,
        ),
        boxShadow: AppTheme.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              if (enabled)
                Icon(
                  Icons.arrow_back_rounded,
                  color: color.withValues(alpha: 0.7),
                  size: 22,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.35,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.space1),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );

    if (!enabled) return card;

    return Semantics(
      button: true,
      label: '$title $value',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: card,
          ),
        ),
      ),
    );
  }
}
