package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.ChildSummaryResponse;
import com.springboot.manhaji.dto.response.ParentDashboardResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.dto.response.SubjectMasterySummary;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Parent;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ParentRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.support.Messages;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
    private final ProgressMetrics metrics;
    private final Messages messages;

    public ParentDashboardResponse getDashboard(Long parentId) {
        Parent parent = parentRepository.findById(parentId)
                .orElseThrow(() -> new ResourceNotFoundException("Parent", parentId));

        List<Student> children = studentRepository.findByParentId(parentId);

        List<ChildSummaryResponse> childSummaries = children.stream()
                .map(this::buildChildSummary)
                .toList();

        return ParentDashboardResponse.builder()
                .parentId(parent.getId())
                .fullName(parent.getFullName())
                .children(childSummaries)
                .build();
    }

    public StudentDetailResponse getChildDetail(Long parentId, Long childId) {
        Parent parent = parentRepository.findById(parentId)
                .orElseThrow(() -> new ResourceNotFoundException("Parent", parentId));

        Student child = studentRepository.findById(childId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", childId));

        if (child.getParent() == null || !child.getParent().getId().equals(parentId)) {
            throw new UnauthorizedException(messages.get("error.parent.childNotLinked"));
        }

        List<Progress> progressRecords = progressRepository.findByStudentId(childId);
        List<Attempt> attempts = attemptRepository.findByStudentIdOrderByCreatedAtDesc(childId);

        List<SubjectMasterySummary> subjectBreakdown = metrics.buildSubjectBreakdown(child, progressRecords);

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
                .build();
    }

    private ChildSummaryResponse buildChildSummary(Student student) {
        List<Progress> progressRecords = progressRepository.findByStudentId(student.getId());

        int totalLessons = lessonRepository
                .findByGradeLevelOrderByOrderIndexAsc(student.getGradeLevel())
                .size();

        return ChildSummaryResponse.builder()
                .studentId(student.getId())
                .fullName(student.getFullName())
                .avatarId(student.getAvatarId())
                .gradeLevel(student.getGradeLevel())
                .totalPoints(student.getTotalPoints())
                .currentStreak(student.getCurrentStreak())
                .lessonsCompleted(metrics.countCompleted(progressRecords))
                .totalLessons(totalLessons)
                .overallMastery(ProgressMetrics.round2(metrics.averageMastery(progressRecords)))
                .lastLoginAt(student.getLastLoginAt())
                .build();
    }
}
