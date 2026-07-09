package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.request.TeacherQuizAssignmentRequest;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizDetailResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizSummaryResponse;
import com.springboot.manhaji.dto.response.TeacherAssignmentResultsResponse;
import com.springboot.manhaji.dto.response.TeacherQuizAssignmentResponse;
import com.springboot.manhaji.service.QuizAssignmentService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.lang.reflect.Method;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class QuizAssignmentControllerTest {

    @Test
    @DisplayName("teacher assignment endpoints bind path, body, and principal")
    void teacherAssignmentEndpointsBindRequests() throws Exception {
        QuizAssignmentService service = mock(QuizAssignmentService.class);
        MockMvc mockMvc = MockMvcBuilders
                .standaloneSetup(new TeacherQuizAssignmentController(service))
                .build();
        when(service.publishAssignment(eq(10L), eq(99L), org.mockito.ArgumentMatchers.any()))
                .thenReturn(TeacherQuizAssignmentResponse.builder()
                        .assignmentId(70L)
                        .assignedCount(2)
                        .build());
        when(service.getQuizAssignments(10L, 99L)).thenReturn(List.of(
                TeacherQuizAssignmentResponse.builder().assignmentId(70L).build()));
        when(service.getAssignmentResults(10L, 70L)).thenReturn(
                TeacherAssignmentResultsResponse.builder()
                        .assignmentId(70L)
                        .assignedCount(2)
                        .completedCount(1)
                        .build());

        mockMvc.perform(post("/api/teacher/quizzes/99/assignments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "gradeLevel": 1,
                                  "schoolId": 7,
                                  "maxAttempts": 2,
                                  "studentIds": [1, 2]
                                }
                                """)
                        .principal(principal(10L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.assignmentId").value(70));

        mockMvc.perform(get("/api/teacher/quizzes/99/assignments")
                        .principal(principal(10L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].assignmentId").value(70));

        mockMvc.perform(get("/api/teacher/assignments/70/results")
                        .principal(principal(10L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.completedCount").value(1));

        verify(service).publishAssignment(
                eq(10L),
                eq(99L),
                argThat(request -> request.getGradeLevel().equals(1)
                        && request.getSchoolId().equals(7L)
                        && request.getMaxAttempts().equals(2)
                        && request.getStudentIds().equals(List.of(1L, 2L))));
        verify(service).getQuizAssignments(10L, 99L);
        verify(service).getAssignmentResults(10L, 70L);
    }

    @Test
    @DisplayName("student assigned quiz endpoints bind path and principal")
    void studentAssignedQuizEndpointsBindRequests() throws Exception {
        QuizAssignmentService service = mock(QuizAssignmentService.class);
        MockMvc mockMvc = MockMvcBuilders
                .standaloneSetup(new StudentAssignedQuizController(service))
                .build();
        when(service.getAssignedQuizzes(1L)).thenReturn(List.of(
                StudentAssignedQuizSummaryResponse.builder()
                        .assignmentId(70L)
                        .quizId(99L)
                        .canStart(true)
                        .build()));
        when(service.getAssignedQuizDetail(1L, 70L)).thenReturn(
                StudentAssignedQuizDetailResponse.builder()
                        .assignmentId(70L)
                        .quizId(99L)
                        .build());
        when(service.startAssignedQuizAttempt(1L, 70L)).thenReturn(
                AttemptResponse.builder()
                        .attemptId(900L)
                        .quizId(99L)
                        .status("IN_PROGRESS")
                        .build());

        mockMvc.perform(get("/api/student/assigned-quizzes")
                        .principal(principal(1L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].assignmentId").value(70));

        mockMvc.perform(get("/api/student/assigned-quizzes/70")
                        .principal(principal(1L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.quizId").value(99));

        mockMvc.perform(post("/api/student/assigned-quizzes/70/attempt/start")
                        .principal(principal(1L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.attemptId").value(900));

        verify(service).getAssignedQuizzes(1L);
        verify(service).getAssignedQuizDetail(1L, 70L);
        verify(service).startAssignedQuizAttempt(1L, 70L);
    }

    @Test
    @DisplayName("new assignment endpoints require exact roles")
    void newAssignmentEndpointsRequireRoles() throws Exception {
        Method publish = TeacherQuizAssignmentController.class.getMethod(
                "publishAssignment",
                Authentication.class,
                Long.class,
                TeacherQuizAssignmentRequest.class);
        Method list = TeacherQuizAssignmentController.class.getMethod(
                "getQuizAssignments",
                Authentication.class,
                Long.class);
        Method results = TeacherQuizAssignmentController.class.getMethod(
                "getAssignmentResults",
                Authentication.class,
                Long.class);
        Method studentList = StudentAssignedQuizController.class.getMethod(
                "getAssignedQuizzes",
                Authentication.class);
        Method studentDetail = StudentAssignedQuizController.class.getMethod(
                "getAssignedQuizDetail",
                Authentication.class,
                Long.class);
        Method studentStart = StudentAssignedQuizController.class.getMethod(
                "startAssignedQuizAttempt",
                Authentication.class,
                Long.class);

        assertThat(publish.getAnnotation(PreAuthorize.class).value()).isEqualTo("hasRole('TEACHER')");
        assertThat(list.getAnnotation(PreAuthorize.class).value()).isEqualTo("hasRole('TEACHER')");
        assertThat(results.getAnnotation(PreAuthorize.class).value()).isEqualTo("hasRole('TEACHER')");
        assertThat(studentList.getAnnotation(PreAuthorize.class).value()).isEqualTo("hasRole('STUDENT')");
        assertThat(studentDetail.getAnnotation(PreAuthorize.class).value()).isEqualTo("hasRole('STUDENT')");
        assertThat(studentStart.getAnnotation(PreAuthorize.class).value()).isEqualTo("hasRole('STUDENT')");
    }

    private Authentication principal(Long userId) {
        return new UsernamePasswordAuthenticationToken(userId, null, List.of());
    }
}
