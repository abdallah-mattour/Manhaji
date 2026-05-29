package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;

/**
 * Persisted Bayesian Knowledge Tracing (BKT) state for one
 * (student × subject × sub-skill) cell.
 *
 * <p>{@code pMastery} is the BKT posterior P(the student has mastered this
 * sub-skill), updated after every quiz response via
 * {@code SkillMasteryService} / {@code BktEngine}. It starts at the prior
 * P(L0) and converges toward 1.0 with correct answers, away with wrong ones.
 *
 * <p>This is the model that powers both the personalized quiz generator
 * (weakest sub-skills get more questions) and the "My Skills" radar chart.
 * Before this entity existed, the only mastery signal was per-lesson
 * ({@link Progress}); there was no per-skill model.
 */
@Entity
@Table(
        name = "skill_mastery",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_skill_mastery",
                columnNames = {"student_id", "subject_id", "sub_skill"}
        ),
        indexes = {
                @Index(name = "idx_skill_mastery_student_subject",
                        columnList = "student_id, subject_id")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SkillMastery {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "subject_id", nullable = false)
    private Subject subject;

    /** Sub-skill tag — same vocabulary as {@code Question.subSkill}. */
    @Column(name = "sub_skill", nullable = false, length = 32)
    private String subSkill;

    /** BKT posterior P(mastered), in [0,1]. Defaults to the prior P(L0). */
    @Column(name = "p_mastery", nullable = false)
    @Check(constraints = "p_mastery >= 0 AND p_mastery <= 1")
    private Double pMastery = 0.30;

    /** How many responses have informed this estimate (for cold-start checks). */
    @Column(nullable = false)
    private Integer observationCount = 0;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
