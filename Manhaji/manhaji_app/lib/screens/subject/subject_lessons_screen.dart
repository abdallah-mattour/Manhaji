import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/vibrant_background.dart';
import '../learning/learning_screen.dart';
import '../progress/skills_screen.dart';

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
          actions: [
            // "My Skills" — the Knowledge Tracing radar for this subject.
            IconButton(
              icon: const Icon(Icons.insights_rounded),
              tooltip: 'مهاراتي',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SkillsScreen(
                    subjectId: widget.subjectId,
                    subjectName: widget.subjectName,
                    subjectColor: widget.subjectColor,
                  ),
                ),
              ),
            ),
          ],
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'الفصل الأول'),
              Tab(text: 'الفصل الثاني'),
            ],
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          patternColor: widget.subjectColor,
          child: Consumer<LessonProvider>(
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
              // Combined ordered list: S1 lessons then S2 lessons.
              // Used to compute global position for the cross-semester lock check.
              final allLessons = [...semester1Lessons, ...semester2Lessons];

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildLessonList(semester1Lessons, 1, allLessons, 0),
                  _buildLessonList(semester2Lessons, 2, allLessons, semester1Lessons.length),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLessonList(List<LessonSummary> lessons, int semester, List<LessonSummary> allLessons, int globalOffset) {
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Stack(
      children: [
        // Path lines layer
        Positioned.fill(
          child: CustomPaint(
            painter: _PathLinePainter(
              lessonsCount: lessons.length,
              color: widget.subjectColor.withValues(alpha: 0.2),
              isRtl: isRtl,
            ),
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 60),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            final globalIndex = globalOffset + index;
            // Gate the NEXT unopened lesson on finishing the previous one, but
            // never re-lock a lesson the student already opened. Without the
            // second clause, the first lesson of a semester locks whenever the
            // last lesson of the previous semester is unfinished — even if the
            // student already completed this one (bug: S2 unit shown locked at
            // 93%). A completed/in-progress lesson is always tappable.
            final isLocked = globalIndex > 0 &&
                !allLessons[globalIndex - 1].isCompleted &&
                !lesson.isCompleted &&
                !lesson.isInProgress;

            final double rawOffset = (index % 4 == 0 || index % 4 == 3)
                ? 0
                : (index % 4 == 1 ? 70 : -70);

            final double offset = isRtl ? -rawOffset : rawOffset;

            return Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: 40,
                start: offset > 0 ? offset : 0,
                end: offset < 0 ? -offset : 0,
              ),
              child: _LessonPathNode(
                lesson: lesson,
                isLocked: isLocked,
                color: widget.subjectColor,
                onTap: isLocked ? null : () => _openLesson(lesson, practice: false),
                onPractice: () => _openLesson(lesson, practice: true),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openLesson(LessonSummary lesson, {required bool practice}) {
    // Full English experience (2026-07-03): English-subject lessons flip the
    // whole in-lesson UI to English. This screen knows the subject name.
    final isEnglish = widget.subjectName.contains('English') ||
        widget.subjectName.contains('نجليزية');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningScreen(
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          practiceMode: practice,
          englishMode: isEnglish,
        ),
      ),
    );
  }
}

/// A circular node in the lesson path.
class _LessonPathNode extends StatelessWidget {
  final LessonSummary lesson;
  final bool isLocked;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onPractice;

  const _LessonPathNode({
    required this.lesson,
    required this.isLocked,
    required this.color,
    this.onTap,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 3D Depth Shadow
              Container(
                width: 84,
                height: 84,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: isLocked ? AppTheme.surfaceMuted : _getDarkerColor(color),
                  shape: BoxShape.circle,
                ),
              ),
              // Top Layer
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: isLocked ? AppTheme.surfaceSubtle : color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLocked ? AppTheme.surfaceMuted : Colors.white.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : (lesson.isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded),
                  color: Colors.white,
                  size: 40,
                ),
              ),
              // Mastery stars if completed
              if (lesson.isCompleted)
                Positioned(
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      // masteryLevel is 0..100 (DB check constraint on
                      // Progress.mastery_level) — but it's a double, so
                      // raw interpolation gives "85.0%". Round to int.
                      '🌟 ${lesson.masteryLevel.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Lesson Title
        SizedBox(
          width: 140,
          child: Text(
            lesson.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isLocked ? AppTheme.textLight : AppTheme.textDark,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isLocked && (lesson.isCompleted || lesson.isInProgress))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: onPractice,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                backgroundColor: color.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
              ),
              child: Text(
                'مراجعة 🎯',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}

class _PathLinePainter extends CustomPainter {
  final int lessonsCount;
  final Color color;
  final bool isRtl;

  _PathLinePainter({
    required this.lessonsCount,
    required this.color,
    required this.isRtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonsCount < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Starting point (approx center of first node)
    double startX = size.width / 2;
    double startY = 60 + (84 / 2); // vertical padding + half node height
    
    path.moveTo(startX, startY);

    for (int i = 1; i < lessonsCount; i++) {
      final double rawOffset = (i % 4 == 0 || i % 4 == 3)
          ? 0
          : (i % 4 == 1 ? 70 : -70);
      final double offset = isRtl ? -rawOffset : rawOffset;
      
      double endX = (size.width / 2) + offset;
      double endY = startY + 40 + 84; // gap + node height
      
      // Control points for a smooth curve
      double ctrlX = (startX + endX) / 2;
      double ctrlY = (startY + endY) / 2;
      
      path.quadraticBezierTo(ctrlX, ctrlY - 20, endX, endY);
      
      startX = endX;
      startY = endY;
    }

    // Draw dashed path
    final dashPath = _dashPath(path, dashLength: 15, gapLength: 10);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
