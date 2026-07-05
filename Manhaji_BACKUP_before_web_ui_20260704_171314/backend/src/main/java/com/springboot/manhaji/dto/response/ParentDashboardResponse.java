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
public class ParentDashboardResponse {
    private Long parentId;
    private String fullName;
    private List<ChildSummaryResponse> children;
    private List<QuizAttemptSummaryResponse> recentActivityAcrossChildren;
    private List<ParentAlertResponse> alerts;
    private List<ParentRecommendationResponse> recommendations;
}
