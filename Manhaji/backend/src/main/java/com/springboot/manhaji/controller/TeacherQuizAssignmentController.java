package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.request.TeacherQuizAssignmentRequest;
import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.TeacherAssignmentResultsResponse;
import com.springboot.manhaji.dto.response.TeacherQuizAssignmentResponse;
import com.springboot.manhaji.service.QuizAssignmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/teacher")
@RequiredArgsConstructor
public class TeacherQuizAssignmentController {

    private final QuizAssignmentService quizAssignmentService;

    @PostMapping("/quizzes/{quizId}/assignments")
    @PreAuthorize("hasRole('TEACHER')")
    public ResponseEntity<ApiResponse<TeacherQuizAssignmentResponse>> publishAssignment(
            Authentication authentication,
            @PathVariable("quizId") Long quizId,
            @Valid @RequestBody TeacherQuizAssignmentRequest request) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                quizAssignmentService.publishAssignment(teacherId, quizId, request)));
    }

    @GetMapping("/quizzes/{quizId}/assignments")
    @PreAuthorize("hasRole('TEACHER')")
    public ResponseEntity<ApiResponse<List<TeacherQuizAssignmentResponse>>> getQuizAssignments(
            Authentication authentication,
            @PathVariable("quizId") Long quizId) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                quizAssignmentService.getQuizAssignments(teacherId, quizId)));
    }

    @GetMapping("/assignments/{assignmentId}/results")
    @PreAuthorize("hasRole('TEACHER')")
    public ResponseEntity<ApiResponse<TeacherAssignmentResultsResponse>> getAssignmentResults(
            Authentication authentication,
            @PathVariable("assignmentId") Long assignmentId) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                quizAssignmentService.getAssignmentResults(teacherId, assignmentId)));
    }
}
