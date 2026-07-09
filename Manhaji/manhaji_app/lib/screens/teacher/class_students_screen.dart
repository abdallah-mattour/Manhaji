import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_dashboard.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_web_shell.dart';
import 'teacher_shell_navigation.dart';

class ClassStudentsScreen extends StatefulWidget {
  const ClassStudentsScreen({super.key});

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeacherProvider>().loadStudents();
    });
  }

  String _csvField(String value) {
    String safe = value;
    if (safe.isNotEmpty && '=+-@'.contains(safe[0])) {
      safe = ' $safe';
    }
    return '"${safe.replaceAll('"', '""')}"';
  }

  String _buildCsv(List<ClassStudentSummary> students) {
    final buf = StringBuffer();
    buf.write('﻿');
    buf.writeln(
      [
        _csvField('الاسم الكامل'),
        _csvField('البريد الإلكتروني'),
        _csvField('الصف الدراسي'),
        _csvField('النقاط الكلية'),
        _csvField('أيام التعلم المتواصل'),
        _csvField('الدروس المكتملة'),
        _csvField('دروس قيد التقدم'),
        _csvField('متوسط الإتقان %'),
        _csvField('آخر نشاط'),
      ].join(','),
    );
    for (final s in students) {
      buf.writeln(
        [
          _csvField(s.fullName),
          _csvField(s.email ?? ''),
          _csvField(s.gradeLevel.toString()),
          _csvField(s.totalPoints.toString()),
          _csvField(s.currentStreak.toString()),
          _csvField(s.lessonsCompleted.toString()),
          _csvField(s.lessonsInProgress.toString()),
          _csvField(s.averageMastery.toStringAsFixed(1)),
          _csvField(s.lastLoginAt ?? ''),
        ].join(','),
      );
    }
    return buf.toString();
  }

  Future<void> _exportCsv() async {
    final students = context.read<TeacherProvider>().students;
    if (students == null || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد بيانات للتصدير',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryOrange,
        ),
      );
      return;
    }
    final csv = _buildCsv(students);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final now = DateTime.now();
    final ts =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        name: 'students_report_$ts.csv',
        mimeType: 'text/csv',
      ),
    ], subject: 'تقرير الطلاب - منهاجي');
  }

  void _openStudent(int studentId) {
    Navigator.pushNamed(
      context,
      AppRoutes.teacherStudentDetail,
      arguments: StudentDetailArgs(studentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'الطلاب',
        subtitle: 'قائمة الطلاب المتاحين حسب تكليفات المعلم',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.classStudents,
        items: teacherShellItems(context),
        actions: [
          Consumer<TeacherProvider>(
            builder: (context, provider, _) {
              final canExport =
                  provider.students?.isNotEmpty == true && !provider.isLoading;
              return IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'تصدير CSV',
                onPressed: canExport ? _exportCsv : null,
              );
            },
          ),
        ],
        child: Consumer<TeacherProvider>(
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

            final students = provider.students ?? const [];
            return RefreshIndicator(
              onRefresh: () => provider.loadStudents(),
              child: _StudentsContent(
                students: students,
                query: _query,
                onQueryChanged: (value) => setState(() => _query = value),
                onOpenStudent: _openStudent,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StudentsContent extends StatelessWidget {
  const _StudentsContent({
    required this.students,
    required this.query,
    required this.onQueryChanged,
    required this.onOpenStudent,
  });

  final List<ClassStudentSummary> students;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterStudents(students, query);
    final groups = _groupByGrade(filtered);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space6),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StudentsSummaryPanel(
                  totalStudents: students.length,
                  visibleStudents: filtered.length,
                  averageMastery: _averageMastery(students),
                ),
                const SizedBox(height: AppTheme.space4),
                _SearchPanel(onChanged: onQueryChanged),
                const SizedBox(height: AppTheme.space5),
                if (students.isEmpty)
                  const _EmptyStudentsPanel(
                    message: 'لا يوجد طلاب مرتبطون بهذا الحساب حالياً.',
                  )
                else if (filtered.isEmpty)
                  const _EmptyStudentsPanel(
                    message: 'لا توجد نتائج مطابقة للبحث الحالي.',
                  )
                else
                  for (final entry in groups.entries) ...[
                    _GradeStudentsSection(
                      gradeLevel: entry.key,
                      students: entry.value,
                      onOpenStudent: onOpenStudent,
                    ),
                    const SizedBox(height: AppTheme.space4),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ClassStudentSummary> _filterStudents(
    List<ClassStudentSummary> students,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return students;
    return students.where((student) {
      final haystack = [
        student.fullName,
        student.email ?? '',
        student.gradeLevel.toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }

  SplayTreeMap<int, List<ClassStudentSummary>> _groupByGrade(
    List<ClassStudentSummary> students,
  ) {
    final groups = SplayTreeMap<int, List<ClassStudentSummary>>();
    for (final student in students) {
      groups.putIfAbsent(student.gradeLevel, () => []).add(student);
    }
    for (final group in groups.values) {
      group.sort((a, b) => a.fullName.compareTo(b.fullName));
    }
    return groups;
  }

  double _averageMastery(List<ClassStudentSummary> students) {
    if (students.isEmpty) return 0;
    final total = students.fold<double>(
      0,
      (sum, student) => sum + student.averageMastery,
    );
    return total / students.length;
  }
}

class _StudentsSummaryPanel extends StatelessWidget {
  const _StudentsSummaryPanel({
    required this.totalStudents,
    required this.visibleStudents,
    required this.averageMastery,
  });

  final int totalStudents;
  final int visibleStudents;
  final double averageMastery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: AppTheme.space4,
        runSpacing: AppTheme.space4,
        children: [
          _SummaryMetric(
            icon: Icons.people_alt_rounded,
            label: 'إجمالي الطلاب',
            value: '$totalStudents',
            color: AppTheme.primaryBlue,
          ),
          _SummaryMetric(
            icon: Icons.filter_alt_rounded,
            label: 'المعروضون',
            value: '$visibleStudents',
            color: AppTheme.primaryTerracotta,
          ),
          _SummaryMetric(
            icon: Icons.insights_rounded,
            label: 'متوسط الإتقان',
            value: '${averageMastery.toStringAsFixed(0)}%',
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    height: 1.2,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: _panelDecoration(),
      child: TextField(
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Cairo'),
        decoration: InputDecoration(
          hintText: 'ابحث باسم الطالب أو البريد أو الصف',
          hintStyle: const TextStyle(fontFamily: 'Cairo'),
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: AppTheme.surfaceSubtle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space4,
          ),
        ),
      ),
    );
  }
}

class _GradeStudentsSection extends StatelessWidget {
  const _GradeStudentsSection({
    required this.gradeLevel,
    required this.students,
    required this.onOpenStudent,
  });

  final int gradeLevel;
  final List<ClassStudentSummary> students;
  final ValueChanged<int> onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final averageMastery = students.isEmpty
        ? 0.0
        : students.fold<double>(
                0,
                (sum, student) => sum + student.averageMastery,
              ) /
              students.length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space4,
            runSpacing: AppTheme.space2,
            children: [
              Text(
                _gradeLabel(gradeLevel),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '${students.length} طالب • متوسط الإتقان ${averageMastery.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1180),
              child: Column(
                children: [
                  const _StudentsTableHeader(),
                  const Divider(height: 1, color: AppTheme.surfaceMuted),
                  for (final student in students) ...[
                    _StudentTableRow(
                      student: student,
                      onOpen: () => onOpenStudent(student.studentId),
                    ),
                    const Divider(height: 1, color: AppTheme.surfaceMuted),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentsTableHeader extends StatelessWidget {
  const _StudentsTableHeader();

  @override
  Widget build(BuildContext context) {
    return const _TableRowShell(
      backgroundColor: AppTheme.surfaceSubtle,
      children: [
        _TableCell(width: 190, text: 'الطالب', header: true),
        _TableCell(width: 210, text: 'البريد', header: true),
        _TableCell(width: 82, text: 'النقاط', header: true),
        _TableCell(width: 82, text: 'السلسلة', header: true),
        _TableCell(width: 126, text: 'الدروس المكتملة', header: true),
        _TableCell(width: 110, text: 'قيد التقدم', header: true),
        _TableCell(width: 126, text: 'متوسط الإتقان', header: true),
        _TableCell(width: 150, text: 'آخر نشاط', header: true),
        _TableCell(width: 104, text: 'إجراء', header: true),
      ],
    );
  }
}

class _StudentTableRow extends StatelessWidget {
  const _StudentTableRow({required this.student, required this.onOpen});

  final ClassStudentSummary student;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _TableRowShell(
      children: [
        SizedBox(
          width: 190,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0] : '؟',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Text(
                  student.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        _TableCell(width: 210, text: student.email ?? 'غير متوفر'),
        _TableCell(width: 82, text: '${student.totalPoints}'),
        _TableCell(width: 82, text: '${student.currentStreak}'),
        _TableCell(width: 126, text: '${student.lessonsCompleted}'),
        _TableCell(width: 110, text: '${student.lessonsInProgress}'),
        _MasteryCell(value: student.averageMastery),
        _TableCell(width: 150, text: _formatLastActivity(student.lastLoginAt)),
        SizedBox(
          width: 104,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text(
                'عرض',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MasteryCell extends StatelessWidget {
  const _MasteryCell({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 126,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRowShell extends StatelessWidget {
  const _TableRowShell({required this.children, this.backgroundColor});

  final List<Widget> children;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space3,
      ),
      child: Row(children: children),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.width,
    required this.text,
    this.header = false,
  });

  final double width;
  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: header ? 12 : 13,
          fontWeight: header ? FontWeight.w900 : FontWeight.w700,
          color: header ? AppTheme.textDark : AppTheme.textGray,
        ),
      ),
    );
  }
}

class _EmptyStudentsPanel extends StatelessWidget {
  const _EmptyStudentsPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: AppTheme.textLight,
            size: 56,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: AppTheme.surfaceMuted),
    boxShadow: AppTheme.elevationLow,
  );
}

String _gradeLabel(int gradeLevel) {
  const labels = {
    1: 'الصف الأول',
    2: 'الصف الثاني',
    3: 'الصف الثالث',
    4: 'الصف الرابع',
    5: 'الصف الخامس',
    6: 'الصف السادس',
    7: 'الصف السابع',
    8: 'الصف الثامن',
    9: 'الصف التاسع',
    10: 'الصف العاشر',
    11: 'الصف الحادي عشر',
    12: 'الصف الثاني عشر',
  };
  return labels[gradeLevel] ?? 'الصف $gradeLevel';
}

String _formatLastActivity(String? value) {
  if (value == null || value.trim().isEmpty) return 'لا يوجد';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
}
