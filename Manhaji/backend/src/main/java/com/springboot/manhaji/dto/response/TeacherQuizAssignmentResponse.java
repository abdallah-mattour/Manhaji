package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherQuizAssignmentResponse {
    private Long assignmentId;
    private Long quizId;
    private String quizTitle;
    private Long subjectId;
    private String subjectName;
    private Long schoolId;
    private String schoolName;
    private Integer gradeLevel;
    private String status;
    private LocalDateTime publishedAt;
    private LocalDateTime dueAt;
    private Integer maxAttempts;
    private Integer assignedCount;
}
