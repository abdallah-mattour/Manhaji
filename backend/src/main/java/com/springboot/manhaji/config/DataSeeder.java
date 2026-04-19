package com.springboot.manhaji.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.entity.Admin;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.Teacher;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.repository.AdminRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ParentRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.QuizRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.repository.TeacherRepository;
import com.springboot.manhaji.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.io.File;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final QuestionRepository questionRepository;
    private final QuizRepository quizRepository;
    private final ObjectMapper objectMapper;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final AdminRepository adminRepository;
    private final ParentRepository parentRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        // Always try to import/sync from curriculum JSON (skips existing lessons)
        boolean imported = importFromCurriculum();

        if (!imported && subjectRepository.count() == 0) {
            log.info("No curriculum JSON files found and database is empty, using hardcoded seed data");
            seedHardcodedData();
            ensureHardcodedSubjects();
        }

        // Always generate quizzes for lessons that have questions but no quiz
        seedQuizzes();

        // Seed demo teacher and admin accounts
        seedDemoAccounts();
    }

    private void seedDemoAccounts() {
        // Teacher account
        if (userRepository.findByEmail("teacher@manhaji.edu").isEmpty()) {
            Teacher teacher = new Teacher();
            teacher.setFullName("أحمد المعلم");
            teacher.setEmail("teacher@manhaji.edu");
            teacher.setPasswordHash(passwordEncoder.encode("teacher123"));
            teacher.setRole(Role.TEACHER);
            teacher.setIsActive(true);
            teacher.setDepartment("اللغة العربية");
            teacher.setAssignedGrade(1);
            teacherRepository.save(teacher);
            log.info("Created demo teacher account: teacher@manhaji.edu / teacher123");
        }

        // Admin account
        if (userRepository.findByEmail("admin@manhaji.edu").isEmpty()) {
            Admin admin = new Admin();
            admin.setFullName("مشرف النظام");
            admin.setEmail("admin@manhaji.edu");
            admin.setPasswordHash(passwordEncoder.encode("admin123"));
            admin.setRole(Role.ADMIN);
            admin.setIsActive(true);
            admin.setPermissions("ALL");
            adminRepository.save(admin);
            log.info("Created demo admin account: admin@manhaji.edu / admin123");
        }

        // Parent account — link to all existing students that have no parent
        if (userRepository.findByEmail("parent@manhaji.edu").isEmpty()) {
            com.springboot.manhaji.entity.Parent parent = new com.springboot.manhaji.entity.Parent();
            parent.setFullName("ولي أمر محمد");
            parent.setEmail("parent@manhaji.edu");
            parent.setPasswordHash(passwordEncoder.encode("parent123"));
            parent.setRole(Role.PARENT);
            parent.setIsActive(true);
            parent = parentRepository.save(parent);

            // Link unassigned students to this demo parent
            var students = studentRepository.findAll();
            for (var student : students) {
                if (student.getParent() == null) {
                    student.setParent(parent);
                    studentRepository.save(student);
                }
            }
            log.info("Created demo parent account: parent@manhaji.edu / parent123 (linked {} children)", students.size());
        }
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

    private void ensureSubjectWithLessons(String name, int gradeLevel,
                                           java.util.function.Consumer<Subject> lessonCreator) {
        Subject subject = subjectRepository.findByNameAndGradeLevel(name, gradeLevel)
                .orElseGet(() -> {
                    Subject s = new Subject();
                    s.setName(name);
                    s.setGradeLevel(gradeLevel);
                    log.info("Creating missing subject: {}", name);
                    return subjectRepository.save(s);
                });

        // Only create lessons if this subject has none
        List<Lesson> existing = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subject.getId());
        if (existing.isEmpty()) {
            log.info("Creating lessons for subject: {}", name);
            lessonCreator.accept(subject);
        } else {
            // Check if existing lessons are missing questions and add them
            supplementMissingQuestions(existing);
        }
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

                    // Build per-lesson image mapping once per file
                    Map<String, List<String>> lessonImageMap = buildLessonImageMap(
                            subjectCode, gradeLevel, semester, lessons);

                    int importedFromFile = 0;
                    List<Lesson> importedLessons = new ArrayList<>();
                    for (Map<String, Object> lessonData : lessons) {
                        String title = (String) lessonData.get("title");
                        if (existingTitles.contains(title)) continue;

                        List<String> mappedImages = lessonImageMap.getOrDefault(title, List.of());
                        Lesson lesson = importLesson(subject, lessonData, semester, mappedImages);
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
                    backfillLessonMetadata(existingLessons, semester, lessons, lessonImageMap);
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
                                 Integer semester, List<String> mappedImages) {
        Lesson lesson = new Lesson();
        lesson.setSubject(subject);
        lesson.setTitle((String) data.get("title"));
        lesson.setGradeLevel(subject.getGradeLevel());
        lesson.setOrderIndex((Integer) data.get("orderIndex"));
        lesson.setSemesterNumber(semester != null ? semester : 1);
        lesson.setContent((String) data.get("content"));
        lesson.setObjectives((String) data.get("objectives"));

        // Prefer JSON-provided imageUrls if present, else use auto-mapped images
        List<String> imageUrls = (List<String>) data.get("imageUrls");
        if (imageUrls == null || imageUrls.isEmpty()) {
            imageUrls = mappedImages;
        }
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
     * Build a mapping of lesson title -> list of image URLs by distributing
     * the page-numbered images in the subject/semester folder evenly across
     * the lessons in order. Returns an empty map if the folder doesn't exist.
     */
    private Map<String, List<String>> buildLessonImageMap(
            String subjectCode, int gradeLevel, Integer semester,
            List<Map<String, Object>> lessons) {
        Map<String, List<String>> result = new java.util.HashMap<>();
        if (subjectCode == null || lessons == null || lessons.isEmpty()) {
            return result;
        }

        String folderName = subjectCode + gradeLevel + "-p" + semester; // e.g. "ar1-p1"
        File folder = new File("./uploads/images/" + folderName);
        if (!folder.exists() || !folder.isDirectory()) {
            return result;
        }

        String[] fileNames = folder.list((dir, name) ->
                name.toLowerCase().matches("page\\d+_img\\d+\\.(png|jpe?g|webp)"));
        if (fileNames == null || fileNames.length == 0) {
            return result;
        }

        // Group files by page number, preserve natural order
        TreeMap<Integer, List<String>> pageGroups = new TreeMap<>();
        for (String name : fileNames) {
            try {
                int pageNum = Integer.parseInt(name.substring(4, name.indexOf('_')));
                pageGroups.computeIfAbsent(pageNum, k -> new ArrayList<>()).add(name);
            } catch (Exception e) {
                log.warn("Could not parse page number from image filename '{}': {}", name, e.getMessage());
            }
        }
        for (List<String> group : pageGroups.values()) {
            Collections.sort(group);
        }

        List<Integer> pageNumbers = new ArrayList<>(pageGroups.keySet());
        int totalPages = pageNumbers.size();
        int lessonCount = lessons.size();
        if (totalPages == 0 || lessonCount == 0) return result;

        // Distribute pages across lessons evenly
        double pagesPerLesson = (double) totalPages / lessonCount;
        for (int i = 0; i < lessonCount; i++) {
            Map<String, Object> lessonData = lessons.get(i);
            String title = (String) lessonData.get("title");
            if (title == null) continue;

            int startIdx = (int) Math.floor(i * pagesPerLesson);
            int endIdx = (i == lessonCount - 1)
                    ? totalPages
                    : (int) Math.floor((i + 1) * pagesPerLesson);
            if (endIdx <= startIdx) endIdx = Math.min(startIdx + 1, totalPages);

            List<String> urls = new ArrayList<>();
            for (int p = startIdx; p < endIdx; p++) {
                int pageNum = pageNumbers.get(p);
                for (String fileName : pageGroups.get(pageNum)) {
                    urls.add("/uploads/images/" + folderName + "/" + fileName);
                }
            }
            result.put(title, urls);
        }
        return result;
    }

    /**
     * Update existing lessons that may be missing semesterNumber or imageUrls
     * (e.g. from an earlier import before these fields were populated).
     */
    private void backfillLessonMetadata(List<Lesson> existingLessons, Integer semester,
                                         List<Map<String, Object>> jsonLessons,
                                         Map<String, List<String>> lessonImageMap) {
        if (existingLessons == null || existingLessons.isEmpty() || jsonLessons == null) return;
        java.util.Set<String> jsonTitles = new java.util.HashSet<>();
        for (Map<String, Object> ld : jsonLessons) {
            Object t = ld.get("title");
            if (t != null) jsonTitles.add(t.toString());
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
            if ((lesson.getImageUrls() == null || lesson.getImageUrls().isBlank()
                    || lesson.getImageUrls().equals("[]"))) {
                List<String> imgs = lessonImageMap.get(lesson.getTitle());
                if (imgs != null && !imgs.isEmpty()) {
                    try {
                        lesson.setImageUrls(objectMapper.writeValueAsString(imgs));
                        changed = true;
                    } catch (Exception e) {
                        log.warn("Failed to backfill imageUrls for lesson '{}': {}", lesson.getTitle(), e.getMessage());
                    }
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

        questionRepository.save(q);
    }

    // =================== Quiz Generation ===================

    private void seedQuizzes() {
        createQuizzesForAllLessons();
    }

    private void createQuizzesForAllLessons() {
        List<Lesson> allLessons = lessonRepository.findAll();
        int created = 0;
        for (Lesson lesson : allLessons) {
            // Skip if this lesson already has a quiz
            List<Quiz> existingQuizzes = quizRepository.findByLessonId(lesson.getId());
            if (!existingQuizzes.isEmpty()) continue;

            List<Question> questions = questionRepository.findByLessonIdOrderByIdAsc(lesson.getId());
            if (!questions.isEmpty()) {
                Quiz quiz = new Quiz();
                quiz.setTitle("اختبار: " + lesson.getTitle());
                quiz.setLesson(lesson);
                quiz.setGamified(true);
                quiz.setGeneratedFromLesson(true);
                quiz.setQuestions(questions);
                quizRepository.save(quiz);
                created++;
            }
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
