package com.springboot.manhaji.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Parent;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.School;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.TeacherAssignment;
import com.springboot.manhaji.entity.StudentResponse;
import com.springboot.manhaji.entity.User;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.repository.AdminRepository;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ParentRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.QuizRepository;
import com.springboot.manhaji.repository.SchoolRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherAssignmentRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.repository.UserRepository;
import com.springboot.manhaji.service.SkillMasteryService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final QuestionRepository questionRepository;
    private final QuizRepository quizRepository;
    private final AttemptRepository attemptRepository;
    private final StudentResponseRepository studentResponseRepository;
    private final ObjectMapper objectMapper;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final AdminRepository adminRepository;
    private final ParentRepository parentRepository;
    private final SchoolRepository schoolRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final ProgressRepository progressRepository;
    private final PasswordEncoder passwordEncoder;
    private final JdbcTemplate jdbcTemplate;
    private final QuizConfigProperties quizConfig;
    private final SkillMasteryService skillMasteryService;

    /**
     * When {@code true}, the seeder wipes all curriculum data (subjects, lessons,
     * questions, quizzes, attempts, responses) before re-importing from JSON.
     * Set in {@code application.yaml} as {@code manhaji.curriculum.reseed: true}
     * for one boot, then flip back to false. <strong>Never enable in production —
     * this destroys student attempts.</strong>
     */
    @Value("${manhaji.curriculum.reseed:false}")
    private boolean curriculumReseed;

    @Override
    public void run(String... args) {
        if (curriculumReseed) {
            wipeCurriculumData();
        }

        // Always try to import/sync from curriculum JSON (skips existing lessons,
        // but backfills new questions into existing lessons — required so
        // newly-added PRONUNCIATION items flow into dev DBs without a wipe).
        boolean imported = importFromCurriculum();

        if (!imported && subjectRepository.count() == 0) {
            log.info("No curriculum JSON files found and database is empty, using hardcoded seed data");
            seedHardcodedData();
            ensureHardcodedSubjects();
        }

        // English-purity self-heal (2026-07-04): dev databases seeded before
        // the "remove Arabic from English subject" cleanup still carry (a) the
        // legacy hardcoded "اللغة الإنجليزية" subject whose questions mix Arabic
        // into English stems, and (b) orphaned pre-cleanup rows under the
        // canonical "English" subject. The backfill only ADDS rows, so those
        // never healed on their own. Purge both on every boot (no-op when clean).
        purgeLegacyEnglishData();

        // Book-alignment self-heal (2026-07-04): subjects are being rebuilt
        // to mirror the real Palestinian textbooks (English G1 units, math G1
        // unit order/renames, Arabic story lessons, ...), so lessons/questions
        // that are no longer in the JSON are stale (old unit names, superseded
        // stem wordings — the "same question appears many times" bug). Remove
        // any curriculum row the canonical JSON doesn't contain.
        // NOTE: this makes the JSON the single source of truth for ALL seeded
        // subjects — teacher-authored additions to seeded lessons would be
        // removed too (acceptable for the demo dataset).
        purgeOrphanCurriculumContent();

        // Fairness self-heal (2026-07-04): a few authored ORDERING questions
        // shipped with options already in the correct order — the child could
        // just press "check". Rotate those rows so the puzzle is real.
        healPresolvedOrderingQuestions();

        // Always generate quizzes for lessons that have questions but no quiz,
        // and attach backfilled questions to quizzes that already exist.
        seedQuizzes();

        // Seed demo teacher and admin accounts
        seedDemoAccounts();

        // One-time BKT recompute after the 2026-07-13 recalibration. Gated by
        // MANHAJI_BKT_REBUILD=true so it only runs when you ask for it.
        rebuildAllMasteryIfRequested();
    }

    /**
     * Re-derive every student's BKT skill mastery from their persisted response
     * history through the (recalibrated) engine. Gated by
     * {@code MANHAJI_BKT_REBUILD=true} — run once after a BKT parameter change so
     * existing seeded mastery stops showing the old inflated numbers, then unset
     * the flag. {@link SkillMasteryService#rebuildForStudent} is idempotent, so a
     * stray re-run is harmless.
     */
    private void rebuildAllMasteryIfRequested() {
        if (!"true".equalsIgnoreCase(System.getenv("MANHAJI_BKT_REBUILD"))) {
            return;
        }
        var students = studentRepository.findAll();
        int folded = 0;
        for (var s : students) {
            folded += skillMasteryService.rebuildForStudent(s.getId());
        }
        log.warn("MANHAJI_BKT_REBUILD=true — recomputed BKT mastery for {} students ({} responses folded)",
                students.size(), folded);
    }

    /**
     * One-time wipe of curriculum + student response data. Triggered by
     * {@code manhaji.curriculum.reseed=true}. Order matters because
     * {@code student_responses} FK to {@code questions} and we don't rely on
     * DB-level cascade. User accounts are preserved.
     */
    private void wipeCurriculumData() {
        log.warn("manhaji.curriculum.reseed=true — wiping all curriculum data (subjects, lessons, questions, quizzes, attempts, responses)");
        studentResponseRepository.deleteAllInBatch();
        attemptRepository.deleteAllInBatch();
        // Quiz↔Question is a join table; deleting quizzes drops join rows. Delete
        // before questions to avoid FK violations on quiz_questions.
        quizRepository.deleteAllInBatch();
        questionRepository.deleteAllInBatch();
        lessonRepository.deleteAllInBatch();
        subjectRepository.deleteAllInBatch();
        log.warn("Curriculum data wiped. Will re-import from /resources/curriculum/*.json on this boot.");
    }

    /**
     * Audit-4 fix C4 + H4 (2026-05-15): demo seeding is now gated by an env
     * var ({@code MANHAJI_DEMO_SEED=true}) and the password values come from
     * env vars too — they are NEVER logged. Without the gate, every boot
     * recreated three privileged users with well-known passwords, and the
     * password literals were emitted to stdout where any log aggregator
     * would capture them. The seed defaults are documented in HANDOFF.md
     * for the demo laptop only.
     */
    private void seedDemoAccounts() {
        if (!"true".equalsIgnoreCase(System.getenv("MANHAJI_DEMO_SEED"))) {
            log.info("Demo seeding disabled (set MANHAJI_DEMO_SEED=true to enable for local dev only).");
            return;
        }

        String teacherPw = System.getenv().getOrDefault("MANHAJI_DEMO_TEACHER_PASSWORD", "teacher123");
        String adminPw = System.getenv().getOrDefault("MANHAJI_DEMO_ADMIN_PASSWORD", "admin123");
        String parentPw = System.getenv().getOrDefault("MANHAJI_DEMO_PARENT_PASSWORD", "parent123");
        String studentPw = System.getenv().getOrDefault("MANHAJI_DEMO_STUDENT_PASSWORD", "student123");

        userRepository.findByEmail("teacher@manhaji.edu")
                .ifPresent(ignored -> log.info(
                        "Legacy demo teacher teacher@manhaji.edu exists; assigning it to Arabic Grade 1"));

        // Admin account
        if (userRepository.findByEmail("admin@manhaji.edu").isEmpty()) {
            Admin admin = new Admin();
            admin.setFullName("مشرف النظام");
            admin.setEmail("admin@manhaji.edu");
            admin.setPasswordHash(passwordEncoder.encode(adminPw));
            admin.setRole(Role.ADMIN);
            admin.setIsActive(true);
            admin.setPermissions("ALL");
            adminRepository.save(admin);
            log.info("Created demo admin account: admin@manhaji.edu (password not logged)");
        }

        // Coherent demo roster (students, families, progress, derived points) is
        // built together in seedSubjectScopedDemoData so every number is backed by
        // real completed work — no "points but zero lessons" filler students.
        seedSubjectScopedDemoData(teacherPw, parentPw, studentPw);
    }

    private void seedSubjectScopedDemoData(String teacherPw, String parentPw, String studentPw) {
        Map<String, Subject> subjects = ensureGradeOneDemoSubjects();
        School school = ensureDemoSchool();

        Map<String, Teacher> teachers = ensureSubjectTeachers(subjects, school, teacherPw);
        ensureTeacherAssignments(teachers, subjects, school);

        seedCoherentRoster(school, parentPw, studentPw);
        seedGradeChampions(school, parentPw, studentPw);
    }

    private Map<String, Subject> ensureGradeOneDemoSubjects() {
        Map<String, Subject> subjects = new LinkedHashMap<>();
        subjects.put("arabic", ensureSubjectWithLessons(
                List.of("اللغة العربية", "Arabic"),
                1,
                this::createArabicLessons));
        subjects.put("islamic", ensureSubjectWithLessons(
                List.of("التربية الإسلامية", "Islamic Education", "Islamic"),
                1,
                this::createIslamicLessons));
        subjects.put("math", ensureSubjectWithLessons(
                List.of("الرياضيات", "Math", "Mathematics"),
                1,
                this::createMathLessons));
        subjects.put("english", ensureSubjectWithLessons(
                List.of("اللغة الإنجليزية", "English"),
                1,
                this::createEnglishLessons));
        return subjects;
    }

    private School ensureDemoSchool() {
        List<School> existing = schoolRepository.findByName("مدرسة منهاجي النموذجية");
        if (!existing.isEmpty()) {
            return existing.get(0);
        }

        School school = new School();
        school.setName("مدرسة منهاجي النموذجية");
        school.setAddress("فلسطين - بيئة عرض محلية");
        log.info("Created local demo school: {}", school.getName());
        return schoolRepository.save(school);
    }

    private Parent ensureDemoParent(String parentPw) {
        return userRepository.findByEmail("parent@manhaji.edu")
                .map(User::getId)
                .flatMap(parentRepository::findById)
                .orElseGet(() -> {
                    Parent parent = new Parent();
                    parent.setFullName("ولي أمر طلاب العرض");
                    parent.setEmail("parent@manhaji.edu");
                    parent.setPasswordHash(passwordEncoder.encode(parentPw));
                    parent.setIsActive(true);
                    log.info("Created demo parent account: parent@manhaji.edu (password not logged)");
                    return parentRepository.save(parent);
                });
    }

    private Map<String, Teacher> ensureSubjectTeachers(
            Map<String, Subject> subjects,
            School school,
            String teacherPw) {
        Map<String, Teacher> teachers = new LinkedHashMap<>();

        Teacher arabicTeacher = findTeacherByEmail("teacher@manhaji.edu");
        if (arabicTeacher == null) {
            arabicTeacher = ensureDemoTeacher(
                    "teacher.arabic@manhaji.local",
                    "أ. سلمى معلمة اللغة العربية",
                    "اللغة العربية",
                    school,
                    teacherPw);
        } else {
            configureDemoTeacher(arabicTeacher, "اللغة العربية", 1, school);
            log.info("Reused legacy demo teacher teacher@manhaji.edu for Arabic Grade 1 assignment");
        }
        teachers.put("arabic", arabicTeacher);

        teachers.put("islamic", ensureDemoTeacher(
                "teacher.islamic@manhaji.local",
                "أ. مريم معلمة التربية الإسلامية",
                "التربية الإسلامية",
                school,
                teacherPw));
        teachers.put("math", ensureDemoTeacher(
                "teacher.math@manhaji.local",
                "أ. خالد معلم الرياضيات",
                "الرياضيات",
                school,
                teacherPw));
        teachers.put("english", ensureDemoTeacher(
                "teacher.english@manhaji.local",
                "أ. ليلى معلمة اللغة الإنجليزية",
                "اللغة الإنجليزية",
                school,
                teacherPw));

        return teachers;
    }

    private Teacher ensureDemoTeacher(
            String email,
            String fullName,
            String department,
            School school,
            String teacherPw) {
        Teacher existing = findTeacherByEmail(email);
        if (existing != null) {
            return configureDemoTeacher(existing, department, 1, school);
        }

        Teacher teacher = new Teacher();
        teacher.setFullName(fullName);
        teacher.setEmail(email);
        teacher.setPasswordHash(passwordEncoder.encode(teacherPw));
        teacher.setIsActive(true);
        teacher.setDepartment(department);
        teacher.setAssignedGrade(1);
        teacher.setSchool(school);
        teacher = teacherRepository.save(teacher);
        log.info("Created subject demo teacher account: {} (password not logged)", email);
        return teacher;
    }

    private Teacher findTeacherByEmail(String email) {
        return userRepository.findByEmail(email)
                .map(User::getId)
                .flatMap(teacherRepository::findById)
                .orElse(null);
    }

    private Teacher configureDemoTeacher(
            Teacher teacher,
            String department,
            Integer assignedGrade,
            School school) {
        teacher.setIsActive(true);
        teacher.setDepartment(department);
        teacher.setAssignedGrade(assignedGrade);
        teacher.setSchool(school);
        return teacherRepository.save(teacher);
    }

    private void ensureTeacherAssignments(
            Map<String, Teacher> teachers,
            Map<String, Subject> subjects,
            School school) {
        for (Map.Entry<String, Teacher> entry : teachers.entrySet()) {
            Subject subject = subjects.get(entry.getKey());
            if (subject == null) continue;
            ensureTeacherAssignment(entry.getValue(), subject, school);
        }
    }

    private void ensureTeacherAssignment(Teacher teacher, Subject subject, School school) {
        TeacherAssignment assignment = teacherAssignmentRepository
                .findByTeacherIdAndSubjectId(teacher.getId(), subject.getId())
                .orElseGet(() -> {
                    TeacherAssignment created = new TeacherAssignment();
                    created.setTeacher(teacher);
                    created.setSubject(subject);
                    return created;
                });
        assignment.setGradeLevel(subject.getGradeLevel());
        assignment.setSchool(school);
        assignment.setIsActive(true);
        teacherAssignmentRepository.save(assignment);
    }

    // ── Coherent demo roster (grades 1-4) ───────────────────────────────────
    private static final List<String> DEMO_STUDENT_NAMES = List.of(
            "ليان أحمد", "آدم محمد", "جنى خالد", "يوسف سمير", "تالا محمود",
            "عمر ناصر", "سارة علي", "كريم حسن", "ريم ياسر", "مريم فادي",
            "زيد رامي", "نور إبراهيم", "لينا وسام", "حمزة طارق", "سلمى عماد",
            "معاذ أنس", "دانية غسان", "أنس وليد", "هبة مازن", "بلال صابر",
            "لمى فراس", "قيس نبيل", "رند سامي", "تميم عادل", "جودي هاني",
            "ملك رائد", "غيث أيمن", "شهد مؤيد", "بيان جهاد", "همام صهيب",
            "رهف عمار", "مهند لؤي", "براء منير", "لجين ثائر", "سما نزار",
            "خالد وسيم");
    private static final List<String> DEMO_STUDENT_AVATARS = List.of(
            "owl", "fox", "penguin", "koala", "panda", "butterfly", "unicorn",
            "bee", "dolphin", "hamster", "cat", "rabbit");

    // Per-grade "champion" accounts that have finished ~80% of the whole grade.
    private static final List<String> CHAMPION_NAMES = List.of(
            "ريماس المتفوقة", "تيم الخطيب", "سيلين ناصر", "زين العابدين");

    /**
     * Build ONE internally-consistent demo roster across grades 1-4. Every
     * student's {@code totalPoints} is DERIVED from the quizzes they actually
     * completed ({@code correctAnswers × pointsPerCorrect}, mirroring
     * QuizService), so the leaderboard, student dashboard and progress screens
     * always agree — no "points but zero lessons" students. Children are grouped
     * into small families (3 per parent); the first family reuses the canonical
     * {@code parent@manhaji.edu} login. Idempotent per email.
     */
    private void seedCoherentRoster(School school, String parentPw, String studentPw) {
        final int studentsPerGrade = 9;
        LocalDateTime now = LocalDateTime.now();
        int nameIdx = 0;
        int total = 0;

        for (int grade = 1; grade <= 4; grade++) {
            List<Subject> subjects = subjectRepository.findByGradeLevel(grade);
            if (subjects.isEmpty()) {
                log.warn("Demo roster: no subjects for grade {} — skipping", grade);
                continue;
            }

            Parent family = null;
            for (int n = 1; n <= studentsPerGrade; n++) {
                if ((n - 1) % 3 == 0) {
                    family = (grade == 1 && n == 1)
                            ? ensureDemoParent(parentPw)
                            : ensureFamilyParent(grade, ((n - 1) / 3) + 1, parentPw);
                }

                String email = String.format("demo.g%d.s%d@manhaji.edu", grade, n);
                String fullName = DEMO_STUDENT_NAMES.get(nameIdx % DEMO_STUDENT_NAMES.size());
                String avatar = DEMO_STUDENT_AVATARS.get(nameIdx % DEMO_STUDENT_AVATARS.size());
                nameIdx++;

                Student student = userRepository.findByEmail(email)
                        .map(User::getId)
                        .flatMap(studentRepository::findById)
                        .orElseGet(Student::new);
                student.setFullName(fullName);
                student.setEmail(email);
                student.setPasswordHash(passwordEncoder.encode(studentPw));
                student.setRole(Role.STUDENT);
                student.setIsActive(true);
                student.setGradeLevel(grade);
                student.setAvatarId(avatar);
                student.setSchool(school);
                student.setParent(family);
                student = studentRepository.save(student);

                // Ability tapers down the roster so the leaderboard has a natural
                // spread: rank 1 completes more lessons at higher mastery.
                double topMastery = 96.0 - (n - 1) * 5.0;
                int lessonsPerSubject = n <= 3 ? 5 : (n <= 6 ? 4 : 3);
                int earned = seedStudentWork(student, subjects, topMastery, lessonsPerSubject, now);

                student.setTotalPoints(earned);
                student.setCurrentStreak(Math.max(1, 8 - (n - 1)));
                student.setLastLoginAt(now.minusDays((n - 1) % 5));
                studentRepository.save(student);
                // Derive per-sub-skill BKT mastery from the work just seeded, so
                // the "My Skills" radar and adaptive "Challenge Me" have real
                // signal for demo accounts (their attempts bypass completeAttempt).
                skillMasteryService.rebuildForStudent(student.getId());
                total++;
            }
        }
        log.info("Seeded coherent demo roster: {} students across grades 1-4 "
                + "(points derived from completed work)", total);
    }

    /**
     * One "champion" student per grade (1-4) who has finished ~80% of EVERY
     * lesson in the grade at high mastery — a near-complete-curriculum demo
     * account. Points are derived from that work like everyone else, so the
     * dashboards/leaderboard stay consistent. Idempotent per email.
     */
    private void seedGradeChampions(School school, String parentPw, String studentPw) {
        LocalDateTime now = LocalDateTime.now();
        Parent parent = ensureDemoParent(parentPw);

        for (int grade = 1; grade <= 4; grade++) {
            List<Subject> subjects = subjectRepository.findByGradeLevel(grade);
            if (subjects.isEmpty()) {
                continue;
            }

            String email = String.format("demo.g%d.top@manhaji.edu", grade);
            Student student = userRepository.findByEmail(email)
                    .map(User::getId)
                    .flatMap(studentRepository::findById)
                    .orElseGet(Student::new);
            student.setFullName(CHAMPION_NAMES.get(grade - 1));
            student.setEmail(email);
            student.setPasswordHash(passwordEncoder.encode(studentPw));
            student.setRole(Role.STUDENT);
            student.setIsActive(true);
            student.setGradeLevel(grade);
            student.setAvatarId("unicorn");
            student.setSchool(school);
            student.setParent(parent);
            student = studentRepository.save(student);

            int earned = seedNearCompleteWork(student, subjects, 0.80, now);
            student.setTotalPoints(earned);
            student.setCurrentStreak(21);
            student.setLastLoginAt(now);
            studentRepository.save(student);
            skillMasteryService.rebuildForStudent(student.getId());
            log.info("Seeded grade {} champion: {} ({} pts, ~80% of lessons)",
                    grade, email, earned);
        }
    }

    /**
     * Seed Progress + a graded Attempt + per-question StudentResponses for the
     * first {@code fraction} of EVERY lesson in each subject (rounded up), all at
     * high mastery so each reads as MASTERED. Returns total derived points.
     */
    private int seedNearCompleteWork(Student student, List<Subject> subjects,
                                     double fraction, LocalDateTime now) {
        int totalPoints = 0;
        int subjectIndex = 0;
        for (Subject subject : subjects) {
            List<Lesson> lessons = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subject.getId());
            int limit = (int) Math.ceil(lessons.size() * fraction);
            for (int i = 0; i < limit; i++) {
                Lesson lesson = lessons.get(i);
                // Cycle 96→81, all comfortably above the mastery threshold (80).
                double mastery = Math.max(82.0, Math.min(99.0, 96.0 - (i % 6) * 3.0));
                CompletionStatus status =
                        mastery >= quizConfig.getMasteryThreshold() ? CompletionStatus.MASTERED
                        : CompletionStatus.COMPLETED;

                Progress progress = progressRepository
                        .findByStudentIdAndLessonId(student.getId(), lesson.getId())
                        .orElseGet(() -> {
                            Progress p = new Progress();
                            p.setStudent(student);
                            p.setLesson(lesson);
                            return p;
                        });
                progress.setMasteryLevel(mastery);
                progress.setCompletionStatus(status);
                progress.setLastAccessedAt(now.minusDays((i + subjectIndex) % 7));
                progress.setLastSegmentIndex(2);
                progress.setCompletedAt(now.minusDays((i + subjectIndex) % 10));
                progressRepository.save(progress);

                totalPoints += seedAttemptWithResponses(student, lesson, mastery, now, i, subjectIndex);
            }
            subjectIndex++;
        }
        return totalPoints;
    }

    private Parent ensureFamilyParent(int grade, int familyNo, String parentPw) {
        String email = String.format("parent.g%d.f%d@manhaji.local", grade, familyNo);
        return userRepository.findByEmail(email)
                .map(User::getId)
                .flatMap(parentRepository::findById)
                .orElseGet(() -> {
                    Parent parent = new Parent();
                    parent.setFullName(String.format("ولي أمر (صف %d - أسرة %d)", grade, familyNo));
                    parent.setEmail(email);
                    parent.setPasswordHash(passwordEncoder.encode(parentPw));
                    parent.setIsActive(true);
                    log.info("Created demo family parent: {} (password not logged)", email);
                    return parentRepository.save(parent);
                });
    }

    /**
     * Seed Progress + a graded Attempt + per-question StudentResponses for the
     * first {@code lessonsPerSubject} lessons of each subject, and return the
     * TOTAL points earned. Points and completion both derive from the same work
     * so the dashboards stay consistent. Mastery decays a little across lessons
     * so the last lesson or two read as "in progress".
     */
    private int seedStudentWork(Student student, List<Subject> subjects,
                                double topMastery, int lessonsPerSubject, LocalDateTime now) {
        int totalPoints = 0;
        int subjectIndex = 0;
        for (Subject subject : subjects) {
            List<Lesson> lessons = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subject.getId());
            int limit = Math.min(lessonsPerSubject, lessons.size());
            for (int i = 0; i < limit; i++) {
                Lesson lesson = lessons.get(i);
                double mastery = Math.max(35.0, Math.min(99.0,
                        topMastery - (i * 6.0) - (subjectIndex * 2.0)));
                CompletionStatus status =
                        mastery >= quizConfig.getMasteryThreshold() ? CompletionStatus.MASTERED
                        : mastery >= quizConfig.getCompletionThreshold() ? CompletionStatus.COMPLETED
                        : CompletionStatus.IN_PROGRESS;

                Progress progress = progressRepository
                        .findByStudentIdAndLessonId(student.getId(), lesson.getId())
                        .orElseGet(() -> {
                            Progress p = new Progress();
                            p.setStudent(student);
                            p.setLesson(lesson);
                            return p;
                        });
                progress.setMasteryLevel(mastery);
                progress.setCompletionStatus(status);
                progress.setLastAccessedAt(now.minusDays((i + subjectIndex) % 7));
                progress.setLastSegmentIndex(Math.min(i, 2));
                progress.setCompletedAt(status == CompletionStatus.IN_PROGRESS ? null
                        : now.minusDays((i + subjectIndex) % 10));
                progressRepository.save(progress);

                totalPoints += seedAttemptWithResponses(student, lesson, mastery, now, i, subjectIndex);
            }
            subjectIndex++;
        }
        return totalPoints;
    }

    /**
     * One GRADED attempt for the lesson's quiz + one StudentResponse per question
     * (correct/incorrect split by mastery so teacher mistake analytics has real
     * data). Returns points earned ({@code correctAnswers × pointsPerCorrect}) —
     * always returns the derived value so totalPoints is stable across re-boots,
     * while the attempt/response rows are only created once per (student, quiz).
     */
    private int seedAttemptWithResponses(Student student, Lesson lesson, double mastery,
                                         LocalDateTime now, int lessonIndex, int subjectIndex) {
        List<Quiz> quizzes = quizRepository.findByLessonId(lesson.getId());
        if (quizzes.isEmpty()) return 0;
        Quiz quiz = quizzes.get(0);

        List<Question> questions = questionRepository.findByLessonId(lesson.getId());
        int questionCount = questions.size();
        int correct = (int) Math.round(mastery / 100.0 * questionCount);

        if (attemptRepository.findByStudentIdAndQuizId(student.getId(), quiz.getId()).isEmpty()) {
            Attempt attempt = new Attempt();
            attempt.setStudent(student);
            attempt.setQuiz(quiz);
            attempt.setStatus(AttemptStatus.GRADED);
            attempt.setScore(mastery);
            attempt.setSubmittedAt(now.minusDays((lessonIndex + subjectIndex) % 8));
            Attempt savedAttempt = attemptRepository.save(attempt);

            for (int q = 0; q < questionCount; q++) {
                StudentResponse response = new StudentResponse();
                response.setAttempt(savedAttempt);
                response.setQuestion(questions.get(q));
                response.setIsCorrect(q < correct);
                studentResponseRepository.save(response);
            }
        }
        return correct * quizConfig.getPointsPerCorrect();
    }

    /**
     * Ensure all hardcoded subjects and their lessons exist.
     * This supplements the JSON import — adds any missing subjects/lessons/questions.
     */
    private void ensureHardcodedSubjects() {
        // English (not in hardcoded fallback, but commonly expected)
        ensureSubjectWithLessons("اللغة الإنجليزية", 1, this::createEnglishLessons);

        // Ensure Arabic, Math, Islamic have all their questions
        ensureSubjectWithLessons("اللغة العربية", 1, this::createArabicLessons);
        ensureSubjectWithLessons("الرياضيات", 1, this::createMathLessons);
        ensureSubjectWithLessons("التربية الإسلامية", 1, this::createIslamicLessons);
    }

    private Subject ensureSubjectWithLessons(String name, int gradeLevel,
                                             java.util.function.Consumer<Subject> lessonCreator) {
        return ensureSubjectWithLessons(List.of(name), gradeLevel, lessonCreator);
    }

    private Subject ensureSubjectWithLessons(List<String> candidateNames, int gradeLevel,
                                             java.util.function.Consumer<Subject> lessonCreator) {
        Subject subject = candidateNames.stream()
                .map(name -> subjectRepository.findByNameAndGradeLevel(name, gradeLevel))
                .filter(java.util.Optional::isPresent)
                .map(java.util.Optional::get)
                .findFirst()
                .orElseGet(() -> {
                    Subject s = new Subject();
                    s.setName(candidateNames.get(0));
                    s.setGradeLevel(gradeLevel);
                    log.info("Creating missing subject: {}", candidateNames.get(0));
                    return subjectRepository.save(s);
                });

        // Only create lessons if this subject has none
        List<Lesson> existing = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subject.getId());
        if (existing.isEmpty()) {
            log.info("Creating lessons for subject: {}", subject.getName());
            lessonCreator.accept(subject);
        } else {
            // Check if existing lessons are missing questions and add them
            supplementMissingQuestions(existing);
        }
        return subject;
    }

    private void supplementMissingQuestions(List<Lesson> lessons) {
        for (Lesson lesson : lessons) {
            List<Question> questions = questionRepository.findByLessonIdOrderByIdAsc(lesson.getId());
            if (questions.size() < 3) {
                log.info("Lesson '{}' has only {} questions, supplementing...",
                        lesson.getTitle(), questions.size());
                supplementLessonQuestions(lesson, questions);
            }
        }
    }

    private void supplementLessonQuestions(Lesson lesson, List<Question> existing) {
        boolean hasMCQ = existing.stream().anyMatch(q -> q.getType() == QuestionType.MCQ);
        boolean hasTF = existing.stream().anyMatch(q -> q.getType() == QuestionType.TRUE_FALSE);
        boolean hasSA = existing.stream().anyMatch(q -> q.getType() == QuestionType.SHORT_ANSWER);

        String title = lesson.getTitle();

        if (!hasTF) {
            createQuestion(lesson, QuestionType.TRUE_FALSE,
                    "هذا الدرس بعنوان: " + title, "صح", null, 1);
        }
        if (!hasMCQ) {
            createQuestion(lesson, QuestionType.MCQ,
                    "ما هو عنوان هذا الدرس؟", title,
                    "[\"" + title + "\",\"درس آخر\",\"لا أعرف\",\"مراجعة\"]", 1);
        }
        if (!hasSA) {
            createQuestion(lesson, QuestionType.SHORT_ANSWER,
                    "اكتب عنوان هذا الدرس", title, null, 1);
        }
    }

    // =================== JSON Curriculum Import ===================

    @SuppressWarnings("unchecked")
    private boolean importFromCurriculum() {
        try {
            PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
            Resource[] resources = resolver.getResources("classpath:curriculum/*.json");

            if (resources.length == 0) {
                return false;
            }

            log.info("Found {} curriculum JSON files to sync", resources.length);
            int newLessons = 0;
            int newQuestions = 0;

            // Diagnostic post-screenshot fix (2026-05-24): the previous version
            // wrapped the entire file-by-file loop in a single try/catch, so
            // any failure on file N silently aborted files N+1..end and the
            // log just said "Failed to import curriculum JSON: …" with no
            // hint of which file. Now each file is wrapped individually so
            // a broken grade 2 file doesn't suppress the grade 2 files after it.
            for (Resource resource : resources) {
                try (InputStream is = resource.getInputStream()) {
                    Map<String, Object> curriculum = objectMapper.readValue(is, new TypeReference<>() {});

                    String subjectName = (String) curriculum.get("subject");
                    String subjectCode = (String) curriculum.get("subjectCode");
                    int gradeLevel = (Integer) curriculum.get("gradeLevel");
                    Integer semester = (Integer) curriculum.getOrDefault("semester", 1);

                    // Create or find subject
                    Subject subject = subjectRepository
                            .findByNameAndGradeLevel(subjectName, gradeLevel)
                            .orElseGet(() -> {
                                Subject s = new Subject();
                                s.setName(subjectName);
                                s.setGradeLevel(gradeLevel);
                                return subjectRepository.save(s);
                            });

                    // Get existing lesson titles for this subject+semester to avoid duplicates
                    List<Lesson> existingLessons = lessonRepository
                            .findBySubjectIdOrderByOrderIndexAsc(subject.getId());
                    java.util.Set<String> existingTitles = existingLessons.stream()
                            .filter(l -> semester.equals(l.getSemesterNumber()))
                            .map(Lesson::getTitle)
                            .collect(java.util.stream.Collectors.toSet());

                    List<Map<String, Object>> lessons = (List<Map<String, Object>>) curriculum.get("lessons");
                    if (lessons == null) continue;

                    // Book-restructure fix (2026-07-05): lessons carry a UNIQUE
                    // (subject, semester, order_index) key. When a subject is
                    // restructured (new lessons inserted mid-sequence, existing
                    // ones reordered — the G1 math/religion rebuilds), surviving
                    // DB rows still hold their OLD index, so inserting a new
                    // lesson at its canonical index used to abort the whole file
                    // with a duplicate-key error, boot after boot. Park all
                    // existing rows of this subject+semester at +1000 first;
                    // every surviving lesson is re-pointed at its canonical
                    // index below (and the in-memory entities are synced so a
                    // later Hibernate flush can't write a stale index back).
                    if (!existingTitles.isEmpty()) {
                        jdbcTemplate.update(
                                "UPDATE lessons SET order_index = order_index + 1000 " +
                                "WHERE subject_id = ? AND semester_number = ? AND order_index < 1000 " +
                                "ORDER BY order_index DESC",
                                subject.getId(), semester);
                        for (Lesson l : existingLessons) {
                            if (semester.equals(l.getSemesterNumber()) && l.getOrderIndex() < 1000) {
                                l.setOrderIndex(l.getOrderIndex() + 1000);
                            }
                        }
                    }

                    // 2026-07-03: the textbook page-scan auto-mapper
                    // (buildLessonImageMap) was REMOVED by product decision —
                    // the scanned book pages rendered too blurry on device.
                    // Lesson images now come ONLY from the JSON "imageUrls"
                    // field (clean bundled illustrations, e.g. assets/openmoji/).

                    int importedFromFile = 0;
                    List<Lesson> importedLessons = new ArrayList<>();
                    for (Map<String, Object> lessonData : lessons) {
                        String title = (String) lessonData.get("title");

                        if (existingTitles.contains(title)) {
                            // Lesson exists — backfill any NEW questions that were
                            // added to the JSON after the initial seed (e.g. the
                            // English PRONUNCIATION additions). Match on type +
                            // questionText so edits to existing questions don't
                            // duplicate-insert. Filter by semester too: a lesson
                            // moved between semesters briefly exists in both.
                            Lesson existing = existingLessons.stream()
                                    .filter(l -> title.equals(l.getTitle())
                                            && semester.equals(l.getSemesterNumber()))
                                    .findFirst().orElse(null);
                            if (existing != null) {
                                newQuestions += backfillLessonQuestions(existing, lessonData);
                                // Un-park: restore this lesson to its canonical
                                // book position from the JSON.
                                if (lessonData.get("orderIndex") instanceof Integer canonicalIdx
                                        && !canonicalIdx.equals(existing.getOrderIndex())) {
                                    existing.setOrderIndex(canonicalIdx);
                                    lessonRepository.save(existing);
                                }
                            }
                            continue;
                        }

                        Lesson lesson = importLesson(subject, lessonData, semester);
                        importedLessons.add(lesson);
                        newLessons++;
                        importedFromFile++;

                        List<Map<String, Object>> questions =
                                (List<Map<String, Object>>) lessonData.get("questions");
                        if (questions != null) {
                            for (Map<String, Object> qData : questions) {
                                importQuestion(lesson, qData);
                                newQuestions++;
                            }
                        }
                    }

                    if (importedFromFile > 0) {
                        log.info("Imported {} new lessons for {} (semester {}) from {}",
                                importedFromFile, subjectName, semester, resource.getFilename());
                    }

                    // Backfill semesterNumber and imageUrls for existing lessons that are missing them
                    backfillLessonMetadata(existingLessons, semester, lessons);
                } catch (Exception perFileEx) {
                    // Don't let one bad file kill the rest. Log loudly with
                    // the filename + exception type so the cause is obvious
                    // (e.g. DataIntegrityViolationException → unique
                    // constraint, JsonMappingException → malformed JSON).
                    log.error("Failed to import curriculum file {} : {} — {}. " +
                            "Other files in this boot are still processed.",
                            resource.getFilename(),
                            perFileEx.getClass().getSimpleName(),
                            perFileEx.getMessage());
                }
            }

            // Post-import diagnostic: dump subject counts per grade so a
            // missing grade is visible at boot time (don't need to wait
            // until a student logs in to find out).
            for (int g = 1; g <= 4; g++) {
                long count = subjectRepository.findByGradeLevel(g).size();
                if (count > 0) {
                    log.info("Curriculum diagnostic: Grade {} has {} subject(s).", g, count);
                }
            }

            if (newLessons > 0) {
                log.info("Curriculum sync complete: {} new lessons, {} new questions", newLessons, newQuestions);
            } else {
                log.info("Curriculum sync: all lessons already present");
            }
            return true;

        } catch (Exception e) {
            log.warn("Failed to import curriculum JSON: {}", e.getMessage());
            return false;
        }
    }

    @SuppressWarnings("unchecked")
    private Lesson importLesson(Subject subject, Map<String, Object> data,
                                 Integer semester) {
        Lesson lesson = new Lesson();
        lesson.setSubject(subject);
        lesson.setTitle((String) data.get("title"));
        lesson.setGradeLevel(subject.getGradeLevel());
        lesson.setOrderIndex((Integer) data.get("orderIndex"));
        lesson.setSemesterNumber(semester != null ? semester : 1);
        lesson.setContent((String) data.get("content"));
        lesson.setObjectives((String) data.get("objectives"));

        // Lesson images come ONLY from the JSON (clean bundled illustrations).
        // The old textbook page-scan auto-mapper is gone — see importCurriculum.
        List<String> imageUrls = (List<String>) data.get("imageUrls");
        if (imageUrls != null && !imageUrls.isEmpty()) {
            try {
                lesson.setImageUrls(objectMapper.writeValueAsString(imageUrls));
            } catch (Exception e) {
                log.warn("Failed to serialize imageUrls for lesson: {}", lesson.getTitle());
            }
        }

        return lessonRepository.save(lesson);
    }

    /**
     * Update existing lessons that may be missing semesterNumber or imageUrls
     * (e.g. from an earlier import before these fields were populated).
     *
     * <p>2026-07-03: also SELF-HEALS the old textbook page scans — any stored
     * imageUrls that point at the removed {@code /uploads/images/**}
     * page-scan convention are replaced with the JSON's imageUrls (or cleared
     * when the JSON has none), so existing dev databases lose the blurry book
     * photos on next boot without needing a destructive reseed.
     */
    @SuppressWarnings("unchecked")
    private void backfillLessonMetadata(List<Lesson> existingLessons, Integer semester,
                                         List<Map<String, Object>> jsonLessons) {
        if (existingLessons == null || existingLessons.isEmpty() || jsonLessons == null) return;
        Map<String, List<String>> jsonImagesByTitle = new java.util.HashMap<>();
        Map<String, Integer> jsonOrderByTitle = new java.util.HashMap<>();
        java.util.Set<String> jsonTitles = new java.util.HashSet<>();
        for (Map<String, Object> ld : jsonLessons) {
            Object t = ld.get("title");
            if (t == null) continue;
            jsonTitles.add(t.toString());
            Object imgs = ld.get("imageUrls");
            if (imgs instanceof List<?> list && !list.isEmpty()) {
                jsonImagesByTitle.put(t.toString(),
                        list.stream().map(Object::toString).toList());
            }
            if (ld.get("orderIndex") instanceof Integer oi) {
                jsonOrderByTitle.put(t.toString(), oi);
            }
        }

        int backfilled = 0;
        for (Lesson lesson : existingLessons) {
            // Skip lessons whose semester is already set to a different value —
            // a shared title (e.g. "مراجعة عامة") may legitimately exist in both files,
            // and we must not overwrite the semester of the other file's row.
            if (lesson.getSemesterNumber() != null
                    && !semester.equals(lesson.getSemesterNumber())) {
                continue;
            }
            if (!jsonTitles.contains(lesson.getTitle())) continue;

            boolean changed = false;
            if (lesson.getSemesterNumber() == null) {
                lesson.setSemesterNumber(semester);
                changed = true;
            }

            // Keep display order in sync with the JSON (e.g. the English
            // alphabet lessons moved behind the book units, 2026-07-04).
            Integer jsonOrder = jsonOrderByTitle.get(lesson.getTitle());
            if (jsonOrder != null && !jsonOrder.equals(lesson.getOrderIndex())) {
                lesson.setOrderIndex(jsonOrder);
                changed = true;
            }

            String stored = lesson.getImageUrls();
            boolean storedEmpty = stored == null || stored.isBlank() || stored.equals("[]");
            // Legacy book scans are recognizable by the auto-mapper's URL shape.
            boolean storedIsBookScan = stored != null && stored.contains("/uploads/images/")
                    && stored.contains("page");
            if (storedEmpty || storedIsBookScan) {
                List<String> imgs = jsonImagesByTitle.get(lesson.getTitle());
                try {
                    String replacement = (imgs == null || imgs.isEmpty())
                            ? (storedIsBookScan ? "[]" : null)
                            : objectMapper.writeValueAsString(imgs);
                    if (replacement != null && !replacement.equals(stored)) {
                        lesson.setImageUrls(replacement);
                        changed = true;
                    }
                } catch (Exception e) {
                    log.warn("Failed to backfill imageUrls for lesson '{}': {}", lesson.getTitle(), e.getMessage());
                }
            }
            if (changed) {
                lessonRepository.save(lesson);
                backfilled++;
            }
        }
        if (backfilled > 0) {
            log.info("Backfilled metadata for {} existing lessons (semester {})", backfilled, semester);
        }
    }

    /**
     * Insert any questions from the JSON that are missing from an already-seeded
     * lesson. Match by (type, questionText) pair — this lets us add new items
     * (like the English PRONUNCIATION additions for the demo) without wiping
     * the DB or duplicating existing rows.
     *
     * @return number of rows inserted
     */
    @SuppressWarnings("unchecked")
    private int backfillLessonQuestions(Lesson lesson, Map<String, Object> lessonData) {
        List<Map<String, Object>> jsonQuestions =
                (List<Map<String, Object>>) lessonData.get("questions");
        if (jsonQuestions == null || jsonQuestions.isEmpty()) return 0;

        List<Question> existing = questionRepository.findByLessonIdOrderByIdAsc(lesson.getId());
        java.util.Set<String> existingKeys = new java.util.HashSet<>();
        for (Question q : existing) {
            existingKeys.add(q.getType().name() + "||" + q.getQuestionText());
        }

        int inserted = 0;
        for (Map<String, Object> qData : jsonQuestions) {
            String type = (String) qData.get("type");
            String text = (String) qData.get("questionText");
            if (type == null || text == null) continue;
            if (existingKeys.contains(type + "||" + text)) continue;

            importQuestion(lesson, qData);
            inserted++;
        }
        if (inserted > 0) {
            log.info("Backfilled {} new questions into existing lesson '{}'",
                    inserted, lesson.getTitle());
        }
        return inserted;
    }

    @SuppressWarnings("unchecked")
    private void importQuestion(Lesson lesson, Map<String, Object> data) {
        Question q = new Question();
        q.setLesson(lesson);
        q.setType(QuestionType.valueOf((String) data.get("type")));
        q.setQuestionText((String) data.get("questionText"));
        q.setCorrectAnswer((String) data.get("correctAnswer"));

        Object options = data.get("options");
        if (options instanceof List) {
            try {
                q.setOptions(objectMapper.writeValueAsString(options));
            } catch (Exception e) {
                log.warn("Failed to serialize options for question: {}", q.getQuestionText());
            }
        }

        Object difficulty = data.get("difficultyLevel");
        if (difficulty instanceof Integer) {
            q.setDifficultyLevel((Integer) difficulty);
        } else {
            q.setDifficultyLevel(1);
        }

        // Optional metadata fields (added 2026-04 per question-authoring-spec.md).
        Object subSkill = data.get("subSkill");
        if (subSkill instanceof String s && !s.isBlank()) {
            q.setSubSkill(s);
        }
        Object imageUrl = data.get("imageUrl");
        if (imageUrl instanceof String s && !s.isBlank()) {
            q.setImageUrl(s);
        }
        Object audioUrl = data.get("audioUrl");
        if (audioUrl instanceof String s && !s.isBlank()) {
            q.setAudioUrl(s);
        }

        // Tier 1 (2026-06): IMAGE_MCQ / LISTEN_CHOOSE parallel images + IMAGE_MATCH pairs.
        // Stored as raw JSON strings on the entity's JSON columns.
        Object optionImages = data.get("optionImages");
        if (optionImages instanceof List<?> list && !list.isEmpty()) {
            try {
                q.setOptionImages(objectMapper.writeValueAsString(list));
            } catch (Exception ignored) {
                // leave null — widget falls back to text options
            }
        }
        Object pairs = data.get("pairs");
        if (pairs instanceof Map<?, ?> map && !map.isEmpty()) {
            try {
                q.setPairsJson(objectMapper.writeValueAsString(map));
            } catch (Exception ignored) {
                // leave null
            }
        }

        questionRepository.save(q);
    }

    // =================== English purity self-heal ===================

    /**
     * Removes English-subject data that must not exist (2026-07-04):
     * <ol>
     *   <li>The legacy hardcoded "اللغة الإنجليزية" subject — a duplicate of the
     *       canonical JSON "English" subject whose hardcoded questions mixed
     *       Arabic into English stems ("How do you say 'مرحباً' in English?").
     *       Deleted wholesale, dependents first.</li>
     *   <li>Any question under a canonical "English" subject whose stem,
     *       options, or answer still contains Arabic script — orphans left in
     *       old dev DBs from before the JSON cleanup (the backfill inserted
     *       the English replacements but never removed the Arabic originals).</li>
     * </ol>
     * Idempotent: a clean database matches nothing and nothing is touched.
     */
    private void purgeLegacyEnglishData() {
        try {
            // ---- (1) legacy duplicate subject, dependents-first ----
            List<Long> subjectIds = queryIds(
                    "SELECT id FROM subjects WHERE name = 'اللغة الإنجليزية'");
            if (!subjectIds.isEmpty()) {
                String sin = joinIds(subjectIds);
                List<Long> lessonIds = queryIds(
                        "SELECT id FROM lessons WHERE subject_id IN (" + sin + ")");
                String lin = joinIds(lessonIds);
                List<Long> quizIds = lessonIds.isEmpty()
                        ? queryIds("SELECT id FROM quizzes WHERE subject_id IN (" + sin + ")")
                        : queryIds("SELECT id FROM quizzes WHERE subject_id IN (" + sin + ")"
                                + " OR lesson_id IN (" + lin + ")");
                if (!quizIds.isEmpty()) {
                    String qin = joinIds(quizIds);
                    List<Long> attemptIds = queryIds(
                            "SELECT id FROM attempts WHERE quiz_id IN (" + qin + ")");
                    if (!attemptIds.isEmpty()) {
                        String ain = joinIds(attemptIds);
                        jdbcTemplate.update("DELETE FROM student_responses WHERE attempt_id IN (" + ain + ")");
                        jdbcTemplate.update("DELETE FROM attempts WHERE id IN (" + ain + ")");
                    }
                    jdbcTemplate.update("DELETE FROM quiz_questions WHERE quiz_id IN (" + qin + ")");
                    jdbcTemplate.update("DELETE FROM quizzes WHERE id IN (" + qin + ")");
                }
                if (!lessonIds.isEmpty()) {
                    List<Long> questionIds = queryIds(
                            "SELECT id FROM questions WHERE lesson_id IN (" + lin + ")");
                    if (!questionIds.isEmpty()) {
                        String qqin = joinIds(questionIds);
                        jdbcTemplate.update("DELETE FROM student_responses WHERE question_id IN (" + qqin + ")");
                        jdbcTemplate.update("DELETE FROM quiz_questions WHERE question_id IN (" + qqin + ")");
                        jdbcTemplate.update("DELETE FROM questions WHERE id IN (" + qqin + ")");
                    }
                    jdbcTemplate.update("DELETE FROM progress WHERE lesson_id IN (" + lin + ")");
                    jdbcTemplate.update("DELETE FROM lessons WHERE id IN (" + lin + ")");
                }
                jdbcTemplate.update("DELETE FROM skill_mastery WHERE subject_id IN (" + sin + ")");
                jdbcTemplate.update("DELETE FROM subjects WHERE id IN (" + sin + ")");
                log.info("Purged legacy duplicate English subject (اللغة الإنجليزية): "
                        + "{} lesson(s), {} quiz(zes)", lessonIds.size(), quizIds.size());
            }

            // ---- (2) Arabic-contaminated rows under canonical English ----
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                    "SELECT q.id, q.question_text, q.options, q.correct_answer "
                    + "FROM questions q "
                    + "JOIN lessons l ON q.lesson_id = l.id "
                    + "JOIN subjects s ON l.subject_id = s.id "
                    + "WHERE s.name = 'English'");
            List<Long> contaminated = new ArrayList<>();
            for (Map<String, Object> row : rows) {
                String blob = String.valueOf(row.get("question_text")) + " "
                        + String.valueOf(row.get("options")) + " "
                        + String.valueOf(row.get("correct_answer"));
                if (containsArabicScript(blob)) {
                    contaminated.add(((Number) row.get("id")).longValue());
                }
            }
            if (!contaminated.isEmpty()) {
                String cin = joinIds(contaminated);
                jdbcTemplate.update("DELETE FROM student_responses WHERE question_id IN (" + cin + ")");
                jdbcTemplate.update("DELETE FROM quiz_questions WHERE question_id IN (" + cin + ")");
                jdbcTemplate.update("DELETE FROM questions WHERE id IN (" + cin + ")");
                log.info("Purged {} Arabic-contaminated question(s) from the English subject", contaminated.size());
            }
        } catch (Exception e) {
            // Never block boot on the sweep — log and continue.
            log.warn("English-purity sweep failed (continuing): {}", e.getMessage());
        }
    }

    /**
     * Deletes seeded-subject lessons and questions that the canonical
     * curriculum JSON no longer contains (see call site for rationale).
     * Lessons match by (subject, gradeLevel, semester, title); questions by
     * (lesson, type, questionText). Dependents are removed first. Subjects
     * that have no JSON files are never touched.
     */
    @SuppressWarnings("unchecked")
    private void purgeOrphanCurriculumContent() {
        try {
            // Canonical content from the classpath JSONs:
            // key "<subject>|<grade>|<semester>|<lessonTitle>" → "TYPE|questionText" set.
            Map<String, java.util.Set<String>> canonical = new java.util.HashMap<>();
            java.util.Set<String> seededSubjects = new java.util.HashSet<>();
            PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
            for (Resource resource : resolver.getResources("classpath:curriculum/*.json")) {
                try (InputStream in = resource.getInputStream()) {
                    Map<String, Object> curriculum = objectMapper.readValue(in, Map.class);
                    String subjectName = String.valueOf(curriculum.get("subject"));
                    int grade = (Integer) curriculum.get("gradeLevel");
                    int semester = (Integer) curriculum.getOrDefault("semester", 1);
                    seededSubjects.add(subjectName);
                    List<Map<String, Object>> lessons =
                            (List<Map<String, Object>>) curriculum.get("lessons");
                    if (lessons == null) continue;
                    for (Map<String, Object> lessonData : lessons) {
                        String key = subjectName + "|" + grade + "|" + semester
                                + "|" + lessonData.get("title");
                        java.util.Set<String> qKeys = canonical
                                .computeIfAbsent(key, k -> new java.util.HashSet<>());
                        List<Map<String, Object>> questions =
                                (List<Map<String, Object>>) lessonData.get("questions");
                        if (questions == null) continue;
                        for (Map<String, Object> qData : questions) {
                            qKeys.add(qData.get("type") + "|" + qData.get("questionText"));
                        }
                    }
                }
            }
            if (canonical.isEmpty()) return;

            // Walk lessons of seeded subjects in the DB.
            List<Map<String, Object>> lessonRows = jdbcTemplate.queryForList(
                    "SELECT l.id, l.title, l.grade_level, l.semester_number, s.name AS subject_name "
                    + "FROM lessons l JOIN subjects s ON l.subject_id = s.id");
            List<Long> orphanLessonIds = new ArrayList<>();
            List<Long> orphanQuestionIds = new ArrayList<>();
            for (Map<String, Object> row : lessonRows) {
                if (!seededSubjects.contains(String.valueOf(row.get("subject_name")))) {
                    continue; // subject not managed by JSON — never touch
                }
                long lessonId = ((Number) row.get("id")).longValue();
                String key = row.get("subject_name") + "|" + row.get("grade_level")
                        + "|" + row.get("semester_number") + "|" + row.get("title");
                java.util.Set<String> qKeys = canonical.get(key);
                if (qKeys == null) {
                    orphanLessonIds.add(lessonId);
                    continue;
                }
                List<Map<String, Object>> qRows = jdbcTemplate.queryForList(
                        "SELECT id, type, question_text FROM questions WHERE lesson_id = " + lessonId);
                for (Map<String, Object> qRow : qRows) {
                    if (!qKeys.contains(qRow.get("type") + "|" + qRow.get("question_text"))) {
                        orphanQuestionIds.add(((Number) qRow.get("id")).longValue());
                    }
                }
            }

            // Orphan lessons: their questions are orphans too.
            if (!orphanLessonIds.isEmpty()) {
                String lin = joinIds(orphanLessonIds);
                orphanQuestionIds.addAll(queryIds(
                        "SELECT id FROM questions WHERE lesson_id IN (" + lin + ")"));
            }
            if (!orphanQuestionIds.isEmpty()) {
                String qin = joinIds(orphanQuestionIds);
                jdbcTemplate.update("DELETE FROM student_responses WHERE question_id IN (" + qin + ")");
                jdbcTemplate.update("DELETE FROM quiz_questions WHERE question_id IN (" + qin + ")");
                jdbcTemplate.update("DELETE FROM questions WHERE id IN (" + qin + ")");
            }
            if (!orphanLessonIds.isEmpty()) {
                String lin = joinIds(orphanLessonIds);
                List<Long> quizIds = queryIds("SELECT id FROM quizzes WHERE lesson_id IN (" + lin + ")");
                if (!quizIds.isEmpty()) {
                    String qzin = joinIds(quizIds);
                    List<Long> attemptIds = queryIds("SELECT id FROM attempts WHERE quiz_id IN (" + qzin + ")");
                    if (!attemptIds.isEmpty()) {
                        String ain = joinIds(attemptIds);
                        jdbcTemplate.update("DELETE FROM student_responses WHERE attempt_id IN (" + ain + ")");
                        jdbcTemplate.update("DELETE FROM attempts WHERE id IN (" + ain + ")");
                    }
                    jdbcTemplate.update("DELETE FROM quiz_questions WHERE quiz_id IN (" + qzin + ")");
                    jdbcTemplate.update("DELETE FROM quizzes WHERE id IN (" + qzin + ")");
                }
                jdbcTemplate.update("DELETE FROM progress WHERE lesson_id IN (" + lin + ")");
                jdbcTemplate.update("DELETE FROM lessons WHERE id IN (" + lin + ")");
            }
            if (!orphanLessonIds.isEmpty() || !orphanQuestionIds.isEmpty()) {
                log.info("Book-alignment purge: removed {} stale lesson(s) and {} stale question(s)",
                        orphanLessonIds.size(), orphanQuestionIds.size());
            }
        } catch (Exception e) {
            log.warn("Curriculum orphan purge failed (continuing): {}", e.getMessage());
        }
    }

    private List<Long> queryIds(String sql) {
        return jdbcTemplate.queryForList(sql, Long.class);
    }

    private static String joinIds(List<Long> ids) {
        StringBuilder sb = new StringBuilder();
        for (Long id : ids) {
            if (sb.length() > 0) sb.append(',');
            sb.append(id);
        }
        return sb.toString();
    }

    private static boolean containsArabicScript(String text) {
        if (text == null) return false;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c >= 0x0600 && c <= 0x06FF) return true;
        }
        return false;
    }

    /**
     * ORDERING rows whose stored options already match the correct-answer
     * sequence present a pre-solved puzzle. Rotate the options by one so the
     * student actually has to reorder. Idempotent — after the rotation the
     * sequences differ and the row is never touched again. (The JSON files
     * carry the same fix via the enrichment script's fairness pass; this
     * heals rows that were seeded before it.)
     */
    private void healPresolvedOrderingQuestions() {
        try {
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                    "SELECT id, options, correct_answer FROM questions WHERE type = 'ORDERING'");
            int healed = 0;
            for (Map<String, Object> row : rows) {
                String optionsJson = String.valueOf(row.get("options"));
                String correct = String.valueOf(row.get("correct_answer"));
                List<String> options;
                try {
                    options = objectMapper.readValue(optionsJson,
                            new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {});
                } catch (Exception parse) {
                    continue;
                }
                if (options == null || options.size() < 2) continue;

                List<String> answerSeq = new ArrayList<>();
                for (String part : correct.split("[،,]")) {
                    answerSeq.add(part.replaceAll("\\s+", ""));
                }
                List<String> optionSeq = new ArrayList<>();
                for (String o : options) {
                    optionSeq.add(o == null ? "" : o.replaceAll("\\s+", ""));
                }
                if (!optionSeq.equals(answerSeq)) continue;

                // Pre-solved — rotate by one (guaranteed different order).
                List<String> rotated = new ArrayList<>(options.subList(1, options.size()));
                rotated.add(options.get(0));
                try {
                    jdbcTemplate.update("UPDATE questions SET options = ? WHERE id = ?",
                            objectMapper.writeValueAsString(rotated), row.get("id"));
                    healed++;
                } catch (Exception write) {
                    log.warn("Could not heal pre-solved ORDERING question {}: {}",
                            row.get("id"), write.getMessage());
                }
            }
            if (healed > 0) {
                log.info("Healed {} pre-solved ORDERING question(s) (options rotated)", healed);
            }
        } catch (Exception e) {
            log.warn("Pre-solved ORDERING sweep failed (continuing): {}", e.getMessage());
        }
    }

    // =================== Quiz Generation ===================

    private void seedQuizzes() {
        createQuizzesForAllLessons();
    }

    private void createQuizzesForAllLessons() {
        List<Lesson> allLessons = lessonRepository.findAll();
        int created = 0;
        int attached = 0;
        for (Lesson lesson : allLessons) {
            List<Question> questions = questionRepository.findByLessonIdOrderByIdAsc(lesson.getId());
            if (questions.isEmpty()) continue;

            List<Quiz> existingQuizzes = quizRepository.findByLessonId(lesson.getId());
            if (!existingQuizzes.isEmpty()) {
                // Attach any questions backfilled since the quiz was first created.
                // Use a direct join-table query (not quiz.getQuestions()) to avoid
                // triggering a LazyInitializationException — the seeder doesn't run
                // inside an open Hibernate session.
                Quiz quiz = existingQuizzes.get(0);
                List<Long> attachedIds = quizRepository.findQuestionIdsByQuizId(quiz.getId());
                java.util.Set<Long> alreadyInQuiz = new java.util.HashSet<>(attachedIds);
                List<Question> toAttach = new ArrayList<>();
                for (Question q : questions) {
                    if (!alreadyInQuiz.contains(q.getId())) {
                        toAttach.add(q);
                    }
                }
                if (!toAttach.isEmpty()) {
                    // Re-fetch the quiz with its questions initialized, add new
                    // ones, save. We merge toAttach into a fresh collection so we
                    // don't rely on the original 'quiz' reference's lazy state.
                    List<Question> merged = new ArrayList<>();
                    for (Long id : alreadyInQuiz) {
                        questionRepository.findById(id).ifPresent(merged::add);
                    }
                    merged.addAll(toAttach);
                    quiz.setQuestions(merged);
                    quizRepository.save(quiz);
                    attached += toAttach.size();
                }
                continue;
            }

            Quiz quiz = new Quiz();
            quiz.setTitle("اختبار: " + lesson.getTitle());
            quiz.setLesson(lesson);
            quiz.setGamified(true);
            quiz.setGeneratedFromLesson(true);
            quiz.setQuestions(questions);
            quizRepository.save(quiz);
            created++;
        }
        if (attached > 0) {
            log.info("Attached {} newly-backfilled questions to existing quizzes", attached);
        }
        if (created > 0) {
            log.info("Created {} new quizzes for lessons without quizzes", created);
        }
    }

    // =================== Hardcoded Fallback Data ===================

    private void seedHardcodedData() {
        Subject arabic1 = new Subject();
        arabic1.setName("اللغة العربية");
        arabic1.setGradeLevel(1);
        arabic1 = subjectRepository.save(arabic1);

        Subject math1 = new Subject();
        math1.setName("الرياضيات");
        math1.setGradeLevel(1);
        math1 = subjectRepository.save(math1);

        Subject islamic1 = new Subject();
        islamic1.setName("التربية الإسلامية");
        islamic1.setGradeLevel(1);
        islamic1 = subjectRepository.save(islamic1);

        createArabicLessons(arabic1);
        createMathLessons(math1);
        createIslamicLessons(islamic1);
    }

    private void createArabicLessons(Subject arabic) {
        Lesson l1 = createLesson(arabic, "حرف الألف", 1,
                "حرف الألف هو أول حرف في الحروف العربية. شكله يشبه العصا المستقيمة. نتعلم اليوم كيف نكتب حرف الألف ونقرأه في كلمات مثل: أسد، أرنب، أم.",
                "تعلم كتابة وقراءة حرف الألف");
        createQuestion(l1, QuestionType.MCQ, "ما هو أول حرف في الحروف العربية؟",
                "الألف", "[\"الألف\",\"الباء\",\"التاء\",\"الثاء\"]", 1);
        createQuestion(l1, QuestionType.TRUE_FALSE, "حرف الألف شكله يشبه العصا المستقيمة",
                "صح", null, 1);
        createQuestion(l1, QuestionType.SHORT_ANSWER, "اذكر كلمة تبدأ بحرف الألف",
                "أسد", null, 1);

        Lesson l2 = createLesson(arabic, "حرف الباء", 2,
                "حرف الباء هو الحرف الثاني في الحروف العربية. شكله مثل الصحن وتحته نقطة واحدة. كلمات تبدأ بحرف الباء: بيت، بطة، باب.",
                "تعلم كتابة وقراءة حرف الباء");
        createQuestion(l2, QuestionType.MCQ, "كم نقطة تحت حرف الباء؟",
                "نقطة واحدة", "[\"نقطة واحدة\",\"نقطتان\",\"ثلاث نقاط\",\"بدون نقاط\"]", 1);
        createQuestion(l2, QuestionType.TRUE_FALSE, "كلمة \"بيت\" تبدأ بحرف الباء",
                "صح", null, 1);
        createQuestion(l2, QuestionType.SHORT_ANSWER, "اكتب حرف الباء",
                "ب", null, 1);

        Lesson l3 = createLesson(arabic, "حرف التاء", 3,
                "حرف التاء هو الحرف الثالث. شكله مثل حرف الباء لكن فوقه نقطتان. كلمات تبدأ بحرف التاء: تفاح، تمر، تاج.",
                "تعلم كتابة وقراءة حرف التاء");
        createQuestion(l3, QuestionType.TRUE_FALSE, "حرف التاء فوقه نقطتان",
                "صح", null, 1);
        createQuestion(l3, QuestionType.MCQ, "أي كلمة تبدأ بحرف التاء؟",
                "تفاح", "[\"تفاح\",\"سمكة\",\"قمر\",\"نجمة\"]", 1);
        createQuestion(l3, QuestionType.SHORT_ANSWER, "اذكر كلمة تبدأ بحرف التاء",
                "تفاح", null, 1);

        Lesson l4 = createLesson(arabic, "حرف الثاء", 4,
                "حرف الثاء شكله مثل حرف الباء والتاء لكن فوقه ثلاث نقاط. كلمات تبدأ بحرف الثاء: ثعلب، ثوب، ثلج.",
                "تعلم كتابة وقراءة حرف الثاء");
        createQuestion(l4, QuestionType.MCQ, "كم نقطة فوق حرف الثاء؟",
                "ثلاث نقاط", "[\"نقطة واحدة\",\"نقطتان\",\"ثلاث نقاط\",\"بدون نقاط\"]", 1);
        createQuestion(l4, QuestionType.TRUE_FALSE, "كلمة \"ثعلب\" تبدأ بحرف الثاء",
                "صح", null, 1);
        createQuestion(l4, QuestionType.SHORT_ANSWER, "اكتب حرف الثاء",
                "ث", null, 1);

        Lesson l5 = createLesson(arabic, "مراجعة الحروف أ ب ت ث", 5,
                "في هذا الدرس نراجع الحروف الأربعة التي تعلمناها: الألف والباء والتاء والثاء. نتدرب على قراءتها وكتابتها في كلمات مختلفة.",
                "مراجعة شاملة للحروف أ ب ت ث");
        createQuestion(l5, QuestionType.MCQ, "أي حرف فوقه نقطتان؟",
                "التاء", "[\"الألف\",\"الباء\",\"التاء\",\"الثاء\"]", 1);
        createQuestion(l5, QuestionType.TRUE_FALSE, "حرف الألف ليس له نقاط",
                "صح", null, 1);
        createQuestion(l5, QuestionType.SHORT_ANSWER, "اكتب الحروف أ ب ت ث بالترتيب",
                "أ ب ت ث", null, 1);
    }

    private void createMathLessons(Subject math) {
        Lesson l1 = createLesson(math, "الأعداد من ١ إلى ٥", 1,
                "نتعلم اليوم الأعداد من واحد إلى خمسة. واحد ١، اثنان ٢، ثلاثة ٣، أربعة ٤، خمسة ٥. نعد الأشياء من حولنا.",
                "تعلم الأعداد من ١ إلى ٥ وعدها");
        createQuestion(l1, QuestionType.MCQ, "كم عدد أصابع يد واحدة؟",
                "٥", "[\"٣\",\"٤\",\"٥\",\"٦\"]", 1);
        createQuestion(l1, QuestionType.SHORT_ANSWER, "ما هو العدد الذي يأتي بعد ٣؟",
                "٤", null, 1);

        Lesson l2 = createLesson(math, "الأعداد من ٦ إلى ١٠", 2,
                "نكمل تعلم الأعداد: ستة ٦، سبعة ٧، ثمانية ٨، تسعة ٩، عشرة ١٠. نتعلم العد من واحد إلى عشرة.",
                "تعلم الأعداد من ٦ إلى ١٠");
        createQuestion(l2, QuestionType.MCQ, "ما هو العدد الذي يأتي بعد ٩؟",
                "١٠", "[\"٨\",\"١٠\",\"١١\",\"٧\"]", 1);
        createQuestion(l2, QuestionType.TRUE_FALSE, "العدد ٧ أكبر من العدد ٩",
                "خطأ", null, 1);
        createQuestion(l2, QuestionType.SHORT_ANSWER, "ما هو العدد الذي يأتي قبل ٨؟",
                "٧", null, 1);

        Lesson l3 = createLesson(math, "الجمع حتى ٥", 3,
                "نتعلم اليوم عملية الجمع. الجمع يعني أن نضيف أشياء مع بعضها. مثال: ٢ + ١ = ٣.",
                "تعلم عملية الجمع البسيطة");
        createQuestion(l3, QuestionType.MCQ, "كم يساوي ٢ + ٣ ؟",
                "٥", "[\"٣\",\"٤\",\"٥\",\"٦\"]", 1);
        createQuestion(l3, QuestionType.TRUE_FALSE, "١ + ٤ = ٥",
                "صح", null, 1);
        createQuestion(l3, QuestionType.SHORT_ANSWER, "كم يساوي ٢ + ١ ؟",
                "٣", null, 1);

        Lesson l4 = createLesson(math, "الطرح حتى ٥", 4,
                "الطرح يعني أن نأخذ أشياء. مثال: ٥ - ٢ = ٣.",
                "تعلم عملية الطرح البسيطة");
        createQuestion(l4, QuestionType.MCQ, "كم يساوي ٥ - ٢ ؟",
                "٣", "[\"١\",\"٢\",\"٣\",\"٤\"]", 1);
        createQuestion(l4, QuestionType.TRUE_FALSE, "٤ - ١ = ٣",
                "صح", null, 1);
        createQuestion(l4, QuestionType.SHORT_ANSWER, "كم يساوي ٣ - ١ ؟",
                "٢", null, 1);

        Lesson l5 = createLesson(math, "مراجعة الأعداد والجمع والطرح", 5,
                "في هذا الدرس نراجع كل ما تعلمناه: الأعداد من ١ إلى ١٠، عملية الجمع، وعملية الطرح.",
                "مراجعة شاملة للأعداد والعمليات");
        createQuestion(l5, QuestionType.MCQ, "كم يساوي ٣ + ٤ ؟",
                "٧", "[\"٥\",\"٦\",\"٧\",\"٨\"]", 1);
        createQuestion(l5, QuestionType.TRUE_FALSE, "١٠ - ٥ = ٥",
                "صح", null, 1);
        createQuestion(l5, QuestionType.SHORT_ANSWER, "ما هو أكبر عدد من رقم واحد؟",
                "٩", null, 1);
    }

    private void createIslamicLessons(Subject islamic) {
        Lesson l1 = createLesson(islamic, "بسم الله الرحمن الرحيم", 1,
                "نبدأ كل عمل بقول بسم الله الرحمن الرحيم. نقولها قبل الأكل وقبل الشرب وقبل القراءة.",
                "تعلم أهمية البسملة في حياتنا");
        createQuestion(l1, QuestionType.MCQ, "ماذا نقول قبل الأكل؟",
                "بسم الله", "[\"بسم الله\",\"الحمد لله\",\"سبحان الله\",\"الله أكبر\"]", 1);

        Lesson l2 = createLesson(islamic, "سورة الفاتحة", 2,
                "سورة الفاتحة هي أول سورة في القرآن الكريم. نقرأها في كل ركعة من الصلاة.",
                "حفظ وفهم سورة الفاتحة");
        createQuestion(l2, QuestionType.TRUE_FALSE, "سورة الفاتحة هي أول سورة في القرآن الكريم",
                "صح", null, 1);
        createQuestion(l2, QuestionType.MCQ, "متى نقرأ سورة الفاتحة؟",
                "في كل ركعة من الصلاة", "[\"قبل النوم فقط\",\"في كل ركعة من الصلاة\",\"يوم الجمعة فقط\",\"في رمضان فقط\"]", 1);
        createQuestion(l2, QuestionType.SHORT_ANSWER, "ما هي أول سورة في القرآن الكريم؟",
                "الفاتحة", null, 1);

        Lesson l3 = createLesson(islamic, "أركان الإسلام", 3,
                "أركان الإسلام خمسة: الشهادتان، الصلاة، الزكاة، صوم رمضان، حج البيت.",
                "تعلم أركان الإسلام الخمسة");
        createQuestion(l3, QuestionType.MCQ, "كم عدد أركان الإسلام؟",
                "خمسة", "[\"ثلاثة\",\"أربعة\",\"خمسة\",\"ستة\"]", 1);
        createQuestion(l3, QuestionType.TRUE_FALSE, "الصلاة من أركان الإسلام",
                "صح", null, 1);
        createQuestion(l3, QuestionType.SHORT_ANSWER, "اذكر ركناً من أركان الإسلام",
                "الصلاة", null, 1);

        Lesson l4 = createLesson(islamic, "آداب التحية والسلام", 4,
                "نتعلم كيف نلقي السلام على الآخرين. نقول: السلام عليكم ورحمة الله وبركاته.",
                "تعلم آداب التحية والسلام في الإسلام");
        createQuestion(l4, QuestionType.MCQ, "ماذا نقول عندما نلقى شخصاً؟",
                "السلام عليكم", "[\"مرحباً\",\"السلام عليكم\",\"صباح الخير\",\"أهلاً\"]", 1);
        createQuestion(l4, QuestionType.TRUE_FALSE, "نرد السلام بقول: وعليكم السلام",
                "صح", null, 1);
        createQuestion(l4, QuestionType.SHORT_ANSWER, "كيف نرد على من يقول السلام عليكم؟",
                "وعليكم السلام", null, 1);

        Lesson l5 = createLesson(islamic, "آداب الطعام والشراب", 5,
                "من آداب الطعام: نقول بسم الله قبل الأكل، نأكل باليد اليمنى، نقول الحمد لله بعد الأكل.",
                "تعلم آداب الطعام والشراب");
        createQuestion(l5, QuestionType.MCQ, "ماذا نقول قبل الأكل؟",
                "بسم الله", "[\"بسم الله\",\"الحمد لله\",\"سبحان الله\",\"الله أكبر\"]", 1);
        createQuestion(l5, QuestionType.TRUE_FALSE, "نأكل باليد اليمنى",
                "صح", null, 1);
        createQuestion(l5, QuestionType.SHORT_ANSWER, "ماذا نقول بعد الأكل؟",
                "الحمد لله", null, 1);
    }

    private void createEnglishLessons(Subject english) {
        Lesson l1 = createLesson(english, "Hello! - Unit 1", 1,
                "In this lesson we learn how to greet people. Hello! Hi! Good morning! My name is...",
                "Learn greetings and introductions in English");
        createQuestion(l1, QuestionType.MCQ, "How do you say 'مرحباً' in English?",
                "Hello", "[\"Hello\",\"Goodbye\",\"Thank you\",\"Please\"]", 1);
        createQuestion(l1, QuestionType.TRUE_FALSE, "We say 'Hello' when we meet someone",
                "صح", null, 1);
        createQuestion(l1, QuestionType.SHORT_ANSWER, "What do you say when you meet a friend?",
                "Hello", null, 1);

        Lesson l2 = createLesson(english, "My Family - Unit 2", 2,
                "Father, Mother, Brother, Sister. This is my family. I love my family.",
                "Learn family vocabulary in English");
        createQuestion(l2, QuestionType.MCQ, "What is 'أب' in English?",
                "Father", "[\"Mother\",\"Father\",\"Brother\",\"Sister\"]", 1);
        createQuestion(l2, QuestionType.TRUE_FALSE, "'Mother' means أم",
                "صح", null, 1);
        createQuestion(l2, QuestionType.SHORT_ANSWER, "What is 'أخ' in English?",
                "Brother", null, 1);

        Lesson l3 = createLesson(english, "My School - Unit 3", 3,
                "Book, Pen, Bag, Desk, Teacher, Classroom. I go to school every day.",
                "Learn school vocabulary in English");
        createQuestion(l3, QuestionType.MCQ, "What is 'كتاب' in English?",
                "Book", "[\"Pen\",\"Book\",\"Bag\",\"Desk\"]", 1);
        createQuestion(l3, QuestionType.TRUE_FALSE, "'Pen' means قلم",
                "صح", null, 1);
        createQuestion(l3, QuestionType.SHORT_ANSWER, "What is 'حقيبة' in English?",
                "Bag", null, 1);

        Lesson l4 = createLesson(english, "Colors - Unit 4", 4,
                "Red, Blue, Green, Yellow, Orange, Purple, Black, White. The sky is blue. The grass is green.",
                "Learn color names in English");
        createQuestion(l4, QuestionType.MCQ, "What color is the sky?",
                "Blue", "[\"Red\",\"Blue\",\"Green\",\"Yellow\"]", 1);
        createQuestion(l4, QuestionType.TRUE_FALSE, "'Red' means أحمر",
                "صح", null, 1);
        createQuestion(l4, QuestionType.SHORT_ANSWER, "What color is a banana?",
                "Yellow", null, 1);

        Lesson l5 = createLesson(english, "Numbers 1-10 - Unit 5", 5,
                "One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten. Let's count together!",
                "Learn numbers 1-10 in English");
        createQuestion(l5, QuestionType.MCQ, "How many fingers on one hand?",
                "Five", "[\"Three\",\"Four\",\"Five\",\"Six\"]", 1);
        createQuestion(l5, QuestionType.TRUE_FALSE, "'Three' means ثلاثة",
                "صح", null, 1);
        createQuestion(l5, QuestionType.SHORT_ANSWER, "What comes after 'two'?",
                "Three", null, 1);

        Lesson l6 = createLesson(english, "Animals - Unit 6", 6,
                "Cat, Dog, Bird, Fish, Cow, Horse. Animals are our friends. The cat says meow!",
                "Learn animal names in English");
        createQuestion(l6, QuestionType.MCQ, "What is 'قطة' in English?",
                "Cat", "[\"Dog\",\"Cat\",\"Bird\",\"Fish\"]", 1);
        createQuestion(l6, QuestionType.TRUE_FALSE, "'Dog' means كلب",
                "صح", null, 1);
        createQuestion(l6, QuestionType.SHORT_ANSWER, "What is 'طائر' in English?",
                "Bird", null, 1);

        Lesson l7 = createLesson(english, "Food - Unit 7", 7,
                "Apple, Banana, Bread, Milk, Water, Rice. I eat breakfast every morning.",
                "Learn food vocabulary in English");
        createQuestion(l7, QuestionType.MCQ, "What is 'تفاحة' in English?",
                "Apple", "[\"Banana\",\"Apple\",\"Orange\",\"Grape\"]", 1);
        createQuestion(l7, QuestionType.TRUE_FALSE, "'Milk' means حليب",
                "صح", null, 1);
        createQuestion(l7, QuestionType.SHORT_ANSWER, "What is 'خبز' in English?",
                "Bread", null, 1);

        Lesson l8 = createLesson(english, "My Body - Unit 8", 8,
                "Head, Hand, Foot, Eye, Ear, Nose, Mouth. I have two eyes and two ears.",
                "Learn body parts in English");
        createQuestion(l8, QuestionType.MCQ, "What is 'رأس' in English?",
                "Head", "[\"Hand\",\"Head\",\"Foot\",\"Eye\"]", 1);
        createQuestion(l8, QuestionType.TRUE_FALSE, "'Hand' means يد",
                "صح", null, 1);
        createQuestion(l8, QuestionType.SHORT_ANSWER, "What is 'عين' in English?",
                "Eye", null, 1);
    }

    private Lesson createLesson(Subject subject, String title, int order, String content, String objectives) {
        Lesson lesson = new Lesson();
        lesson.setSubject(subject);
        lesson.setTitle(title);
        lesson.setGradeLevel(subject.getGradeLevel());
        lesson.setOrderIndex(order);
        lesson.setContent(content);
        lesson.setObjectives(objectives);
        return lessonRepository.save(lesson);
    }

    private void createQuestion(Lesson lesson, QuestionType type, String text, String answer, String options, int difficulty) {
        Question q = new Question();
        q.setLesson(lesson);
        q.setType(type);
        q.setQuestionText(text);
        q.setCorrectAnswer(answer);
        q.setOptions(options);
        q.setDifficultyLevel(difficulty);
        questionRepository.save(q);
    }
}
