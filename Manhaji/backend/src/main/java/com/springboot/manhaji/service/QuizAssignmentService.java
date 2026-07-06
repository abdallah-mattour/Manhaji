package com.springboot.manhaji.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.QuizConfigProperties;
import com.springboot.manhaji.dto.request.TeacherQuizAssignmentRequest;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.QuestionResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizDetailResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizSummaryResponse;
import com.springboot.manhaji.dto.response.TeacherAssignmentAttemptResponse;
import com.springboot.manhaji.dto.response.TeacherAssignmentResultsResponse;
import com.springboot.manhaji.dto.response.TeacherQuizAssignmentResponse;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.QuizAssignment;
import com.springboot.manhaji.entity.QuizAssignmentStudent;
import com.springboot.manhaji.entity.School;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.StudentResponse;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.TeacherAssignment;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.QuizAssignmentStatus;
import com.springboot.manhaji.entity.enums.QuizAssignmentStudentStatus;
import com.springboot.manhaji.entity.enums.QuizStatus;
import com.springboot.manhaji.entity.enums.QuizType;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.QuizAssignmentRepository;
import com.springboot.manhaji.repository.QuizAssignmentStudentRepository;
import com.springboot.manhaji.repository.QuizRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.TeacherAssignmentRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.OptionalDouble;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class QuizAssignmentService {

    private static final int RECENT_ATTEMPT_LIMIT = 10;

    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final StudentRepository studentRepository;
    private final QuizRepository quizRepository;
    private final QuizAssignmentRepository quizAssignmentRepository;
    private final QuizAssignmentStudentRepository quizAssignmentStudentRepository;
    private final AttemptRepository attemptRepository;
    private final StudentResponseRepository responseRepository;
    private final ObjectMapper objectMapper;
    private final QuizConfigProperties quizConfig;

    @Transactional
    public TeacherQuizAssignmentResponse publishAssignment(
            Long teacherId,
            Long quizId,
            TeacherQuizAssignmentRequest request) {
        if (request == null) {
            throw new BadRequestException("Assignment request is required");
        }
        if (request.getGradeLevel() == null) {
            throw new BadRequestException("gradeLevel is required");
        }
        if (request.getMaxAttempts() != null && request.getMaxAttempts() <= 0) {
            throw new BadRequestException("maxAttempts must be positive");
        }
        if (request.getDueAt() != null && !request.getDueAt().isAfter(LocalDateTime.now())) {
            throw new BadRequestException("dueAt must be in the future");
        }

        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Quiz quiz = quizRepository.findByIdWithTeacherDetails(quizId)
                .orElseThrow(() -> new ResourceNotFoundException("Quiz", quizId));
        requireOwnedDraftTeacherQuiz(teacherId, quiz);

        Subject subject = subjectFor(quiz);
        if (subject == null || subject.getId() == null) {
            throw new BadRequestException("Quiz subject is required before publishing");
        }
        requirePublishableQuestions(quiz, subject.getId());

        List<AssignmentScope> scopes = activeScopesForTeacher(teacher);
        AssignmentScope scope = selectScope(scopes, subject.getId(), request);
        List<Student> targetStudents = resolveTargetStudents(scope, request.getStudentIds());
        if (targetStudents.isEmpty()) {
            throw new BadRequestException("No students are available in this assignment scope");
        }

        QuizAssignment assignment = new QuizAssignment();
        assignment.setQuiz(quiz);
        assignment.setTeacher(teacher);
        assignment.setSubject(subject);
        assignment.setSchool(scope.school());
        assignment.setGradeLevel(scope.gradeLevel());
        assignment.setStatus(QuizAssignmentStatus.PUBLISHED);
        assignment.setDueAt(request.getDueAt());
        assignment.setMaxAttempts(request.getMaxAttempts());

        for (Student student : targetStudents) {
            QuizAssignmentStudent assignedStudent = new QuizAssignmentStudent();
            assignedStudent.setQuizAssignment(assignment);
            assignedStudent.setStudent(student);
            assignedStudent.setStatus(QuizAssignmentStudentStatus.ASSIGNED);
            assignment.getStudents().add(assignedStudent);
        }

        quiz.setStatus(QuizStatus.PUBLISHED);
        quizAssignmentRepository.save(assignment);
        quizRepository.save(quiz);

        return toTeacherAssignmentResponse(assignment);
    }

    public List<TeacherQuizAssignmentResponse> getQuizAssignments(Long teacherId, Long quizId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        Quiz quiz = quizRepository.findByIdWithTeacherDetails(quizId)
                .orElseThrow(() -> new ResourceNotFoundException("Quiz", quizId));
        requireTeacherCanViewQuizAssignments(teacher, quiz);

        return quizAssignmentRepository.findByQuizIdAndTeacherIdOrderByPublishedAtDesc(quizId, teacherId)
                .stream()
                .map(this::toTeacherAssignmentResponse)
                .toList();
    }

    public TeacherAssignmentResultsResponse getAssignmentResults(Long teacherId, Long assignmentId) {
        QuizAssignment assignment = quizAssignmentRepository.findByIdAndTeacherId(assignmentId, teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("QuizAssignment", assignmentId));
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new ResourceNotFoundException("Teacher", teacherId));
        requireAssignmentInActiveTeacherScope(teacher, assignment);

        List<Attempt> attempts = attemptRepository.findByQuizAssignmentIdOrderByCreatedAtDesc(assignmentId);
        List<Attempt> completed = attempts.stream()
                .filter(this::isCompletedAttempt)
                .toList();
        OptionalDouble average = completed.stream()
                .map(Attempt::getScore)
                .filter(Objects::nonNull)
                .mapToDouble(Double::doubleValue)
                .average();
        Double averageScore = average.isPresent() ? average.getAsDouble() : null;

        List<TeacherAssignmentAttemptResponse> recentAttempts = attempts.stream()
                .limit(RECENT_ATTEMPT_LIMIT)
                .map(this::toTeacherAttemptResponse)
                .toList();

        return TeacherAssignmentResultsResponse.builder()
                .assignmentId(assignment.getId())
                .quizId(assignment.getQuiz().getId())
                .quizTitle(assignment.getQuiz().getTitle())
                .assignedCount((int) quizAssignmentStudentRepository.countByQuizAssignmentId(assignmentId))
                .completedCount(completed.size())
                .averageScore(averageScore)
                .recentAttempts(recentAttempts)
                .build();
    }

    public List<StudentAssignedQuizSummaryResponse> getAssignedQuizzes(Long studentId) {
        studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));
        LocalDateTime now = LocalDateTime.now();

        return quizAssignmentStudentRepository.findByStudentId(studentId).stream()
                .sorted(Comparator
                        .comparing((QuizAssignmentStudent row) ->
                                row.getQuizAssignment().getDueAt(), Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(row -> row.getQuizAssignment().getPublishedAt(),
                                Comparator.nullsLast(Comparator.reverseOrder())))
                .map(row -> toStudentSummary(row, now))
                .toList();
    }

    public StudentAssignedQuizDetailResponse getAssignedQuizDetail(Long studentId, Long assignmentId) {
        QuizAssignmentStudent row = requireAssignedStudent(assignmentId, studentId);
        QuizAssignment assignment = row.getQuizAssignment();
        requireAssignmentOpenForDetails(assignment);
        return toStudentDetail(row, LocalDateTime.now());
    }

    @Transactional
    public AttemptResponse startAssignedQuizAttempt(Long studentId, Long assignmentId) {
        QuizAssignmentStudent row = requireAssignedStudent(assignmentId, studentId);
        QuizAssignment assignment = row.getQuizAssignment();
        requireAssignmentOpenForStart(assignment);

        Quiz quiz = assignment.getQuiz();
        return attemptRepository
                .findByStudentIdAndQuizAssignmentIdAndStatus(
                        studentId, assignmentId, AttemptStatus.IN_PROGRESS)
                .map(attempt -> buildAttemptResponse(attempt, quiz))
                .orElseGet(() -> createAssignedAttempt(studentId, assignment, quiz));
    }

    private AttemptResponse createAssignedAttempt(Long studentId, QuizAssignment assignment, Quiz quiz) {
        long attemptsUsed = attemptRepository.countByStudentIdAndQuizAssignmentId(studentId, assignment.getId());
        if (assignment.getMaxAttempts() != null && attemptsUsed >= assignment.getMaxAttempts()) {
            throw new BadRequestException("Maximum attempts reached for this assignment");
        }

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));
        Attempt attempt = new Attempt();
        attempt.setStudent(student);
        attempt.setQuiz(quiz);
        attempt.setQuizAssignment(assignment);
        attempt.setStatus(AttemptStatus.IN_PROGRESS);
        attempt = attemptRepository.save(attempt);
        return buildAttemptResponse(attempt, quiz);
    }

    private void requireOwnedDraftTeacherQuiz(Long teacherId, Quiz quiz) {
        if (quiz.getCreatedByTeacher() == null
                || quiz.getCreatedByTeacher().getId() == null
                || !teacherId.equals(quiz.getCreatedByTeacher().getId())
                || quiz.getQuizType() != QuizType.TEACHER_ASSIGNED) {
            throw new UnauthorizedException("Quiz is not owned by this teacher");
        }
        if (quiz.getStatus() != QuizStatus.DRAFT) {
            throw new BadRequestException("Only draft teacher quizzes can be published");
        }
    }

    private void requireTeacherCanViewQuizAssignments(Teacher teacher, Quiz quiz) {
        if (quiz.getCreatedByTeacher() == null
                || !teacher.getId().equals(quiz.getCreatedByTeacher().getId())) {
            throw new UnauthorizedException("Quiz is not owned by this teacher");
        }
        Subject subject = subjectFor(quiz);
        if (subject == null || subject.getId() == null) {
            throw new UnauthorizedException("Quiz subject is not assigned to this teacher");
        }
        boolean inScope = activeScopesForTeacher(teacher).stream()
                .anyMatch(scope -> subject.getId().equals(scope.subjectId()));
        if (!inScope) {
            throw new UnauthorizedException("Quiz subject is not assigned to this teacher");
        }
    }

    private void requireAssignmentInActiveTeacherScope(Teacher teacher, QuizAssignment assignment) {
        Long assignmentSchoolId = schoolIdFor(assignment.getSchool());
        boolean inScope = activeScopesForTeacher(teacher).stream()
                .anyMatch(scope -> assignment.getSubject() != null
                        && assignment.getSubject().getId() != null
                        && assignment.getSubject().getId().equals(scope.subjectId())
                        && assignment.getGradeLevel().equals(scope.gradeLevel())
                        && assignmentSchoolId != null
                        && assignmentSchoolId.equals(scope.schoolId()));
        if (!inScope) {
            throw new UnauthorizedException("Assignment is outside this teacher scope");
        }
    }

    private void requirePublishableQuestions(Quiz quiz, Long subjectId) {
        if (quiz.getQuestions() == null || quiz.getQuestions().isEmpty()) {
            throw new BadRequestException("Quiz must have at least one question before publishing");
        }
        boolean allMatchSubject = quiz.getQuestions().stream()
                .allMatch(question -> subjectId.equals(subjectIdFor(question)));
        if (!allMatchSubject) {
            throw new BadRequestException("All quiz questions must belong to the quiz subject");
        }
    }

    private AssignmentScope selectScope(
            List<AssignmentScope> scopes,
            Long subjectId,
            TeacherQuizAssignmentRequest request) {
        List<AssignmentScope> matches = scopes.stream()
                .filter(scope -> subjectId.equals(scope.subjectId()))
                .filter(scope -> request.getGradeLevel().equals(scope.gradeLevel()))
                .filter(scope -> request.getSchoolId() == null
                        || request.getSchoolId().equals(scope.schoolId()))
                .toList();
        if (matches.isEmpty()) {
            throw new UnauthorizedException("Teacher is not assigned to this subject, grade, and school");
        }
        Set<Long> schoolIds = matches.stream()
                .map(AssignmentScope::schoolId)
                .collect(LinkedHashSet::new, Set::add, Set::addAll);
        if (request.getSchoolId() == null && schoolIds.size() != 1) {
            throw new BadRequestException("schoolId is required for this assignment scope");
        }
        return matches.get(0);
    }

    private List<Student> resolveTargetStudents(AssignmentScope scope, List<Long> requestedStudentIds) {
        List<Student> visibleStudents = studentRepository
                .findBySchoolIdAndGradeLevel(scope.schoolId(), scope.gradeLevel())
                .stream()
                .filter(scope::matches)
                .toList();
        if (requestedStudentIds == null || requestedStudentIds.isEmpty()) {
            return visibleStudents;
        }

        LinkedHashSet<Long> requestedIds = new LinkedHashSet<>();
        for (Long studentId : requestedStudentIds) {
            if (studentId == null) {
                throw new BadRequestException("studentIds cannot contain null values");
            }
            requestedIds.add(studentId);
        }
        Map<Long, Student> visibleById = visibleStudents.stream()
                .collect(LinkedHashMap::new, (map, student) -> map.put(student.getId(), student), Map::putAll);
        if (!visibleById.keySet().containsAll(requestedIds)) {
            throw new UnauthorizedException("One or more students are outside this teacher scope");
        }
        return requestedIds.stream()
                .map(visibleById::get)
                .toList();
    }

    private QuizAssignmentStudent requireAssignedStudent(Long assignmentId, Long studentId) {
        return quizAssignmentStudentRepository
                .findByQuizAssignmentIdAndStudentId(assignmentId, studentId)
                .orElseThrow(() -> new UnauthorizedException("Assigned quiz is not available for this student"));
    }

    private void requireAssignmentOpenForDetails(QuizAssignment assignment) {
        if (assignment.getStatus() != QuizAssignmentStatus.PUBLISHED) {
            throw new BadRequestException("Assigned quiz is closed");
        }
        if (isExpired(assignment, LocalDateTime.now())) {
            throw new BadRequestException("Assigned quiz has expired");
        }
    }

    private void requireAssignmentOpenForStart(QuizAssignment assignment) {
        requireAssignmentOpenForDetails(assignment);
        if (assignment.getQuiz() == null || assignment.getQuiz().getStatus() != QuizStatus.PUBLISHED) {
            throw new BadRequestException("Quiz is not published");
        }
    }

    private List<AssignmentScope> activeScopesForTeacher(Teacher teacher) {
        return teacherAssignmentRepository.findActiveByTeacherIdWithSubject(teacher.getId()).stream()
                .map(assignment -> new AssignmentScope(
                        assignment.getGradeLevel(),
                        effectiveSchool(teacher, assignment),
                        assignment.getSubject() == null ? null : assignment.getSubject().getId()))
                .filter(AssignmentScope::isUsable)
                .distinct()
                .toList();
    }

    private School effectiveSchool(Teacher teacher, TeacherAssignment assignment) {
        if (assignment.getSchool() != null) {
            return assignment.getSchool();
        }
        return teacher.getSchool();
    }

    private TeacherQuizAssignmentResponse toTeacherAssignmentResponse(QuizAssignment assignment) {
        return TeacherQuizAssignmentResponse.builder()
                .assignmentId(assignment.getId())
                .quizId(assignment.getQuiz().getId())
                .quizTitle(assignment.getQuiz().getTitle())
                .subjectId(assignment.getSubject().getId())
                .subjectName(assignment.getSubject().getName())
                .schoolId(schoolIdFor(assignment.getSchool()))
                .schoolName(assignment.getSchool() == null ? null : assignment.getSchool().getName())
                .gradeLevel(assignment.getGradeLevel())
                .status(assignment.getStatus().name())
                .publishedAt(assignment.getPublishedAt())
                .dueAt(assignment.getDueAt())
                .maxAttempts(assignment.getMaxAttempts())
                .assignedCount(assignment.getStudents() == null ? 0 : assignment.getStudents().size())
                .build();
    }

    private StudentAssignedQuizSummaryResponse toStudentSummary(
            QuizAssignmentStudent row,
            LocalDateTime now) {
        QuizAssignment assignment = row.getQuizAssignment();
        Quiz quiz = assignment.getQuiz();
        long attemptsUsed = attemptRepository.countByStudentIdAndQuizAssignmentId(
                row.getStudent().getId(), assignment.getId());
        boolean hasInProgress = attemptRepository
                .findByStudentIdAndQuizAssignmentIdAndStatus(
                        row.getStudent().getId(), assignment.getId(), AttemptStatus.IN_PROGRESS)
                .isPresent();

        return StudentAssignedQuizSummaryResponse.builder()
                .assignmentId(assignment.getId())
                .quizId(quiz.getId())
                .title(quiz.getTitle())
                .subjectName(assignment.getSubject().getName())
                .questionCount(quiz.getQuestions() == null ? 0 : quiz.getQuestions().size())
                .dueAt(assignment.getDueAt())
                .status(studentVisibleStatus(row, assignment, now))
                .attemptsUsed(attemptsUsed)
                .maxAttempts(assignment.getMaxAttempts())
                .canStart(canStart(assignment, attemptsUsed, hasInProgress, now))
                .build();
    }

    private StudentAssignedQuizDetailResponse toStudentDetail(
            QuizAssignmentStudent row,
            LocalDateTime now) {
        QuizAssignment assignment = row.getQuizAssignment();
        Quiz quiz = assignment.getQuiz();
        long attemptsUsed = attemptRepository.countByStudentIdAndQuizAssignmentId(
                row.getStudent().getId(), assignment.getId());
        boolean hasInProgress = attemptRepository
                .findByStudentIdAndQuizAssignmentIdAndStatus(
                        row.getStudent().getId(), assignment.getId(), AttemptStatus.IN_PROGRESS)
                .isPresent();

        return StudentAssignedQuizDetailResponse.builder()
                .assignmentId(assignment.getId())
                .quizId(quiz.getId())
                .title(quiz.getTitle())
                .subjectId(assignment.getSubject().getId())
                .subjectName(assignment.getSubject().getName())
                .questionCount(quiz.getQuestions() == null ? 0 : quiz.getQuestions().size())
                .dueAt(assignment.getDueAt())
                .status(studentVisibleStatus(row, assignment, now))
                .attemptsUsed(attemptsUsed)
                .maxAttempts(assignment.getMaxAttempts())
                .canStart(canStart(assignment, attemptsUsed, hasInProgress, now))
                .questions(questionsFor(quiz))
                .build();
    }

    private List<QuestionResponse> questionsFor(Quiz quiz) {
        if (quiz.getQuestions() == null) {
            return Collections.emptyList();
        }
        return quiz.getQuestions().stream()
                .sorted(Comparator.comparing(Question::getId))
                .map(this::toQuestionResponse)
                .toList();
    }

    private QuestionResponse toQuestionResponse(Question question) {
        List<String> options = null;
        if (question.getOptions() != null && !question.getOptions().isEmpty()) {
            try {
                options = objectMapper.readValue(question.getOptions(), new TypeReference<List<String>>() {});
            } catch (Exception ignored) {
                options = List.of();
            }
        }
        if (question.getType() == QuestionType.TRUE_FALSE && options == null) {
            options = List.of("صح", "خطأ");
        }

        return QuestionResponse.builder()
                .id(question.getId())
                .type(question.getType().name())
                .questionText(question.getQuestionText())
                .options(options)
                .difficultyLevel(question.getDifficultyLevel())
                .subSkill(question.getSubSkill())
                .imageUrl(question.getImageUrl())
                .audioUrl(question.getAudioUrl())
                .build();
    }

    private AttemptResponse buildAttemptResponse(Attempt attempt, Quiz quiz) {
        List<StudentResponse> responses = responseRepository.findByAttemptId(attempt.getId());
        int correctAnswers = (int) responses.stream()
                .filter(response -> Boolean.TRUE.equals(response.getIsCorrect()))
                .count();

        return AttemptResponse.builder()
                .attemptId(attempt.getId())
                .quizId(quiz.getId())
                .status(attempt.getStatus().name())
                .score(attempt.getScore())
                .totalQuestions(quiz.getQuestions() == null ? 0 : quiz.getQuestions().size())
                .correctAnswers(correctAnswers)
                .pointsEarned(correctAnswers * quizConfig.getPointsPerCorrect())
                .submittedAt(attempt.getSubmittedAt())
                .build();
    }

    private TeacherAssignmentAttemptResponse toTeacherAttemptResponse(Attempt attempt) {
        Student student = attempt.getStudent();
        return TeacherAssignmentAttemptResponse.builder()
                .attemptId(attempt.getId())
                .studentId(student == null ? null : student.getId())
                .studentName(student == null ? null : student.getFullName())
                .status(attempt.getStatus().name())
                .score(attempt.getScore())
                .startedAt(attempt.getCreatedAt())
                .submittedAt(attempt.getSubmittedAt())
                .build();
    }

    private boolean canStart(
            QuizAssignment assignment,
            long attemptsUsed,
            boolean hasInProgress,
            LocalDateTime now) {
        if (assignment.getStatus() != QuizAssignmentStatus.PUBLISHED) {
            return false;
        }
        if (isExpired(assignment, now)) {
            return false;
        }
        return hasInProgress
                || assignment.getMaxAttempts() == null
                || attemptsUsed < assignment.getMaxAttempts();
    }

    private String studentVisibleStatus(
            QuizAssignmentStudent row,
            QuizAssignment assignment,
            LocalDateTime now) {
        if (assignment.getStatus() == QuizAssignmentStatus.CLOSED) {
            return QuizAssignmentStatus.CLOSED.name();
        }
        if (isExpired(assignment, now)) {
            return QuizAssignmentStudentStatus.EXPIRED.name();
        }
        return row.getStatus().name();
    }

    private boolean isExpired(QuizAssignment assignment, LocalDateTime now) {
        return assignment.getDueAt() != null && !assignment.getDueAt().isAfter(now);
    }

    private boolean isCompletedAttempt(Attempt attempt) {
        return attempt.getStatus() == AttemptStatus.GRADED
                || attempt.getStatus() == AttemptStatus.SUBMITTED;
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
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);
    }

    private Subject subjectFor(Question question) {
        if (question == null || question.getLesson() == null) {
            return null;
        }
        return question.getLesson().getSubject();
    }

    private Long subjectIdFor(Question question) {
        Subject subject = subjectFor(question);
        return subject == null ? null : subject.getId();
    }

    private Long schoolIdFor(School school) {
        return school == null ? null : school.getId();
    }

    private record AssignmentScope(Integer gradeLevel, School school, Long subjectId) {
        boolean isUsable() {
            return gradeLevel != null && school != null && school.getId() != null && subjectId != null;
        }

        Long schoolId() {
            return school.getId();
        }

        boolean matches(Student student) {
            Long studentSchoolId = student.getSchool() == null ? null : student.getSchool().getId();
            return gradeLevel.equals(student.getGradeLevel()) && schoolId().equals(studentSchoolId);
        }
    }
}
