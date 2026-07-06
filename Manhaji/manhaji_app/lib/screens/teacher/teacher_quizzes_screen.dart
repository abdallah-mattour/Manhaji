import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';
import '../../models/teacher_dashboard.dart';
import '../../models/teacher_quiz.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_web_shell.dart';
import 'teacher_shell_navigation.dart';

class TeacherQuizzesScreen extends StatefulWidget {
  const TeacherQuizzesScreen({super.key});

  @override
  State<TeacherQuizzesScreen> createState() => _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends State<TeacherQuizzesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TeacherProvider>();
      provider.loadTeacherQuizzes();
      if (provider.assignedSubjects == null) {
        provider.loadAssignedSubjects();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'إدارة الاختبارات',
        subtitle: 'إنشاء اختبارات من بنك الأسئلة',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.teacherQuizzes,
        items: teacherShellItems(context),
        actions: [
          FilledButton.icon(
            onPressed: () => _openCreateDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء اختبار جديد'),
          ),
        ],
        child: Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            if (provider.isTeacherQuizzesLoading &&
                provider.teacherQuizzes == null) {
              return const LoadingState();
            }
            if (provider.teacherQuizzesError != null &&
                provider.teacherQuizzes == null) {
              return ErrorState(
                message: provider.teacherQuizzesError!,
                onRetry: provider.loadTeacherQuizzes,
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadTeacherQuizzes(),
              child: _TeacherQuizzesContent(
                quizzes: provider.teacherQuizzes ?? const [],
                onCreate: () => _openCreateDialog(context),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    final provider = context.read<TeacherProvider>();
    showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _CreateTeacherQuizDialog(),
      ),
    );
  }
}

class _TeacherQuizzesContent extends StatelessWidget {
  const _TeacherQuizzesContent({required this.quizzes, required this.onCreate});

  final List<TeacherQuizSummary> quizzes;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space6),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverviewPanel(quizCount: quizzes.length, onCreate: onCreate),
                const SizedBox(height: AppTheme.space5),
                if (quizzes.isEmpty)
                  const _EmptyQuizzesPanel()
                else
                  _QuizGrid(quizzes: quizzes),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.quizCount, required this.onCreate});

  final int quizCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppTheme.space4,
        runSpacing: AppTheme.space3,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBox(
                icon: Icons.assignment_turned_in_rounded,
                color: AppTheme.primaryTerracotta,
              ),
              const SizedBox(width: AppTheme.space4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختباراتك الحالية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    quizCount == 0
                        ? 'ابدأ بإنشاء اختبار من الأسئلة المتاحة لك'
                        : '$quizCount اختبار محفوظ ضمن نطاق موادك',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء اختبار جديد'),
          ),
        ],
      ),
    );
  }
}

class _QuizGrid extends StatelessWidget {
  const _QuizGrid({required this.quizzes});

  final List<TeacherQuizSummary> quizzes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        const spacing = AppTheme.space4;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final quiz in quizzes)
              SizedBox(
                width: width,
                child: _QuizCard(quiz: quiz),
              ),
          ],
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});

  final TeacherQuizSummary quiz;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final assignments = provider.quizAssignmentsFor(quiz.id);
    final hasAssignments = assignments?.isNotEmpty ?? false;
    final status = _effectiveStatus(quiz, hasAssignments);
    final canPublish = status == _QuizUiStatus.draft;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: Icons.quiz_rounded, color: AppTheme.primaryBlue),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title.isEmpty ? 'اختبار بدون عنوان' : quiz.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      _fallback(quiz.subjectName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _InfoChip(
                icon: Icons.help_outline_rounded,
                label: '${quiz.questionCount} سؤال',
              ),
              if (quiz.lessonTitle != null && quiz.lessonTitle!.isNotBlank)
                _InfoChip(
                  icon: Icons.menu_book_rounded,
                  label: quiz.lessonTitle!,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'تاريخ الإنشاء: ${_formatDate(quiz.createdAt)}',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              if (canPublish)
                FilledButton.icon(
                  key: Key('teacher_quiz_publish_${quiz.id}'),
                  onPressed: () => _openPublishDialog(context),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('نشر / تعيين'),
                ),
              OutlinedButton.icon(
                key: Key('teacher_quiz_assignments_${quiz.id}'),
                onPressed: () => _openAssignmentsDialog(context),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('التعيينات'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _QuizUiStatus _effectiveStatus(
    TeacherQuizSummary quiz,
    bool hasLoadedAssignments,
  ) {
    if (quiz.isArchived) return _QuizUiStatus.archived;
    if (quiz.isPublished || hasLoadedAssignments) {
      return _QuizUiStatus.published;
    }
    return _QuizUiStatus.draft;
  }

  void _openPublishDialog(BuildContext context) {
    final provider = context.read<TeacherProvider>();
    showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _PublishQuizDialog(quiz: quiz),
      ),
    );
  }

  void _openAssignmentsDialog(BuildContext context) {
    final provider = context.read<TeacherProvider>();
    showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _QuizAssignmentsDialog(quiz: quiz),
      ),
    );
  }
}

