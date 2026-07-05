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
public class TeacherQuizSummaryResponse {
    private Long id;
    private String title;
    private Long subjectId;
    private String subjectName;
    private Long lessonId;
    private String lessonTitle;
    private Integer questionCount;
    private LocalDateTime createdAt;
}
