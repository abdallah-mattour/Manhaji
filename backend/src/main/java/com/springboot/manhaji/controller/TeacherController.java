package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.ClassStudentSummary;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.TeacherDashboardResponse;
import com.springboot.manhaji.service.TeacherService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
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
            @PathVariable Long studentId) {
        Long teacherId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(ApiResponse.success(teacherService.getStudentDetail(teacherId, studentId)));
    }
}
