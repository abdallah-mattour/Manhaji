package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(
        name = "lessons",
        // Audit fix (2026-05-15): a lesson is uniquely identified within a
        // subject by its semester + position. Without this constraint, two
        // lessons could share orderIndex within the same subject/semester
        // and the UI ordering would be undefined.
        uniqueConstraints = @UniqueConstraint(
                name = "uk_lesson_subject_semester_order",
                columnNames = {"subject_id", "semester_number", "order_index"}
        ),
        // Audit fix (2026-05-15): both common lesson-list queries
        // (`findBySubjectIdOrderByOrderIndexAsc`,
        //  `findByGradeLevelOrderByOrderIndexAsc`) sort by orderIndex inside
        // a partition. The unique-constraint index above includes
        // semester_number in the middle, so it only helps when semester is in
        // the filter. These two composite indexes handle the no-semester case.
        indexes = {
                @Index(name = "idx_lesson_subject_order",
                        columnList = "subject_id, order_index"),
                @Index(name = "idx_lesson_grade_order",
                        columnList = "grade_level, order_index")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Lesson {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Integer gradeLevel;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String content;

    /**
     * Tier B / B4 (2026-05-15): optional JSON array of segment strings.
     * When non-null, the lesson UI renders {@code segmentsJson[lastSegmentIndex..]}
     * with prev/next controls so students can resume mid-lesson per UC-1 alt
     * flow A1. When null, the UI falls back to rendering the single-block
     * {@code content} field unchanged (existing behaviour preserved).
     *
     * <p>Schema example: {@code ["مرحبا بحرف الراء", "كلمات تبدأ بحرف الراء: رمان، ريشة", "لنتدرب على نطق ر"]}
     */
    @Column(columnDefinition = "TEXT")
    private String segmentsJson;

    @Column
    private String audioUrl;

    /**
     * Fingerprint of the spoken text the cached narration at {@code audioUrl}
     * was generated from (see {@code TtsService.speechFingerprint}). Lets the
     * narration cache self-invalidate when the lesson title/content is edited,
     * mirroring {@code Question.audioTextHash}.
     */
    @Column(length = 64)
    private String audioTextHash;

    @Column(columnDefinition = "JSON")
    private String imageUrls;

    @Column(columnDefinition = "TEXT")
    private String objectives;

    @Column
    private String styleNarration;

    @Column(nullable = false)
    private Integer orderIndex = 0;

    @Column(nullable = false)
    private Integer semesterNumber = 1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_id", nullable = false)
    private Subject subject;

    @OneToMany(mappedBy = "lesson", cascade = CascadeType.ALL)
    private List<Question> questions = new ArrayList<>();

    @OneToMany(mappedBy = "lesson", cascade = CascadeType.ALL)
    private List<Quiz> quizzes = new ArrayList<>();
}
