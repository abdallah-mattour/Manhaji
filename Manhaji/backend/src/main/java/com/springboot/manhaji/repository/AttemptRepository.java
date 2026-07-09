package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttemptRepository extends JpaRepository<Attempt, Long> {
    List<Attempt> findByStudentIdOrderByCreatedAtDesc(Long studentId);
    List<Attempt> findByStudentIdAndQuizId(Long studentId, Long quizId);
    Optional<Attempt> findByStudentIdAndQuizIdAndStatus(Long studentId, Long quizId, AttemptStatus status);
    List<Attempt> findByStudentIdAndStatus(Long studentId, AttemptStatus status);
    Optional<Attempt> findByStudentIdAndQuizAssignmentIdAndStatus(
            Long studentId,
            Long quizAssignmentId,
            AttemptStatus status);
    long countByStudentIdAndQuizAssignmentId(Long studentId, Long quizAssignmentId);
    List<Attempt> findByQuizAssignmentIdOrderByCreatedAtDesc(Long quizAssignmentId);

    @Query("""
            SELECT a FROM Attempt a
            JOIN FETCH a.quiz q
            LEFT JOIN FETCH q.lesson l
            LEFT JOIN FETCH l.subject lessonSubject
            LEFT JOIN FETCH q.subject quizSubject
            WHERE a.student.id = :studentId
              AND (
                    lessonSubject.id IN :subjectIds
                    OR quizSubject.id IN :subjectIds
              )
            ORDER BY a.createdAt DESC
            """)
    List<Attempt> findByStudentIdAndSubjectIdsOrderByCreatedAtDesc(
            @Param("studentId") Long studentId,
            @Param("subjectIds") List<Long> subjectIds);
}
