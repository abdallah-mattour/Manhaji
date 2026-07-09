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
public class StudentAssignedQuizSummaryResponse {
    private Long assignmentId;
    private Long quizId;
    private String title;
    private String subjectName;
    private Integer questionCount;
    private LocalDateTime dueAt;
    private String status;
    private Long attemptsUsed;
    private Integer maxAttempts;
    private Boolean canStart;
}
