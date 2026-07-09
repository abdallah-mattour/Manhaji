-- ============================================================================
-- LOCAL DEMO SEED — assigned teacher quiz with mixed student results
-- File: local_db_scripts/local_demo_assigned_quiz_results_seed.sql
-- Purpose: "Demo Assigned Quiz - Arabic Results" for the graduation demo.
--
-- DEMO MARKER: quiz title 'اختبار ديمو: حروف اللغة العربية'
--   (TEACHER_ASSIGNED, teacher 111). Cleanup below deletes ONLY rows
--   hanging off quizzes with this exact title — never other app data.
--
-- Idempotent: safe to run any number of times (delete-then-insert).
-- No schema changes, no DROP/TRUNCATE, no user/password changes.
--
-- Verified against local DB 2026-07-07:
--   teacher 111 teacher.arabic@manhaji.local (اللغة العربية, grade 1, school 1)
--   students 131..140 = student01..student10@manhaji.local
--   questions [1, 2, 3, 6, 13, 14, 24, 27, 35, 44] from Arabic grade-1 bank (MCQ/TRUE_FALSE/FILL_BLANK)
--
-- Result design (10 questions, 10 pts each):
--   student01 ليان  100%  | student02 آدم   90% | student03 جنى  80%
--   student09 ريم    70%  | student04 يوسف 60% | student06 عمر  60%
--   student05 تالا   50%  | student10 نور  40% | student07 سارة IN_PROGRESS
--   student08 كريم  not started
-- ============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @demo_title = 'اختبار ديمو: حروف اللغة العربية';

-- ---------------------------------------------------------------------------
-- 1. CLEANUP — remove ONLY previous rows created by this script
-- ---------------------------------------------------------------------------
DELETE sr FROM student_responses sr
  JOIN attempts a ON sr.attempt_id = a.id
  JOIN quizzes q ON a.quiz_id = q.id
 WHERE q.title = @demo_title AND q.quiz_type = 'TEACHER_ASSIGNED';

DELETE a FROM attempts a
  JOIN quizzes q ON a.quiz_id = q.id
 WHERE q.title = @demo_title AND q.quiz_type = 'TEACHER_ASSIGNED';

DELETE qas FROM quiz_assignment_students qas
  JOIN quiz_assignments qa ON qas.quiz_assignment_id = qa.id
  JOIN quizzes q ON qa.quiz_id = q.id
 WHERE q.title = @demo_title AND q.quiz_type = 'TEACHER_ASSIGNED';

DELETE qa FROM quiz_assignments qa
  JOIN quizzes q ON qa.quiz_id = q.id
 WHERE q.title = @demo_title AND q.quiz_type = 'TEACHER_ASSIGNED';

DELETE qq FROM quiz_questions qq
  JOIN quizzes q ON qq.quiz_id = q.id
 WHERE q.title = @demo_title AND q.quiz_type = 'TEACHER_ASSIGNED';

DELETE FROM quizzes
 WHERE title = @demo_title AND quiz_type = 'TEACHER_ASSIGNED';

-- ---------------------------------------------------------------------------
-- 2. QUIZ (PUBLISHED, TEACHER_ASSIGNED, owned by the Arabic teacher)
-- ---------------------------------------------------------------------------
INSERT INTO quizzes
  (created_at, gamified, generated_for_student_id, generated_from_lesson,
   quiz_type, title, lesson_id, subject_id, status, created_by_teacher_id)
VALUES
  (NOW(6) - INTERVAL 2 DAY, b'0', NULL, b'0',
   'TEACHER_ASSIGNED', @demo_title, NULL, 1, 'PUBLISHED', 111);
SET @quiz_id = LAST_INSERT_ID();

-- Question bank picks (existing real Arabic grade-1 questions)
INSERT INTO quiz_questions (quiz_id, question_id) VALUES
  (@quiz_id, 1),
  (@quiz_id, 2),
  (@quiz_id, 3),
  (@quiz_id, 6),
  (@quiz_id, 13),
  (@quiz_id, 14),
  (@quiz_id, 24),
  (@quiz_id, 27),
  (@quiz_id, 35),
  (@quiz_id, 44);

-- ---------------------------------------------------------------------------
-- 3. ASSIGNMENT — published 2 days ago, due in 48h, single attempt
-- ---------------------------------------------------------------------------
INSERT INTO quiz_assignments
  (created_at, due_at, grade_level, max_attempts, published_at, status,
   quiz_id, school_id, subject_id, teacher_id)
