package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.request.AdminCreateUserRequest;
import com.springboot.manhaji.dto.request.AdminUpdateUserRequest;
import com.springboot.manhaji.dto.request.LinkParentRequest;
import com.springboot.manhaji.dto.request.TeacherAssignmentRequest;
import com.springboot.manhaji.dto.response.AdminStatsResponse;
import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.QuestionBankResponse;
import com.springboot.manhaji.dto.response.SubjectSummary;
import com.springboot.manhaji.dto.response.TeacherAssignmentResponse;
import com.springboot.manhaji.dto.response.UserSummaryResponse;
import com.springboot.manhaji.entity.AuditLog;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.repository.AuditLogRepository;
import com.springboot.manhaji.service.AdminService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final AuditLogRepository auditLogRepository;

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AdminStatsResponse>> getStats() {
        return ResponseEntity.ok(ApiResponse.success(adminService.getStats()));
    }

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserSummaryResponse>>> getUsers(
            @RequestParam(name = "role", required = false) Role role) {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllUsers(role)));
    }

    // ==================== CRUD for STUDENT + TEACHER ====================

    @PostMapping("/users")
    public ResponseEntity<ApiResponse<UserSummaryResponse>> createUser(
            @Valid @RequestBody AdminCreateUserRequest request) {
        return ResponseEntity.ok(ApiResponse.success(adminService.createUser(request)));
    }

    @PutMapping("/users/{userId}")
    public ResponseEntity<ApiResponse<UserSummaryResponse>> updateUser(
            @PathVariable("userId") Long userId,
            @Valid @RequestBody AdminUpdateUserRequest request) {
        return ResponseEntity.ok(ApiResponse.success(adminService.updateUser(userId, request)));
    }

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable("userId") Long userId) {
        Long callerUserId = currentUserId();
        adminService.deleteUser(userId, callerUserId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    @PutMapping("/students/{studentId}/link-parent")
    public ResponseEntity<ApiResponse<UserSummaryResponse>> linkParent(
            @PathVariable("studentId") Long studentId,
            @RequestBody LinkParentRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                adminService.linkStudentToParent(studentId, request.getParentId())));
    }

    @GetMapping("/teachers/{teacherId}/assignments")
    public ResponseEntity<ApiResponse<List<TeacherAssignmentResponse>>> getTeacherAssignments(
            @PathVariable("teacherId") Long teacherId) {
        return ResponseEntity.ok(ApiResponse.success(
                adminService.getTeacherAssignments(teacherId)));
    }

    @PutMapping("/teachers/{teacherId}/assignments")
    public ResponseEntity<ApiResponse<List<TeacherAssignmentResponse>>> replaceTeacherAssignments(
            @PathVariable("teacherId") Long teacherId,
            @Valid @RequestBody List<@Valid TeacherAssignmentRequest> request) {
        return ResponseEntity.ok(ApiResponse.success(
                adminService.replaceTeacherAssignments(teacherId, request)));
    }

    // ==================== Question Bank (FR-9, unrestricted) ====================

    @GetMapping("/subjects")
    public ResponseEntity<ApiResponse<List<SubjectSummary>>> getSubjects(
            @RequestParam(name = "grade", required = false) Integer grade) {
        return ResponseEntity.ok(ApiResponse.success(adminService.getAllSubjects(grade)));
    }

    @GetMapping("/subjects/{subjectId}/questions")
    public ResponseEntity<ApiResponse<QuestionBankResponse>> getQuestionsForSubject(
            @PathVariable("subjectId") Long subjectId,
            @RequestParam(name = "difficulty", required = false) Integer difficulty,
            @RequestParam(name = "lessonId", required = false) Long lessonId) {
        return ResponseEntity.ok(ApiResponse.success(
                adminService.getQuestionsForSubject(subjectId, difficulty, lessonId)));
    }

    /**
     * Tier B / B3 (2026-05-15): paginated audit-log viewer. Closes FR-11.2.
     * Default page size capped at 50 so a careless ?size=10000 can't pin the
     * server. Most-recent-first ordering.
     */
    @GetMapping("/audit-logs")
    public ResponseEntity<ApiResponse<Page<AuditLog>>> getAuditLogs(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "50") int size,
            @RequestParam(name = "actorUserId", required = false) Long actorUserId) {
        int safeSize = Math.max(1, Math.min(size, 200));
        PageRequest pageable = PageRequest.of(Math.max(0, page), safeSize);
        Page<AuditLog> result = actorUserId == null
                ? auditLogRepository.findAllByOrderByCreatedAtDesc(pageable)
                : auditLogRepository.findByActorUserIdOrderByCreatedAtDesc(actorUserId, pageable);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    private Long currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null && auth.getPrincipal() instanceof Long id) ? id : null;
    }
}