class _CreateTeacherQuizDialog extends StatefulWidget {
  const _CreateTeacherQuizDialog();

  @override
  State<_CreateTeacherQuizDialog> createState() =>
      _CreateTeacherQuizDialogState();
}

class _CreateTeacherQuizDialogState extends State<_CreateTeacherQuizDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedQuestionIds = <int>{};
  final Map<int, QuestionBankItem> _selectedQuestions = {};
  int? _subjectId;
  int? _lessonId;
  String _query = '';

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.space5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 820),
          child: Consumer<TeacherProvider>(
            builder: (context, provider, _) {
              final subjects = provider.assignedSubjects ?? const [];
              final bank = provider.quizQuestionBank;
              final lessons = bank?.lessons ?? const <LessonSummary>[];
              final questions = _filteredQuestions(bank?.questions ?? const []);
              final canSave =
                  _titleController.text.trim().isNotEmpty &&
                  _subjectId != null &&
                  _selectedQuestionIds.isNotEmpty &&
                  !provider.isCreatingTeacherQuiz;

              return Column(
                children: [
                  _DialogHeader(onClose: () => Navigator.of(context).pop()),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        final controls = _CreateControls(
                          titleController: _titleController,
                          subjects: subjects,
                          lessons: lessons,
                          subjectId: _subjectId,
                          lessonId: _lessonId,
                          searchController: _searchController,
                          onSubjectChanged: (value) =>
                              _onSubjectChanged(provider, value),
                          onLessonChanged: (value) =>
                              setState(() => _lessonId = value),
                          onSearchChanged: (value) =>
                              setState(() => _query = value),
                          onTitleChanged: (_) => setState(() {}),
                        );
                        final picker = _QuestionPickerPanel(
                          isLoading: provider.isQuizQuestionBankLoading,
                          error: provider.quizQuestionBankError,
                          subjectSelected: _subjectId != null,
                          questions: questions,
                          selectedQuestionIds: _selectedQuestionIds,
                          onToggle: _toggleQuestion,
                          onRetry: _subjectId == null
                              ? null
                              : () =>
                                    provider.loadQuizQuestionBank(_subjectId!),
                        );
                        final selected = _SelectedQuestionsPanel(
                          questions: _selectedQuestions.values.toList(),
                          onRemove: _removeQuestion,
                        );

                        if (!wide) {
                          return ListView(
                            padding: const EdgeInsets.all(AppTheme.space5),
                            children: [
                              controls,
                              const SizedBox(height: AppTheme.space4),
                              picker,
                              const SizedBox(height: AppTheme.space4),
                              selected,
                            ],
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(AppTheme.space5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 310, child: controls),
                              const SizedBox(width: AppTheme.space4),
                              Expanded(child: picker),
                              const SizedBox(width: AppTheme.space4),
                              SizedBox(width: 300, child: selected),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _DialogActions(
                    canSave: canSave,
                    isSaving: provider.isCreatingTeacherQuiz,
                    error: provider.createTeacherQuizError,
                    onCancel: () => Navigator.of(context).pop(),
                    onSave: () => _save(provider),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<QuestionBankItem> _filteredQuestions(List<QuestionBankItem> questions) {
    final query = _query.trim().toLowerCase();
    return questions.where((question) {
      final lessonMatches = _lessonId == null || question.lessonId == _lessonId;
      final queryMatches =
          query.isEmpty ||
          [
            question.questionText,
            question.lessonTitle,
            question.type,
          ].whereType<String>().join(' ').toLowerCase().contains(query);
      return lessonMatches && queryMatches;
    }).toList();
  }

  void _onSubjectChanged(TeacherProvider provider, int? value) {
    setState(() {
      _subjectId = value;
      _lessonId = null;
      _selectedQuestionIds.clear();
      _selectedQuestions.clear();
      _query = '';
      _searchController.clear();
    });
    if (value != null) {
      provider.loadQuizQuestionBank(value);
    }
  }

  void _toggleQuestion(QuestionBankItem question) {
    setState(() {
      if (_selectedQuestionIds.contains(question.id)) {
        _selectedQuestionIds.remove(question.id);
        _selectedQuestions.remove(question.id);
      } else {
        _selectedQuestionIds.add(question.id);
        _selectedQuestions[question.id] = question;
      }
    });
  }

  void _removeQuestion(QuestionBankItem question) {
    setState(() {
      _selectedQuestionIds.remove(question.id);
      _selectedQuestions.remove(question.id);
    });
  }

  Future<void> _save(TeacherProvider provider) async {
    if (_subjectId == null || provider.isCreatingTeacherQuiz) return;
    final ok = await provider.createTeacherQuiz(
      title: _titleController.text.trim(),
      subjectId: _subjectId!,
      lessonId: _lessonId,
      questionIds: _selectedQuestionIds.toList(),
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop();
  }
}

enum _AssignmentMode { allVisible, selectedStudents }

enum _DeadlineChoice { hours24, hours48, custom }

class _PublishQuizDialog extends StatefulWidget {
  const _PublishQuizDialog({required this.quiz});

  final TeacherQuizSummary quiz;

  @override
  State<_PublishQuizDialog> createState() => _PublishQuizDialogState();
}

class _PublishQuizDialogState extends State<_PublishQuizDialog> {
  final TextEditingController _maxAttemptsController = TextEditingController(
    text: '1',
  );
  final Set<int> _selectedStudentIds = <int>{};
  _AssignmentMode _mode = _AssignmentMode.allVisible;
  _DeadlineChoice _deadline = _DeadlineChoice.hours24;
  DateTime? _customDueAt;
  String? _localError;

  @override
  void dispose() {
    _maxAttemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.space5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: Consumer<TeacherProvider>(
            builder: (context, provider, _) {
              final subject = _subjectForQuiz(
                provider.assignedSubjects ?? const [],
                widget.quiz,
              );
              final gradeLevel = subject?.gradeLevel;
              final students = _studentsForGrade(
                provider.students ?? const [],
                gradeLevel,
              );
              final canPublish =
                  !provider.isPublishingTeacherQuiz &&
                  gradeLevel != null &&
                  _validMaxAttempts != null &&
                  (_mode == _AssignmentMode.allVisible ||
                      _selectedStudentIds.isNotEmpty) &&
                  (_deadline != _DeadlineChoice.custom || _customDueAt != null);

              return Column(
                children: [
                  _PublishDialogHeader(
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      children: [
                        _PublishQuizSummary(
                          quiz: widget.quiz,
                          gradeLevel: gradeLevel,
                        ),
                        const SizedBox(height: AppTheme.space4),
                        _PublishSection(
                          title: 'طريقة التعيين',
                          child: Column(
                            children: [
                              _ChoiceTile<_AssignmentMode>(
                                key: const Key('teacher_quiz_assign_all_radio'),
                                value: _AssignmentMode.allVisible,
                                selected: _mode == _AssignmentMode.allVisible,
                                enabled: !provider.isPublishingTeacherQuiz,
                                onSelected: _setMode,
                                title: 'كل الطلاب المتاحين',
                                subtitle:
                                    'سيتم تعيين الاختبار لجميع الطلاب المتاحين ضمن نطاق المادة والصف',
                              ),
                              _ChoiceTile<_AssignmentMode>(
                                key: const Key(
                                  'teacher_quiz_assign_selected_radio',
                                ),
                                value: _AssignmentMode.selectedStudents,
                                selected:
                                    _mode == _AssignmentMode.selectedStudents,
                                enabled: !provider.isPublishingTeacherQuiz,
                                onSelected: _setMode,
                                title: 'طلاب محددون',
                                subtitle: 'اختر من الطلاب المتاحين لهذا المعلم',
                              ),
                              if (_mode == _AssignmentMode.selectedStudents)
                                _StudentSelectionPanel(
                                  isLoading:
                                      provider.isLoading &&
                                      provider.students == null,
                                  error: provider.error,
                                  students: students,
                                  selectedIds: _selectedStudentIds,
                                  onToggle: _toggleStudent,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        _PublishSection(
                          title: 'موعد التسليم',
                          child: Column(
                            children: [
                              _ChoiceTile<_DeadlineChoice>(
                                key: const Key('teacher_quiz_due_24_radio'),
                                value: _DeadlineChoice.hours24,
                                selected: _deadline == _DeadlineChoice.hours24,
                                enabled: !provider.isPublishingTeacherQuiz,
                                onSelected: _setDeadline,
                                title: 'خلال 24 ساعة',
                              ),
                              _ChoiceTile<_DeadlineChoice>(
                                key: const Key('teacher_quiz_due_48_radio'),
                                value: _DeadlineChoice.hours48,
                                selected: _deadline == _DeadlineChoice.hours48,
                                enabled: !provider.isPublishingTeacherQuiz,
                                onSelected: _setDeadline,
                                title: 'خلال 48 ساعة',
                              ),
                              _ChoiceTile<_DeadlineChoice>(
                                key: const Key('teacher_quiz_due_custom_radio'),
                                value: _DeadlineChoice.custom,
                                selected: _deadline == _DeadlineChoice.custom,
                                enabled: !provider.isPublishingTeacherQuiz,
                                onSelected: _setDeadline,
                                title: 'تاريخ مخصص',
                              ),
                              if (_deadline == _DeadlineChoice.custom)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: OutlinedButton.icon(
                                    key: const Key(
                                      'teacher_quiz_custom_due_button',
                                    ),
                                    onPressed: provider.isPublishingTeacherQuiz
                                        ? null
                                        : _pickCustomDueDate,
                                    icon: const Icon(
                                      Icons.calendar_month_rounded,
                                    ),
                                    label: Text(
                                      _customDueAt == null
                                          ? 'اختيار التاريخ'
                                          : _formatDate(
                                              _customDueAt!.toIso8601String(),
                                            ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        _PublishSection(
                          title: 'عدد المحاولات',
                          child: TextField(
                            key: const Key('teacher_quiz_max_attempts_field'),
                            controller: _maxAttemptsController,
                            enabled: !provider.isPublishingTeacherQuiz,
                            keyboardType: TextInputType.number,
                            onChanged: (_) =>
                                setState(() => _localError = null),
                            decoration: const InputDecoration(
                              labelText: 'الحد الأقصى للمحاولات',
                              prefixIcon: Icon(Icons.repeat_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PublishDialogActions(
                    canPublish: canPublish,
                    isPublishing: provider.isPublishingTeacherQuiz,
                    error: _localError ?? provider.publishTeacherQuizError,
                    onCancel: () => Navigator.of(context).pop(),
                    onPublish: () => _publish(provider, gradeLevel),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  int? get _validMaxAttempts {
    final value = int.tryParse(_maxAttemptsController.text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  DateTime? get _dueAt {
    final now = DateTime.now();
    return switch (_deadline) {
      _DeadlineChoice.hours24 => now.add(const Duration(hours: 24)),
      _DeadlineChoice.hours48 => now.add(const Duration(hours: 48)),
      _DeadlineChoice.custom => _customDueAt,
    };
  }

  void _setMode(_AssignmentMode? value) {
    if (value == null) return;
    setState(() {
      _mode = value;
      _localError = null;
    });
    if (value == _AssignmentMode.selectedStudents) {
      context.read<TeacherProvider>().loadStudents();
    }
  }

  void _setDeadline(_DeadlineChoice? value) {
    if (value == null) return;
    setState(() {
      _deadline = value;
      _localError = null;
    });
  }

  void _toggleStudent(int studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
      _localError = null;
    });
  }

  Future<void> _pickCustomDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _customDueAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
      _localError = null;
    });
  }

  Future<void> _publish(TeacherProvider provider, int? gradeLevel) async {
    if (gradeLevel == null) {
      setState(() => _localError = 'تعذر تحديد صف المادة لهذا الاختبار');
      return;
    }
    final maxAttempts = _validMaxAttempts;
    if (maxAttempts == null) {
      setState(() => _localError = 'أدخل عدد محاولات صحيح');
      return;
    }
    if (_mode == _AssignmentMode.selectedStudents &&
        _selectedStudentIds.isEmpty) {
      setState(() => _localError = 'اختر طالبًا واحدًا على الأقل');
      return;
    }
    final dueAt = _dueAt;
    if (dueAt == null) {
      setState(() => _localError = 'اختر موعد التسليم');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await provider.publishTeacherQuiz(
      quizId: widget.quiz.id,
      gradeLevel: gradeLevel,
      dueAt: dueAt,
      maxAttempts: maxAttempts,
      studentIds: _mode == _AssignmentMode.selectedStudents
          ? _selectedStudentIds.toList()
          : null,
    );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('تم نشر الاختبار بنجاح')),
      );
    }
  }
}

class _PublishDialogHeader extends StatelessWidget {
  const _PublishDialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space4,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'نشر الاختبار للطلاب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _PublishQuizSummary extends StatelessWidget {
  const _PublishQuizSummary({required this.quiz, required this.gradeLevel});

  final TeacherQuizSummary quiz;
  final int? gradeLevel;

  @override
  Widget build(BuildContext context) {
    final grade = gradeLevel;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quiz.title.isEmpty ? 'اختبار بدون عنوان' : quiz.title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _InfoChip(
                icon: Icons.menu_book_rounded,
                label: _fallback(quiz.subjectName),
              ),
              _InfoChip(
                icon: Icons.school_rounded,
                label: grade == null ? 'الصف غير متوفر' : _gradeLabel(grade),
              ),
              _InfoChip(
                icon: Icons.help_outline_rounded,
                label: '${quiz.questionCount} سؤال',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublishSection extends StatelessWidget {
  const _PublishSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          child,
        ],
      ),
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    required this.title,
    this.subtitle,
  });

  final T value;
  final bool selected;
  final bool enabled;
  final ValueChanged<T?> onSelected;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.primaryTerracotta : AppTheme.textGray;
    return InkWell(
      onTap: enabled ? () => onSelected(value) : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryTerracotta.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: selected
                ? AppTheme.primaryTerracotta.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: enabled ? color : AppTheme.textLight,
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w900,
                      color: enabled ? AppTheme.textDark : AppTheme.textLight,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: enabled ? AppTheme.textGray : AppTheme.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentSelectionPanel extends StatelessWidget {
  const _StudentSelectionPanel({
    required this.isLoading,
    required this.error,
    required this.students,
    required this.selectedIds,
    required this.onToggle,
  });

  final bool isLoading;
  final String? error;
  final List<ClassStudentSummary> students;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.space4),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.space3),
        child: Text(
          error!,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppTheme.error,
          ),
        ),
      );
    }
    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.space3),
        child: Text(
          'لا توجد بيانات طلاب متاحة لهذا الصف',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppTheme.textGray,
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return CheckboxListTile(
            value: selectedIds.contains(student.studentId),
            onChanged: (_) => onToggle(student.studentId),
            title: Text(student.fullName),
            subtitle: Text(_gradeLabel(student.gradeLevel)),
          );
        },
      ),
    );
  }
}

class _PublishDialogActions extends StatelessWidget {
  const _PublishDialogActions({
    required this.canPublish,
    required this.isPublishing,
    required this.error,
    required this.onCancel,
    required this.onPublish,
  });

  final bool canPublish;
  final bool isPublishing;
  final String? error;
  final VoidCallback onCancel;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              error ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: isPublishing ? null : onCancel,
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: AppTheme.space3),
          FilledButton.icon(
            key: const Key('teacher_quiz_publish_submit'),
            onPressed: canPublish ? onPublish : null,
            icon: isPublishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(isPublishing ? 'جار النشر' : 'نشر الاختبار'),
          ),
        ],
      ),
    );
  }
}

class _QuizAssignmentsDialog extends StatefulWidget {
  const _QuizAssignmentsDialog({required this.quiz});

  final TeacherQuizSummary quiz;

  @override
  State<_QuizAssignmentsDialog> createState() => _QuizAssignmentsDialogState();
}

class _QuizAssignmentsDialogState extends State<_QuizAssignmentsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeacherProvider>().loadQuizAssignments(widget.quiz.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.space5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
          child: Consumer<TeacherProvider>(
            builder: (context, provider, _) {
              final isLoading = provider.isLoadingQuizAssignments(
                widget.quiz.id,
              );
              final error = provider.quizAssignmentsErrorFor(widget.quiz.id);
              final assignments =
                  provider.quizAssignmentsFor(widget.quiz.id) ??
                  const <TeacherQuizAssignment>[];

              return Column(
                children: [
                  _AssignmentsDialogHeader(
                    title: widget.quiz.title,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space5),
                      child: _AssignmentsBody(
                        isLoading: isLoading,
                        error: error,
                        assignments: assignments,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AssignmentsDialogHeader extends StatelessWidget {
  const _AssignmentsDialogHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space4,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعيينات الاختبار',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  title.isEmpty ? 'اختبار بدون عنوان' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsBody extends StatelessWidget {
  const _AssignmentsBody({
    required this.isLoading,
    required this.error,
    required this.assignments,
  });

  final bool isLoading;
  final String? error;
  final List<TeacherQuizAssignment> assignments;

  @override
  Widget build(BuildContext context) {
    if (isLoading && assignments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && assignments.isEmpty) {
      return _InlineEmptyState(
        icon: Icons.error_outline_rounded,
        message: error!,
      );
    }
    if (assignments.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.inbox_rounded,
        message: 'لا توجد تعيينات لهذا الاختبار',
      );
    }
    return ListView.separated(
      itemCount: assignments.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.space4),
      itemBuilder: (context, index) {
        return _AssignmentCard(assignment: assignments[index]);
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});

  final TeacherQuizAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final results = provider.assignmentResultsFor(assignment.assignmentId);
    final isLoadingResults = provider.isLoadingAssignmentResults(
      assignment.assignmentId,
    );
    final resultsError = provider.assignmentResultsErrorFor(
      assignment.assignmentId,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _InfoChip(
                icon: Icons.group_rounded,
                label: '${assignment.assignedCount} طالب',
              ),
              _InfoChip(
                icon: Icons.publish_rounded,
                label: 'نشر: ${_formatDate(assignment.publishedAt)}',
              ),
              _InfoChip(
                icon: Icons.event_rounded,
                label: 'التسليم: ${_formatDate(assignment.dueAt)}',
              ),
              _InfoChip(
                icon: Icons.repeat_rounded,
                label: 'المحاولات: ${assignment.maxAttempts ?? 1}',
              ),
              _InfoChip(
                icon: Icons.verified_rounded,
                label: _assignmentStatusLabel(assignment.status),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: isLoadingResults
                  ? null
                  : () => context.read<TeacherProvider>().loadAssignmentResults(
                      assignment.assignmentId,
                    ),
              icon: isLoadingResults
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_rounded),
              label: const Text('عرض النتائج'),
            ),
          ),
          if (resultsError != null) ...[
            const SizedBox(height: AppTheme.space2),
            Text(
              resultsError,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ],
          if (results != null) ...[
            const SizedBox(height: AppTheme.space3),
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space2,
              children: [
                _InfoChip(
                  icon: Icons.groups_rounded,
                  label: 'عدد الطلاب ${results.assignedCount}',
                ),
                _InfoChip(
                  icon: Icons.check_circle_rounded,
                  label: 'المكتملون ${results.completedCount}',
                ),
                _InfoChip(
                  icon: Icons.percent_rounded,
                  label: 'متوسط النتيجة ${_scoreLabel(results.averageScore)}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space4,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء اختبار جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: AppTheme.space1),
                Text(
                  'اختر الأسئلة من بنك الأسئلة الخاص بموادك',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _CreateControls extends StatelessWidget {
  const _CreateControls({
    required this.titleController,
    required this.subjects,
    required this.lessons,
    required this.subjectId,
    required this.lessonId,
    required this.searchController,
    required this.onSubjectChanged,
    required this.onLessonChanged,
    required this.onSearchChanged,
    required this.onTitleChanged,
  });

  final TextEditingController titleController;
  final List<SubjectSummary> subjects;
  final List<LessonSummary> lessons;
  final int? subjectId;
  final int? lessonId;
  final TextEditingController searchController;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onLessonChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTitleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('teacher_quiz_title_field'),
            controller: titleController,
            onChanged: onTitleChanged,
            decoration: const InputDecoration(
              labelText: 'عنوان الاختبار',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          DropdownButtonFormField<int>(
            key: const Key('teacher_quiz_subject_dropdown'),
            initialValue: subjectId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'المادة',
              prefixIcon: Icon(Icons.menu_book_rounded),
            ),
            items: [
              for (final subject in subjects)
                DropdownMenuItem(
                  value: subject.id,
                  child: Text(
                    '${subject.name} - ${_gradeLabel(subject.gradeLevel)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: subjects.isEmpty ? null : onSubjectChanged,
          ),
          const SizedBox(height: AppTheme.space4),
          DropdownButtonFormField<int?>(
            key: ValueKey('teacher_quiz_lesson_dropdown_$subjectId'),
            initialValue: lessonId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'الدرس',
              prefixIcon: Icon(Icons.filter_list_rounded),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('كل الدروس'),
              ),
              for (final lesson in lessons)
                DropdownMenuItem<int?>(
                  value: lesson.id,
                  child: Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: subjectId == null ? null : onLessonChanged,
          ),
          const SizedBox(height: AppTheme.space4),
          TextField(
            key: const Key('teacher_quiz_question_search_field'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'بحث في الأسئلة',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPickerPanel extends StatelessWidget {
  const _QuestionPickerPanel({
    required this.isLoading,
    required this.error,
    required this.subjectSelected,
    required this.questions,
    required this.selectedQuestionIds,
    required this.onToggle,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final bool subjectSelected;
  final List<QuestionBankItem> questions;
  final Set<int> selectedQuestionIds;
  final ValueChanged<QuestionBankItem> onToggle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الأسئلة المتاحة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(height: 430, child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!subjectSelected) {
      return const _InlineEmptyState(
        icon: Icons.menu_book_rounded,
        message: 'اختر مادة لعرض أسئلتها',
      );
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (questions.isEmpty) {
      return const _InlineEmptyState(
        icon: Icons.inbox_rounded,
        message: 'لا توجد أسئلة متاحة لهذه المادة',
      );
    }
    return ListView.separated(
      itemCount: questions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.space3),
      itemBuilder: (context, index) {
        final question = questions[index];
        final selected = selectedQuestionIds.contains(question.id);
        return _QuestionRow(
          question: question,
          selected: selected,
          onPressed: () => onToggle(question),
        );
      },
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.selected,
    required this.onPressed,
  });

  final QuestionBankItem question;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: selected ? AppTheme.infoContainer : AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: selected ? AppTheme.info : AppTheme.surfaceMuted,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: selected ? 'إزالة السؤال' : 'إضافة السؤال',
            onPressed: onPressed,
            icon: Icon(
              selected ? Icons.remove_circle_rounded : Icons.add_circle_rounded,
              color: selected ? AppTheme.primaryRed : AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Wrap(
                  spacing: AppTheme.space2,
                  runSpacing: AppTheme.space2,
                  children: [
                    _InfoChip(
                      icon: Icons.menu_book_rounded,
                      label: _fallback(question.lessonTitle),
                    ),
                    _InfoChip(
                      icon: Icons.category_rounded,
                      label: _questionTypeLabel(question.type),
                    ),
                    _InfoChip(
                      icon: Icons.stacked_bar_chart_rounded,
                      label: 'مستوى ${question.difficultyLevel}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedQuestionsPanel extends StatelessWidget {
  const _SelectedQuestionsPanel({
    required this.questions,
    required this.onRemove,
  });

  final List<QuestionBankItem> questions;
  final ValueChanged<QuestionBankItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الأسئلة المختارة (${questions.length})',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            height: 430,
            child: questions.isEmpty
                ? const _InlineEmptyState(
                    icon: Icons.playlist_add_rounded,
                    message: 'لم تختر أي سؤال بعد',
                  )
                : ListView.separated(
                    itemCount: questions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AppTheme.surfaceMuted),
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'إزالة',
                          onPressed: () => onRemove(question),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.canSave,
    required this.isSaving,
    required this.error,
    required this.onCancel,
    required this.onSave,
  });

  final bool canSave;
  final bool isSaving;
  final String? error;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              error ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: isSaving ? null : onCancel,
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: AppTheme.space3),
          FilledButton.icon(
            onPressed: canSave ? onSave : null,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(isSaving ? 'جار الحفظ' : 'حفظ الاختبار'),
          ),
        ],
      ),
    );
  }
}

class _EmptyQuizzesPanel extends StatelessWidget {
  const _EmptyQuizzesPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: _panelDecoration(),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: AppTheme.textLight),
          SizedBox(height: AppTheme.space4),
          Text(
            'لا توجد اختبارات بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
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

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppTheme.textLight),
          const SizedBox(height: AppTheme.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

enum _QuizUiStatus { draft, published, archived }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _QuizUiStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      _QuizUiStatus.draft => (
        'مسودة',
        AppTheme.primaryOrange,
        Icons.edit_note_rounded,
      ),
      _QuizUiStatus.published => (
        'منشور',
        AppTheme.primaryGreen,
        Icons.verified_rounded,
      ),
      _QuizUiStatus.archived => (
        'مؤرشف',
        AppTheme.textGray,
        Icons.archive_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.space1),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textGray),
          const SizedBox(width: AppTheme.space1),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Icon(icon, color: color, size: 24),
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

String _fallback(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'غير متوفر';
  }
  return value;
}

String _formatDate(String? value) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) return 'غير متوفر';
  return '${parsed.year}/${_two(parsed.month)}/${_two(parsed.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');

SubjectSummary? _subjectForQuiz(
  List<SubjectSummary> subjects,
  TeacherQuizSummary quiz,
) {
  for (final subject in subjects) {
    if (subject.id == quiz.subjectId) return subject;
  }
  return null;
}

List<ClassStudentSummary> _studentsForGrade(
  List<ClassStudentSummary> students,
  int? gradeLevel,
) {
  if (gradeLevel == null) return students;
  return students.where((student) => student.gradeLevel == gradeLevel).toList();
}

String _assignmentStatusLabel(String status) {
  return switch (status.toUpperCase()) {
    'PUBLISHED' => 'منشور',
    'CLOSED' => 'مغلق',
    _ => status,
  };
}

String _scoreLabel(double? value) {
  if (value == null) return 'غير متوفر';
  return '${value.toStringAsFixed(1)}%';
}

String _questionTypeLabel(String type) {
  return switch (type) {
    'MCQ' => 'اختيار من متعدد',
    'TRUE_FALSE' => 'صح أو خطأ',
    'SHORT_ANSWER' => 'إجابة قصيرة',
    'FILL_BLANK' => 'إكمال فراغ',
    'ORDERING' => 'ترتيب',
    'PRONUNCIATION' => 'نطق',
    'TRACING' => 'تتبع',
    _ => type,
  };
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

extension on String {
  bool get isNotBlank => trim().isNotEmpty;
}
