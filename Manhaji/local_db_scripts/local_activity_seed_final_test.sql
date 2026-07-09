-- ============================================================================
-- local_activity_seed_final_test.sql
-- Manhaji — LOCAL learning-activity seed for final testing (db: manhaji_db)
--
-- PURPOSE
--   Seeds realistic progress + graded attempts for the 10 existing Grade-1
--   students (ids 131-140) across the 4 assigned Grade-1 subjects, so every
--   teacher dashboard shows meaningful non-zero values.
--
-- WHAT THIS TOUCHES (ONLY):
--   * progress rows  WHERE student_id BETWEEN 131 AND 140
--   * attempts rows  WHERE student_id BETWEEN 131 AND 140
--   * (student_responses for those attempts — none exist; deleted for safety)
--
-- WHAT THIS NEVER TOUCHES:
--   * users / admins / teachers / parents / students (accounts unchanged)
--   * subjects / lessons / questions / quizzes / quiz_questions / schools
--   * teacher_assignments / skill_mastery / learning_paths / progress_reports
--   * any user outside the 131-140 id range
--   * No DROP. No TRUNCATE. One transaction; failure rolls everything back.
--
-- DESIGN (deterministic — no RAND(); re-import always converges):
--   High band   (131,133,136): mastery 85-100, 6 lessons/subject,
--                              L1 MASTERED, L2-4 COMPLETED, L5-6 IN_PROGRESS
--   Medium band (132,135,139,140): mastery 60-84, 5 lessons/subject,
--                              L1-3 COMPLETED, L4-5 IN_PROGRESS
--   Low band    (134,137,138): mastery 25-59, 4 lessons/subject,
--                              L1 COMPLETED, L2-4 IN_PROGRESS
--   "First lessons" are ranked by (semester_number, order_index, id) per
--   subject — no hardcoded lesson ids (order_index restarts each semester).
--
-- EXPECTED DASHBOARD PER TEACHER AFTER IMPORT:
--   totalStudents=10 (unchanged), activeThisWeek=8 (unchanged),
--   lessonsCompletedTotal = 24, averageMasteryAcrossClass ~ 67
--   (MASTERED rows deliberately do not count as "completed" —
--    ProgressMetrics.countCompleted counts COMPLETED only.)
--
-- BEFORE IMPORT: backend can stay running (read paths only), but a backup
-- is still recommended:
--   /Applications/XAMPP/xamppfiles/bin/mysqldump -u root \
--     --socket=/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock \
--     --single-transaction --default-character-set=utf8mb4 \
--     manhaji_db > ~/Desktop/manhaji_db_backup_$(date +%Y%m%d_%H%M%S).sql
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1) Idempotent cleanup — ONLY activity rows of students 131-140
-- ----------------------------------------------------------------------------
DELETE sr FROM student_responses sr
  JOIN attempts a ON a.id = sr.attempt_id
 WHERE a.student_id BETWEEN 131 AND 140;

DELETE FROM attempts WHERE student_id BETWEEN 131 AND 140;
DELETE FROM progress WHERE student_id BETWEEN 131 AND 140;

-- ----------------------------------------------------------------------------
-- 2) Seed progress
--    Derived tables:
--      rl = first 6 lessons per subject, ranked without hardcoding ids
--      sb = student -> band mapping (aligned with existing total_points)
--      bp = band parameters (base mastery, decay, clamp range, reach)
-- ----------------------------------------------------------------------------
INSERT INTO progress
    (mastery_level, completion_status, last_accessed_at, completed_at,
     last_segment_index, student_id, lesson_id)
