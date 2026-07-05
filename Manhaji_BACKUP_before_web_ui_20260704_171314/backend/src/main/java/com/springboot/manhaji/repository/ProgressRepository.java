package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProgressRepository extends JpaRepository<Progress, Long> {
    Optional<Progress> findByStudentIdAndLessonId(Long studentId, Long lessonId);
    List<Progress> findByStudentId(Long studentId);
    List<Progress> findByStudentIdAndCompletionStatus(Long studentId, CompletionStatus completionStatus);
    List<Progress> findByStudentIdIn(List<Long> studentIds);

    @Query("""
            SELECT p FROM Progress p
            JOIN FETCH p.student
            JOIN FETCH p.lesson l
            JOIN FETCH l.subject s
            WHERE p.student.id IN :studentIds
              AND s.id IN :subjectIds
            """)
    List<Progress> findByStudentIdsAndSubjectIds(
            @Param("studentIds") List<Long> studentIds,
            @Param("subjectIds") List<Long> subjectIds);

    @Query("""
            SELECT p FROM Progress p
            JOIN FETCH p.lesson l
            JOIN FETCH l.subject s
            WHERE p.student.id = :studentId
              AND s.id IN :subjectIds
            """)
    List<Progress> findByStudentIdAndSubjectIds(
            @Param("studentId") Long studentId,
            @Param("subjectIds") List<Long> subjectIds);
}
