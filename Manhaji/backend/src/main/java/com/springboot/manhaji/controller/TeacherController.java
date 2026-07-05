package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.ClassStudentSummary;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.TeacherDashboardResponse;
import com.springboot.manhaji.dto.response.TeacherMistakeAnalyticsResponse;
import com.springboot.manhaji.service.TeacherService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/teacher")
@RequiredArgsConstructor
public class TeacherController {

    private final TeacherService teacherService;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<TeacherDashboardResponse>> getDashboard(Authentication authentication) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(teacherService.getDashboard(teacherId)));
    }

    @GetMapping("/students")
    public ResponseEntity<ApiResponse<List<ClassStudentSummary>>> getStudents(Authentication authentication) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(teacherService.getStudents(teacherId)));
    }

    @GetMapping("/students/{studentId}")
    public ResponseEntity<ApiResponse<StudentDetailResponse>> getStudent(
            Authentication authentication,
            @PathVariable("studentId") Long studentId) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(teacherService.getStudentDetail(teacherId, studentId)));
    }

    @GetMapping("/analytics/mistakes")
    @PreAuthorize("hasRole('TEACHER')")
    public ResponseEntity<ApiResponse<TeacherMistakeAnalyticsResponse>> getMistakeAnalytics(
            Authentication authentication,
            @RequestParam(name = "subjectId", required = false) Long subjectId,
            @RequestParam(name = "lessonId", required = false) Long lessonId,
            @RequestParam(name = "studentId", required = false) Long studentId,
            @RequestParam(name = "limit", required = false) Integer limit) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(teacherService.getMistakeAnalytics(
                teacherId, subjectId, lessonId, studentId, limit)));
    }

    // ==================== Question Bank (FR-9) ====================

    @GetMapping("/subjects")
    public ResponseEntity<ApiResponse<List<SubjectSummary>>> getAssignedSubjects(
            Authentication authentication) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(teacherService.getAssignedSubjects(teacherId)));
    }

    @GetMapping("/subjects/{subjectId}/questions")
    public ResponseEntity<ApiResponse<QuestionBankResponse>> getQuestionsForSubject(
            Authentication authentication,
            @PathVariable("subjectId") Long subjectId,
            @RequestParam(name = "difficulty", required = false) Integer difficulty,
            @RequestParam(name = "lessonId", required = false) Long lessonId) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(
                teacherService.getQuestionsForSubject(teacherId, subjectId, difficulty, lessonId)));
    }
}
