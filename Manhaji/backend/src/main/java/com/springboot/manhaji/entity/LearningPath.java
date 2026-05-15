package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "learning_paths")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LearningPath {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "JSON")
    private String recommendations;

    // Audit fix (2026-05-15): `updatable = false` was dropped so the
    // @PreUpdate hook below can refresh the timestamp when recommendations
    // are regenerated. The "outdated timestamp in UI" symptom was caused by
    // the field staying frozen at the initial generation time.
    @Column(nullable = false)
    private LocalDateTime generatedAt;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false, unique = true)
    private Student student;

    @PrePersist
    protected void onCreate() {
        this.generatedAt = LocalDateTime.now();
    }

    /**
     * Audit fix (2026-05-15): refresh {@code generatedAt} on every regenerate
     * so the parent dashboard's "last updated" timestamp reflects reality.
     */
    @PreUpdate
    protected void onUpdate() {
        this.generatedAt = LocalDateTime.now();
    }
}
