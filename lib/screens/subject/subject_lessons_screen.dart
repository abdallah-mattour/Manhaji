// lib/screens/subject/subject_lessons_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/lesson.dart';
import '../../providers/lesson_provider.dart';

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

class _SubjectLessonsScreenState extends State<SubjectLessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons(widget.subjectId);
    });
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
        ),
        body: Consumer<LessonProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.currentLessons.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null &&
                provider.currentLessons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadLessons(widget.subjectId),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.currentLessons.length,
              itemBuilder: (context, index) {
                final lesson = provider.currentLessons[index];
                return _buildLessonTile(lesson, index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLessonTile(LessonSummary lesson, int index) {
    final isLocked = index > 0 && !_isPreviousCompleted(index);

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              // الحل الصحيح في GoRouter
              context.push(
                '/lesson/${lesson.id}',
                extra: {'lessonTitle': lesson.title},
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLocked
              ? []
              : [
                  BoxShadow(
                    color: widget.subjectColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Lesson number circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.shade300
                    : lesson.isCompleted
                    ? AppColors.primary
                    : widget.subjectColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.grey, size: 22)
                    : lesson.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : Text(
                        '${lesson.orderIndex}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.subjectColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Lesson info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(lesson.completionStatus),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: isLocked
                          ? AppColors.textLight
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            if (!isLocked && lesson.isInProgress)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: lesson.masteryLevel / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(widget.subjectColor),
                  strokeWidth: 4,
                ),
              ),
            if (!isLocked && !lesson.isCompleted && !lesson.isInProgress)
              Icon(Icons.arrow_back_ios, size: 18, color: widget.subjectColor),
          ],
        ),
      ),
    );
  }

  bool _isPreviousCompleted(int index) {
    if (index == 0) return true;
    final lessons = context.read<LessonProvider>().currentLessons;
    if (index - 1 >= lessons.length) return false;
    return lessons[index - 1].isCompleted;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'NOT_STARTED':
        return 'لم يبدأ بعد';
      case 'IN_PROGRESS':
        return 'قيد التعلم';
      case 'COMPLETED':
        return 'مكتمل ✅';
      case 'MASTERED':
        return 'متقن 🌟';
      default:
        return '';
    }
  }
}
