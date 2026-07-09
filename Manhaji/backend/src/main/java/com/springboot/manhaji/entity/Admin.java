package com.springboot.manhaji.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Admin profile. Lives in its own {@code admins} table under JOINED
 * inheritance; the {@code permissions} column is admin-only and was
 * previously a nullable column polluting every student/teacher/parent row.
 */
@Entity
@Table(name = "admins")
@DiscriminatorValue("ADMIN")
@Getter
@Setter
@NoArgsConstructor
public class Admin extends User {

    @Column
    private String avatarId;

    @Column
    private String permissions;
}
