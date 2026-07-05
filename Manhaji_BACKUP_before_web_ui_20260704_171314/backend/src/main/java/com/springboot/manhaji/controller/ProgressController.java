package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.LeaderboardEntryResponse;
import com.springboot.manhaji.dto.response.ProgressSummaryResponse;
import com.springboot.manhaji.service.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/progress")
@RequiredArgsConstructor
public class ProgressController {

    private final ProgressService progressService;

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<ProgressSummaryResponse>> getProgressSummary(
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        ProgressSummaryResponse summary = progressService.getProgressSummary(studentId);
        return ResponseEntity.ok(ApiResponse.success(summary));
    }

    @GetMapping("/leaderboard")
    public ResponseEntity<ApiResponse<List<LeaderboardEntryResponse>>> getLeaderboard(
            @RequestParam(name = "gradeLevel", required = false) Integer gradeLevel,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        List<LeaderboardEntryResponse> leaderboard = progressService.getLeaderboard(studentId, gradeLevel);
        return ResponseEntity.ok(ApiResponse.success(leaderboard));
    }

    /**
     * Tier B / B4 (2026-05-15): track which lesson segment the student is
     * viewing so they can resume after navigating away. Closes SR-10
     * ("pick up right where they last left off") and UC-1 alt flow A1.
     *
     * <p>Idempotent: callable on every segment advance (next/prev tap) or
     * just once on dispose. Creates the Progress row if none exists.
     */
    @org.springframework.web.bind.annotation.PatchMapping("/lesson/{lessonId}/segment/{segmentIndex}")
    public ResponseEntity<ApiResponse<Void>> setLastSegment(
            @org.springframework.web.bind.annotation.PathVariable("lessonId") Long lessonId,
            @org.springframework.web.bind.annotation.PathVariable("segmentIndex") Integer segmentIndex,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        progressService.updateLastSegmentIndex(studentId, lessonId, segmentIndex);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
