package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
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
