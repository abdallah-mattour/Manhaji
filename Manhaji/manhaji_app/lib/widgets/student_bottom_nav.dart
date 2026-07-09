import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../app/theme.dart';

class StudentBottomNav extends StatelessWidget {
  final int currentIndex;

  const StudentBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
          onTap: (index) {
            if (index == currentIndex) return;
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              case 1:
                Navigator.pushReplacementNamed(context, AppRoutes.progress);
              case 2:
                Navigator.pushReplacementNamed(context, AppRoutes.settings);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: 'تقدمي'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}
