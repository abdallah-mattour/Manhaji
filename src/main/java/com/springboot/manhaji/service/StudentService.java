package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.StudentDashboardResponse;
import com.springboot.manhaji.dto.response.SubjectResponse;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;
    private final LessonService lessonService;

    public StudentDashboardResponse getDashboard(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        List<SubjectResponse> subjects = lessonService.getSubjectsByGrade(student.getGradeLevel(), studentId);

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
