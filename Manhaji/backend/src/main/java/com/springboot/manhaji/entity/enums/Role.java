package com.springboot.manhaji.entity.enums;

/**
 * Roles used by the {@code @DiscriminatorColumn} on {@link com.springboot.manhaji.entity.User}
 * and by Spring Security's role-based access control.
 *
 * <p>Audit fix (2026-05-15): a stray {@code SCHOOL} value was removed. There
 * is no {@code @DiscriminatorValue("SCHOOL")} user subclass — {@code School}
 * is a separate entity (a tenant, not a login). Leaving the unreachable enum
 * value created a footgun where {@code role = 'SCHOOL'} rows could exist in
 * the users table with no matching Java class to deserialize them.
 */
public enum Role {
    STUDENT,
    TEACHER,
    PARENT,
    ADMIN
}
