package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherQuizDetailResponse {
    private Long id;
    private String title;
    private Long subjectId;
    private String subjectName;
    private Long lessonId;
    private String lessonTitle;
    private Integer questionCount;
    private LocalDateTime createdAt;
    private List<QuestionBankItem> questions;
}
