import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'duolingo_card.dart';

/// A single tappable settings row: a DuolingoCard wrapping a ListTile with a
/// leading icon, an Arabic title and a back-chevron (RTL "forward"). Lifted out
/// of settings_screen so the settings hub and the About screen share one style.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DuolingoCard(
        padding: EdgeInsets.zero,
        borderRadius: AppTheme.radiusM,
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? AppTheme.primaryGreen),
          title: Text(
            title,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.arrow_back_ios, size: 16),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
