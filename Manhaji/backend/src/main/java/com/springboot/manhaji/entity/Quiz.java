package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.QuizType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "quizzes",
        // Audit fix (2026-05-15): `findByLessonIdAndGamified` is the home-screen
        // filter (gamified vs practice quizzes). The FK alone covers lesson_id
        // only; this composite serves both filters together.
        indexes = {
                @Index(name = "idx_quiz_lesson_gamified",
                        columnList = "lesson_id, gamified"),
                // Personalized-quiz feature (2026-05-27): find-or-create the
                // single PERSONALIZED quiz per (student, subject).
                @Index(name = "idx_quiz_personalized",
                        columnList = "generated_for_student_id, subject_id, quiz_type")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Quiz {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private Boolean gamified = false;

    @Column(nullable = false)
    private Boolean generatedFromLesson = false;

    /**
     * Personalized-quiz feature (2026-05-27): LESSON for the conventional
     * per-lesson quizzes (the default for every existing row), PERSONALIZED
     * for Knowledge-Tracing-generated cross-lesson quizzes.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "quiz_type", nullable = false, length = 16)
    private QuizType quizType = QuizType.LESSON;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * The lesson this quiz belongs to. NULL for PERSONALIZED quizzes, which
     * span a subject's lessons rather than belonging to one. Was
     * {@code nullable = false} before the personalized-quiz feature.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = true)
    private Lesson lesson;

    /**
     * The subject a PERSONALIZED quiz draws from. NULL for LESSON quizzes
     * (their subject is reachable via {@code lesson.getSubject()}).
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_id")
    private Subject subject;

    /**
     * For PERSONALIZED quizzes: the student this quiz was generated for.
     * NULL for LESSON quizzes (which are shared across all students). We
     * keep ONE personalized quiz row per (student, subject) and repopulate
     * its questions on each generation.
     */
    @Column(name = "generated_for_student_id")
    private Long generatedForStudentId;

    // Audit fix (2026-05-15): without the unique constraint on the join
    // table, the same Question could be linked to the same Quiz multiple
    // times (e.g. via accidental re-add). The unique constraint makes the
    // join-table row idempotent and ensures `quiz.questions` is set-like.
    @ManyToMany
    @JoinTable(
            name = "quiz_questions",
            joinColumns = @JoinColumn(name = "quiz_id"),
            inverseJoinColumns = @JoinColumn(name = "question_id"),
            uniqueConstraints = @UniqueConstraint(
                    name = "uk_quiz_question",
                    columnNames = {"quiz_id", "question_id"}
            )
    )
    private List<Question> questions = new ArrayList<>();

    @OneToMany(mappedBy = "quiz", cascade = CascadeType.ALL)
    private List<Attempt> attempts = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
