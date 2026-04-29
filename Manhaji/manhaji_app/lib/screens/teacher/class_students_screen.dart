import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ClassStudentsScreen extends StatefulWidget {
  const ClassStudentsScreen({super.key});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TeacherProvider>().loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة الطلاب')),
        body: Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.students == null) {
              return const LoadingState();
            }
            if (provider.error != null && provider.students == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: provider.loadStudents,
              );
            }
            final students = provider.students ?? [];
            if (students.isEmpty) {
              return const Center(
                child: Text('لا يوجد طلاب',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadStudents(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.teacherStudentDetail,
                        arguments: s.studentId,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          s.fullName.isNotEmpty ? s.fullName[0] : '?',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      title: Text(
                        s.fullName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            _MiniChip(
                                icon: Icons.star,
                                text: '${s.totalPoints}',
                                color: AppTheme.primaryYellow),
                            const SizedBox(width: 8),
                            _MiniChip(
                                icon: Icons.check_circle,
                                text: '${s.lessonsCompleted}',
                                color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            _MiniChip(
                                icon: Icons.show_chart,
                                text:
                                    '${s.averageMastery.toStringAsFixed(0)}%',
                                color: AppTheme.primaryPurple),
                          ],
                        ),
                      ),
                      trailing:
                          const Icon(Icons.arrow_back_ios, size: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
