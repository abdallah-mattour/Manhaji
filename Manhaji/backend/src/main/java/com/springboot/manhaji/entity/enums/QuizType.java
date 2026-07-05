package com.springboot.manhaji.entity.enums;

/**
 * Distinguishes a normal lesson quiz from a generated personalized quiz.
 *
 * <ul>
 *   <li>{@code LESSON} — the conventional quiz bound to one {@code Lesson}
 *       (every quiz before the personalized-quiz feature). {@code lesson_id}
 *       is set; {@code subject}/{@code generatedForStudentId} are null.</li>
 *   <li>{@code PERSONALIZED} — a Knowledge-Tracing-generated quiz that pulls
 *       questions from across one subject's lessons, targeting the student's
 *       weakest sub-skills. {@code lesson_id} is null; {@code subject} and
 *       {@code generatedForStudentId} are set. One such row is kept per
 *       (student, subject) and its {@code quiz_questions} are repopulated on
 *       each "Challenge Me" generation.</li>
 * </ul>
 */
public enum QuizType {
    LESSON,
    PERSONALIZED,
    TEACHER_ASSIGNED
}