SELECT
    -- mastery: base - decay*(rn-1) + jitter(-3..+3), clamped to the band range
    ROUND(LEAST(bp.clamp_max, GREATEST(bp.clamp_min,
        bp.base_mastery
        - (rl.rn - 1) * bp.decay
        + ((sb.student_id * 7 + rl.subject_id * 3 + rl.rn * 5) % 7) - 3
    )), 1)                                                        AS mastery_level,
    CASE
        WHEN sb.band = 'HIGH'   AND rl.rn = 1  THEN 'MASTERED'
        WHEN sb.band = 'HIGH'   AND rl.rn <= 4 THEN 'COMPLETED'
        WHEN sb.band = 'MEDIUM' AND rl.rn <= 3 THEN 'COMPLETED'
        WHEN sb.band = 'LOW'    AND rl.rn = 1  THEN 'COMPLETED'
        ELSE 'IN_PROGRESS'
    END                                                           AS completion_status,
    NOW(6) - INTERVAL ((sb.student_id + rl.rn) % 7) DAY           AS last_accessed_at,
    CASE
        WHEN (sb.band = 'HIGH'   AND rl.rn <= 4)
          OR (sb.band = 'MEDIUM' AND rl.rn <= 3)
          OR (sb.band = 'LOW'    AND rl.rn = 1)
        THEN NOW(6) - INTERVAL ((sb.student_id + rl.rn + rl.subject_id) % 10 + 1) DAY
        ELSE NULL
    END                                                           AS completed_at,
    CASE
        WHEN (sb.band = 'HIGH'   AND rl.rn >= 5)
          OR (sb.band = 'MEDIUM' AND rl.rn >= 4)
          OR (sb.band = 'LOW'    AND rl.rn >= 2)
        THEN 1 ELSE NULL
    END                                                           AS last_segment_index,
    sb.student_id,
    rl.lesson_id
FROM (
    SELECT id AS lesson_id, subject_id,
           ROW_NUMBER() OVER (PARTITION BY subject_id
                              ORDER BY semester_number, order_index, id) AS rn
    FROM lessons
    WHERE subject_id IN (1, 3, 5, 7)      -- Arabic, English, Math, Islamic (grade 1)
) rl
JOIN (
              SELECT 131 AS student_id, 'HIGH'   AS band
    UNION ALL SELECT 133, 'HIGH'
    UNION ALL SELECT 136, 'HIGH'
    UNION ALL SELECT 132, 'MEDIUM'
    UNION ALL SELECT 135, 'MEDIUM'
    UNION ALL SELECT 139, 'MEDIUM'
    UNION ALL SELECT 140, 'MEDIUM'
    UNION ALL SELECT 134, 'LOW'
    UNION ALL SELECT 137, 'LOW'
    UNION ALL SELECT 138, 'LOW'
) sb
JOIN (
              SELECT 'HIGH'   AS band, 94.0 AS base_mastery, 1.5 AS decay, 85.0 AS clamp_min, 100.0 AS clamp_max, 6 AS reach
    UNION ALL SELECT 'MEDIUM',         74.0,                3.0,           60.0,              84.0,               5
    UNION ALL SELECT 'LOW',            55.0,                7.0,           25.0,              59.0,               4
) bp ON bp.band = sb.band
WHERE rl.rn <= bp.reach;

-- ----------------------------------------------------------------------------
-- 3) Seed attempts — one GRADED attempt per COMPLETED/MASTERED progress row.
--    quizzes join is safe: verified live that every LESSON quiz maps 1:1 to
--    a lesson. student_responses intentionally NOT seeded (not required by
--    any read path; same pattern the project's own DataSeeder uses).
-- ----------------------------------------------------------------------------
INSERT INTO attempts
    (created_at, score, status, submitted_at, quiz_id, student_id)
SELECT
    COALESCE(p.completed_at, NOW(6)) - INTERVAL 15 MINUTE          AS created_at,
    ROUND(LEAST(100, GREATEST(20,
        p.mastery_level + 3 - ((p.student_id + q.lesson_id) % 5)
    )), 1)                                                         AS score,
    'GRADED'                                                       AS status,
    COALESCE(p.completed_at, NOW(6))                               AS submitted_at,
    q.id                                                           AS quiz_id,
    p.student_id
FROM progress p
JOIN quizzes q
  ON q.lesson_id = p.lesson_id
 AND q.quiz_type = 'LESSON'
WHERE p.student_id BETWEEN 131 AND 140
  AND p.completion_status IN ('COMPLETED', 'MASTERED');

COMMIT;

-- Expected row counts: progress = 216 (10 students x 4 subjects x 4-6 lessons),
--                      attempts = 108 (27 per subject).

-- ============================================================================
-- VERIFICATION QUERIES (read-only — run after import)
-- ============================================================================

-- 1) Progress count for students 131-140 (expect 216)
-- SELECT COUNT(*) AS progress_rows FROM progress WHERE student_id BETWEEN 131 AND 140;

