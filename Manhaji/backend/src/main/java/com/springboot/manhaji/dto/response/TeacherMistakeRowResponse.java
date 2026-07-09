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
public class TeacherMistakeRowResponse {
    private Long studentId;
    private String studentName;
    private Long subjectId;
    private String subjectName;
    private Long lessonId;
    private String lessonTitle;
    private Long questionId;
    private String questionText;
    private String studentAnswer;
    private String correctAnswer;
    private long mistakeCount;
    private LocalDateTime lastMistakeAt;
    private boolean commonMistake;
    private int affectedStudentsForQuestion;
}
