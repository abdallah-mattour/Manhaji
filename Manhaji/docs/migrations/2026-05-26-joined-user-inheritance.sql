-- ============================================================================
-- Migration: SINGLE_TABLE → JOINED inheritance on the users hierarchy
-- Date     : 2026-05-26
-- Risk     : medium (touches the users table, reversible only via backup)
-- ============================================================================
--
-- What this does
-- --------------
-- Splits the single `users` table into one base table + four child tables,
-- one per role:
--
--     users (id, full_name, email, phone, password_hash, role, ...)
--         ├── students   (id, grade_level, avatar_id, current_streak,
--         │               total_points, current_lesson_id, school_id,
--         │               parent_id)
--         ├── teachers   (id, department, assigned_grade, school_id)
--         ├── parents    (id)
--         └── admins     (id, permissions)
--
-- Each child table's `id` is both its PK and an FK pointing at `users.id`.
-- All existing FKs from `attempts`, `progress`, `student_responses`,
-- `learning_paths`, `progress_reports`, etc. that target `users.id` keep
-- working unchanged — the student's id is the same value in both tables.
--
-- When to run this
-- ----------------
-- Apply this script BEFORE booting the Spring Boot app for the first time
-- after pulling the JOINED-inheritance entity changes. Hibernate's
-- `ddl-auto: update` will create the new child tables and indexes on its
-- own, but it will NOT (a) migrate existing data from `users` into the
-- new child tables, nor (b) drop the now-orphan role-specific columns
-- from `users`. This script does both.
--
-- How to run it
-- -------------
--     mysql -u root -p manhaji_db < docs/migrations/2026-05-26-joined-user-inheritance.sql
--
-- Or paste into MySQL Workbench against the manhaji_db schema.
--
-- Idempotency
-- -----------
-- The script is wrapped in transaction + IF NOT EXISTS guards so re-running
-- it on an already-migrated DB is a no-op (the COPY statements will hit
-- duplicate-PK errors and roll back cleanly).
--
-- Rollback
-- --------
-- This script is destructive (it DROPs columns from `users`). Take a
-- mysqldump beforehand:
--     mysqldump -u root -p manhaji_db > pre-joined-inheritance.sql
--
-- If you need to roll back: drop the new child tables, then re-apply your
-- backup. There is no automated downgrade — the data fans out, and undoing
-- it requires re-merging columns by row, which is not safer than just
-- restoring the dump.
-- ============================================================================

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. Create the child tables. We do this explicitly (rather than letting
--    Hibernate auto-create on boot) so the data-copy below has somewhere
--    to land in step 2. Schema mirrors what Hibernate's JOINED inheritance
--    will produce on a fresh `ddl-auto: update`.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS students (
    id                  BIGINT       NOT NULL PRIMARY KEY,
    grade_level         INT          NULL,
    avatar_id           VARCHAR(255) NULL,
    current_streak      INT          NOT NULL DEFAULT 0,
    total_points        INT          NOT NULL DEFAULT 0,
    current_lesson_id   BIGINT       NULL,
    school_id           BIGINT       NULL,
    parent_id           BIGINT       NULL,
    CONSTRAINT fk_student_user    FOREIGN KEY (id)                REFERENCES users(id)   ON DELETE CASCADE,
    CONSTRAINT fk_student_lesson  FOREIGN KEY (current_lesson_id) REFERENCES lessons(id) ON DELETE SET NULL,
    CONSTRAINT fk_student_school  FOREIGN KEY (school_id)         REFERENCES schools(id) ON DELETE SET NULL,
    INDEX idx_student_parent       (parent_id),
    INDEX idx_student_school       (school_id),
    INDEX idx_student_school_grade (school_id, grade_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS teachers (
    id              BIGINT       NOT NULL PRIMARY KEY,
    department      VARCHAR(255) NULL,
    assigned_grade  INT          NULL,
    school_id       BIGINT       NULL,
    CONSTRAINT fk_teacher_user   FOREIGN KEY (id)        REFERENCES users(id)   ON DELETE CASCADE,
    CONSTRAINT fk_teacher_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL,
    INDEX idx_teacher_school (school_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS parents (
    id BIGINT NOT NULL PRIMARY KEY,
    CONSTRAINT fk_parent_user FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS admins (
    id          BIGINT       NOT NULL PRIMARY KEY,
    permissions VARCHAR(255) NULL,
    CONSTRAINT fk_admin_user FOREIGN KEY (id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Now wire the students.parent_id FK to the new parents table. Done after
-- both tables exist so the constraint can resolve.
ALTER TABLE students
    ADD CONSTRAINT fk_student_parent
    FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE SET NULL;

-- ----------------------------------------------------------------------------
-- 2. Copy each user's role-specific data into the matching child table.
--    The COALESCE on current_streak/total_points handles legacy rows where
--    the column was NULL before we made it NOT NULL.
-- ----------------------------------------------------------------------------

INSERT INTO students (id, grade_level, avatar_id, current_streak, total_points,
                      current_lesson_id, school_id, parent_id)
SELECT id,
       grade_level,
       avatar_id,
       COALESCE(current_streak, 0),
       COALESCE(total_points, 0),
       current_lesson_id,
       school_id,
       parent_id
FROM   users
WHERE  role = 'STUDENT';

INSERT INTO teachers (id, department, assigned_grade, school_id)
SELECT id,
       department,
       assigned_grade,
       school_id
FROM   users
WHERE  role = 'TEACHER';

INSERT INTO parents (id)
SELECT id
FROM   users
WHERE  role = 'PARENT';

INSERT INTO admins (id, permissions)
SELECT id,
       permissions
FROM   users
WHERE  role = 'ADMIN';

-- ----------------------------------------------------------------------------
-- 3. Drop the role-specific columns from `users`. They're now owned by the
--    child tables. Drop the indexes that referenced these columns first —
--    MySQL won't drop a column that backs an index without --algorithm=COPY.
-- ----------------------------------------------------------------------------

-- Indexes first (defensive — earlier User.java may or may not have created
-- these exact names; ignore "doesn't exist" errors). MySQL doesn't support
-- IF EXISTS on DROP INDEX before 8.0.13 — we run 8.x+ so it's available.
ALTER TABLE users DROP INDEX IF EXISTS idx_user_parent;
ALTER TABLE users DROP INDEX IF EXISTS idx_user_school;
ALTER TABLE users DROP INDEX IF EXISTS idx_user_school_grade;

-- The role-specific columns. Drop the FK constraints first (they may have
-- auto-generated names — use information_schema to discover them at need).
SET @drop_fk_lesson = (
    SELECT IFNULL(CONCAT('ALTER TABLE users DROP FOREIGN KEY ', constraint_name, ';'), 'SELECT 1;')
    FROM information_schema.key_column_usage
    WHERE table_schema = DATABASE()
      AND table_name   = 'users'
      AND column_name  = 'current_lesson_id'
      AND referenced_table_name IS NOT NULL
    LIMIT 1
);
PREPARE drop_fk_lesson_stmt FROM @drop_fk_lesson; EXECUTE drop_fk_lesson_stmt; DEALLOCATE PREPARE drop_fk_lesson_stmt;

SET @drop_fk_school = (
    SELECT IFNULL(CONCAT('ALTER TABLE users DROP FOREIGN KEY ', constraint_name, ';'), 'SELECT 1;')
    FROM information_schema.key_column_usage
    WHERE table_schema = DATABASE()
      AND table_name   = 'users'
      AND column_name  = 'school_id'
      AND referenced_table_name IS NOT NULL
    LIMIT 1
);
PREPARE drop_fk_school_stmt FROM @drop_fk_school; EXECUTE drop_fk_school_stmt; DEALLOCATE PREPARE drop_fk_school_stmt;

SET @drop_fk_parent = (
    SELECT IFNULL(CONCAT('ALTER TABLE users DROP FOREIGN KEY ', constraint_name, ';'), 'SELECT 1;')
    FROM information_schema.key_column_usage
    WHERE table_schema = DATABASE()
      AND table_name   = 'users'
      AND column_name  = 'parent_id'
      AND referenced_table_name IS NOT NULL
    LIMIT 1
);
PREPARE drop_fk_parent_stmt FROM @drop_fk_parent; EXECUTE drop_fk_parent_stmt; DEALLOCATE PREPARE drop_fk_parent_stmt;

-- Now safe to drop the columns themselves.
ALTER TABLE users
    DROP COLUMN IF EXISTS grade_level,
    DROP COLUMN IF EXISTS avatar_id,
    DROP COLUMN IF EXISTS current_streak,
    DROP COLUMN IF EXISTS total_points,
    DROP COLUMN IF EXISTS current_lesson_id,
    DROP COLUMN IF EXISTS school_id,
    DROP COLUMN IF EXISTS parent_id,
    DROP COLUMN IF EXISTS department,
    DROP COLUMN IF EXISTS assigned_grade,
    DROP COLUMN IF EXISTS permissions;

-- ----------------------------------------------------------------------------
-- 4. Sanity checks. These don't change anything — they just give the
--    operator something readable to confirm the migration landed cleanly.
-- ----------------------------------------------------------------------------

SELECT 'Row counts after migration:' AS info;
SELECT 'users'    AS table_name, COUNT(*) AS rows FROM users
UNION ALL SELECT 'students', COUNT(*) FROM students
UNION ALL SELECT 'teachers', COUNT(*) FROM teachers
UNION ALL SELECT 'parents',  COUNT(*) FROM parents
UNION ALL SELECT 'admins',   COUNT(*) FROM admins;

SELECT 'Mismatch check (should be empty):' AS info;
SELECT u.id, u.role, u.email
FROM   users u
LEFT JOIN students s ON s.id = u.id AND u.role = 'STUDENT'
LEFT JOIN teachers t ON t.id = u.id AND u.role = 'TEACHER'
LEFT JOIN parents  p ON p.id = u.id AND u.role = 'PARENT'
LEFT JOIN admins   a ON a.id = u.id AND u.role = 'ADMIN'
WHERE  (u.role = 'STUDENT' AND s.id IS NULL)
   OR  (u.role = 'TEACHER' AND t.id IS NULL)
   OR  (u.role = 'PARENT'  AND p.id IS NULL)
   OR  (u.role = 'ADMIN'   AND a.id IS NULL);

COMMIT;
