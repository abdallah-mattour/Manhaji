package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentReportSummaryResponse {
    private Long id;
    private LocalDate periodStart;
    private LocalDate periodEnd;
    private String summary;
    private String riskLevel;
    private LocalDateTime generatedAt;
}
