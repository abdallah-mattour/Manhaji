-- ============================================================================
-- Migration: Personalized quiz + Bayesian Knowledge Tracing
-- Date     : 2026-05-27
-- Risk     : low (additive columns + one nullability relax + one new table)
-- ============================================================================
--
-- What this does
-- --------------
-- 1. Relaxes quizzes.lesson_id to NULL so a PERSONALIZED quiz (which spans a
--    subject's lessons) can exist without belonging to one lesson.
-- 2. Adds the columns that distinguish + scope a personalized quiz.
-- 3. Creates the skill_mastery table that stores per-(student,subject,subskill)
--    BKT mastery state.
--
-- Why a script (vs relying on ddl-auto: update)
-- ---------------------------------------------
-- Hibernate's `ddl-auto: update` will ADD the new nullable columns and CREATE
-- the new table on its own, but it will NOT relax the existing
-- `lesson_id BIGINT NOT NULL` constraint (Hibernate never narrows/widens
-- existing column nullability on update). This script does that one ALTER.
-- Everything else here is idempotent/defensive so the script is safe to run
-- even after a boot where Hibernate already created the additive bits.
--
-- How to run
-- ----------
--     mysql -u root -p manhaji_db < docs/migrations/2026-05-27-personalized-quiz.sql
--
-- No reseed required — existing LESSON quizzes keep working unchanged
-- (quiz_type defaults to 'LESSON').
-- ============================================================================

-- NOTE (MySQL 8 compatibility): MySQL 8.0 does NOT support
-- `ADD COLUMN IF NOT EXISTS` / `ADD CONSTRAINT IF NOT EXISTS` (that's MariaDB
-- syntax). In practice Hibernate's `ddl-auto: update` ADDS the new nullable
-- columns, the index, the skill_mastery table, and skill_mastery's FKs on the
-- first boot with the new entities — so on this project the only statements
-- you actually need to run by hand are:
--   (a) relax quizzes.lesson_id to NULL   (ddl-auto never narrows/widens),
--   (b) add the fk_quiz_subject constraint (Hibernate names FKs randomly, so
--       we add an explicitly-named one).
-- The rest below is written for a FRESH database where Hibernate has NOT yet
-- run. If a statement errors with "Duplicate column/key" on an
-- already-booted DB, that object already exists — skip it and continue.

START TRANSACTION;

-- 1. Relax lesson_id nullability (the one thing ddl-auto won't do). Safe to
--    re-run — modifying an already-nullable column to NULL is a no-op.
ALTER TABLE quizzes MODIFY COLUMN lesson_id BIGINT NULL;

-- 2. Add personalized-quiz columns. On a FRESH DB run these; on an
--    already-booted DB Hibernate added them, so each will error
--    "Duplicate column name" — skip and continue.
ALTER TABLE quizzes ADD COLUMN quiz_type VARCHAR(16) NOT NULL DEFAULT 'LESSON';
ALTER TABLE quizzes ADD COLUMN subject_id BIGINT NULL;
ALTER TABLE quizzes ADD COLUMN generated_for_student_id BIGINT NULL;

-- Backfill any pre-existing rows (defensive — DEFAULT handles new inserts).
UPDATE quizzes SET quiz_type = 'LESSON' WHERE quiz_type IS NULL OR quiz_type = '';

-- FK + index for the subject relation. On an already-booted DB the index may
-- exist (Hibernate creates it from @Index); the explicitly-named FK usually
-- does not. Skip whichever errors "Duplicate key name".
ALTER TABLE quizzes
    ADD CONSTRAINT fk_quiz_subject FOREIGN KEY (subject_id) REFERENCES subjects(id)
        ON DELETE SET NULL;

CREATE INDEX idx_quiz_personalized
    ON quizzes (generated_for_student_id, subject_id, quiz_type);

-- 3. The BKT mastery table.
CREATE TABLE IF NOT EXISTS skill_mastery (
    id                  BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    student_id          BIGINT       NOT NULL,
    subject_id          BIGINT       NOT NULL,
    sub_skill           VARCHAR(32)  NOT NULL,
    p_mastery           DOUBLE       NOT NULL DEFAULT 0.30,
    observation_count   INT          NOT NULL DEFAULT 0,
    created_at          DATETIME(6)  NOT NULL,
    updated_at          DATETIME(6)  NOT NULL,
    CONSTRAINT uk_skill_mastery UNIQUE (student_id, subject_id, sub_skill),
    CONSTRAINT fk_skill_mastery_student FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_skill_mastery_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    CONSTRAINT chk_skill_mastery_p CHECK (p_mastery >= 0 AND p_mastery <= 1),
    INDEX idx_skill_mastery_student_subject (student_id, subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;

-- Sanity check
SELECT 'quizzes.lesson_id nullable?' AS check_name,
       IF(IS_NULLABLE = 'YES', 'OK', 'STILL NOT NULL') AS result
FROM information_schema.columns
WHERE table_schema = DATABASE() AND table_name = 'quizzes' AND column_name = 'lesson_id';
