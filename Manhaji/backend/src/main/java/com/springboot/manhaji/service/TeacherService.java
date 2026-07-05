package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.request.TeacherQuizCreateRequest;
import com.springboot.manhaji.dto.response.ClassStudentSummary;
import com.springboot.manhaji.dto.response.LessonSummary;
import com.springboot.manhaji.dto.response.QuestionBankItem;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.SubjectMasterySummary;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.TeacherDashboardResponse;
import com.springboot.manhaji.dto.response.TeacherMistakeAnalyticsResponse;
import com.springboot.manhaji.dto.response.TeacherMistakeRowResponse;
import com.springboot.manhaji.dto.response.TeacherMistakeSummaryResponse;
import com.springboot.manhaji.dto.response.TeacherQuizDetailResponse;
import com.springboot.manhaji.dto.response.TeacherQuizSummaryResponse;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.StudentResponse;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.TeacherAssignment;
import com.springboot.manhaji.entity.enums.QuizStatus;
import com.springboot.manhaji.entity.enums.QuizType;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.QuizRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherAssignmentRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import com.springboot.manhaji.infrastructure.Messages;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TeacherService {

    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final AttemptRepository attemptRepository;
    private final StudentResponseRepository studentResponseRepository;
    private final SubjectRepository subjectRepository;
    private final QuestionRepository questionRepository;
    private final QuizRepository quizRepository;
    private final QuestionBankMapper questionBankMapper;
    private final ProgressMetrics metrics;
    private final Messages messages;

    public TeacherDashboardResponse getDashboard(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));

        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> scopes = buildScopes(teacher, assignments);
        List<Student> students = loadStudentsForTeacher(scopes);
        Map<Long, List<Progress>> progressByStudent =
                loadProgressByStudent(students, subjectIdsForScopes(scopes));
        List<ClassStudentSummary> summaries = students.stream()
                .map(s -> buildSummary(
                        s,
                        progressForStudentScope(
                                s,
                                scopes,
                                progressByStudent.getOrDefault(s.getId(), Collections.emptyList()))))
                .sorted(Comparator.comparing(ClassStudentSummary::getTotalPoints,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();

        LocalDateTime weekAgo = LocalDateTime.now().minusDays(7);
        int activeThisWeek = (int) students.stream()
                .filter(s -> s.getLastLoginAt() != null && s.getLastLoginAt().isAfter(weekAgo))
                .count();

        int lessonsCompletedTotal = summaries.stream()
                .mapToInt(s -> s.getLessonsCompleted() == null ? 0 : s.getLessonsCompleted())
                .sum();

        double avgMastery = summaries.stream()
                .filter(s -> s.getAverageMastery() != null)
                .mapToDouble(ClassStudentSummary::getAverageMastery)
                .average()
                .orElse(0.0);

        List<ClassStudentSummary> topStudents = summaries.stream()
                .limit(5)
                .toList();

        return TeacherDashboardResponse.builder()
                .teacherId(teacher.getId())
                .fullName(teacher.getFullName())
                .department(teacher.getDepartment())
                .assignedGrade(teacher.getAssignedGrade())
                .totalStudents(students.size())
                .activeThisWeek(activeThisWeek)
                .lessonsCompletedTotal(lessonsCompletedTotal)
                .averageMasteryAcrossClass(ProgressMetrics.round2(avgMastery))
                .topStudents(topStudents)
                .build();
    }

    public List<ClassStudentSummary> getStudents(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> scopes = buildScopes(teacher, assignments);
        List<Student> students = loadStudentsForTeacher(scopes);
        Map<Long, List<Progress>> progressByStudent =
                loadProgressByStudent(students, subjectIdsForScopes(scopes));
        return students.stream()
                .map(s -> buildSummary(
                        s,
                        progressForStudentScope(
                                s,
                                scopes,
                                progressByStudent.getOrDefault(s.getId(), Collections.emptyList()))))
                .sorted(Comparator.comparing(ClassStudentSummary::getFullName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }

    /**
     * Post-review fix (2026-05-24): the previous code did one
     * {@code progressRepository.findByStudentId} query per student. Now we
     * pull every Progress row for the student set in a single
     * subject-scoped bulk query and group by studentId in memory.
     */
    private Map<Long, List<Progress>> loadProgressByStudent(
            List<Student> students,
            List<Long> subjectIds) {
        if (students.isEmpty() || subjectIds.isEmpty()) return Collections.emptyMap();
        List<Long> ids = students.stream().map(Student::getId).toList();
        return progressRepository.findByStudentIdsAndSubjectIds(ids, subjectIds).stream()
                .collect(Collectors.groupingBy(p -> p.getStudent().getId()));
    }

    public StudentDetailResponse getStudentDetail(Long teacherId, Long studentId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> studentScopes = scopesForStudent(
                student,
                buildScopes(teacher, assignments));
        if (studentScopes.isEmpty()) {
            throw new UnauthorizedException(messages.get("error.teacher.studentNotAccessible"));
        }

        List<Long> subjectIds = subjectIdsForScopes(studentScopes);
        List<Progress> progressRecords = progressRepository
                .findByStudentIdAndSubjectIds(studentId, subjectIds);
        List<Attempt> attempts = attemptRepository
                .findByStudentIdAndSubjectIdsOrderByCreatedAtDesc(studentId, subjectIds);

        List<SubjectMasterySummary> subjectBreakdown = metrics.buildSubjectBreakdown(
                student,
                progressRecords,
                subjectsForScopes(assignments, studentScopes));

        return StudentDetailResponse.builder()
                .studentId(student.getId())
                .fullName(student.getFullName())
                .email(student.getEmail())
                .phone(student.getPhone())
                .gradeLevel(student.getGradeLevel())
                .totalPoints(student.getTotalPoints())
                .currentStreak(student.getCurrentStreak())
                .lastLoginAt(student.getLastLoginAt())
                .createdAt(student.getCreatedAt())
                .lessonsCompleted(metrics.countCompleted(progressRecords))
                .lessonsInProgress(metrics.countInProgress(progressRecords))
                .overallMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .totalAttempts(attempts.size())
                .averageScore(ProgressMetrics.round2(metrics.averageGradedScore(attempts)))
                .subjectBreakdown(subjectBreakdown)
                .build();
    }

    public TeacherMistakeAnalyticsResponse getMistakeAnalytics(
            Long teacherId,
            Long subjectId,
            Long lessonId,
            Long studentId,
            Integer limit) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));

        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        List<AssignmentScope> scopes = buildScopes(teacher, assignments);
        if (scopes.isEmpty()) {
            return emptyMistakeAnalytics();
        }

        List<Long> scopedSubjectIds = subjectIdsForScopes(scopes);
        if (subjectId != null && !scopedSubjectIds.contains(subjectId)) {
            return emptyMistakeAnalytics();
        }

        List<Student> visibleStudents = loadStudentsForTeacher(scopes);
        if (visibleStudents.isEmpty()) {
            return emptyMistakeAnalytics();
        }

        Set<Long> visibleStudentIds = visibleStudents.stream()
                .map(Student::getId)
                .collect(Collectors.toSet());
        if (studentId != null && !visibleStudentIds.contains(studentId)) {
            return emptyMistakeAnalytics();
        }

        List<Long> queryStudentIds = studentId == null
                ? visibleStudents.stream().map(Student::getId).toList()
                : List.of(studentId);
        List<Long> querySubjectIds = subjectId == null ? scopedSubjectIds : List.of(subjectId);

        List<StudentResponse> scopedResponses = studentResponseRepository
                .findIncorrectByStudentIdsAndSubjectIds(
                        queryStudentIds, querySubjectIds, subjectId, lessonId, studentId)
                .stream()
                .filter(response -> responseMatchesExactScope(response, scopes))
                .filter(response -> lessonId == null
                        || lessonId.equals(lessonIdFor(response)))
                .filter(response -> subjectId == null
                        || subjectId.equals(subjectIdFor(response)))
                .filter(response -> studentId == null
                        || studentId.equals(studentIdFor(response)))
                .toList();

        Map<Long, Set<Long>> studentsByQuestion = new HashMap<>();
        for (StudentResponse response : scopedResponses) {
            Long questionId = questionIdFor(response);
            Long rowStudentId = studentIdFor(response);
            if (questionId != null && rowStudentId != null) {
                studentsByQuestion
                        .computeIfAbsent(questionId, ignored -> new HashSet<>())
                        .add(rowStudentId);
            }
        }

        Map<MistakeKey, MistakeAccumulator> grouped = new LinkedHashMap<>();
        for (StudentResponse response : scopedResponses) {
            MistakeKey key = new MistakeKey(
                    studentIdFor(response),
                    questionIdFor(response),
                    normalizedAnswerKey(studentAnswerFor(response)));
            grouped.computeIfAbsent(key, ignored -> new MistakeAccumulator(response))
                    .add(response);
        }

        int rowLimit = sanitizeLimit(limit);
        List<TeacherMistakeRowResponse> rows = grouped.values().stream()
                .map(accumulator -> accumulator.toResponse(studentsByQuestion))
                .sorted(Comparator
                        .comparing(
                                TeacherMistakeRowResponse::getLastMistakeAt,
                                Comparator.nullsLast(Comparator.reverseOrder()))
                        .thenComparing(
                                TeacherMistakeRowResponse::getMistakeCount,
                                Comparator.reverseOrder()))
                .limit(rowLimit)
                .toList();

        return TeacherMistakeAnalyticsResponse.builder()
                .summary(buildMistakeSummary(scopedResponses))
                .mistakes(rows)
                .build();
    }

    // ==================== Question Bank (FR-9) ====================

    /**
     * Lists only active subject assignments for this teacher.
     */
    public List<SubjectSummary> getAssignedSubjects(Long teacherId) {
        teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));

        List<Subject> subjects = teacherAssignmentRepository
                .findActiveByTeacherIdWithSubject(teacherId)
                .stream()
                .map(TeacherAssignment::getSubject)
                .toList();

        return subjects.stream()
                .sorted(Comparator.comparing(
                        Subject::getName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .map(questionBankMapper::toSubjectSummary)
                .toList();
    }

    /**
     * Returns questions belonging to the given subject, filtered by optional
     * difficulty + lesson. Access requires an active teacher-subject assignment.
     */
    public QuestionBankResponse getQuestionsForSubject(
            Long teacherId,
            Long subjectId,
            Integer difficultyLevel,
            Long lessonId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));

        if (!isAssignedSubject(teacher, subject.getId())) {
            throw new UnauthorizedException(messages.get("error.teacher.subjectNotAssigned"));
        }

        List<Question> allForSubject = questionRepository.findAllBySubjectIdWithLesson(subjectId);
        List<LessonSummary> lessons = questionBankMapper.collectLessonFilters(allForSubject);

        List<QuestionBankItem> filtered = allForSubject.stream()
                .filter(q -> difficultyLevel == null
                        || difficultyLevel.equals(q.getDifficultyLevel()))
                .filter(q -> lessonId == null
                        || (q.getLesson() != null && lessonId.equals(q.getLesson().getId())))
                .map(questionBankMapper::toQuestionItem)
                .toList();

        return QuestionBankResponse.builder()
                .subjectId(subject.getId())
                .subjectName(subject.getName())
                .gradeLevel(subject.getGradeLevel())
                .lessons(lessons)
                .questions(filtered)
                .totalQuestionsInSubject(allForSubject.size())
                .build();
    }

    // ==================== Teacher Quiz Creation (Phase 8D) ====================

    public List<TeacherQuizSummaryResponse> getTeacherQuizzes(Long teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        List<Long> subjectIds = assignedSubjectIds(loadActiveAssignments(teacher));
        if (subjectIds.isEmpty()) {
            return Collections.emptyList();
        }

        return quizRepository.findTeacherVisibleBySubjectIds(subjectIds).stream()
                .filter(quiz -> quiz.getGeneratedForStudentId() == null)
                .filter(quiz -> subjectIds.contains(subjectIdFor(quiz)))
                .map(this::toTeacherQuizSummary)
                .toList();
    }

    @Transactional
    public TeacherQuizDetailResponse createTeacherQuiz(
            Long teacherId,
            TeacherQuizCreateRequest request) {
        if (request == null) {
            throw new BadRequestException("Quiz request is required");
        }
        String title = request.getTitle() == null ? "" : request.getTitle().trim();
        if (title.isBlank()) {
            throw new BadRequestException("Quiz title is required");
        }

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        List<TeacherAssignment> assignments = loadActiveAssignments(teacher);
        Subject subject = requireAssignedSubject(assignments, request.getSubjectId());
        List<Question> questions = validateTeacherQuizQuestions(request, subject.getId());

        Quiz quiz = new Quiz();
        quiz.setTitle(title);
        quiz.setGamified(false);
        quiz.setGeneratedFromLesson(false);
        quiz.setQuizType(QuizType.TEACHER_ASSIGNED);
        quiz.setLesson(null);
        quiz.setSubject(subject);
        quiz.setCreatedByTeacher(teacher);
        quiz.setStatus(QuizStatus.DRAFT);
        quiz.setGeneratedForStudentId(null);
        quiz.setQuestions(new ArrayList<>(questions));

        return toTeacherQuizDetail(quizRepository.save(quiz));
    }

    public TeacherQuizDetailResponse getTeacherQuiz(Long teacherId, Long quizId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        List<Long> subjectIds = assignedSubjectIds(loadActiveAssignments(teacher));
        if (subjectIds.isEmpty()) {
            throw new UnauthorizedException(messages.get("error.teacher.subjectNotAssigned"));
        }

        Quiz quiz = quizRepository.findByIdWithTeacherDetails(quizId)
                .orElseThrow(() -> new ResourceNotFoundException("Quiz", quizId));
        Long subjectId = subjectIdFor(quiz);
        if (quiz.getGeneratedForStudentId() != null
                || subjectId == null
                || !subjectIds.contains(subjectId)) {
            throw new UnauthorizedException(messages.get("error.teacher.subjectNotAssigned"));
        }

        return toTeacherQuizDetail(quiz);
    }

    private List<TeacherAssignment> loadActiveAssignments(Teacher teacher) {
        return teacherAssignmentRepository.findActiveByTeacherIdWithSubject(teacher.getId());
    }

    private TeacherMistakeAnalyticsResponse emptyMistakeAnalytics() {
        return TeacherMistakeAnalyticsResponse.builder()
                .summary(TeacherMistakeSummaryResponse.builder()
                        .totalMistakes(0)
                        .affectedStudents(0)
                        .build())
                .mistakes(Collections.emptyList())
                .build();
    }

    private boolean isAssignedSubject(Teacher teacher, Long subjectId) {
        return loadActiveAssignments(teacher).stream()
                .map(TeacherAssignment::getSubject)
                .anyMatch(subject -> subject != null && subjectId.equals(subject.getId()));
    }

    private List<Long> assignedSubjectIds(List<TeacherAssignment> assignments) {
        return assignments.stream()
                .map(TeacherAssignment::getSubject)
                .filter(subject -> subject != null && subject.getId() != null)
                .map(Subject::getId)
                .distinct()
                .toList();
    }

    private Subject requireAssignedSubject(
            List<TeacherAssignment> assignments,
            Long subjectId) {
        if (assignments.isEmpty() || subjectId == null) {
            throw new UnauthorizedException(messages.get("error.teacher.subjectNotAssigned"));
        }
        return assignments.stream()
                .map(TeacherAssignment::getSubject)
                .filter(subject -> subject != null && subjectId.equals(subject.getId()))
                .findFirst()
                .orElseThrow(() -> new UnauthorizedException(
                        messages.get("error.teacher.subjectNotAssigned")));
    }

    private List<Question> validateTeacherQuizQuestions(
            TeacherQuizCreateRequest request,
            Long subjectId) {
        List<Long> requested = request.getQuestionIds();
        if (requested == null || requested.isEmpty()) {
            throw new BadRequestException("Question ids are required");
        }
        for (Long questionId : requested) {
            if (questionId == null) {
                throw new BadRequestException("Question ids are required");
            }
        }

        List<Long> uniqueIds = new ArrayList<>(new LinkedHashSet<>(requested));
        Map<Long, Question> foundById = questionRepository.findAllById(uniqueIds)
                .stream()
                .collect(Collectors.toMap(
                        Question::getId,
                        question -> question,
                        (first, ignored) -> first));
        List<Long> missing = uniqueIds.stream()
                .filter(id -> !foundById.containsKey(id))
                .toList();
        if (!missing.isEmpty()) {
            throw new BadRequestException("Invalid question ids: " + missing);
        }

        List<Question> ordered = uniqueIds.stream()
                .map(foundById::get)
                .toList();
        for (Question question : ordered) {
            if (!subjectId.equals(subjectIdFor(question))) {
                throw new UnauthorizedException(messages.get("error.teacher.subjectNotAssigned"));
            }
            Long lessonId = request.getLessonId();
            if (lessonId != null && !lessonId.equals(lessonIdFor(question))) {
                throw new BadRequestException("Question does not belong to selected lesson");
            }
        }
        return ordered;
    }

    private TeacherQuizSummaryResponse toTeacherQuizSummary(Quiz quiz) {
        Subject subject = subjectFor(quiz);
        Lesson lesson = lessonFor(quiz);
        return TeacherQuizSummaryResponse.builder()
                .id(quiz.getId())
                .title(quiz.getTitle())
                .subjectId(subject == null ? null : subject.getId())
                .subjectName(subject == null ? null : subject.getName())
                .lessonId(lesson == null ? null : lesson.getId())
                .lessonTitle(lesson == null ? null : lesson.getTitle())
                .questionCount(quiz.getQuestions() == null ? 0 : quiz.getQuestions().size())
                .createdAt(quiz.getCreatedAt())
                .build();
    }

    private TeacherQuizDetailResponse toTeacherQuizDetail(Quiz quiz) {
        TeacherQuizSummaryResponse summary = toTeacherQuizSummary(quiz);
        List<QuestionBankItem> questions = quiz.getQuestions() == null
                ? Collections.emptyList()
                : quiz.getQuestions().stream()
                        .sorted(Comparator.comparing(
                                Question::getId,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                        .map(questionBankMapper::toQuestionItem)
                        .toList();
        return TeacherQuizDetailResponse.builder()
                .id(summary.getId())
                .title(summary.getTitle())
                .subjectId(summary.getSubjectId())
                .subjectName(summary.getSubjectName())
                .lessonId(summary.getLessonId())
                .lessonTitle(summary.getLessonTitle())
                .questionCount(summary.getQuestionCount())
                .createdAt(summary.getCreatedAt())
                .questions(questions)
                .build();
    }

    private Subject subjectFor(Quiz quiz) {
        if (quiz.getSubject() != null) {
            return quiz.getSubject();
        }
        if (quiz.getLesson() != null && quiz.getLesson().getSubject() != null) {
            return quiz.getLesson().getSubject();
        }
        if (quiz.getQuestions() == null) {
            return null;
        }
        return quiz.getQuestions().stream()
                .map(this::subjectFor)
                .filter(subject -> subject != null)
                .findFirst()
                .orElse(null);
    }

    private Subject subjectFor(Question question) {
        if (question == null || question.getLesson() == null) {
            return null;
        }
        return question.getLesson().getSubject();
    }

    private Long subjectIdFor(Quiz quiz) {
        Subject subject = subjectFor(quiz);
        return subject == null ? null : subject.getId();
    }

    private Long subjectIdFor(Question question) {
        Subject subject = subjectFor(question);
        return subject == null ? null : subject.getId();
    }

    private Lesson lessonFor(Quiz quiz) {
        if (quiz.getLesson() != null) {
            return quiz.getLesson();
        }
        if (quiz.getQuestions() == null || quiz.getQuestions().isEmpty()) {
            return null;
        }
        Lesson firstLesson = null;
        for (Question question : quiz.getQuestions()) {
            Lesson lesson = question.getLesson();
            if (lesson == null) {
                return null;
            }
            if (firstLesson == null) {
                firstLesson = lesson;
            } else if (!firstLesson.getId().equals(lesson.getId())) {
                return null;
            }
        }
        return firstLesson;
    }

    private Long lessonIdFor(Question question) {
        Lesson lesson = question == null ? null : question.getLesson();
        return lesson == null ? null : lesson.getId();
    }

    private List<Student> loadStudentsForTeacher(List<AssignmentScope> scopes) {
        if (scopes.isEmpty()) {
            return Collections.emptyList();
        }

        List<Long> schoolIds = scopes.stream()
                .map(AssignmentScope::schoolId)
                .distinct()
                .toList();
        List<Integer> gradeLevels = scopes.stream()
                .map(AssignmentScope::gradeLevel)
                .distinct()
                .toList();

        Map<Long, Student> visible = new LinkedHashMap<>();
        for (Student student : studentRepository.findBySchoolIdInAndGradeLevelIn(schoolIds, gradeLevels)) {
            if (matchesAnyScope(student, scopes)) {
                visible.putIfAbsent(student.getId(), student);
            }
        }
        return visible.values().stream().toList();
    }

    private List<AssignmentScope> buildScopes(
            Teacher teacher,
            List<TeacherAssignment> assignments) {
        return assignments.stream()
                .map(assignment -> new AssignmentScope(
                        assignment.getGradeLevel(),
                        effectiveSchoolId(teacher, assignment),
                        assignment.getSubject() == null ? null : assignment.getSubject().getId()))
                .filter(AssignmentScope::isUsable)
                .distinct()
                .toList();
    }

    private Long effectiveSchoolId(Teacher teacher, TeacherAssignment assignment) {
        if (assignment.getSchool() != null) {
            return assignment.getSchool().getId();
        }
        return teacher.getSchool() == null ? null : teacher.getSchool().getId();
    }

    private boolean matchesAnyScope(Student student, List<AssignmentScope> scopes) {
        return scopes.stream().anyMatch(scope -> scope.matches(student));
    }

    private List<AssignmentScope> scopesForStudent(
            Student student,
            List<AssignmentScope> scopes) {
        return scopes.stream()
                .filter(scope -> scope.matches(student))
                .toList();
    }

    private List<Long> subjectIdsForScopes(List<AssignmentScope> scopes) {
        return scopes.stream()
                .map(AssignmentScope::subjectId)
                .distinct()
                .toList();
    }

    private List<Progress> progressForStudentScope(
            Student student,
            List<AssignmentScope> scopes,
            List<Progress> progressRecords) {
        Set<Long> subjectIds = new HashSet<>(subjectIdsForScopes(scopesForStudent(student, scopes)));
        return progressRecords.stream()
                .filter(progress -> subjectIds.contains(subjectIdFor(progress)))
                .toList();
    }

    private Long subjectIdFor(Progress progress) {
        if (progress.getLesson() == null || progress.getLesson().getSubject() == null) {
            return null;
        }
        return progress.getLesson().getSubject().getId();
    }

    private boolean responseMatchesExactScope(
            StudentResponse response,
            List<AssignmentScope> scopes) {
        Student student = studentFor(response);
        Long responseSubjectId = subjectIdFor(response);
        if (student == null || responseSubjectId == null) {
            return false;
        }
        return scopes.stream().anyMatch(scope ->
                responseSubjectId.equals(scope.subjectId()) && scope.matches(student));
    }

    private TeacherMistakeSummaryResponse buildMistakeSummary(
            List<StudentResponse> responses) {
        if (responses.isEmpty()) {
            return TeacherMistakeSummaryResponse.builder()
                    .totalMistakes(0)
                    .affectedStudents(0)
                    .build();
        }

        Set<Long> affectedStudents = responses.stream()
                .map(this::studentIdFor)
                .filter(id -> id != null)
                .collect(Collectors.toSet());

        Map<Long, CountedLabel> lessons = new LinkedHashMap<>();
        Map<Long, CountedLabel> questions = new LinkedHashMap<>();
        for (StudentResponse response : responses) {
            Long lessonId = lessonIdFor(response);
            if (lessonId != null) {
                lessons.computeIfAbsent(
                        lessonId,
                        ignored -> new CountedLabel(lessonId, lessonTitleFor(response)))
                        .increment();
            }
            Long questionId = questionIdFor(response);
            if (questionId != null) {
                questions.computeIfAbsent(
                        questionId,
                        ignored -> new CountedLabel(questionId, questionTextFor(response)))
                        .increment();
            }
        }

        CountedLabel topLesson = mostCommon(lessons);
        CountedLabel topQuestion = mostCommon(questions);

        return TeacherMistakeSummaryResponse.builder()
                .totalMistakes(responses.size())
                .affectedStudents(affectedStudents.size())
                .mostMistakenLessonId(topLesson == null ? null : topLesson.id())
                .mostMistakenLessonTitle(topLesson == null ? null : topLesson.label())
                .mostMistakenQuestionId(topQuestion == null ? null : topQuestion.id())
                .mostMistakenQuestionText(topQuestion == null ? null : topQuestion.label())
                .build();
    }

    private CountedLabel mostCommon(Map<Long, CountedLabel> counts) {
        return counts.values().stream()
                .max(Comparator
                        .comparingLong(CountedLabel::count)
                        .thenComparing(CountedLabel::id, Comparator.nullsLast(Comparator.reverseOrder())))
                .orElse(null);
    }

    private int sanitizeLimit(Integer limit) {
        if (limit == null) {
            return 100;
        }
        return Math.max(1, Math.min(limit, 500));
    }

    private String normalizedAnswerKey(String answer) {
        if (answer == null) {
            return "";
        }
        return answer.trim();
    }

    private Student studentFor(StudentResponse response) {
        if (response == null || response.getAttempt() == null) {
            return null;
        }
        return response.getAttempt().getStudent();
    }

    private Long studentIdFor(StudentResponse response) {
        Student student = studentFor(response);
        return student == null ? null : student.getId();
    }

    private String studentNameFor(StudentResponse response) {
        Student student = studentFor(response);
        return student == null ? null : student.getFullName();
    }

    private Question questionFor(StudentResponse response) {
        return response == null ? null : response.getQuestion();
    }

    private Long questionIdFor(StudentResponse response) {
        Question question = questionFor(response);
        return question == null ? null : question.getId();
    }

    private String questionTextFor(StudentResponse response) {
        Question question = questionFor(response);
        return question == null ? null : question.getQuestionText();
    }

    private String correctAnswerFor(StudentResponse response) {
        Question question = questionFor(response);
        return question == null ? null : question.getCorrectAnswer();
    }

    private Lesson lessonFor(StudentResponse response) {
        Question question = questionFor(response);
        return question == null ? null : question.getLesson();
    }

    private Long lessonIdFor(StudentResponse response) {
        Lesson lesson = lessonFor(response);
        return lesson == null ? null : lesson.getId();
    }

    private String lessonTitleFor(StudentResponse response) {
        Lesson lesson = lessonFor(response);
        return lesson == null ? null : lesson.getTitle();
    }

    private Long subjectIdFor(StudentResponse response) {
        Lesson lesson = lessonFor(response);
        if (lesson == null || lesson.getSubject() == null) {
            return null;
        }
        return lesson.getSubject().getId();
    }

    private String subjectNameFor(StudentResponse response) {
        Lesson lesson = lessonFor(response);
        if (lesson == null || lesson.getSubject() == null) {
            return null;
        }
        return lesson.getSubject().getName();
    }

    private LocalDateTime mistakeTimeFor(StudentResponse response) {
        if (response == null || response.getAttempt() == null) {
            return null;
        }
        Attempt attempt = response.getAttempt();
        return attempt.getSubmittedAt() == null
                ? attempt.getCreatedAt()
                : attempt.getSubmittedAt();
    }

    private String studentAnswerFor(StudentResponse response) {
        if (response == null) {
            return null;
        }
        if (response.getEvaluatedText() != null
                && !response.getEvaluatedText().isBlank()) {
            return response.getEvaluatedText();
        }
        if (response.getSpokenText() != null
                && !response.getSpokenText().isBlank()) {
            return response.getSpokenText();
        }
        if (response.getAudioRef() != null && !response.getAudioRef().isBlank()) {
            return response.getAudioRef();
        }
        return null;
    }

    private List<Subject> subjectsForScopes(
            List<TeacherAssignment> assignments,
            List<AssignmentScope> scopes) {
        Set<Long> subjectIds = new HashSet<>(subjectIdsForScopes(scopes));
        return assignments.stream()
                .map(TeacherAssignment::getSubject)
                .filter(subject -> subject != null && subjectIds.contains(subject.getId()))
                .collect(Collectors.toMap(
                        Subject::getId,
                        subject -> subject,
                        (first, ignored) -> first,
                        LinkedHashMap::new))
                .values()
                .stream()
                .sorted(Comparator.comparing(
                        Subject::getName,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }

    private ClassStudentSummary buildSummary(Student student, List<Progress> progressRecords) {
        return ClassStudentSummary.builder()
                .studentId(student.getId())
                .fullName(student.getFullName())
                .email(student.getEmail())
                .gradeLevel(student.getGradeLevel())
                .totalPoints(student.getTotalPoints())
                .currentStreak(student.getCurrentStreak())
                .lessonsCompleted(metrics.countCompleted(progressRecords))
                .lessonsInProgress(metrics.countInProgress(progressRecords))
                .averageMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .lastLoginAt(student.getLastLoginAt())
                .build();
    }

    private record MistakeKey(Long studentId, Long questionId, String studentAnswer) {
    }

    private final class MistakeAccumulator {
        private final StudentResponse first;
        private long count = 0;
        private LocalDateTime lastMistakeAt;

        private MistakeAccumulator(StudentResponse first) {
            this.first = first;
        }

        private void add(StudentResponse response) {
            count++;
            LocalDateTime candidate = mistakeTimeFor(response);
            if (candidate != null
                    && (lastMistakeAt == null || candidate.isAfter(lastMistakeAt))) {
                lastMistakeAt = candidate;
            }
        }

        private TeacherMistakeRowResponse toResponse(
                Map<Long, Set<Long>> studentsByQuestion) {
            Long questionId = questionIdFor(first);
            int affectedForQuestion = questionId == null
                    ? 0
                    : studentsByQuestion.getOrDefault(questionId, Collections.emptySet()).size();
            return TeacherMistakeRowResponse.builder()
                    .studentId(studentIdFor(first))
                    .studentName(studentNameFor(first))
                    .subjectId(subjectIdFor(first))
                    .subjectName(subjectNameFor(first))
                    .lessonId(lessonIdFor(first))
                    .lessonTitle(lessonTitleFor(first))
                    .questionId(questionId)
                    .questionText(questionTextFor(first))
                    .studentAnswer(studentAnswerFor(first))
                    .correctAnswer(correctAnswerFor(first))
                    .mistakeCount(count)
                    .lastMistakeAt(lastMistakeAt)
                    .commonMistake(affectedForQuestion > 1)
                    .affectedStudentsForQuestion(affectedForQuestion)
                    .build();
        }
    }

    private static final class CountedLabel {
        private final Long id;
        private final String label;
        private long count = 0;

        private CountedLabel(Long id, String label) {
            this.id = id;
            this.label = label;
        }

        private Long id() {
            return id;
        }

        private String label() {
            return label;
        }

        private long count() {
            return count;
        }

        private void increment() {
            count++;
        }
    }

    private record AssignmentScope(Integer gradeLevel, Long schoolId, Long subjectId) {
        boolean isUsable() {
            return gradeLevel != null && schoolId != null && subjectId != null;
        }

        boolean matches(Student student) {
            Long studentSchoolId = student.getSchool() == null ? null : student.getSchool().getId();
            return gradeLevel.equals(student.getGradeLevel())
                    && schoolId.equals(studentSchoolId);
        }
    }
}
