package com.springboot.manhaji.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Tier 3 (2026-07): body for {@code PUT /api/student/avatar}. The avatar id is
 * a short registry key (e.g. "fox") — the emoji/name/unlock threshold live in
 * the Flutter-side registry, mirroring how avatarId is already stored on
 * {@code Student} and echoed by the dashboard/leaderboard DTOs.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateAvatarRequest {

    @NotBlank(message = "avatarId is required")
    @Size(max = 40, message = "avatarId too long")
    private String avatarId;
}
