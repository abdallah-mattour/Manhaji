package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.QuestionType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(
        name = "questions",
        // Audit fix (2026-05-15): `findByLessonIdAndDifficultyLevel` is hit by
        // the adaptive selector. The single FK index on lesson_id wouldn't
        // narrow the difficulty filter; the composite index handles both.
        indexes = {
                @Index(name = "idx_question_lesson_difficulty",
                        columnList = "lesson_id, difficulty_level")
        }
)
// Audit fix (2026-05-15): difficulty 0 or 4+ would break the adaptive engine's
// L1/L2/L3 bucketing. The audit lint (R7) already catches this on the JSON
// authoring side; this is belt-and-suspenders at the DB level.
@Check(constraints = "difficulty_level BETWEEN 1 AND 3")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    // Post-screenshot fix (2026-05-24): Hibernate's first CREATE TABLE for an
    // EnumType.STRING column uses the longest enum value at that time as the
    // VARCHAR length. The original schema was created before PRONUNCIATION
    // (13 chars) and TRACING were added, so existing dev DBs had a too-short
    // column and inserts truncated/failed. Pinning to 32 gives headroom for
    // future enum values; existing DBs need a one-time
    // `ALTER TABLE questions MODIFY COLUMN type VARCHAR(32)`.
    @Column(nullable = false, length = 32)
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

    /**
     * Tier 1 (2026-06): JSON array of image paths, parallel to {@code options},
     * for IMAGE_MCQ / LISTEN_CHOOSE — each option can show a picture. Null for
     * non-image types. Image-ready: the client falls back to option text when a
     * given entry is null/missing, so a question works even before images ship.
     * Example: {@code ["/assets/openmoji/apple.png", "/assets/openmoji/banana.png"]}
     */
    @Column(columnDefinition = "JSON")
    private String optionImages;

    /**
     * Tier 1 (2026-06): JSON for IMAGE_MATCH — the two columns to pair plus the
     * correct mapping, e.g.
     * {@code {"left":[{"id":"a","text":"تفاحة","image":"…apple.png"}],
     *          "right":[{"id":"1","text":"apple"}],
     *          "answer":{"a":"1"}}}.
     * Null for non-match types.
     */
    @Column(columnDefinition = "JSON")
    private String pairsJson;

    /**
     * Fingerprint of the spoken text the cached TTS clip at {@code audioUrl}
     * was generated from (see {@code TtsService.speechFingerprint}). Lets the
     * audio cache self-invalidate: when {@code questionText} is edited, the
     * stored hash no longer matches and {@code AudioController} regenerates the
     * clip instead of serving the stale one.
     *
     * <p>Only set for TTS-generated clips (URL under {@code uploads/audio/}).
     * Stays null for authored asset audio (bundled reciter/native-speaker
     * files), which must never be overwritten by synthesis.
     */
    @Column(length = 64)
    private String audioTextHash;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @ManyToMany(mappedBy = "questions")
    private List<Quiz> quizzes = new ArrayList<>();
}
