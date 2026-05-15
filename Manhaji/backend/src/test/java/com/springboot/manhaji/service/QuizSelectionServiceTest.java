package com.springboot.manhaji.service;

import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Tier A / A1 (2026-05-15): verifies the adaptive selection scoring.
 *
 * <p>Strategy: hand-build a small lesson (5 questions of varying type +
 * difficulty + sub-skill) and a fabricated response history, then assert
 * that the returned ordering matches the expected "weakest first" intent.
 * Edge cases: no history → fixed order, lesson with one question → returns it.
 */
@ExtendWith(MockitoExtension.class)
class QuizSelectionServiceTest {

    @Mock private QuestionRepository questionRepository;
    @Mock private StudentResponseRepository responseRepository;

    private QuizSelectionService service;

    private Lesson lesson;

    @BeforeEach
    void setUp() {
        service = new QuizSelectionService(questionRepository, responseRepository);

        lesson = new Lesson();
        lesson.setId(1L);
        lesson.setGradeLevel(1);
        lesson.setTitle("حرف الراء");
    }

    /** Build a Question with id + type + difficulty + (optional) explicit subSkill. */
    private Question q(long id, QuestionType type, int difficulty, String subSkill) {
        Question q = new Question();
        q.setId(id);
        q.setType(type);
        q.setQuestionText("Q" + id);
        q.setCorrectAnswer("a");
        q.setDifficultyLevel(difficulty);
        q.setSubSkill(subSkill);
        q.setLesson(lesson);
        return q;
    }

    /** Build a response: attempt → student, question → lesson, isCorrect. */
    private StudentResponse response(Long studentId, Question question, boolean correct) {
        Student s = new Student();
        s.setId(studentId);
        Attempt a = new Attempt();
        a.setStudent(s);

        StudentResponse r = new StudentResponse();
        r.setAttempt(a);
        r.setQuestion(question);
        r.setIsCorrect(correct);
        return r;
    }

    @Test
    @DisplayName("no prior history → returns first N in fixed order (no-signal fallback)")
    void noHistoryFallsBackToFixedOrder() {
        Question q1 = q(1L, QuestionType.MCQ, 1, "recognition");
        Question q2 = q(2L, QuestionType.PRONUNCIATION, 2, "pronunciation");
        Question q3 = q(3L, QuestionType.TRACING, 1, "handwriting");

        when(questionRepository.findByLessonIdOrderByIdAsc(1L))
                .thenReturn(List.of(q1, q2, q3));
        when(responseRepository.findByStudentIdAndLessonId(100L, 1L))
                .thenReturn(List.of()); // empty history

        List<Question> result = service.selectAdaptive(100L, 1L, 3);

        assertThat(result).containsExactly(q1, q2, q3);
    }

    @Test
    @DisplayName("respects target count even when lesson has more questions")
    void clampsToTargetCount() {
        Question q1 = q(1L, QuestionType.MCQ, 1, "recognition");
        Question q2 = q(2L, QuestionType.MCQ, 1, "recognition");
        Question q3 = q(3L, QuestionType.MCQ, 1, "recognition");
        Question q4 = q(4L, QuestionType.MCQ, 1, "recognition");
        Question q5 = q(5L, QuestionType.MCQ, 1, "recognition");

        when(questionRepository.findByLessonIdOrderByIdAsc(1L))
                .thenReturn(List.of(q1, q2, q3, q4, q5));
        when(responseRepository.findByStudentIdAndLessonId(any(), any()))
                .thenReturn(List.of());

        assertThat(service.selectAdaptive(100L, 1L, 2)).hasSize(2);
        assertThat(service.selectAdaptive(100L, 1L, 99)).hasSize(5); // clamped to available
    }

    @Test
    @DisplayName("empty lesson → empty result")
    void emptyLessonReturnsEmpty() {
        when(questionRepository.findByLessonIdOrderByIdAsc(1L)).thenReturn(List.of());

        assertThat(service.selectAdaptive(100L, 1L, 10)).isEmpty();
    }

    @Test
    @DisplayName("weak sub-skill gets prioritised over mastered sub-skill")
    void weakSubSkillRanksHigher() {
        // Student is great at "recognition" (got 4/4 right) but bad at
        // "pronunciation" (0/2). Practice should surface pronunciation first.
        Question recog = q(1L, QuestionType.MCQ, 1, "recognition");
        Question pron  = q(2L, QuestionType.PRONUNCIATION, 1, "pronunciation");
        Question other = q(3L, QuestionType.TRUE_FALSE, 1, "comprehension");

        when(questionRepository.findByLessonIdOrderByIdAsc(1L))
                .thenReturn(List.of(recog, pron, other));

        // History: 4 correct on recognition, 2 wrong on pronunciation, no comprehension.
        when(responseRepository.findByStudentIdAndLessonId(100L, 1L)).thenReturn(List.of(
                response(100L, recog, true),
                response(100L, recog, true),
                response(100L, recog, true),
                response(100L, recog, true),
                response(100L, pron, false),
                response(100L, pron, false)
        ));

        List<Question> result = service.selectAdaptive(100L, 1L, 3);

        // Pronunciation should be ahead of mastered recognition.
        int pronIdx = result.indexOf(pron);
        int recogIdx = result.indexOf(recog);
        assertThat(pronIdx).isLessThan(recogIdx);
    }

    @Test
    @DisplayName("difficulty fit: when student masters L1, prefer L2 next")
    void difficultyFitPrefersStretchLevel() {
        // Student got 4 L1 questions all correct in the same sub-skill.
        // The "target difficulty" should be ~1.5, biasing toward L2.
        Question easy1 = q(1L, QuestionType.MCQ, 1, "recognition");
        Question easy2 = q(2L, QuestionType.MCQ, 1, "recognition");
        Question medium = q(3L, QuestionType.MCQ, 2, "recognition");
        Question hard = q(4L, QuestionType.MCQ, 3, "recognition");

        when(questionRepository.findByLessonIdOrderByIdAsc(1L))
                .thenReturn(List.of(easy1, easy2, medium, hard));

        // All-correct L1 history.
        when(responseRepository.findByStudentIdAndLessonId(100L, 1L)).thenReturn(List.of(
                response(100L, easy1, true),
                response(100L, easy1, true),
                response(100L, easy2, true),
                response(100L, easy2, true)
        ));

        List<Question> result = service.selectAdaptive(100L, 1L, 4);

        // Medium (L2) should rank ahead of the L1s the student has mastered
        // AND ahead of the L3 (too big a jump).
        int mediumIdx = result.indexOf(medium);
        int hardIdx = result.indexOf(hard);
        assertThat(mediumIdx).isLessThan(hardIdx);
        // Medium should be at the top (sub-skill mastered, novelty highest, diff fit best).
        assertThat(result.get(0)).isEqualTo(medium);
    }
}
