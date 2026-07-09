import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../widgets/staff_web_shell.dart';

List<StaffShellItem> adminShellItems(BuildContext context) {
  return [
    const StaffShellItem(
      label: 'لوحة التحكم',
      icon: Icons.dashboard_rounded,
      route: AppRoutes.adminDashboard,
    ),
    const StaffShellItem(
      label: 'المستخدمون',
      icon: Icons.manage_accounts_rounded,
      route: AppRoutes.adminManageUsers,
    ),
    const StaffShellItem(
      label: 'بنك الأسئلة',
      icon: Icons.quiz_rounded,
      route: AppRoutes.adminQuestionBank,
    ),
    const StaffShellItem(
      label: 'الإعدادات',
      icon: Icons.settings_rounded,
      route: AppRoutes.adminSettings,
    ),
  ];
}
