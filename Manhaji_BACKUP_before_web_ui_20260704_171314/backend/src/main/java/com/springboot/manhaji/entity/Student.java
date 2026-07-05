package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Student profile data. With JOINED inheritance (see {@link User}), the
 * physical row layout is:
 * <pre>
 *   users    : (id, email, phone, password_hash, role='STUDENT', ...)
 *   students : (id ←FK→ users.id, grade_level, avatar_id, current_streak,
 *               total_points, current_lesson_id, school_id, parent_id)
 * </pre>
 * Existing FKs from {@code attempts}, {@code progress}, {@code learning_paths},
 * etc. that point at {@code users.id} keep working — the student's id is the
 * same value in both tables.
 */
@Entity
@Table(name = "students", indexes = {
        @Index(name = "idx_student_parent", columnList = "parent_id"),
        @Index(name = "idx_student_school", columnList = "school_id"),
        @Index(name = "idx_student_school_grade", columnList = "school_id, grade_level")
})
@DiscriminatorValue("STUDENT")
@Getter
@Setter
@NoArgsConstructor
public class Student extends User {

    @Column
    private Integer gradeLevel;

    @Column
    private String avatarId;

    // Audit fix (2026-05-15): dropped the MySQL-specific `INTEGER NOT NULL DEFAULT 0`
    // columnDefinition. The Java field initializer already supplies the default
    // for new entities, and `nullable = false` is portable across MySQL / Postgres /
    // H2 alike.
    @Column(nullable = false)
    private Integer currentStreak = 0;

    @Column(nullable = false)
    private Integer totalPoints = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_lesson_id")
    private Lesson currentLesson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "school_id")
    private School school;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private Parent parent;

    @OneToMany(mappedBy = "student", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Progress> progressRecords = new ArrayList<>();

    @OneToMany(mappedBy = "student", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Attempt> attempts = new ArrayList<>();

    @OneToOne(mappedBy = "student", cascade = CascadeType.ALL, orphanRemoval = true)
    private LearningPath learningPath;
}
