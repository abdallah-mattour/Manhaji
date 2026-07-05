package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.TeacherAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Long> {

    @Query("""
            SELECT ta FROM TeacherAssignment ta
            JOIN FETCH ta.subject
            LEFT JOIN FETCH ta.school
            WHERE ta.teacher.id = :teacherId
              AND ta.isActive = true
            """)
    List<TeacherAssignment> findActiveByTeacherIdWithSubject(@Param("teacherId") Long teacherId);

    @Query("""
            SELECT CASE WHEN COUNT(ta) > 0 THEN true ELSE false END
            FROM TeacherAssignment ta
            WHERE ta.teacher.id = :teacherId
              AND ta.subject.id = :subjectId
              AND ta.isActive = true
            """)
    boolean existsActiveByTeacherIdAndSubjectId(
            @Param("teacherId") Long teacherId,
            @Param("subjectId") Long subjectId);

    Optional<TeacherAssignment> findByTeacherIdAndSubjectId(Long teacherId, Long subjectId);

    @Query("""
            SELECT ta.subject.id FROM TeacherAssignment ta
            WHERE ta.teacher.id = :teacherId
              AND ta.isActive = true
            """)
    List<Long> findActiveSubjectIdsByTeacherId(@Param("teacherId") Long teacherId);
}
