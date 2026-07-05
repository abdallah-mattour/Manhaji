package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.RiskLevel;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "progress_reports",
        indexes = {
                @Index(name = "idx_report_student", columnList = "student_id"),
                // Audit fix (2026-05-15): the parent + teacher dashboards both
                // use `findByStudentIdOrderByGeneratedAtDesc`. This composite
                // index makes the ORDER BY index-resolved.
                @Index(name = "idx_report_student_generated",
                        columnList = "student_id, generated_at DESC")
        })
// Audit fix (2026-05-15): reporting periods must be ordered correctly.
// A swapped pair would render charts inverted or empty.
@Check(constraints = "period_end >= period_start")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ProgressReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private LocalDate periodStart;

    @Column(nullable = false)
    private LocalDate periodEnd;

    @Column(columnDefinition = "TEXT")
    private String summary;

    /**
     * AI-extracted detail lists (strengths / improvements / recommendations)
     * stored as a JSON object string, e.g.
     * {@code {"strengths":[...],"improvements":[...],"recommendations":[...]}}.
     * Plain TEXT (not a JSON column) so a malformed value can never crash the
     * insert; the service guarantees valid JSON. Null for older rows.
     */
    @Column(columnDefinition = "TEXT")
    private String detailsJson;

    @Enumerated(EnumType.STRING)
    @Column
    private RiskLevel riskLevel;

    @Column(nullable = false, updatable = false)
    private LocalDateTime generatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @PrePersist
    protected void onCreate() {
        this.generatedAt = LocalDateTime.now();
    }
}
