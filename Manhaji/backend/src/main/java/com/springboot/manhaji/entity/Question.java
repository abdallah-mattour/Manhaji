package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.QuestionType;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "questions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private QuestionType type;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String questionText;

    @Column(nullable = false)
    private String correctAnswer;

    @Column(columnDefinition = "JSON")
    private String options;

    @Column(nullable = false)
    private Integer difficultyLevel = 1;

    /**
     * Optional sub-skill tag — drives mastery analytics so we can tell e.g.
     * recognition-vs-handwriting weakness within a single lesson. Allowed
     * values defined in {@code Manhaji/docs/question-authoring-spec.md} §6.
     * When null, the client/scoring layer derives it from {@code type}.
     */
    @Column(length = 32)
    private String subSkill;

    /**
     * Optional path to an image asset (e.g.
     * {@code /assets/questions/ar/letters/ra/remmaan.png}). Bundled under
     * {@code src/main/resources/static/} and served by Spring at the matching URL.
     */
    @Column(length = 512)
    private String imageUrl;

    /**
     * Optional path to an audio asset (mp3 or m4a). Used by Religion Surah
     * questions for reciter playback, and by English vocabulary questions
     * for native pronunciation playback.
     */
    @Column(length = 512)
    private String audioUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @ManyToMany(mappedBy = "questions")
    private List<Quiz> quizzes = new ArrayList<>();
}
