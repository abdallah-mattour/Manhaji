package com.springboot.manhaji.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParentAlertResponse {
    private Long studentId;
    private String alertType;
    private String message;
    private String severity;
    private String studentName;
}
