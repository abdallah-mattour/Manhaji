package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Live performance snapshot shown at the top of the "Performance Report" tab.
 * Computed on each fetch from current data (not stored per report), so the
 * numbers always reflect the student's latest state.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PerformanceStatsResponse {
    private int completedLessons;
    private int totalLessons;
    private int inProgressLessons;
    private double averageMastery;   // 0–100
    private double averageScore;     // 0–100, graded quizzes
    private int totalPoints;
    private int currentStreak;
    private int quizzesTaken;
    private List<SubjectStat> subjects;

    /**
     * The student's weakest sub-skills from the Bayesian Knowledge Tracing model
     * (practised but not yet mastered), weakest first. Drives the "focus areas"
     * section — unique to the Smart Reports screen (تقدمي shows raw stats only).
     */
    private List<FocusSkill> focusSkills;

    /** True when the student has no recorded activity yet (drives the empty state). */
    private boolean hasActivity;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FocusSkill {
        private String subSkill;       // raw tag, e.g. "pronunciation"
        private String subjectName;    // which subject this weak skill is in
        private double masteryPercent; // BKT P(mastered) × 100, 0–100
        private int observationCount;  // how many answers informed the estimate
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubjectStat {
        private String subjectName;
        private int completedLessons;
        private int totalLessons;
        private double averageMastery; // 0–100
    }
}
