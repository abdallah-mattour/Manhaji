package com.springboot.manhaji.entity;

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
                        columnList = "lesson_id, gamified")
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

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

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
