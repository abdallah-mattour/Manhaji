package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.enums.QuizType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface QuizRepository extends JpaRepository<Quiz, Long> {
    List<Quiz> findByLessonId(Long lessonId);
    List<Quiz> findByLessonIdAndGamified(Long lessonId, Boolean gamified);

    /**
     * The single PERSONALIZED quiz kept per (student, subject). The
     * personalized-quiz generator finds-or-creates this row and repopulates
     * its questions on each "Challenge Me" tap.
     */
    Optional<Quiz> findByGeneratedForStudentIdAndSubjectIdAndQuizType(
            Long generatedForStudentId, Long subjectId, QuizType quizType);

    @Query("""
            SELECT DISTINCT quiz FROM Quiz quiz
            LEFT JOIN FETCH quiz.subject subject
            LEFT JOIN FETCH quiz.lesson lesson
            LEFT JOIN FETCH lesson.subject lessonSubject
            LEFT JOIN FETCH quiz.questions question
            LEFT JOIN FETCH question.lesson questionLesson
            LEFT JOIN FETCH questionLesson.subject questionSubject
            WHERE quiz.generatedForStudentId IS NULL
              AND (subject.id IN :subjectIds
               OR lessonSubject.id IN :subjectIds)
            ORDER BY quiz.createdAt DESC, quiz.id DESC
            """)
    List<Quiz> findTeacherVisibleBySubjectIds(@Param("subjectIds") List<Long> subjectIds);

    @Query("""
            SELECT DISTINCT quiz FROM Quiz quiz
            LEFT JOIN FETCH quiz.subject subject
            LEFT JOIN FETCH quiz.lesson lesson
            LEFT JOIN FETCH lesson.subject lessonSubject
            LEFT JOIN FETCH quiz.questions question
            LEFT JOIN FETCH question.lesson questionLesson
            LEFT JOIN FETCH questionLesson.subject questionSubject
            WHERE quiz.id = :quizId
            """)
    Optional<Quiz> findByIdWithTeacherDetails(@Param("quizId") Long quizId);

    /**
     * Direct join-table read so DataSeeder can check which questions are already
     * attached to a quiz without pulling the lazy collection (which requires an
     * open Hibernate session).
     */
    @Query("SELECT q.id FROM Quiz qu JOIN qu.questions q WHERE qu.id = :quizId")
    List<Long> findQuestionIdsByQuizId(@Param("quizId") Long quizId);
}
