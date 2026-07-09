package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentRecommendationResponse {
    private String type;
    private String title;
    private String message;
    private String priority;
    private String studentName;
    private String subjectName;
    private String actionLabel;
}
