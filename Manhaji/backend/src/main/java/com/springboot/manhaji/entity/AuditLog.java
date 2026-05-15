package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Persistent record of an administrator action.
 *
 * <p>Tier B / B3 (2026-05-15): closes FR-11.2 from the proposal ("The
 * solution shall have audit logs for all administrative actions"). Written
 * automatically by {@code AdminActionAuditAspect} around every public method
 * of {@code AdminController}. Never written by other code paths — keep the
 * surface narrow so the audit is meaningful.
 */
@Entity
@Table(name = "audit_logs",
        indexes = {
                @Index(name = "idx_audit_actor", columnList = "actor_user_id"),
                @Index(name = "idx_audit_created", columnList = "created_at DESC")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Numeric ID of the admin user who performed the action.
     * Null when the action ran without an authenticated principal (e.g. a
     * boot-time seed; we don't expect this in practice).
     */
    @Column(name = "actor_user_id")
    private Long actorUserId;

    /** Snapshot of the actor's role at action time. Frozen so a later role change doesn't lose the audit trail. */
    @Column(length = 32)
    private String actorRole;

    /**
     * Short name of the controller method invoked (e.g. {@code "getStats"},
     * {@code "getUsers"}). Tied to method names, not URL paths, so a
     * route-refactor doesn't break the audit history.
     */
    @Column(nullable = false, length = 128)
    private String action;

    /** Brief textual summary of the operation: arguments and outcome class. */
    @Column(length = 512)
    private String details;

    /** HTTP method (GET/POST/...) — null for non-HTTP callers. */
    @Column(length = 8)
    private String httpMethod;

    /** Request URI for the call — null when not derivable. */
    @Column(length = 512)
    private String path;

    /** True iff the method returned normally; false if it threw. */
    @Column(nullable = false)
    private Boolean success;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
