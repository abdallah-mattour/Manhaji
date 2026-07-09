package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherMistakeSummaryResponse {
    private int totalMistakes;
    private int affectedStudents;
    private Long mostMistakenLessonId;
    private String mostMistakenLessonTitle;
    private Long mostMistakenQuestionId;
    private String mostMistakenQuestionText;
}
