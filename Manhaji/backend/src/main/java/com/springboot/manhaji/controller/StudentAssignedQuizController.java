package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizDetailResponse;
import com.springboot.manhaji.dto.response.StudentAssignedQuizSummaryResponse;
import com.springboot.manhaji.service.QuizAssignmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/student/assigned-quizzes")
@RequiredArgsConstructor
public class StudentAssignedQuizController {

    private final QuizAssignmentService quizAssignmentService;

    @GetMapping
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<List<StudentAssignedQuizSummaryResponse>>> getAssignedQuizzes(
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                quizAssignmentService.getAssignedQuizzes(studentId)));
    }

    @GetMapping("/{assignmentId}")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<StudentAssignedQuizDetailResponse>> getAssignedQuizDetail(
            Authentication authentication,
            @PathVariable("assignmentId") Long assignmentId) {
        Long studentId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                quizAssignmentService.getAssignedQuizDetail(studentId, assignmentId)));
    }

    @PostMapping("/{assignmentId}/attempt/start")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<AttemptResponse>> startAssignedQuizAttempt(
            Authentication authentication,
            @PathVariable("assignmentId") Long assignmentId) {
        Long studentId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                quizAssignmentService.startAssignedQuizAttempt(studentId, assignmentId)));
    }
}
