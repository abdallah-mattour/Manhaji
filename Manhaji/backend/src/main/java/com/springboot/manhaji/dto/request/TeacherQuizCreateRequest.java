package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeacherQuizCreateRequest {
    @NotBlank
    private String title;

    @NotNull
    private Long subjectId;

    private Long lessonId;

    @NotEmpty
    private List<Long> questionIds;
}
