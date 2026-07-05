import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../widgets/vibrant_background.dart';
import 'preview_banner.dart';

/// Screenshot-ready replica of AdminDashboardScreen with hardcoded Arabic
/// mock data. No providers, no API calls, no auth required.
class PreviewAdminScreen extends StatelessWidget {
  const PreviewAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المشرف'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(28),
            child: PreviewBanner(),
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('إحصائيات النظام', fontSize: 20),
              const SizedBox(height: 16),
              Row(children: [
                _StatCard(icon: Icons.people, color: AppTheme.primaryBlue, title: 'الطلاب', value: '42'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.school, color: AppTheme.primaryGreen, title: 'المعلمون', value: '8'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(icon: Icons.family_restroom, color: AppTheme.primaryOrange, title: 'أولياء الأمور', value: '15'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.admin_panel_settings, color: AppTheme.primaryPurple, title: 'المشرفون', value: '3'),
              ]),
              const SizedBox(height: 20),
              _sectionHeader('المحتوى التعليمي'),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(icon: Icons.menu_book, color: AppTheme.primaryBlue, title: 'المواد', value: '4'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.library_books, color: AppTheme.primaryGreen, title: 'الدروس', value: '113'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _StatCard(icon: Icons.quiz, color: AppTheme.primaryYellow, title: 'اختبارات مكتملة', value: '287'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.check_circle, color: AppTheme.primaryGreen, title: 'دروس مكتملة', value: '198'),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: AppTheme.primaryBlue, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'طلاب نشطون هذا الأسبوع: 27',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _NavTile(
                icon: Icons.manage_accounts_rounded,
                accentColor: AppTheme.primaryBlue,
                title: 'إدارة المستخدمين',
                subtitle: 'أضف أو عدّل أو احذف الطلاب والمعلمين',
              ),
              const SizedBox(height: 10),
              _NavTile(
                icon: Icons.quiz_rounded,
                accentColor: AppTheme.primaryGreen,
                title: 'بنك الأسئلة',
                subtitle: 'استعرض أسئلة جميع المواد عبر كل الصفوف',
              ),
              const SizedBox(height: 24),
              _sectionHeader('المستخدمون'),
              const SizedBox(height: 8),
              ..._users.map((u) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: u.color.withValues(alpha: 0.1),
                        child: Icon(u.icon, color: u.color, size: 20),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('${u.role}  •  ${u.email}',
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('نشط',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppTheme.primaryGreen)),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionHeader(String text, {double fontSize = 18}) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      );
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

class _UserEntry {
  final String name;
  final String email;
  final String role;
  final Color color;
  final IconData icon;
  const _UserEntry(this.name, this.email, this.role, this.color, this.icon);
}

const _users = [
  _UserEntry('محمد أحمد السالم', 'teacher@manhaji.ps', 'معلم',
      AppTheme.primaryGreen, Icons.school),
  _UserEntry('سعاد خالد ناصر', 'parent@manhaji.ps', 'ولي أمر',
      AppTheme.primaryOrange, Icons.family_restroom),
  _UserEntry('ليلى خالد أبو عمر', 'leila@manhaji.ps', 'طالبة',
      AppTheme.primaryBlue, Icons.person),
  _UserEntry('عمر سعيد المصري', 'omar@manhaji.ps', 'طالب',
      AppTheme.primaryBlue, Icons.person),
  _UserEntry('نور إبراهيم حسن', 'noor@manhaji.ps', 'طالبة',
      AppTheme.primaryBlue, Icons.person),
];

// ---------------------------------------------------------------------------
// Local UI widgets (self-contained, no provider dependencies)
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.elevationLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.textGray)),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _NavTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppTheme.textGray)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, size: 16, color: AppTheme.textGray),
          ],
        ),
      ),
    );
  }
}
