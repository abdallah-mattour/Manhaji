package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.CompletionStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;

@Entity
@Table(name = "progress",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"student_id", "lesson_id"})
        },
        indexes = {
                @Index(name = "idx_progress_student", columnList = "student_id"),
                @Index(name = "idx_progress_lesson", columnList = "lesson_id"),
                // Audit fix (2026-05-15): the parent dashboard hits
                // `findByStudentIdAndCompletionStatus`. This composite index
                // turns that into an index-only lookup.
                @Index(name = "idx_progress_student_status",
                        columnList = "student_id, completion_status")
        })
// Audit fix (2026-05-15): masteryLevel is a percentage. Out-of-range values
// would corrupt the home-screen "stars" and the analytics rollups.
@Check(constraints = "mastery_level BETWEEN 0 AND 100")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Progress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Double masteryLevel = 0.0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CompletionStatus completionStatus = CompletionStatus.NOT_STARTED;

    @Column
    private LocalDateTime lastAccessedAt;

    @Column
    private LocalDateTime completedAt;

    /**
     * Tier B / B4 (2026-05-15): index of the last lesson segment the student
     * was viewing when they navigated away. When they re-open the lesson, the
     * UI can jump to this segment instead of starting from segment 0. Closes
     * SR-10 ("pick up right where they last left off") and UC-1 alt flow A1.
     *
     * <p>Null on legacy rows / lessons without segments; the UI treats null
     * as "start from segment 0".
     */
    @Column
    private Integer lastSegmentIndex;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;
}
