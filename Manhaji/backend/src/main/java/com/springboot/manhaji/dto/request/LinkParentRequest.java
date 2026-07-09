package com.springboot.manhaji.dto.request;

import lombok.Data;

@Data
public class LinkParentRequest {
    private Long parentId; // null = unlink
}
