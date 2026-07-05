import 'package:flutter/material.dart';

import '../app/theme.dart';

class StaffShellItem {
  const StaffShellItem({
    required this.label,
    required this.icon,
    this.route,
    this.onTap,
    this.enabled = true,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final bool enabled;
  final String? badge;

  bool isActive(String? currentRoute) {
    return route != null && currentRoute != null && route == currentRoute;
  }
}

class StaffWebShell extends StatelessWidget {
  const StaffWebShell({
    super.key,
    required this.title,
    required this.items,
    required this.child,
    this.subtitle,
    this.roleLabel = 'طاقم المنصة',
    this.currentRoute,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final String roleLabel;
  final String? currentRoute;
  final List<StaffShellItem> items;
  final Widget child;
  final List<Widget> actions;

  static const double _desktopBreakpoint = 940;
  static const double _sidebarWidth = 282;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
          return Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            drawer: isDesktop ? null : _ShellDrawer(child: _sidebar(context)),
            body: SafeArea(
              child: Row(
                children: [
                  if (isDesktop) _sidebar(context),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          showMenuButton: !isDesktop,
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            color: AppTheme.backgroundMint,
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sidebar(BuildContext context) {
    return Container(
      width: _sidebarWidth,
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          left: BorderSide(color: AppTheme.surfaceMuted, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space5,
              AppTheme.space6,
              AppTheme.space5,
              AppTheme.space5,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTerracotta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppTheme.primaryTerracotta,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'منهجي',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textGray,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceMuted),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.space4),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.space2),
              itemBuilder: (context, index) {
                return _ShellNavTile(
                  item: items[index],
                  active: items[index].isActive(currentRoute),
                  onTap: () => _handleItemTap(context, items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleItemTap(BuildContext context, StaffShellItem item) {
    if (!item.enabled) return;
    final navigator = Navigator.of(context);
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      navigator.pop();
    }
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    final route = item.route;
    if (route == null || route == currentRoute) return;
    navigator.pushNamed(route);
  }
}

class _ShellDrawer extends StatelessWidget {
  const _ShellDrawer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(child: child),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.showMenuButton,
    required this.actions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool showMenuButton;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceMuted, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'القائمة',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          if (showMenuButton) const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textGray,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _ShellNavTile extends StatelessWidget {
  const _ShellNavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final StaffShellItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primaryTerracotta : AppTheme.textGray;
    final enabled = item.enabled;
    return Material(
      color: active
          ? AppTheme.primaryTerracotta.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space3,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: enabled ? color : AppTheme.textLight,
                size: 22,
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    color: enabled
                        ? (active ? AppTheme.textDark : AppTheme.textGray)
                        : AppTheme.textLight,
                    height: 1.35,
                  ),
                ),
              ),
              if (item.badge != null && item.badge!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textGray,
                      height: 1.2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