-- 2) Progress grouped by subject (expect per subject: 54 rows,
--    completed=24, mastered=3, in_progress=27)
-- SELECT sub.id AS subject_id, sub.name,
--        COUNT(*)                                 AS progress_rows,
--        SUM(p.completion_status = 'COMPLETED')   AS completed,
--        SUM(p.completion_status = 'MASTERED')    AS mastered,
--        SUM(p.completion_status = 'IN_PROGRESS') AS in_progress
-- FROM progress p
-- JOIN lessons l    ON l.id = p.lesson_id
-- JOIN subjects sub ON sub.id = l.subject_id
-- WHERE p.student_id BETWEEN 131 AND 140
-- GROUP BY sub.id, sub.name;

-- 3) Dashboard mimic — expect lessonsCompletedTotal=24, averageMastery ~67
-- SELECT subject_id, subject_name,
--        SUM(completed)             AS lessonsCompletedTotal,
--        ROUND(AVG(avg_mastery), 2) AS averageMasteryAcrossClass
-- FROM (
--     SELECT l.subject_id, sub.name AS subject_name, p.student_id,
--            SUM(p.completion_status = 'COMPLETED') AS completed,
--            AVG(p.mastery_level)                   AS avg_mastery
--     FROM progress p
--     JOIN lessons l    ON l.id = p.lesson_id
--     JOIN subjects sub ON sub.id = l.subject_id
--     WHERE p.student_id BETWEEN 131 AND 140
--     GROUP BY l.subject_id, sub.name, p.student_id
-- ) per_student
-- GROUP BY subject_id, subject_name;

-- 4) Per-student view for Arabic (bands should be visible)
-- SELECT p.student_id, u.full_name,
--        COUNT(*) AS lessons_touched,
--        SUM(p.completion_status='COMPLETED') AS completed,
--        ROUND(AVG(p.mastery_level),1) AS avg_mastery
-- FROM progress p
-- JOIN lessons l ON l.id = p.lesson_id AND l.subject_id = 1
-- JOIN users u   ON u.id = p.student_id
-- WHERE p.student_id BETWEEN 131 AND 140
-- GROUP BY p.student_id, u.full_name
-- ORDER BY avg_mastery DESC;

-- 5) Attempts (expect 108 total, 27 per subject, all GRADED, scores 20-100)
-- SELECT sub.name, COUNT(*) AS attempts, ROUND(AVG(a.score),1) AS avg_score
-- FROM attempts a
-- JOIN quizzes q    ON q.id = a.quiz_id
-- JOIN lessons l    ON l.id = q.lesson_id
-- JOIN subjects sub ON sub.id = l.subject_id
-- WHERE a.student_id BETWEEN 131 AND 140
-- GROUP BY sub.name;

-- 6) Nothing else was touched (compare with pre-import values)
-- SELECT 'users' k, COUNT(*) v FROM users                                  -- expect 16
-- UNION ALL SELECT 'teacher_assignments', COUNT(*) FROM teacher_assignments -- expect 4
-- UNION ALL SELECT 'lessons', COUNT(*) FROM lessons                        -- expect 249
-- UNION ALL SELECT 'questions', COUNT(*) FROM questions                    -- expect 2742
-- UNION ALL SELECT 'quizzes', COUNT(*) FROM quizzes                        -- expect 249
-- UNION ALL SELECT 'student_responses', COUNT(*) FROM student_responses;   -- expect 0
