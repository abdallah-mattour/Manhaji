package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "teacher_assignments",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_teacher_assignment_teacher_subject",
                columnNames = {"teacher_id", "subject_id"}
        ),
        indexes = {
                @Index(
                        name = "idx_teacher_assignment_teacher_active",
                        columnList = "teacher_id, is_active"
                )
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TeacherAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id", nullable = false)
    private Teacher teacher;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_id", nullable = false)
    private Subject subject;

    @Column(name = "grade_level", nullable = false)
    private Integer gradeLevel;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
