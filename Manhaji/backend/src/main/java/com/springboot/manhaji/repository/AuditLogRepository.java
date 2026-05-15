package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Tier B / B3 (2026-05-15): query side of the admin audit log. Pagination
 * is mandatory — these tables grow without ceiling and the dashboard view
 * should never load thousands of rows in one shot.
 */
@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {
    Page<AuditLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<AuditLog> findByActorUserIdOrderByCreatedAtDesc(Long actorUserId, Pageable pageable);
}
