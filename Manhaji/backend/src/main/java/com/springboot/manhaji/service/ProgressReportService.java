package com.springboot.manhaji.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.dto.response.ProgressReportResponse;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.ProgressReport;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.enums.RiskLevel;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.ProgressReportRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.SkillMasteryRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.entity.SkillMastery;
import com.springboot.manhaji.service.ai.BktEngine;
import com.springboot.manhaji.service.ai.GeminiService;
import com.springboot.manhaji.service.support.ProgressMetrics;
import java.util.Comparator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ProgressReportService {

    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final AttemptRepository attemptRepository;
    private final SubjectRepository subjectRepository;
    private final ProgressReportRepository reportRepository;
    private final GeminiService geminiService;
    private final ObjectMapper objectMapper;
    private final ProgressMetrics metrics;
    private final SkillMasteryRepository skillMasteryRepository;
    private final BktEngine bktEngine;

    /** How many weak sub-skills to surface as "focus areas". */
    private static final int FOCUS_SKILL_LIMIT = 3;

    @Transactional
    public ProgressReportResponse generateReport(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        String performanceData = buildPerformanceData(student);

        String aiResponse = geminiService.generateProgressReport(
                student.getFullName(), student.getGradeLevel(), performanceData);

        String summary;
        RiskLevel riskLevel = RiskLevel.LOW;

        String detailsJson = null;

        if (aiResponse != null) {
            // Gemini wraps JSON in ```json ... ``` fences despite the JSON-only
            // prompt; strip them before parsing or the raw blob leaks into the UI.
            String cleaned = GeminiService.stripJsonFences(aiResponse);
            try {
                JsonNode json = objectMapper.readTree(cleaned);
                summary = json.has("summary") ? json.get("summary").asText() : cleaned;
                if (json.has("riskLevel")) {
                    riskLevel = RiskLevel.valueOf(json.get("riskLevel").asText("LOW"));
                }
                detailsJson = extractDetailsJson(json);
            } catch (Exception e) {
                summary = cleaned;
                log.warn("Could not parse AI report as JSON, using raw text");
            }
        } else {
            summary = buildFallbackSummary(student);
            riskLevel = determineFallbackRisk(student);
        }

        ProgressReport report = new ProgressReport();
        report.setStudent(student);
        report.setPeriodStart(LocalDate.now().minusDays(30));
        report.setPeriodEnd(LocalDate.now());
        report.setSummary(summary);
        report.setDetailsJson(detailsJson);
        report.setRiskLevel(riskLevel);
        report = reportRepository.save(report);

        return toResponse(report);
    }

    /**
     * Re-serialises just the strengths/improvements/recommendations arrays from
     * the AI JSON into a compact object string for storage. Returns null if none
     * are present. Guaranteed-valid JSON (built via Jackson).
     */
    private String extractDetailsJson(JsonNode json) {
        var root = objectMapper.createObjectNode();
        boolean any = false;
        for (String key : new String[]{"strengths", "improvements", "recommendations"}) {
            if (json.has(key) && json.get(key).isArray()) {
                root.set(key, json.get(key));
                any = true;
            }
        }
        if (!any) return null;
        try {
            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Live performance snapshot for the report screen header — computed fresh
     * each call from current data, so the numbers always reflect the latest
     * state regardless of when reports were generated.
     */
    public com.springboot.manhaji.dto.response.PerformanceStatsResponse getStats(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        List<Progress> progressRecords = progressRepository.findByStudentId(student.getId());
        List<Attempt> attempts = attemptRepository.findByStudentIdOrderByCreatedAtDesc(student.getId());
        List<com.springboot.manhaji.dto.response.SubjectMasterySummary> breakdown =
                metrics.buildSubjectBreakdown(student, progressRecords);

        int completed = metrics.countCompleted(progressRecords);
        int inProgress = metrics.countInProgress(progressRecords);
        int totalLessons = breakdown.stream()
                .mapToInt(com.springboot.manhaji.dto.response.SubjectMasterySummary::getTotalLessons).sum();
        long graded = attempts.stream()
                .filter(a -> a.getStatus() == com.springboot.manhaji.entity.enums.AttemptStatus.GRADED)
                .count();

        var subjects = breakdown.stream()
                .map(s -> com.springboot.manhaji.dto.response.PerformanceStatsResponse.SubjectStat.builder()
                        .subjectName(s.getSubjectName())
                        .completedLessons(s.getLessonsCompleted())
                        .totalLessons(s.getTotalLessons())
                        .averageMastery(s.getAverageMastery())
                        .build())
                .toList();

        boolean hasActivity = completed > 0 || inProgress > 0 || graded > 0
                || student.getTotalPoints() > 0;

        return com.springboot.manhaji.dto.response.PerformanceStatsResponse.builder()
                .completedLessons(completed)
                .totalLessons(totalLessons)
                .inProgressLessons(inProgress)
                .averageMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .averageScore(ProgressMetrics.round2(metrics.averageGradedScore(attempts)))
                .totalPoints(student.getTotalPoints())
                .currentStreak(student.getCurrentStreak())
                .quizzesTaken((int) graded)
                .subjects(subjects)
                .focusSkills(buildFocusSkills(student.getId()))
                .hasActivity(hasActivity)
                .build();
    }

    /**
     * The student's weakest practised-but-unmastered sub-skills from the BKT
     * model, weakest first — the "مهارات تحتاج تركيز" section that makes the
     * Smart Reports screen distinct from the raw stats on تقدمي.
     *
     * <p>Only cells with real observations are considered (a never-practised
     * skill sitting at the BKT prior isn't a "weakness"), and mastered skills
     * are excluded so the list is genuinely actionable.
     */
    private List<com.springboot.manhaji.dto.response.PerformanceStatsResponse.FocusSkill>
            buildFocusSkills(Long studentId) {
        return skillMasteryRepository.findByStudentId(studentId).stream()
                .filter(sm -> sm.getObservationCount() > 0)
                .filter(sm -> !bktEngine.isMastered(sm.getPMastery()))
                .sorted(Comparator.comparingDouble(SkillMastery::getPMastery))
                .limit(FOCUS_SKILL_LIMIT)
                .map(sm -> com.springboot.manhaji.dto.response.PerformanceStatsResponse.FocusSkill.builder()
                        .subSkill(sm.getSubSkill())
                        .subjectName(sm.getSubject() != null ? sm.getSubject().getName() : "")
                        .masteryPercent(ProgressMetrics.round2(sm.getPMastery() * 100.0))
                        .observationCount(sm.getObservationCount())
                        .build())
                .toList();
    }

    public List<ProgressReportResponse> getReports(Long studentId) {
        return reportRepository.findByStudentIdOrderByGeneratedAtDesc(studentId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    private String buildPerformanceData(Student student) {
        List<Progress> progressRecords = progressRepository.findByStudentId(student.getId());
        List<Attempt> attempts = attemptRepository.findByStudentIdOrderByCreatedAtDesc(student.getId());
        List<Subject> subjects = subjectRepository.findByGradeLevel(student.getGradeLevel());

        int completed = metrics.countCompleted(progressRecords);
        double avgMastery = metrics.averageMastery(progressRecords);
        double avgScore = metrics.averageGradedScore(attempts);

        Map<Long, List<Progress>> bySubject = progressRecords.stream()
                .filter(p -> p.getLesson() != null && p.getLesson().getSubject() != null)
                .collect(Collectors.groupingBy(p -> p.getLesson().getSubject().getId()));

        StringBuilder sb = new StringBuilder();
        sb.append(String.format("النقاط: %d, السلسلة: %d\n", student.getTotalPoints(), student.getCurrentStreak()));
        sb.append(String.format("دروس مكتملة: %d, متوسط الإتقان: %.1f%%, متوسط الدرجات: %.1f%%\n",
                completed, avgMastery, avgScore));

        for (Subject subject : subjects) {
            List<Progress> sp = bySubject.getOrDefault(subject.getId(), List.of());
            double subMastery = metrics.averageMastery(sp);
            int subCompleted = metrics.countCompleted(sp);
            sb.append(String.format("%s: إتقان %.0f%%, مكتمل %d\n", subject.getName(), subMastery, subCompleted));
        }
        return sb.toString();
    }

    private String buildFallbackSummary(Student student) {
        List<Progress> progress = progressRepository.findByStudentId(student.getId());
        int completed = metrics.countCompleted(progress);
        double avg = metrics.averageMastery(progress);
        return String.format("أكمل الطالب %s عدد %d درس بمتوسط إتقان %.0f%%.",
                student.getFullName(), completed, avg);
    }

    private RiskLevel determineFallbackRisk(Student student) {
        List<Progress> progress = progressRepository.findByStudentId(student.getId());
        double avg = metrics.averageMastery(progress);
        if (avg >= 70) return RiskLevel.LOW;
        if (avg >= 40) return RiskLevel.MEDIUM;
        return RiskLevel.HIGH;
    }

    private ProgressReportResponse toResponse(ProgressReport report) {
        return ProgressReportResponse.builder()
                .id(report.getId())
                .studentId(report.getStudent().getId())
                .studentName(report.getStudent().getFullName())
                .periodStart(report.getPeriodStart())
                .periodEnd(report.getPeriodEnd())
                .summary(report.getSummary())
                .riskLevel(report.getRiskLevel())
                .generatedAt(report.getGeneratedAt())
                .strengths(readDetailList(report.getDetailsJson(), "strengths"))
                .improvements(readDetailList(report.getDetailsJson(), "improvements"))
                .recommendations(readDetailList(report.getDetailsJson(), "recommendations"))
                .build();
    }

    private List<String> readDetailList(String detailsJson, String key) {
        if (detailsJson == null || detailsJson.isBlank()) return List.of();
        try {
            JsonNode node = objectMapper.readTree(detailsJson).get(key);
            if (node == null || !node.isArray()) return List.of();
            List<String> out = new java.util.ArrayList<>();
            node.forEach(n -> {
                String s = n.asText("").trim();
                if (!s.isEmpty()) out.add(s);
            });
            return out;
        } catch (Exception e) {
            return List.of();
        }
    }
}
