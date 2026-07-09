package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.*;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.infrastructure.Messages;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.support.ProgressMetrics;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ParentService {

    private final ParentRepository parentRepository;
    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final AttemptRepository attemptRepository;
    private final LessonRepository lessonRepository;
    private final ProgressReportRepository progressReportRepository;
    private final ProgressMetrics metrics;
    private final Messages messages;

    public ParentDashboardResponse getDashboard(Long parentId) {
        Parent parent = parentRepository.findById(parentId)
                .orElseThrow(() -> new ResourceNotFoundException("Parent", parentId));

        List<Student> children = studentRepository.findByParentId(parentId);

        List<ChildSummaryResponse> childSummaries = new ArrayList<>();
        List<QuizAttemptSummaryResponse> recentActivity = new ArrayList<>();
        List<ParentAlertResponse> allAlerts = new ArrayList<>();
        List<ParentRecommendationResponse> allRecommendations = new ArrayList<>();

        for (Student child : children) {
            List<Progress> prog = progressRepository.findByStudentId(child.getId());
            List<Attempt> atts = attemptRepository.findByStudentIdOrderByCreatedAtDesc(child.getId());
            int totalLessons = lessonRepository
                    .findByGradeLevelOrderByOrderIndexAsc(child.getGradeLevel()).size();

            childSummaries.add(ChildSummaryResponse.builder()
                    .studentId(child.getId())
                    .fullName(child.getFullName())
                    .avatarId(child.getAvatarId())
                    .gradeLevel(child.getGradeLevel())
                    .totalPoints(child.getTotalPoints())
                    .currentStreak(child.getCurrentStreak())
                    .lessonsCompleted(metrics.countCompleted(prog))
                    .totalLessons(totalLessons)
                    .overallMastery(ProgressMetrics.round2(metrics.averageMastery(prog)))
                    .lastLoginAt(child.getLastLoginAt())
                    .build());

            atts.stream()
                    .filter(a -> a.getStatus() == AttemptStatus.GRADED && a.getScore() != null)
                    .limit(3)
                    .map(this::toAttemptSummary)
                    .forEach(recentActivity::add);

            List<ParentAlertResponse> childAlerts = buildAlerts(child, prog, atts);
            allAlerts.addAll(childAlerts);

            List<SubjectMasterySummary> subjectBreakdown = metrics.buildSubjectBreakdown(child, prog);
            allRecommendations.addAll(buildRecommendations(child, subjectBreakdown, childAlerts));
        }

        recentActivity.sort(Comparator.comparing(
                QuizAttemptSummaryResponse::getAttemptedAt,
                Comparator.nullsLast(Comparator.reverseOrder())));

        allRecommendations.sort(Comparator.comparing(
                r -> "HIGH".equals(r.getPriority()) ? 0 : 1));

        return ParentDashboardResponse.builder()
                .parentId(parent.getId())
                .fullName(parent.getFullName())
                .children(childSummaries)
                .recentActivityAcrossChildren(recentActivity.stream().limit(5).toList())
                .alerts(allAlerts)
                .recommendations(allRecommendations.stream().limit(6).toList())
                .build();
    }

    public StudentDetailResponse getChildDetail(Long parentId, Long childId) {
        parentRepository.findById(parentId)
                .orElseThrow(() -> new ResourceNotFoundException("Parent", parentId));

        Student child = studentRepository.findById(childId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", childId));

        if (child.getParent() == null || !child.getParent().getId().equals(parentId)) {
            throw new UnauthorizedException(messages.get("error.parent.childNotLinked"));
        }

        List<Progress> progressRecords = progressRepository.findByStudentId(childId);
        List<Attempt> attempts = attemptRepository.findByStudentIdOrderByCreatedAtDesc(childId);

        List<QuizAttemptSummaryResponse> recentAttempts = attempts.stream()
                .filter(a -> a.getStatus() == AttemptStatus.GRADED && a.getScore() != null)
                .limit(5)
                .map(this::toAttemptSummary)
                .toList();

        List<ParentReportSummaryResponse> reports = progressReportRepository
                .findByStudentIdOrderByGeneratedAtDesc(childId)
                .stream()
                .limit(3)
                .map(this::toReportSummary)
                .toList();

        List<SubjectMasterySummary> subjectBreakdown = metrics.buildSubjectBreakdown(child, progressRecords);
        List<ParentAlertResponse> childAlerts = buildAlerts(child, progressRecords, attempts);

        return StudentDetailResponse.builder()
                .studentId(child.getId())
                .fullName(child.getFullName())
                .email(child.getEmail())
                .phone(child.getPhone())
                .gradeLevel(child.getGradeLevel())
                .totalPoints(child.getTotalPoints())
                .currentStreak(child.getCurrentStreak())
                .lastLoginAt(child.getLastLoginAt())
                .createdAt(child.getCreatedAt())
                .lessonsCompleted(metrics.countCompleted(progressRecords))
                .lessonsInProgress(metrics.countInProgress(progressRecords))
                .overallMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .totalAttempts(attempts.size())
                .averageScore(ProgressMetrics.round2(metrics.averageGradedScore(attempts)))
                .subjectBreakdown(subjectBreakdown)
                .recentAttempts(recentAttempts)
                .alerts(childAlerts)
                .reports(reports)
                .recommendations(buildRecommendations(child, subjectBreakdown, childAlerts))
                .build();
    }

    private QuizAttemptSummaryResponse toAttemptSummary(Attempt a) {
        Quiz quiz = a.getQuiz();
        if (quiz == null) {
            return QuizAttemptSummaryResponse.builder()
                    .attemptId(a.getId())
                    .quizTitle("اختبار")
                    .score(a.getScore())
                    .status(a.getStatus().name())
                    .attemptedAt(a.getCreatedAt())
                    .build();
        }
        Lesson lesson = quiz.getLesson();
        Subject subject = lesson != null ? lesson.getSubject() : quiz.getSubject();
        return QuizAttemptSummaryResponse.builder()
                .attemptId(a.getId())
                .quizTitle(quiz.getTitle())
                .lessonTitle(lesson != null ? lesson.getTitle() : null)
                .subjectName(subject != null ? subject.getName() : null)
                .score(a.getScore())
                .status(a.getStatus().name())
                .attemptedAt(a.getCreatedAt())
                .build();
    }

    private ParentReportSummaryResponse toReportSummary(ProgressReport r) {
        return ParentReportSummaryResponse.builder()
                .id(r.getId())
                .periodStart(r.getPeriodStart())
                .periodEnd(r.getPeriodEnd())
                .summary(r.getSummary())
                .riskLevel(r.getRiskLevel() != null ? r.getRiskLevel().name() : null)
                .generatedAt(r.getGeneratedAt())
                .build();
    }

    private List<ParentAlertResponse> buildAlerts(
            Student student, List<Progress> progress, List<Attempt> attempts) {
        List<ParentAlertResponse> alerts = new ArrayList<>();
        Long studentId = student.getId();
        String name = student.getFullName();

        double mastery = metrics.averageMastery(progress);
        double avgScore = metrics.averageGradedScore(attempts);
        int inProgress = metrics.countInProgress(progress);

        if (!progress.isEmpty() && mastery > 0 && mastery < 60) {
            alerts.add(ParentAlertResponse.builder()
                    .studentId(studentId)
                    .alertType("LOW_MASTERY")
                    .message(name + " يحتاج دعماً: متوسط الإتقان " + Math.round(mastery) + "%")
                    .severity(mastery < 40 ? "HIGH" : "MEDIUM")
                    .studentName(name)
                    .build());
        }

        if (student.getLastLoginAt() != null
                && student.getLastLoginAt().isBefore(LocalDateTime.now().minusDays(7))) {
            alerts.add(ParentAlertResponse.builder()
                    .studentId(studentId)
                    .alertType("INACTIVE")
                    .message("لم يدخل " + name + " إلى التطبيق منذ أكثر من 7 أيام")
                    .severity("MEDIUM")
                    .studentName(name)
                    .build());
        }

        if (!attempts.isEmpty() && avgScore > 0 && avgScore < 50) {
            alerts.add(ParentAlertResponse.builder()
                    .studentId(studentId)
                    .alertType("LOW_SCORE")
                    .message("متوسط درجات " + name + " في الاختبارات: " + Math.round(avgScore) + "%")
                    .severity("MEDIUM")
                    .studentName(name)
                    .build());
        }

        if (inProgress > 2) {
            alerts.add(ParentAlertResponse.builder()
                    .studentId(studentId)
                    .alertType("INCOMPLETE_LESSONS")
                    .message("لدى " + name + " " + inProgress + " درس قيد التقدم")
                    .severity("MEDIUM")
                    .studentName(name)
                    .build());
        }

        return alerts;
    }

    private List<ParentRecommendationResponse> buildRecommendations(
            Student student, List<SubjectMasterySummary> subjectBreakdown, List<ParentAlertResponse> alerts) {
        List<ParentRecommendationResponse> recommendations = new ArrayList<>();
        String name = student.getFullName();

        subjectBreakdown.stream()
                .filter(s -> s.getAverageMastery() != null && s.getAverageMastery() > 0 && s.getAverageMastery() < 65)
                .forEach(subject -> recommendations.add(ParentRecommendationResponse.builder()
                        .type("WEAK_SUBJECT")
                        .title("راجعوا " + subject.getSubjectName() + " معاً")
                        .message("خصص 10 دقائق لمراجعة " + subject.getSubjectName() + " مع " + name + ".")
                        .priority(subject.getAverageMastery() < 40 ? "HIGH" : "MEDIUM")
                        .studentName(name)
                        .subjectName(subject.getSubjectName())
                        .actionLabel("مراجعة المادة")
                        .build()));

        for (ParentAlertResponse alert : alerts) {
            switch (alert.getAlertType()) {
                case "INACTIVE" -> recommendations.add(ParentRecommendationResponse.builder()
                        .type("ENCOURAGE_ACTIVITY")
                        .title("شجّع " + name + " على العودة للتطبيق")
                        .message(alert.getMessage())
                        .priority(alert.getSeverity())
                        .studentName(name)
                        .actionLabel("فتح التطبيق معاً")
                        .build());
                case "INCOMPLETE_LESSONS" -> recommendations.add(ParentRecommendationResponse.builder()
                        .type("FINISH_LESSONS")
                        .title("أكملوا الدروس المتبقية")
                        .message(alert.getMessage())
                        .priority(alert.getSeverity())
                        .studentName(name)
                        .actionLabel("متابعة الدروس")
                        .build());
                case "LOW_SCORE" -> recommendations.add(ParentRecommendationResponse.builder()
                        .type("IMPROVE_SCORES")
                        .title("راجعوا نتائج الاختبارات الأخيرة")
                        .message(alert.getMessage())
                        .priority(alert.getSeverity())
                        .studentName(name)
                        .actionLabel("مراجعة الاختبارات")
                        .build());
                default -> {
                }
            }
        }

        return recommendations;
    }
}
