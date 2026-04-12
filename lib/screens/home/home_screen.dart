// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/size_config.dart';
import '../../models/subject.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../routing/app_routes.dart';
import 'widgets/home_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Consumer<LessonProvider>(
          builder: (context, lessonProvider, _) {
            if (lessonProvider.isLoading && lessonProvider.dashboard == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (lessonProvider.errorMessage != null &&
                lessonProvider.dashboard == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lessonProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => lessonProvider.loadDashboard(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final dashboard = lessonProvider.dashboard;
            if (dashboard == null) {
              return const Center(child: Text('حدث خطأ، يرجى إعادة المحاولة'));
            }

            return RefreshIndicator(
              onRefresh: () => lessonProvider.loadDashboard(),
              child: CustomScrollView(
                slivers: [
                  // Header Gradient
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        AppDimensions.paddingL,
                        7.h,
                        AppDimensions.paddingL,
                        AppDimensions.paddingXXL,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, Color(0xFF15803D)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مرحباً 👋',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dashboard.fullName,
                                      style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showLogoutDialog(context),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.25,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingL),
                      child: Row(
                        children: [
                          _buildStatCard(
                            '⭐',
                            '${dashboard.totalPoints}',
                            'نقاط',
                          ),
                          SizedBox(width: AppDimensions.paddingS),
                          _buildStatCard(
                            '🔥',
                            '${dashboard.currentStreak}',
                            'متتالية',
                          ),
                          SizedBox(width: AppDimensions.paddingS),
                          _buildStatCard(
                            '✅',
                            '${dashboard.subjects.fold<int>(0, (sum, s) => sum + s.completedLessons)}',
                            'درس مكتمل',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subjects Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                        vertical: AppDimensions.paddingM,
                      ),
                      child: Text(
                        'المواد الدراسية',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Subjects Grid
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: SizeConfig.isTablet ? 3 : 2,
                        crossAxisSpacing: AppDimensions.paddingM,
                        mainAxisSpacing: AppDimensions.paddingM,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final subject = dashboard.subjects[index];
                        return _buildSubjectCard(subject, index);
                      }, childCount: dashboard.subjects.length),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: HomeBottomNavigation(
          onTap: (index) {
            if (index == 1) context.go(AppRoutes.progress);
            if (index == 2) context.go(AppRoutes.settings);
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return HomeStatCard(emoji: emoji, value: value, label: label);
  }

  Widget _buildSubjectCard(Subject subject, int index) {
    final colors = AppColors.subjectColors;
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.subjectLessons(subject.id),
          extra: {'subjectName': subject.name, 'subjectColor': color},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(_getSubjectIcon(index), size: 59, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                subject.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: subject.progressPercent,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${subject.completedLessons}/${subject.totalLessons}',
                style: TextStyle(
                  fontSize: 17.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(int index) {
    const icons = [
      Icons.menu_book_rounded,
      Icons.abc_outlined,
      Icons.calculate_rounded,
      Icons.mosque_rounded,
    ];
    return icons[index % icons.length];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.read<AuthProvider>().logout();
                context.go(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }
}
