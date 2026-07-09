package com.springboot.manhaji.config;

import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.function.Consumer;

/**
 * Temporary one-shot migration runner: replaces @manhaji.local demo accounts
 * with official accounts supplied via environment variables.
 *
 * Enabled only when MANHAJI_REPLACE_DEMO_ACCOUNTS=true is exported.
 * Remove this file after successful migration.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AccountMigrationRunner implements CommandLineRunner {

    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final TeacherRepository teacherRepository;
    private final ParentRepository parentRepository;
    private final StudentRepository studentRepository;
    private final PasswordEncoder passwordEncoder;
    private final PlatformTransactionManager txManager;

    @Override
    public void run(String... args) {
        if (!"true".equalsIgnoreCase(System.getenv("MANHAJI_REPLACE_DEMO_ACCOUNTS"))) {
            log.debug("AccountMigrationRunner: disabled (MANHAJI_REPLACE_DEMO_ACCOUNTS not set to true)");
            return;
        }

        log.info("AccountMigrationRunner: MANHAJI_REPLACE_DEMO_ACCOUNTS=true — validating env vars");

        final String adminEmail   = requireEnv("MANHAJI_ADMIN_EMAIL");
        final String adminName    = requireEnv("MANHAJI_ADMIN_FULL_NAME");
        final String adminPw      = requireEnv("MANHAJI_ADMIN_PASSWORD");
        final String teacherEmail = requireEnv("MANHAJI_TEACHER_EMAIL");
        final String teacherName  = requireEnv("MANHAJI_TEACHER_FULL_NAME");
        final String teacherPw    = requireEnv("MANHAJI_TEACHER_PASSWORD");
        final String parentEmail  = requireEnv("MANHAJI_PARENT_EMAIL");
        final String parentName   = requireEnv("MANHAJI_PARENT_FULL_NAME");
        final String parentPw     = requireEnv("MANHAJI_PARENT_PASSWORD");
        final String studentEmail = requireEnv("MANHAJI_STUDENT_EMAIL");
        final String studentName  = requireEnv("MANHAJI_STUDENT_FULL_NAME");
        final String studentPw    = requireEnv("MANHAJI_STUDENT_PASSWORD");
        final int    gradeLevel   = parseGradeLevel(System.getenv("MANHAJI_STUDENT_GRADE_LEVEL"));

        log.info("AccountMigrationRunner: env vars OK — starting transaction");

        new TransactionTemplate(txManager).executeWithoutResult(status -> {

            // --- Idempotency guard ---
            boolean allDemoGone =
                    !userRepository.existsByEmail("admin@manhaji.local") &&
                    !userRepository.existsByEmail("teacher@manhaji.local") &&
                    !userRepository.existsByEmail("parent@manhaji.local") &&
                    !userRepository.existsByEmail("student@manhaji.local");
            if (allDemoGone && userRepository.existsByEmail(adminEmail)) {
                log.warn("AccountMigrationRunner: already applied — skipping. " +
                         "Unset MANHAJI_REPLACE_DEMO_ACCOUNTS.");
                return;
            }

            // --- Step 1: Delete demo accounts in safe FK order ---

            // Student first: holds parent_id FK pointing at demo parent
            deleteDemo("student@manhaji.local", Role.STUDENT,
                    id -> studentRepository.findById(id).ifPresent(s -> {
                        studentRepository.delete(s);
                        log.info("AccountMigrationRunner: deleted student@manhaji.local");
                    }));

            // Parent second: safe now that student row (parent_id=3) is gone
            deleteDemo("parent@manhaji.local", Role.PARENT,
                    id -> parentRepository.findById(id).ifPresent(p -> {
                        parentRepository.delete(p);
                        log.info("AccountMigrationRunner: deleted parent@manhaji.local");
                    }));

            // Teacher (no blocking FKs among the demo rows)
            deleteDemo("teacher@manhaji.local", Role.TEACHER,
                    id -> teacherRepository.findById(id).ifPresent(t -> {
                        teacherRepository.delete(t);
                        log.info("AccountMigrationRunner: deleted teacher@manhaji.local");
                    }));

            // Admin last
            deleteDemo("admin@manhaji.local", Role.ADMIN,
                    id -> adminRepository.findById(id).ifPresent(a -> {
                        adminRepository.delete(a);
                        log.info("AccountMigrationRunner: deleted admin@manhaji.local");
                    }));

            // --- Step 2: Insert official accounts ---

            if (!userRepository.existsByEmail(adminEmail)) {
                Admin admin = new Admin();
                admin.setFullName(adminName);
                admin.setEmail(adminEmail);
                admin.setPasswordHash(passwordEncoder.encode(adminPw));
                admin.setIsActive(true);
                admin.setPermissions("ALL");
                adminRepository.save(admin);
                log.info("AccountMigrationRunner: created admin {}", adminEmail);
            } else {
                log.warn("AccountMigrationRunner: {} already exists — skip admin insert", adminEmail);
            }

            if (!userRepository.existsByEmail(teacherEmail)) {
                Teacher teacher = new Teacher();
                teacher.setFullName(teacherName);
                teacher.setEmail(teacherEmail);
                teacher.setPasswordHash(passwordEncoder.encode(teacherPw));
                teacher.setIsActive(true);
                teacher.setAssignedGrade(1);
                teacherRepository.save(teacher);
                log.info("AccountMigrationRunner: created teacher {}", teacherEmail);
            } else {
                log.warn("AccountMigrationRunner: {} already exists — skip teacher insert", teacherEmail);
            }

            // Parent must be persisted before student so we have its generated id
            Parent[] parentRef = {null};
            if (!userRepository.existsByEmail(parentEmail)) {
                Parent parent = new Parent();
                parent.setFullName(parentName);
                parent.setEmail(parentEmail);
                parent.setPasswordHash(passwordEncoder.encode(parentPw));
                parent.setIsActive(true);
                parentRef[0] = parentRepository.save(parent);
                log.info("AccountMigrationRunner: created parent {}", parentEmail);
            } else {
                log.warn("AccountMigrationRunner: {} already exists — skip parent insert", parentEmail);
                Long pid = userRepository.findByEmail(parentEmail)
                        .map(User::getId)
                        .orElseThrow(() -> new IllegalStateException(
                                "existsByEmail=true but findByEmail empty for " + parentEmail));
                parentRef[0] = parentRepository.findById(pid)
                        .orElseThrow(() -> new IllegalStateException(
                                "Parent child row missing for id=" + pid));
            }

            if (!userRepository.existsByEmail(studentEmail)) {
                Student student = new Student();
                student.setFullName(studentName);
                student.setEmail(studentEmail);
                student.setPasswordHash(passwordEncoder.encode(studentPw));
                student.setIsActive(true);
                student.setGradeLevel(gradeLevel);
                student.setCurrentStreak(0);
                student.setTotalPoints(0);
                student.setParent(parentRef[0]);
                studentRepository.save(student);
                log.info("AccountMigrationRunner: created student {} (grade={}, parent={})",
                        studentEmail, gradeLevel, parentEmail);
            } else {
                log.warn("AccountMigrationRunner: {} already exists — skip student insert", studentEmail);
            }
        });

        log.info("========================================================");
        log.info("AccountMigrationRunner: SUCCESS");
        log.info("ACTION REQUIRED: unset MANHAJI_REPLACE_DEMO_ACCOUNTS before next startup.");
        log.info("========================================================");
    }

    private void deleteDemo(String email, Role expectedRole, Consumer<Long> deleter) {
        userRepository.findByEmail(email).ifPresentOrElse(u -> {
            if (u.getRole() != expectedRole) {
                throw new IllegalStateException(
                        "AccountMigrationRunner: " + email + " has role " + u.getRole() +
                        " but expected " + expectedRole + " — aborting");
            }
            deleter.accept(u.getId());
        }, () -> log.warn("AccountMigrationRunner: {} not found — already removed?", email));
    }

    private String requireEnv(String name) {
        String val = System.getenv(name);
        if (val == null || val.isBlank()) {
            throw new IllegalStateException(
                    "AccountMigrationRunner: required env var '" + name + "' is missing or blank. " +
                    "Set all MANHAJI_*_EMAIL/FULL_NAME/PASSWORD before enabling MANHAJI_REPLACE_DEMO_ACCOUNTS.");
        }
        return val;
    }

    private int parseGradeLevel(String raw) {
        if (raw == null || raw.isBlank()) return 1;
        try {
            int g = Integer.parseInt(raw.trim());
            if (g < 1 || g > 4) throw new IllegalStateException(
                    "AccountMigrationRunner: MANHAJI_STUDENT_GRADE_LEVEL=" + raw + " is out of range 1-4");
            return g;
        } catch (NumberFormatException e) {
            throw new IllegalStateException(
                    "AccountMigrationRunner: MANHAJI_STUDENT_GRADE_LEVEL='" + raw + "' is not a valid integer");
        }
    }
}
