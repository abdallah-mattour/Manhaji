-- ============================================================================
-- local_parent_student_mapping_patch.sql
-- Manhaji — LOCAL parent↔student mapping patch (db: manhaji_db)
--
-- PURPOSE (approved mapping, name-based, one parent per student):
--   * Rename the existing parent@manhaji.local to «أحمد - ولي أمر ليان»
--     and keep exactly ONE child linked to it: ليان أحمد (student01).
--   * Create 9 new parent accounts (only if missing) derived from the
--     actual students' father names, one child each.
--   * Relink students.parent_id so every student 131-140 (matched BY EMAIL,
--     not by hardcoded id) has exactly one correct parent.
--
-- SCHEMA FACTS (verified live before writing this patch):
--   * There is NO parent_student table — the link is students.parent_id.
--   * users(role, id AUTO_INCREMENT, created_at, email, full_name,
--           is_active bit(1), last_login_at, password_hash, phone)
--   * parents(id) — JOINED inheritance marker row.
--
-- PASSWORD: all parents use Parent123! — the bcrypt hash below is the SAME
-- hash already used by parent@manhaji.local in the live DB and in
-- local_account_reset_final_test.sql (verified identical). No new hash.
--
-- SAFETY:
--   * One transaction; any failure rolls everything back.
--   * Idempotent: NOT-EXISTS inserts + deterministic email-based updates —
--     safe to re-import any number of times.
--   * No fixed numeric ids: parents are found/created by email, students
--     matched by email. AUTO_INCREMENT assigns new parent ids.
--   * Touches ONLY: users (parent rows), parents, students.parent_id.
--     Never touches: subjects, lessons, questions, quizzes, quiz_questions,
--     progress, attempts, student_responses, teachers, teacher_assignments,
--     admins, student accounts/emails/passwords, curriculum.
--   * No DROP / TRUNCATE / DELETE.
--
-- REMINDER: do not boot the backend with MANHAJI_REPLACE_DEMO_ACCOUNTS=true
-- (it deletes parent@manhaji.local) nor MANHAJI_DEMO_SEED=true (it creates
-- extra *.edu accounts). Neither is needed for this patch.
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

-- ----------------------------------------------------------------------------
-- 0) Rename the existing parent (email-based, PARENT role only)
-- ----------------------------------------------------------------------------
UPDATE users
   SET full_name = 'أحمد - ولي أمر ليان'
 WHERE email = 'parent@manhaji.local'
   AND role  = 'PARENT';

-- ----------------------------------------------------------------------------
-- 1) Create the 9 new parent accounts (users + parents), only if missing.
--    Same bcrypt hash of Parent123! as the existing parent (see header).
-- ----------------------------------------------------------------------------

-- محمد - ولي أمر آدم
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.adam@manhaji.local', 'محمد - ولي أمر آدم', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.adam@manhaji.local');

-- خالد - ولي أمر جنى
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.jana@manhaji.local', 'خالد - ولي أمر جنى', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.jana@manhaji.local');

-- سمير - ولي أمر يوسف
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.yousef@manhaji.local', 'سمير - ولي أمر يوسف', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.yousef@manhaji.local');

-- محمود - ولي أمر تالا
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.tala@manhaji.local', 'محمود - ولي أمر تالا', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.tala@manhaji.local');

-- ناصر - ولي أمر عمر
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.omar@manhaji.local', 'ناصر - ولي أمر عمر', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.omar@manhaji.local');

-- علي - ولي أمر سارة
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.sara@manhaji.local', 'علي - ولي أمر سارة', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.sara@manhaji.local');

-- حسن - ولي أمر كريم
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.kareem@manhaji.local', 'حسن - ولي أمر كريم', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.kareem@manhaji.local');

-- ياسر - ولي أمر ريم
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.reem@manhaji.local', 'ياسر - ولي أمر ريم', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.reem@manhaji.local');

-- إبراهيم - ولي أمر نور
INSERT INTO users (role, created_at, email, full_name, is_active, last_login_at, password_hash, phone)
SELECT 'PARENT', NOW(6), 'parent.noor@manhaji.local', 'إبراهيم - ولي أمر نور', b'1', NULL,
       '$2a$10$dPmM1ZDYR9o0hTDz0.KL1.YMgPX1Fgd2BOQWodTxuNDbytosHPNRC', NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'parent.noor@manhaji.local');

