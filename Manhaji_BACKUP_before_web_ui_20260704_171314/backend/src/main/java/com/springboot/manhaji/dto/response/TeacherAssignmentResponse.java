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
public class TeacherAssignmentResponse {
    private Long id;
    private Long teacherId;
    private Long subjectId;
    private String subjectName;
    private Integer gradeLevel;
    private Long schoolId;
    private String schoolName;
    private Boolean isActive;
    private LocalDateTime createdAt;
}
