package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.StudentDashboardResponse;
import com.springboot.manhaji.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/student")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<StudentDashboardResponse>> getDashboard(Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        StudentDashboardResponse dashboard = studentService.getDashboard(studentId);
        return ResponseEntity.ok(ApiResponse.success(dashboard));
    }
}
