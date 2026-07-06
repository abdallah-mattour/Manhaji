package com.springboot.manhaji.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.QuizConfigProperties;
import com.springboot.manhaji.dto.request.TeacherQuizAssignmentRequest;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizDetailResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizSummaryResponse;
import com.springboot.manhaji.dto.response.TeacherAssignmentResultsResponse;
import com.springboot.manhaji.dto.response.TeacherQuizAssignmentResponse;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.QuizAssignment;
import com.springboot.manhaji.entity.QuizAssignmentStudent;
import com.springboot.manhaji.entity.School;
import com.springboot.manhaji.entity.Student;
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
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.QuizAssignmentRepository;
import com.springboot.manhaji.repository.QuizAssignmentStudentRepository;
import com.springboot.manhaji.repository.QuizRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.TeacherAssignmentRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class QuizAssignmentServiceTest {

    @Mock private TeacherRepository teacherRepository;
    @Mock private TeacherAssignmentRepository teacherAssignmentRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private QuizRepository quizRepository;
    @Mock private QuizAssignmentRepository quizAssignmentRepository;
    @Mock private QuizAssignmentStudentRepository quizAssignmentStudentRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private StudentResponseRepository responseRepository;
    @Spy private ObjectMapper objectMapper = new ObjectMapper();

    private QuizAssignmentService service;
    private Teacher teacher;
    private School school;
    private Subject arabic;
    private Subject math;
    private Student student1;
    private Student student2;
    private Student unrelatedStudent;
    private Quiz draftQuiz;

    @BeforeEach
    void setUp() {
        service = new QuizAssignmentService(
                teacherRepository,
                teacherAssignmentRepository,
                studentRepository,
                quizRepository,
                quizAssignmentRepository,
                quizAssignmentStudentRepository,
                attemptRepository,
                responseRepository,
                objectMapper,
                new QuizConfigProperties());

        school = new School();
        school.setId(7L);
        school.setName("Manhaji School");

        teacher = new Teacher();
        teacher.setId(10L);
        teacher.setFullName("Teacher");
        teacher.setSchool(school);

        arabic = subject(100L, "Arabic");
        math = subject(200L, "Math");

        student1 = student(1L, "Student One", 1, school);
        student2 = student(2L, "Student Two", 1, school);

        School otherSchool = new School();
        otherSchool.setId(9L);
        unrelatedStudent = student(3L, "Outside Student", 1, otherSchool);

        draftQuiz = teacherQuiz(50L, arabic, QuizStatus.DRAFT);

        lenient().when(responseRepository.findByAttemptId(anyLong())).thenReturn(List.of());
        lenient().when(attemptRepository.findByStudentIdAndQuizAssignmentIdAndStatus(
                        anyLong(), anyLong(), eq(AttemptStatus.IN_PROGRESS)))
                .thenReturn(Optional.empty());
    }

    @Test
    @DisplayName("teacher can publish assigned-subject draft quiz to visible students")
    void teacherCanPublishAssignedSubjectDraftQuizToVisibleStudents() {
        stubTeacherScope(arabic);
        when(quizRepository.findByIdWithTeacherDetails(50L)).thenReturn(Optional.of(draftQuiz));
        when(studentRepository.findBySchoolIdAndGradeLevel(7L, 1))
                .thenReturn(List.of(student1, student2));
        when(quizAssignmentRepository.save(any())).thenAnswer(inv -> {
            QuizAssignment assignment = inv.getArgument(0);
            assignment.setId(70L);
            assignment.setPublishedAt(LocalDateTime.now());
            return assignment;
        });
        when(quizRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        TeacherQuizAssignmentResponse response = service.publishAssignment(
                10L,
                50L,
                new TeacherQuizAssignmentRequest(1, 7L, null, 2, null));

        assertThat(response.getAssignmentId()).isEqualTo(70L);
        assertThat(response.getAssignedCount()).isEqualTo(2);
        assertThat(response.getStatus()).isEqualTo("PUBLISHED");
        assertThat(draftQuiz.getStatus()).isEqualTo(QuizStatus.PUBLISHED);

        ArgumentCaptor<QuizAssignment> assignmentCaptor = ArgumentCaptor.forClass(QuizAssignment.class);
        verify(quizAssignmentRepository).save(assignmentCaptor.capture());
        QuizAssignment saved = assignmentCaptor.getValue();
        assertThat(saved.getTeacher()).isEqualTo(teacher);
        assertThat(saved.getSubject()).isEqualTo(arabic);
        assertThat(saved.getSchool()).isEqualTo(school);
        assertThat(saved.getStudents()).hasSize(2);
        assertThat(saved.getStudents())
                .extracting(row -> row.getStudent().getId())
                .containsExactly(1L, 2L);
    }

    @Test
    @DisplayName("teacher cannot publish quiz for unassigned subject")
    void teacherCannotPublishQuizForUnassignedSubject() {
        Quiz mathQuiz = teacherQuiz(51L, math, QuizStatus.DRAFT);
        stubTeacherScope(arabic);
        when(quizRepository.findByIdWithTeacherDetails(51L)).thenReturn(Optional.of(mathQuiz));

        assertThatThrownBy(() -> service.publishAssignment(
                10L,
                51L,
                new TeacherQuizAssignmentRequest(1, 7L, null, null, null)))
                .isInstanceOf(UnauthorizedException.class);
        verify(quizAssignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("teacher cannot assign unrelated student")
    void teacherCannotAssignUnrelatedStudent() {
        stubTeacherScope(arabic);
        when(quizRepository.findByIdWithTeacherDetails(50L)).thenReturn(Optional.of(draftQuiz));
        when(studentRepository.findBySchoolIdAndGradeLevel(7L, 1))
                .thenReturn(List.of(student1, student2));

        assertThatThrownBy(() -> service.publishAssignment(
                10L,
                50L,
                new TeacherQuizAssignmentRequest(1, 7L, null, null, List.of(1L, 3L))))
                .isInstanceOf(UnauthorizedException.class);
        verify(quizAssignmentRepository, never()).save(any());
        assertThat(unrelatedStudent.getId()).isEqualTo(3L);
    }

    @Test
    @DisplayName("teacher with no active assignment cannot publish")
    void teacherWithNoActiveAssignmentCannotPublish() {
        when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
        when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L)).thenReturn(List.of());
        when(quizRepository.findByIdWithTeacherDetails(50L)).thenReturn(Optional.of(draftQuiz));

        assertThatThrownBy(() -> service.publishAssignment(
                10L,
                50L,
                new TeacherQuizAssignmentRequest(1, 7L, null, null, null)))
                .isInstanceOf(UnauthorizedException.class);
        verify(quizAssignmentRepository, never()).save(any());
    }

    @Test
    @DisplayName("student sees only assigned quizzes returned for their student id")
    void studentSeesOnlyOwnAssignedQuizzes() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        QuizAssignmentStudent row = assignment.getStudents().get(0);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student1));
        when(quizAssignmentStudentRepository.findByStudentId(1L)).thenReturn(List.of(row));
        when(attemptRepository.countByStudentIdAndQuizAssignmentId(1L, 70L)).thenReturn(0L);

        List<StudentAssignedQuizSummaryResponse> quizzes = service.getAssignedQuizzes(1L);

        assertThat(quizzes).hasSize(1);
        assertThat(quizzes.get(0).getAssignmentId()).isEqualTo(70L);
        assertThat(quizzes.get(0).getQuizId()).isEqualTo(50L);
        assertThat(quizzes.get(0).getCanStart()).isTrue();
        verify(quizAssignmentStudentRepository).findByStudentId(1L);
    }

    @Test
    @DisplayName("student cannot see another student's assigned quiz")
    void studentCannotSeeAnotherStudentsAssignedQuiz() {
        when(quizAssignmentStudentRepository.findByQuizAssignmentIdAndStudentId(70L, 1L))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getAssignedQuizDetail(1L, 70L))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    @DisplayName("student can start assigned quiz and attempt stores quizAssignment")
    void studentCanStartAssignedQuizAndAttemptStoresAssignment() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        QuizAssignmentStudent row = assignment.getStudents().get(0);
        draftQuiz.setStatus(QuizStatus.PUBLISHED);

        when(quizAssignmentStudentRepository.findByQuizAssignmentIdAndStudentId(70L, 1L))
                .thenReturn(Optional.of(row));
        when(attemptRepository.countByStudentIdAndQuizAssignmentId(1L, 70L)).thenReturn(0L);
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student1));
        when(attemptRepository.save(any())).thenAnswer(inv -> {
            Attempt attempt = inv.getArgument(0);
            attempt.setId(900L);
            return attempt;
        });

        AttemptResponse response = service.startAssignedQuizAttempt(1L, 70L);

        assertThat(response.getAttemptId()).isEqualTo(900L);
        assertThat(response.getQuizId()).isEqualTo(50L);
        assertThat(response.getStatus()).isEqualTo("IN_PROGRESS");

        ArgumentCaptor<Attempt> attemptCaptor = ArgumentCaptor.forClass(Attempt.class);
        verify(attemptRepository).save(attemptCaptor.capture());
        assertThat(attemptCaptor.getValue().getQuizAssignment()).isEqualTo(assignment);
    }

    @Test
    @DisplayName("maxAttempts is enforced for assigned quiz starts")
    void maxAttemptsIsEnforced() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        assignment.setMaxAttempts(1);
        draftQuiz.setStatus(QuizStatus.PUBLISHED);
        when(quizAssignmentStudentRepository.findByQuizAssignmentIdAndStudentId(70L, 1L))
                .thenReturn(Optional.of(assignment.getStudents().get(0)));
        when(attemptRepository.countByStudentIdAndQuizAssignmentId(1L, 70L)).thenReturn(1L);

        assertThatThrownBy(() -> service.startAssignedQuizAttempt(1L, 70L))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Maximum attempts");
        verify(attemptRepository, never()).save(any());
    }

    @Test
    @DisplayName("closed assignment is rejected")
    void closedAssignmentRejected() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        assignment.setStatus(QuizAssignmentStatus.CLOSED);
        when(quizAssignmentStudentRepository.findByQuizAssignmentIdAndStudentId(70L, 1L))
                .thenReturn(Optional.of(assignment.getStudents().get(0)));

        assertThatThrownBy(() -> service.startAssignedQuizAttempt(1L, 70L))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("closed");
    }

    @Test
    @DisplayName("expired assignment is rejected")
    void expiredAssignmentRejected() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        assignment.setDueAt(LocalDateTime.now().minusMinutes(1));
        when(quizAssignmentStudentRepository.findByQuizAssignmentIdAndStudentId(70L, 1L))
                .thenReturn(Optional.of(assignment.getStudents().get(0)));

        assertThatThrownBy(() -> service.getAssignedQuizDetail(1L, 70L))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("expired");
    }

    @Test
    @DisplayName("authorized student can load assigned quiz detail")
    void authorizedStudentCanLoadAssignedQuizDetail() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        when(quizAssignmentStudentRepository.findByQuizAssignmentIdAndStudentId(70L, 1L))
                .thenReturn(Optional.of(assignment.getStudents().get(0)));

        StudentAssignedQuizDetailResponse response = service.getAssignedQuizDetail(1L, 70L);

        assertThat(response.getAssignmentId()).isEqualTo(70L);
        assertThat(response.getQuestions()).hasSize(2);
        assertThat(response.getCanStart()).isTrue();
    }

    @Test
    @DisplayName("teacher sees scoped assignment result summary")
    void teacherSeesScopedAssignmentResults() {
        QuizAssignment assignment = publishedAssignment(70L, draftQuiz, student1);
        Attempt graded = attempt(1_000L, assignment, student1, AttemptStatus.GRADED, 80.0);
        Attempt inProgress = attempt(1_001L, assignment, student1, AttemptStatus.IN_PROGRESS, null);
        stubTeacherScope(arabic);
        when(quizAssignmentRepository.findByIdAndTeacherId(70L, 10L)).thenReturn(Optional.of(assignment));
        when(attemptRepository.findByQuizAssignmentIdOrderByCreatedAtDesc(70L))
                .thenReturn(List.of(inProgress, graded));
        when(quizAssignmentStudentRepository.countByQuizAssignmentId(70L)).thenReturn(1L);

        TeacherAssignmentResultsResponse response = service.getAssignmentResults(10L, 70L);

        assertThat(response.getAssignedCount()).isEqualTo(1);
        assertThat(response.getCompletedCount()).isEqualTo(1);
        assertThat(response.getAverageScore()).isEqualTo(80.0);
        assertThat(response.getRecentAttempts()).hasSize(2);
    }

    private void stubTeacherScope(Subject subject) {
        when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
        when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                .thenReturn(List.of(teacherAssignment(subject)));
    }

    private TeacherAssignment teacherAssignment(Subject subject) {
        TeacherAssignment assignment = new TeacherAssignment();
        assignment.setId(20L);
        assignment.setTeacher(teacher);
        assignment.setSubject(subject);
        assignment.setGradeLevel(1);
        assignment.setSchool(school);
        assignment.setIsActive(true);
        return assignment;
    }

    private Quiz teacherQuiz(Long id, Subject subject, QuizStatus status) {
        Quiz quiz = new Quiz();
        quiz.setId(id);
        quiz.setTitle(subject.getName() + " Quiz");
        quiz.setQuizType(QuizType.TEACHER_ASSIGNED);
        quiz.setStatus(status);
        quiz.setSubject(subject);
        quiz.setLesson(null);
        quiz.setCreatedByTeacher(teacher);
        quiz.setGeneratedForStudentId(null);
        quiz.setQuestions(List.of(
                question(id * 10 + 1, subject),
                question(id * 10 + 2, subject)));
        return quiz;
    }

    private QuizAssignment publishedAssignment(Long id, Quiz quiz, Student student) {
        quiz.setStatus(QuizStatus.PUBLISHED);
        QuizAssignment assignment = new QuizAssignment();
        assignment.setId(id);
        assignment.setQuiz(quiz);
        assignment.setTeacher(teacher);
        assignment.setSubject(quiz.getSubject());
        assignment.setSchool(school);
        assignment.setGradeLevel(1);
        assignment.setStatus(QuizAssignmentStatus.PUBLISHED);
        assignment.setPublishedAt(LocalDateTime.now().minusHours(1));

        QuizAssignmentStudent row = new QuizAssignmentStudent();
        row.setId(id + 1);
        row.setQuizAssignment(assignment);
        row.setStudent(student);
        row.setStatus(QuizAssignmentStudentStatus.ASSIGNED);
        assignment.getStudents().add(row);
        return assignment;
    }

    private Attempt attempt(
            Long id,
            QuizAssignment assignment,
            Student student,
            AttemptStatus status,
            Double score) {
        Attempt attempt = new Attempt();
        attempt.setId(id);
        attempt.setQuizAssignment(assignment);
        attempt.setQuiz(assignment.getQuiz());
        attempt.setStudent(student);
        attempt.setStatus(status);
        attempt.setScore(score);
        attempt.setCreatedAt(LocalDateTime.now().minusMinutes(id % 60));
        return attempt;
    }

    private Subject subject(Long id, String name) {
        Subject subject = new Subject();
        subject.setId(id);
        subject.setName(name);
        subject.setGradeLevel(1);
        return subject;
    }

    private Student student(Long id, String name, Integer gradeLevel, School school) {
        Student student = new Student();
        student.setId(id);
        student.setFullName(name);
        student.setGradeLevel(gradeLevel);
        student.setSchool(school);
        return student;
    }

    private Question question(Long id, Subject subject) {
        Lesson lesson = new Lesson();
        lesson.setId(id + 100);
        lesson.setSubject(subject);

        Question question = new Question();
        question.setId(id);
        question.setType(QuestionType.MCQ);
        question.setQuestionText("Question " + id);
        question.setCorrectAnswer("A");
        question.setOptions("[\"A\",\"B\"]");
        question.setDifficultyLevel(1);
        question.setLesson(lesson);
        return question;
    }
}
