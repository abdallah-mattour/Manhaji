package com.springboot.manhaji.entity;

import com.springboot.manhaji.entity.enums.Role;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Check;

import java.time.LocalDateTime;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_user_role", columnList = "role"),
        @Index(name = "idx_user_parent", columnList = "parent_id"),
        @Index(name = "idx_user_school", columnList = "school_id"),
        // Audit fix (2026-05-15): use the physical DB column name explicitly
        // (`grade_level`, snake_case) rather than the camelCase Java field
        // name. Hibernate's SpringPhysicalNamingStrategy translates @Column
        // names but the safer, portable form is to specify the DB column.
        @Index(name = "idx_user_school_grade", columnList = "school_id, grade_level")
})
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "role", discriminatorType = DiscriminatorType.STRING)
// Audit fix (2026-05-15): a user must have at least one of email / phone for
// login. Currently the application validates this in AuthService.register but
// nothing prevents a direct INSERT (or a test fixture) from creating an
// unloggable user. MySQL's UNIQUE permits multiple NULLs so the existing
// unique constraints on email + phone don't enforce this.
@Check(constraints = "email IS NOT NULL OR phone IS NOT NULL")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public abstract class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String fullName;

    @Column(unique = true)
    private String email;

    @Column(unique = true)
    private String phone;

    @Column(nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", insertable = false, updatable = false)
    private Role role;

    @Column(nullable = false)
    private Boolean isActive = true;

    private LocalDateTime lastLoginAt;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
