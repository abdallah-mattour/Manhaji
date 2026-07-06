package com.springboot.manhaji.controller;

import com.springboot.manhaji.entity.School;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.TeacherAssignment;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.entity.enums.QuizStatus;
import com.springboot.manhaji.exception.GlobalExceptionHandler;
import com.springboot.manhaji.infrastructure.TestMessages;
import com.springboot.manhaji.dto.response.TeacherMistakeAnalyticsResponse;
import com.springboot.manhaji.dto.response.TeacherMistakeSummaryResponse;
import com.springboot.manhaji.dto.response.TeacherQuizDetailResponse;
import com.springboot.manhaji.dto.response.TeacherQuizSummaryResponse;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.QuizRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherAssignmentRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.service.TeacherService;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.service.support.QuestionBankMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.lang.reflect.Method;
import java.security.Principal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class TeacherControllerTest {

    @Mock private TeacherRepository teacherRepository;
    @Mock private TeacherAssignmentRepository teacherAssignmentRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private ProgressRepository progressRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private StudentResponseRepository studentResponseRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private LessonRepository lessonRepository;
    @Mock private QuestionRepository questionRepository;
    @Mock private QuizRepository quizRepository;

    private MockMvc mockMvc;
    private Teacher teacher;
    private School school;

    @BeforeEach
    void setUp() {
        TeacherService teacherService = new TeacherService(
                teacherRepository,
                teacherAssignmentRepository,
                studentRepository,
                progressRepository,
                attemptRepository,
                studentResponseRepository,
                subjectRepository,
                questionRepository,
                quizRepository,
                new QuestionBankMapper(),
                new ProgressMetrics(subjectRepository, lessonRepository),
                TestMessages.create());
        mockMvc = MockMvcBuilders
                .standaloneSetup(new TeacherController(teacherService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        school = new School();
        school.setId(7L);

        teacher = new Teacher();
        teacher.setId(10L);
        teacher.setRole(Role.TEACHER);
        teacher.setSchool(school);
    }

    @Test
    @DisplayName("questions endpoint binds subjectId path variable")
    void questionsEndpointBindsSubjectIdPathVariable() throws Exception {
        TeacherService mockedTeacherService = org.mockito.Mockito.mock(TeacherService.class);
        MockMvc controllerOnlyMockMvc = MockMvcBuilders
                .standaloneSetup(new TeacherController(mockedTeacherService))
                .build();

        controllerOnlyMockMvc.perform(get("/api/teacher/subjects/5/questions")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(mockedTeacherService).getQuestionsForSubject(10L, 5L, null, null);
    }

    @Test
    @DisplayName("mistake analytics endpoint binds optional filters")
    void mistakeAnalyticsEndpointBindsOptionalFilters() throws Exception {
        TeacherService mockedTeacherService = org.mockito.Mockito.mock(TeacherService.class);
        MockMvc controllerOnlyMockMvc = MockMvcBuilders
                .standaloneSetup(new TeacherController(mockedTeacherService))
                .build();
        when(mockedTeacherService.getMistakeAnalytics(10L, 100L, 200L, 1L, 25))
                .thenReturn(TeacherMistakeAnalyticsResponse.builder()
                        .summary(TeacherMistakeSummaryResponse.builder()
                                .totalMistakes(0)
                                .affectedStudents(0)
                                .build())
                        .mistakes(List.of())
                        .build());

        controllerOnlyMockMvc.perform(get("/api/teacher/analytics/mistakes")
                        .param("subjectId", "100")
                        .param("lessonId", "200")
                        .param("studentId", "1")
                        .param("limit", "25")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(mockedTeacherService).getMistakeAnalytics(10L, 100L, 200L, 1L, 25);
    }

    @Test
    @DisplayName("mistake analytics endpoint requires TEACHER role")
    void mistakeAnalyticsEndpointRequiresTeacherRole() throws Exception {
        Method method = TeacherController.class.getMethod(
                "getMistakeAnalytics",
                org.springframework.security.core.Authentication.class,
                Long.class,
                Long.class,
                Long.class,
                Integer.class);

        PreAuthorize annotation = method.getAnnotation(PreAuthorize.class);

        assertThat(annotation).isNotNull();
        assertThat(annotation.value()).isEqualTo("hasRole('TEACHER')");
    }

    @Test
    @DisplayName("teacher quiz endpoints bind requests")
    void teacherQuizEndpointsBindRequests() throws Exception {
        TeacherService mockedTeacherService = org.mockito.Mockito.mock(TeacherService.class);
        MockMvc controllerOnlyMockMvc = MockMvcBuilders
                .standaloneSetup(new TeacherController(mockedTeacherService))
                .build();

        controllerOnlyMockMvc.perform(get("/api/teacher/quizzes")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        controllerOnlyMockMvc.perform(post("/api/teacher/quizzes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "اختبار قصير",
                                  "subjectId": 5,
                                  "lessonId": 7,
                                  "questionIds": [10, 11]
                                }
                                """)
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        controllerOnlyMockMvc.perform(get("/api/teacher/quizzes/99")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(mockedTeacherService).getTeacherQuizzes(10L);
        verify(mockedTeacherService).createTeacherQuiz(
                org.mockito.ArgumentMatchers.eq(10L),
                argThat(request -> request.getSubjectId().equals(5L)
                        && request.getLessonId().equals(7L)
                        && request.getQuestionIds().equals(List.of(10L, 11L))));
        verify(mockedTeacherService).getTeacherQuiz(10L, 99L);
    }

    @Test
    @DisplayName("teacher quiz responses include status")
    void teacherQuizResponsesIncludeStatus() throws Exception {
        TeacherService mockedTeacherService = org.mockito.Mockito.mock(TeacherService.class);
        MockMvc controllerOnlyMockMvc = MockMvcBuilders
                .standaloneSetup(new TeacherController(mockedTeacherService))
                .build();

        when(mockedTeacherService.getTeacherQuizzes(10L))
                .thenReturn(List.of(TeacherQuizSummaryResponse.builder()
                        .id(44L)
                        .title("اختبار الحروف")
                        .status(QuizStatus.DRAFT)
                        .build()));
        when(mockedTeacherService.getTeacherQuiz(10L, 44L))
                .thenReturn(TeacherQuizDetailResponse.builder()
                        .id(44L)
                        .title("اختبار الحروف")
                        .status(QuizStatus.PUBLISHED)
                        .questions(List.of())
                        .build());

        controllerOnlyMockMvc.perform(get("/api/teacher/quizzes")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].status").value("DRAFT"));

        controllerOnlyMockMvc.perform(get("/api/teacher/quizzes/44")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PUBLISHED"));
    }

    @Test
    @DisplayName("teacher quiz endpoints require TEACHER role")
    void teacherQuizEndpointsRequireTeacherRole() throws Exception {
        Method listMethod = TeacherController.class.getMethod(
                "getTeacherQuizzes",
                org.springframework.security.core.Authentication.class);
        Method createMethod = TeacherController.class.getMethod(
                "createTeacherQuiz",
                org.springframework.security.core.Authentication.class,
                com.springboot.manhaji.dto.request.TeacherQuizCreateRequest.class);
        Method detailMethod = TeacherController.class.getMethod(
                "getTeacherQuiz",
                org.springframework.security.core.Authentication.class,
                Long.class);

        assertThat(listMethod.getAnnotation(PreAuthorize.class).value())
                .isEqualTo("hasRole('TEACHER')");
        assertThat(createMethod.getAnnotation(PreAuthorize.class).value())
                .isEqualTo("hasRole('TEACHER')");
        assertThat(detailMethod.getAnnotation(PreAuthorize.class).value())
                .isEqualTo("hasRole('TEACHER')");
    }

    @Test
    @DisplayName("Arabic teacher requesting Math questions returns 403")
    void unassignedSubjectQuestionsReturnForbidden() throws Exception {
        Subject arabic = createSubject(1L, "اللغة العربية");
        Subject math = createSubject(5L, "الرياضيات");
        when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
        when(subjectRepository.findById(5L)).thenReturn(Optional.of(math));
        when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                .thenReturn(List.of(createAssignment(arabic)));

        mockMvc.perform(get("/api/teacher/subjects/5/questions")
                        .principal(teacherPrincipal()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Subject is not assigned to this teacher"));

        verify(questionRepository, never()).findAllBySubjectIdWithLesson(anyLong());
        verify(teacherAssignmentRepository, never())
                .existsActiveByTeacherIdAndSubjectId(anyLong(), anyLong());
    }

    @Test
    @DisplayName("student outside assignment scope returns 403")
    void studentOutsideAssignmentScopeReturnsForbidden() throws Exception {
        Subject arabic = createSubject(1L, "اللغة العربية");
        School otherSchool = new School();
        otherSchool.setId(99L);
        Student student = new Student();
        student.setId(99L);
        student.setGradeLevel(1);
        student.setSchool(otherSchool);
        when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
        when(studentRepository.findById(99L)).thenReturn(Optional.of(student));
        when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                .thenReturn(List.of(createAssignment(arabic)));

        mockMvc.perform(get("/api/teacher/students/99")
                        .principal(teacherPrincipal()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Teacher cannot access this student"));
    }

    @Test
    @DisplayName("Arabic teacher requesting Arabic questions still succeeds")
    void assignedSubjectQuestionsStillSucceed() throws Exception {
        Subject arabic = createSubject(1L, "اللغة العربية");
        when(teacherRepository.findById(10L)).thenReturn(Optional.of(teacher));
        when(subjectRepository.findById(1L)).thenReturn(Optional.of(arabic));
        when(teacherAssignmentRepository.findActiveByTeacherIdWithSubject(10L))
                .thenReturn(List.of(createAssignment(arabic)));
        when(questionRepository.findAllBySubjectIdWithLesson(1L)).thenReturn(List.of());

        mockMvc.perform(get("/api/teacher/subjects/1/questions")
                        .principal(teacherPrincipal()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.subjectId").value(1))
                .andExpect(jsonPath("$.data.subjectName").value("اللغة العربية"));
    }

    private Principal teacherPrincipal() {
        return new UsernamePasswordAuthenticationToken(10L, null, List.of());
    }

    private Subject createSubject(Long id, String name) {
        Subject subject = new Subject();
        subject.setId(id);
        subject.setName(name);
        subject.setGradeLevel(1);
        return subject;
    }

    private TeacherAssignment createAssignment(Subject subject) {
        TeacherAssignment assignment = new TeacherAssignment();
        assignment.setTeacher(teacher);
        assignment.setSubject(subject);
        assignment.setGradeLevel(subject.getGradeLevel());
        assignment.setSchool(school);
        assignment.setIsActive(true);
        return assignment;
    }
}
