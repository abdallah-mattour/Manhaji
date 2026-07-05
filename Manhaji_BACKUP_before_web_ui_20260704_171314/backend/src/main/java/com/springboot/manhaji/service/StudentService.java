package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.StudentDashboardResponse;
import com.springboot.manhaji.dto.response.SubjectResponse;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class StudentService {

    private final StudentRepository studentRepository;
    private final LessonService lessonService;

    public StudentDashboardResponse getDashboard(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        // Post-screenshot fix (2026-05-24): when a Grade 2 student logged in we
        // returned an empty subjects list with no signal anywhere. Now we log
        // BOTH a missing-grade case and a no-subjects-for-grade case so the
        // developer sees the cause in stdout, and we guard against a null
        // gradeLevel (which used to silently fall through to
        // `findByGradeLevel(null)` → empty result).
        Integer gradeLevel = student.getGradeLevel();
        List<SubjectResponse> subjects;
        if (gradeLevel == null) {
            log.warn("Student {} ({}) has no gradeLevel set — returning empty subjects. "
                    + "Set gradeLevel on the student record to populate the dashboard.",
                    studentId, student.getFullName());
            subjects = Collections.emptyList();
        } else {
            subjects = lessonService.getSubjectsByGrade(gradeLevel, studentId);
            if (subjects.isEmpty()) {
                log.warn("Student {} ({}) is in grade {} but no Subject rows exist for that grade. "
                        + "Curriculum JSON for the grade may not have been seeded — "
                        + "restart the backend or set MANHAJI_CURRICULUM_RESEED=true to force re-import.",
                        studentId, student.getFullName(), gradeLevel);
            }
        }

        return StudentDashboardResponse.builder()
                .studentId(student.getId())
                .fullName(student.getFullName())
                .avatarId(student.getAvatarId())
                .gradeLevel(student.getGradeLevel())
                .currentStreak(student.getCurrentStreak())
                .totalPoints(student.getTotalPoints())
                .subjects(subjects)
                .build();
    }
}
