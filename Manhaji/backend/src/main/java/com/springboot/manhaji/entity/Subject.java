package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(
        name = "subjects",
        // Audit fix (2026-05-15): a subject is uniquely identified by its
        // name + grade level. Without this constraint, two "اللغة العربية"
        // Grade 1 rows could exist after a hand-edit or test-double bug, and
        // DataSeeder's findByNameAndGradeLevel idempotency would silently
        // pick one at random.
        uniqueConstraints = @UniqueConstraint(
                name = "uk_subject_name_grade",
                columnNames = {"name", "grade_level"}
        ),
        // Audit fix (2026-05-15): `findByGradeLevel` is the home-screen
        // entry-point query (listing subjects for the student's grade).
        // The unique-constraint index above is on (name, grade_level) so it
        // only serves prefix matches on `name`, not lookups on `grade_level`.
        indexes = {
                @Index(name = "idx_subject_grade", columnList = "grade_level")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Subject {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Integer gradeLevel;

    @OneToMany(mappedBy = "subject", cascade = CascadeType.ALL)
    private List<Lesson> lessons = new ArrayList<>();
}
