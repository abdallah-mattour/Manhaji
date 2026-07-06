package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherAssignmentResultsResponse {
    private Long assignmentId;
    private Long quizId;
    private String quizTitle;
    private Integer assignedCount;
    private Integer completedCount;
    private Double averageScore;
    private List<TeacherAssignmentAttemptResponse> recentAttempts;
}
