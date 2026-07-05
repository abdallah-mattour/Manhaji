import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../widgets/staff_web_shell.dart';
import '../question_bank/question_bank_subjects_screen.dart';

List<StaffShellItem> teacherShellItems(BuildContext context) {
  return [
    const StaffShellItem(
      label: 'لوحة التحكم',
      icon: Icons.dashboard_rounded,
      route: AppRoutes.teacherDashboard,
    ),
    const StaffShellItem(
      label: 'الطلاب',
      icon: Icons.people_alt_rounded,
      route: AppRoutes.classStudents,
    ),
    const StaffShellItem(
      label: 'المواد المخصصة',
      icon: Icons.menu_book_rounded,
      route: AppRoutes.teacherSubjects,
    ),
    const StaffShellItem(
      label: 'تحليل الأخطاء',
      icon: Icons.analytics_rounded,
      route: AppRoutes.teacherMistakes,
    ),
    const StaffShellItem(
      label: 'الاختبارات',
      icon: Icons.assignment_turned_in_rounded,
      route: AppRoutes.teacherQuizzes,
    ),
    StaffShellItem(
      label: 'بنك الأسئلة',
      icon: Icons.quiz_rounded,
      onTap: () => context.openTeacherQuestionBank(),
    ),
    const StaffShellItem(
      label: 'الإعدادات',
      icon: Icons.settings_rounded,
      route: AppRoutes.teacherSettings,
    ),
  ];
}