VALUES
  (NOW(6) - INTERVAL 2 DAY, NOW(6) + INTERVAL 48 HOUR, 1, 1,
   NOW(6) - INTERVAL 2 DAY, 'PUBLISHED', @quiz_id, 1, 1, 111);
SET @assignment_id = LAST_INSERT_ID();

-- Per-student assignment rows (COMPLETED for graded, ASSIGNED otherwise)
INSERT INTO quiz_assignment_students (assigned_at, status, quiz_assignment_id, student_id) VALUES
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 131),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 132),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 133),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 134),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 135),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 136),
  (NOW(6) - INTERVAL 2 DAY, 'ASSIGNED', @assignment_id, 137),
  (NOW(6) - INTERVAL 2 DAY, 'ASSIGNED', @assignment_id, 138),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 139),
  (NOW(6) - INTERVAL 2 DAY, 'COMPLETED', @assignment_id, 140);

-- ---------------------------------------------------------------------------
-- 4. ATTEMPTS + RESPONSES
-- ---------------------------------------------------------------------------

-- student 131: 10/10 correct -> score 100
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 26 HOUR, 100, 'GRADED',
        NOW(6) - INTERVAL 26 HOUR + INTERVAL 13 MINUTE,
        @quiz_id, 131, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'ليمون', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الراء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 14),
  (NULL, 'نقطة واحدة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 24),
  (NULL, 'باب', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 27),
  (NULL, 'الباء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 35),
  (NULL, 'موز', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 44);

-- student 132: 9/10 correct -> score 90
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 24 HOUR, 90, 'GRADED',
        NOW(6) - INTERVAL 24 HOUR + INTERVAL 15 MINUTE,
        @quiz_id, 132, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'ليمون', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الراء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 14),
  (NULL, 'نقطة واحدة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 24),
  (NULL, 'باب', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 27),
  (NULL, 'الراء', 'إجابة خاطئة. الإجابة الصحيحة هي: الباء', b'0', NULL, @a, 35),
  (NULL, 'موز', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 44);

-- student 133: 8/10 correct -> score 80
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 22 HOUR, 80, 'GRADED',
        NOW(6) - INTERVAL 22 HOUR + INTERVAL 11 MINUTE,
        @quiz_id, 133, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'رسم', 'إجابة خاطئة. الإجابة الصحيحة هي: ليمون', b'0', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الراء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 14),
  (NULL, 'نقطتان', 'إجابة خاطئة. الإجابة الصحيحة هي: نقطة واحدة', b'0', NULL, @a, 24),
  (NULL, 'باب', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 27),
  (NULL, 'الباء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 35),
  (NULL, 'موز', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 44);

-- student 139: 7/10 correct -> score 70
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 30 HOUR, 70, 'GRADED',
        NOW(6) - INTERVAL 30 HOUR + INTERVAL 14 MINUTE,
        @quiz_id, 139, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'ليمون', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الميم', 'إجابة خاطئة. الإجابة الصحيحة هي: الراء', b'0', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13),
  (NULL, 'خطأ', 'إجابة خاطئة. الإجابة الصحيحة هي: صح', b'0', NULL, @a, 14),
  (NULL, 'نقطة واحدة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 24),
  (NULL, 'باب', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 27),
  (NULL, 'الباء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 35),
  (NULL, 'نور', 'إجابة خاطئة. الإجابة الصحيحة هي: موز', b'0', NULL, @a, 44);

-- student 134: 6/10 correct -> score 60
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 20 HOUR, 60, 'GRADED',
        NOW(6) - INTERVAL 20 HOUR + INTERVAL 17 MINUTE,
        @quiz_id, 134, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'رمل', 'إجابة خاطئة. الإجابة الصحيحة هي: ليمون', b'0', NULL, @a, 2),
  (NULL, 'خطأ', 'إجابة خاطئة. الإجابة الصحيحة هي: صح', b'0', NULL, @a, 3),
  (NULL, 'الراء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 14),
  (NULL, 'بدون نقاط', 'إجابة خاطئة. الإجابة الصحيحة هي: نقطة واحدة', b'0', NULL, @a, 24),
  (NULL, 'باب', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 27),
  (NULL, 'الدال', 'إجابة خاطئة. الإجابة الصحيحة هي: الباء', b'0', NULL, @a, 35),
  (NULL, 'موز', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 44);

-- student 136: 6/10 correct -> score 60
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 7 HOUR, 60, 'GRADED',
        NOW(6) - INTERVAL 7 HOUR + INTERVAL 12 MINUTE,
        @quiz_id, 136, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'قمر', 'إجابة خاطئة. الإجابة الصحيحة هي: رمان', b'0', NULL, @a, 1),
  (NULL, 'ليمون', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الراء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 6),
  (NULL, 'بيت', 'إجابة خاطئة. الإجابة الصحيحة هي: دجاجة', b'0', NULL, @a, 13),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 14),
  (NULL, 'نقطة واحدة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 24),
  (NULL, 'تاج', 'إجابة خاطئة. الإجابة الصحيحة هي: باب', b'0', NULL, @a, 27),
  (NULL, 'الباء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 35),
  (NULL, 'سمك', 'إجابة خاطئة. الإجابة الصحيحة هي: موز', b'0', NULL, @a, 44);

-- student 135: 5/10 correct -> score 50
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 9 HOUR, 50, 'GRADED',
        NOW(6) - INTERVAL 9 HOUR + INTERVAL 19 MINUTE,
        @quiz_id, 135, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'قمر', 'إجابة خاطئة. الإجابة الصحيحة هي: ليمون', b'0', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الباء', 'إجابة خاطئة. الإجابة الصحيحة هي: الراء', b'0', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13),
  (NULL, 'خطأ', 'إجابة خاطئة. الإجابة الصحيحة هي: صح', b'0', NULL, @a, 14),
  (NULL, 'نقطتان', 'إجابة خاطئة. الإجابة الصحيحة هي: نقطة واحدة', b'0', NULL, @a, 24),
  (NULL, 'باب', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 27),
  (NULL, 'الميم', 'إجابة خاطئة. الإجابة الصحيحة هي: الباء', b'0', NULL, @a, 35),
  (NULL, 'موز', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 44);

-- student 140: 4/10 correct -> score 40
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 5 HOUR, 40, 'GRADED',
        NOW(6) - INTERVAL 5 HOUR + INTERVAL 16 MINUTE,
        @quiz_id, 140, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'سمكة', 'إجابة خاطئة. الإجابة الصحيحة هي: رمان', b'0', NULL, @a, 1),
  (NULL, 'ليمون', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 2),
  (NULL, 'خطأ', 'إجابة خاطئة. الإجابة الصحيحة هي: صح', b'0', NULL, @a, 3),
  (NULL, 'الراء', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 6),
  (NULL, 'قلم', 'إجابة خاطئة. الإجابة الصحيحة هي: دجاجة', b'0', NULL, @a, 13),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 14),
  (NULL, 'نقطة واحدة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 24),
  (NULL, 'سمك', 'إجابة خاطئة. الإجابة الصحيحة هي: باب', b'0', NULL, @a, 27),
  (NULL, 'الميم', 'إجابة خاطئة. الإجابة الصحيحة هي: الباء', b'0', NULL, @a, 35),
  (NULL, 'بيت', 'إجابة خاطئة. الإجابة الصحيحة هي: موز', b'0', NULL, @a, 44);

-- student 137: IN_PROGRESS — 5 of 10 answered, no score yet
INSERT INTO attempts (created_at, score, status, submitted_at, quiz_id, student_id, quiz_assignment_id)
VALUES (NOW(6) - INTERVAL 40 MINUTE, NULL, 'IN_PROGRESS', NULL, @quiz_id, 137, @assignment_id);
SET @a = LAST_INSERT_ID();
INSERT INTO student_responses (audio_ref, evaluated_text, feedback, is_correct, spoken_text, attempt_id, question_id) VALUES
  (NULL, 'رمان', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 1),
  (NULL, 'رسم', 'إجابة خاطئة. الإجابة الصحيحة هي: ليمون', b'0', NULL, @a, 2),
  (NULL, 'صح', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 3),
  (NULL, 'الميم', 'إجابة خاطئة. الإجابة الصحيحة هي: الراء', b'0', NULL, @a, 6),
  (NULL, 'دجاجة', 'أحسنت! إجابة صحيحة 🌟', b'1', NULL, @a, 13);

-- student 138: assigned but NOT STARTED — no attempt row on purpose

COMMIT;
