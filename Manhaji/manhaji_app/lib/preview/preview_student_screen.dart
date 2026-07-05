import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../widgets/vibrant_background.dart';
import 'preview_banner.dart';

/// Screenshot-ready replica of the student HomeScreen with hardcoded
/// Arabic mock data. No providers, no API calls, no auth required.
/// StudentBottomNav is replaced with a static non-navigating version.
class PreviewStudentScreen extends StatelessWidget {
  const PreviewStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: VibrantBackground(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header bar
                SliverToBoxAdapter(child: _buildHeader()),
                // Preview mode indicator
                const SliverToBoxAdapter(child: PreviewBanner()),
                // Section title
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'موادي الدراسية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
                // Daily goal card
                const SliverToBoxAdapter(child: _DailyGoalCard()),
                // Challenge me banner
                const SliverToBoxAdapter(child: _ChallengeBanner()),
                // Subject cards grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space4),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _SubjectCard(subject: _subjects[index]),
                      childCount: _subjects.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const _StaticBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceMuted, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Owl avatar (replaces Mascot widget to keep preview self-contained)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surfaceMuted, width: 2),
            ),
            child: const Center(
              child: Text('🦉', style: TextStyle(fontSize: 22)),
            ),
          ),
          // Stats
          Row(
            children: [
              _buildStatItem('🔥', '5', AppTheme.primaryOrange),
              const SizedBox(width: 16),
              _buildStatItem('⭐', '340', AppTheme.primaryYellow),
            ],
          ),
          const Icon(Icons.person_rounded,
              color: AppTheme.textGray, size: 28),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mock subject data
// ---------------------------------------------------------------------------

class _MockSubject {
  final String name;
  final IconData icon;
  final int colorIndex;
  final double progress;
  const _MockSubject(this.name, this.icon, this.colorIndex, this.progress);
}

const _subjects = [
  _MockSubject('اللغة العربية', Icons.menu_book_rounded, 0, 0.65),
  _MockSubject('الرياضيات', Icons.calculate_rounded, 1, 0.45),
  _MockSubject('التربية الإسلامية', Icons.mosque_rounded, 2, 0.80),
  _MockSubject('اللغة الإنجليزية', Icons.language_rounded, 3, 0.30),
];

// ---------------------------------------------------------------------------
// Local UI widgets
// ---------------------------------------------------------------------------

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    const completed = 5;
    const total = 8;
    const fraction = completed / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space2),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.primaryYellow, width: 2),
          boxShadow: AppTheme.elevationLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text('🎯', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('هدف اليوم',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark)),
                Spacer(),
                Text('$completed / $total',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryTerracotta)),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: const LinearProgressIndicator(
                value: fraction,
                minHeight: 14,
                backgroundColor: AppTheme.surfaceMuted,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            const Text(
              'استمرّ، أنت تتقدّم بشكل رائع!',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  const _ChallengeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space2),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppTheme.space5, vertical: AppTheme.space4),
          child: Row(
            children: [
              Text('⚡', style: TextStyle(fontSize: 34)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تحدَّ نفسك!',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text('اختبار ذكيّ يركّز على ما تحتاج تدريبه',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: Colors.white)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final _MockSubject subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.subjectColors[subject.colorIndex];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceMuted, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surfaceMuted,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: Icon(subject.icon, size: 36, color: color),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: Text(
                subject.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: subject.progress,
                backgroundColor: AppTheme.surfaceSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-navigating bottom nav bar for the student preview.
/// Visually identical to StudentBottomNav but onTap is a no-op so there
/// are no RoleGuard redirects while taking screenshots.
class _StaticBottomNav extends StatelessWidget {
  const _StaticBottomNav();

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
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600),
          onTap: (_) {},
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
