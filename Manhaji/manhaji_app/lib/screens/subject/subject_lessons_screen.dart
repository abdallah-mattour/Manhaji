import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/mascot.dart';
import '../learning/learning_screen.dart';

class SubjectLessonsScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final Color subjectColor;

  const SubjectLessonsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColor,
  });

  @override
  State<SubjectLessonsScreen> createState() => _SubjectLessonsScreenState();
}

class _SubjectLessonsScreenState extends State<SubjectLessonsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons(widget.subjectId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.subjectName),
          backgroundColor: widget.subjectColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'الفصل الأول'),
              Tab(text: 'الفصل الثاني'),
            ],
          ),
        ),
        body: Consumer<LessonProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.currentLessons.isEmpty) {
              return const LoadingState();
            }

            if (provider.errorMessage != null &&
                provider.currentLessons.isEmpty) {
              return ErrorState(
                message: provider.errorMessage!,
                onRetry: () => provider.loadLessons(widget.subjectId),
              );
            }

            final semester1Lessons = provider.currentLessons
                .where((l) => l.semesterNumber == 1)
                .toList();
            final semester2Lessons = provider.currentLessons
                .where((l) => l.semesterNumber == 2)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildLessonList(semester1Lessons, 1),
                _buildLessonList(semester2Lessons, 2),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLessonList(List<LessonSummary> lessons, int semester) {
    if (lessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(mood: MascotMood.sleeping, size: 140),
              const AppGap.v5(),
              Text(
                semester == 1
                    ? 'لا توجد دروس في الفصل الأول بعد'
                    : 'لا توجد دروس في الفصل الثاني بعد',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space8),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        return _buildLessonTile(lessons, lessons[index], index);
      },
    );
  }

  Widget _buildLessonTile(
      List<LessonSummary> semesterLessons, LessonSummary lesson, int index) {
    final isLocked = index > 0 && !semesterLessons[index - 1].isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      decoration: BoxDecoration(
        color: isLocked ? AppTheme.surfaceMuted : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: isLocked ? [] : AppTheme.elevationLow,
        border: Border.all(
          color: isLocked
              ? AppTheme.surfaceSubtle
              : widget.subjectColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: isLocked ? null : () => _openLesson(lesson, practice: false),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(
              children: [
                _LessonBadge(
                  isLocked: isLocked,
                  isCompleted: lesson.isCompleted,
                  orderIndex: lesson.orderIndex,
                  subjectColor: widget.subjectColor,
                ),
                const AppGap.h4(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isLocked
                              ? AppTheme.textLight
                              : AppTheme.textDark,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _StatusChip(
                        status: lesson.completionStatus,
                        isLocked: isLocked,
                        subjectColor: widget.subjectColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Progress ring + practice chip OR chevron, depending on state.
                if (!isLocked && lesson.isInProgress)
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: lesson.masteryLevel / 100,
                      backgroundColor: AppTheme.surfaceSubtle,
                      valueColor:
                          AlwaysStoppedAnimation(widget.subjectColor),
                      strokeWidth: 5,
                    ),
                  ),
                if (!isLocked && (lesson.isCompleted || lesson.isInProgress))
                  // Practice Mode button — labeled instead of bare emoji so
                  // kids can see what it does. Sized to be a clear tap target.
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: InkWell(
                      onTap: () => _openLesson(lesson, practice: true),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.subjectColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color:
                                widget.subjectColor.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎯',
                                style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              'تدريب',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: widget.subjectColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!isLocked && !lesson.isCompleted && !lesson.isInProgress)
                  Icon(Icons.arrow_back_ios_rounded,
                      size: 20, color: widget.subjectColor),
                if (isLocked)
                  Icon(Icons.lock_rounded,
                      size: 22, color: AppTheme.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLesson(LessonSummary lesson, {required bool practice}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningScreen(
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          practiceMode: practice,
        ),
      ),
    );
  }
}

/// The left-edge badge — lock / check / lesson number — in a single widget
/// so the parent build method stays compact.
class _LessonBadge extends StatelessWidget {
  final bool isLocked;
  final bool isCompleted;
  final int orderIndex;
  final Color subjectColor;

  const _LessonBadge({
    required this.isLocked,
    required this.isCompleted,
    required this.orderIndex,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = 52.0;
    if (isLocked) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: const Icon(Icons.lock_rounded,
            color: AppTheme.textLight, size: 24),
      );
    }
    if (isCompleted) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.success, AppTheme.primaryGreenDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.coloredGlow(AppTheme.success),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: subjectColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: subjectColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$orderIndex',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: subjectColor,
        ),
      ),
    );
  }
}

/// Status pill — shows "قيد التعلم" / "مكتمل ✅" / "متقن 🌟" / "لم يبدأ".
class _StatusChip extends StatelessWidget {
  final String status;
  final bool isLocked;
  final Color subjectColor;

  const _StatusChip({
    required this.status,
    required this.isLocked,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return const Text(
        'مقفل',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textLight,
        ),
      );
    }
    final (text, color, bg) = _statusVisual(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  (String, Color, Color) _statusVisual(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return ('لم يبدأ بعد', AppTheme.textGray, AppTheme.surfaceMuted);
      case 'IN_PROGRESS':
        return ('قيد التعلم', subjectColor, subjectColor.withValues(alpha: 0.1));
      case 'COMPLETED':
        return ('مكتمل ✅', AppTheme.success, AppTheme.successContainer);
      case 'MASTERED':
        return ('متقن 🌟', AppTheme.primaryYellowDeep, AppTheme.warningContainer);
      default:
        return ('', AppTheme.textGray, AppTheme.surfaceMuted);
    }
  }
}