-- JOINED-inheritance marker rows: one parents(id) row per PARENT user above.
-- Guarded by role='PARENT' so a same-email non-parent user can never be
-- hijacked into the parents table.
INSERT INTO parents (id)
SELECT u.id
  FROM users u
 WHERE u.role = 'PARENT'
   AND u.email IN (
        'parent.adam@manhaji.local',  'parent.jana@manhaji.local',
        'parent.yousef@manhaji.local','parent.tala@manhaji.local',
        'parent.omar@manhaji.local',  'parent.sara@manhaji.local',
        'parent.kareem@manhaji.local','parent.reem@manhaji.local',
        'parent.noor@manhaji.local')
   AND NOT EXISTS (SELECT 1 FROM parents p WHERE p.id = u.id);

-- ----------------------------------------------------------------------------
-- 2) Relink students (email-based on BOTH sides; no hardcoded ids).
--    First clear links for exactly our ten local students, then assign the
--    approved one-parent-per-student mapping.
-- ----------------------------------------------------------------------------
UPDATE students s
  JOIN users su ON su.id = s.id
   SET s.parent_id = NULL
 WHERE su.email IN (
        'student01@manhaji.local','student02@manhaji.local',
        'student03@manhaji.local','student04@manhaji.local',
        'student05@manhaji.local','student06@manhaji.local',
        'student07@manhaji.local','student08@manhaji.local',
        'student09@manhaji.local','student10@manhaji.local');

-- ليان أحمد ← أحمد - ولي أمر ليان (الحساب الأصلي)
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student01@manhaji.local'
  JOIN users pu ON pu.email = 'parent@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- آدم محمد ← محمد - ولي أمر آدم
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student02@manhaji.local'
  JOIN users pu ON pu.email = 'parent.adam@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- جنى خالد ← خالد - ولي أمر جنى
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student03@manhaji.local'
  JOIN users pu ON pu.email = 'parent.jana@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- يوسف سمير ← سمير - ولي أمر يوسف
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student04@manhaji.local'
  JOIN users pu ON pu.email = 'parent.yousef@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- تالا محمود ← محمود - ولي أمر تالا
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student05@manhaji.local'
  JOIN users pu ON pu.email = 'parent.tala@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- عمر ناصر ← ناصر - ولي أمر عمر
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student06@manhaji.local'
  JOIN users pu ON pu.email = 'parent.omar@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- سارة علي ← علي - ولي أمر سارة
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student07@manhaji.local'
  JOIN users pu ON pu.email = 'parent.sara@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- كريم حسن ← حسن - ولي أمر كريم
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student08@manhaji.local'
  JOIN users pu ON pu.email = 'parent.kareem@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- ريم ياسر ← ياسر - ولي أمر ريم
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student09@manhaji.local'
  JOIN users pu ON pu.email = 'parent.reem@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

-- نور إبراهيم ← إبراهيم - ولي أمر نور
UPDATE students s
  JOIN users su ON su.id = s.id AND su.email = 'student10@manhaji.local'
  JOIN users pu ON pu.email = 'parent.noor@manhaji.local' AND pu.role = 'PARENT'
  JOIN parents p ON p.id = pu.id
   SET s.parent_id = p.id;

COMMIT;

-- ============================================================================
-- VERIFICATION (read-only — runs after the patch)
-- ============================================================================

-- 1) Parent -> linked child mapping (expect 10 rows, names matching by father)
SELECT pu.email AS parent_email, pu.full_name AS parent_name,
       su.email AS student_email, su.full_name AS student_name
  FROM students s
  JOIN users su ON su.id = s.id
  JOIN parents p ON p.id = s.parent_id
  JOIN users pu ON pu.id = p.id
 WHERE su.email LIKE 'student%@manhaji.local'
 ORDER BY su.email;

-- 2) Children count per parent (expect exactly 1 for each of the 10 parents)
SELECT pu.email AS parent_email, pu.full_name AS parent_name,
       COUNT(s.id) AS children_count
  FROM parents p
  JOIN users pu ON pu.id = p.id
  LEFT JOIN students s ON s.parent_id = p.id
 GROUP BY p.id, pu.email, pu.full_name
 ORDER BY pu.email;

-- 3) Students 131-140 with NULL parent_id (expect 0 rows)
SELECT su.email, su.full_name
  FROM students s
  JOIN users su ON su.id = s.id
 WHERE su.email LIKE 'student%@manhaji.local'
   AND s.parent_id IS NULL;

-- 4) Parents linked to MORE than 1 child (expect 0 rows in this mapping)
SELECT pu.email AS parent_email, COUNT(s.id) AS children_count
  FROM parents p
  JOIN users pu ON pu.id = p.id
  JOIN students s ON s.parent_id = p.id
 GROUP BY p.id, pu.email
HAVING COUNT(s.id) > 1;
