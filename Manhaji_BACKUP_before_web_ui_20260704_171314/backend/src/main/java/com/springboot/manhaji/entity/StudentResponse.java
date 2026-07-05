package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "student_responses",
        // Audit fix (2026-05-15): `findByAttemptId` is the hot path on the
        // results screen (and the completeAttempt dedupe). The FK alone is
        // implicit-indexed by MySQL, but naming it explicitly avoids any
        // surprises if the underlying engine changes.
        indexes = {
                @Index(name = "idx_response_attempt", columnList = "attempt_id"),
                @Index(name = "idx_response_question", columnList = "question_id")
        })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StudentResponse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "TEXT")
    private String spokenText;

    @Column(columnDefinition = "TEXT")
    private String evaluatedText;

    @Column
    private String audioRef;

    // Audit fix (2026-05-15): isCorrect is required for scoring and was always
    // set by QuizService.submitAnswer + submitTracingResult. Tightening to
    // nullable=false prevents a future code path from accidentally leaving it
    // null, which would propagate NaN into the score aggregate.
    @Column(nullable = false)
    private Boolean isCorrect;

    @Column(columnDefinition = "TEXT")
    private String feedback;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "attempt_id", nullable = false)
    private Attempt attempt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;
}
