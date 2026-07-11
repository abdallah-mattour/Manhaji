package com.springboot.manhaji.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.AiConfigProperties;
import com.springboot.manhaji.config.QuizConfigProperties;
import com.springboot.manhaji.dto.request.SubmitAnswerRequest;
import com.springboot.manhaji.dto.request.TracingSubmitRequest;
import com.springboot.manhaji.dto.response.*;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.QuizType;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.ai.AiQuestionGenerationService;
import com.springboot.manhaji.service.ai.GeminiService;
import com.springboot.manhaji.service.ai.PronunciationScoringService;
import com.springboot.manhaji.service.ai.WhisperService;
import com.springboot.manhaji.infrastructure.Messages;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class QuizService {

    private final QuizRepository quizRepository;
    private final QuestionRepository questionRepository;
    private final AttemptRepository attemptRepository;
    private final StudentResponseRepository responseRepository;
    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final SubjectRepository subjectRepository;
    private final ObjectMapper objectMapper;
    private final GeminiService geminiService;
    private final WhisperService whisperService;
    private final PronunciationScoringService pronunciationScoringService;
    private final ReadingComparisonService readingComparisonService;
    private final QuizSelectionService quizSelectionService;
    private final SkillMasteryService skillMasteryService;
    private final AiQuestionGenerationService aiGenerationService;
    private final Messages messages;
    private final QuizConfigProperties quizConfig;
    private final AiConfigProperties aiConfig;

    // Get quiz for a lesson
    public QuizResponse getQuizByLesson(Long lessonId) {
        List<Quiz> quizzes = quizRepository.findByLessonId(lessonId);
        if (quizzes.isEmpty()) {
            throw new ResourceNotFoundException("Quiz", lessonId);
        }
        Quiz quiz = quizzes.get(0); // Get the first quiz for the lesson
        return buildQuizResponse(quiz);
    }

    /**
     * Tier A / A1 (2026-05-15): Practice Mode — returns the same lesson's
     * quiz but with questions reordered/picked by {@link QuizSelectionService}
     * based on the student's past performance. Closes the FR-6 / UC-3 gap.
     *
     * <p>Independent endpoint so the existing fixed-order
     * {@link #getQuizByLesson} is untouched (and its callers in tests / on
     * the Flutter standard quiz path keep their current behaviour).
     */
    public QuizResponse getAdaptiveQuizByLesson(Long lessonId, Long studentId) {
        List<Quiz> quizzes = quizRepository.findByLessonId(lessonId);
        if (quizzes.isEmpty()) {
            throw new ResourceNotFoundException("Quiz", lessonId);
        }
        Quiz quiz = quizzes.get(0);

        List<Question> chosen = quizSelectionService.selectAdaptive(
                studentId, lessonId, QuizSelectionService.DEFAULT_PRACTICE_SIZE);

        List<QuestionResponse> questionResponses = chosen.stream()
                .map(this::buildQuestionResponse)
                .toList();
        List<String> lessonImageUrls = parseImageUrls(quiz.getLesson().getImageUrls());

        return QuizResponse.builder()
                .id(quiz.getId())
                .title(quiz.getTitle() + " — تدريب")
                .gamified(true) // Practice Mode is always gamified per the proposal's UC-2.
                .totalQuestions(chosen.size())
                .questions(questionResponses)
                .lessonContent(quiz.getLesson().getContent())
                .lessonObjectives(quiz.getLesson().getObjectives())
                .lessonImageUrls(lessonImageUrls)
                .build();
    }

    /**
     * Personalized-quiz feature (2026-05-27): generate (or refresh) the
     * student's "Challenge Me" quiz for one subject. Questions are selected
     * across the subject's lessons by {@link QuizSelectionService#selectPersonalized}
     * using the persisted BKT mastery model — weakest sub-skills get the most
     * questions.
     *
     * <p>We keep ONE {@code PERSONALIZED} {@link Quiz} row per (student,
     * subject) and repopulate its {@code quiz_questions} on each call, so all
     * the existing attempt machinery ({@code startAttempt}, the submit paths,
     * {@code requireQuestionInAttemptQuiz}, {@code completeAttempt}) works
     * unchanged — every path still resolves a real Quiz with a populated
     * question set.
     *
     * @return the same {@link QuizResponse} shape {@link #getQuizByLesson}
     *         returns, so Flutter renders it with the existing quiz UI.
     */
    @Transactional
    public QuizResponse generatePersonalizedQuiz(Long subjectId, Long studentId) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ResourceNotFoundException("Subject", subjectId));
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        List<Question> chosen = quizSelectionService.selectPersonalized(
                studentId, subjectId, QuizSelectionService.DEFAULT_PRACTICE_SIZE);
        if (chosen.isEmpty()) {
            throw new ResourceNotFoundException("Subject questions", subjectId);
        }

        // Optionally blend a few runtime-generated AI questions aimed at the
        // weakest sub-skill. Total quiz size is preserved; any failure/timeout/
        // cold-start silently keeps the curriculum-only quiz.
        chosen = blendAiQuestions(chosen, subject, studentId);

        // Find-or-create the one personalized quiz row for this (student, subject).
        Quiz quiz = quizRepository
                .findByGeneratedForStudentIdAndSubjectIdAndQuizType(
                        studentId, subjectId, QuizType.PERSONALIZED)
                .orElseGet(Quiz::new);
        quiz.setTitle("تحدَّ نفسك — " + subject.getName());
        quiz.setGamified(true);
        quiz.setGeneratedFromLesson(false);
        quiz.setQuizType(QuizType.PERSONALIZED);
        quiz.setLesson(null);
        quiz.setSubject(subject);
        quiz.setGeneratedForStudentId(studentId);
        // Repopulate the question set (replace, don't append). Order matters
        // here — it's the adaptive/pedagogical arc from selectPersonalized, so
        // render it as-is instead of the default textbook-id sort.
        quiz.setQuestions(new ArrayList<>(chosen));
        quiz = quizRepository.save(quiz);

        return buildQuizResponse(quiz, true);
    }

    /**
     * Blend up to {@code count} runtime AI-generated questions (targeting the
     * child's weakest sub-skill) into the bank selection, preserving the total
     * quiz size (AI questions replace the lowest-ranked bank questions). At
     * least one bank question is always kept. Re-applies the pedagogical arc so
     * the AI (stretch-difficulty) items seat mid-quiz.
     *
     * <p><b>Fail-soft:</b> if the feature is off, Gemini is unavailable, the
     * student is at cold-start (no BKT signal), or generation returns nothing,
     * the original bank selection is returned unchanged — the child always gets
     * a full, valid quiz with no error and no hang.
     */
    private List<Question> blendAiQuestions(List<Question> bankChosen, Subject subject, Long studentId) {
        AiConfigProperties.GenerateQuestions cfg = aiConfig.getGenerateQuestions();
        if (!cfg.isEnabled() || !geminiService.isAvailable()) {
            return bankChosen;
        }
        int total = bankChosen.size();
        int aiWanted = Math.min(cfg.getCount(), Math.max(0, total - 1)); // keep ≥1 bank question
        if (aiWanted <= 0) {
            return bankChosen;
        }
        try {
            QuizSelectionService.WeakSkillTarget weak =
                    quizSelectionService.analyzeWeakestSkill(studentId, subject.getId());
            if (weak == null) {
                return bankChosen; // cold start — pure bank
            }
            Lesson ground = groundingLesson(subject.getId(), weak.subSkill());
            if (ground == null) {
                return bankChosen;
            }
            String language = isEnglishSubject(subject) ? "en" : "ar";
            List<Question> ai = aiGenerationService.generate(
                    ground, weak.subSkill(), weak.targetDifficulty(), aiWanted, language);
            if (ai.isEmpty()) {
                return bankChosen;
            }
            int keepBank = total - ai.size();
            List<Question> blended = new ArrayList<>(total);
            blended.addAll(bankChosen.subList(0, Math.max(0, keepBank)));
            blended.addAll(ai);
            return quizSelectionService.pedagogicalOrder(blended);
        } catch (Exception e) {
            log.warn("AI blend failed for student {} subject {} (non-fatal, bank-only): {}",
                    studentId, subject.getId(), e.getMessage());
            return bankChosen;
        }
    }

    /** A curriculum lesson in the subject that carries the given sub-skill (to ground generation). */
    private Lesson groundingLesson(Long subjectId, String subSkill) {
        for (Question q : questionRepository.findAllBySubjectIdWithLesson(subjectId)) {
            if (Boolean.TRUE.equals(q.getAiGenerated())) continue;
            if (q.getLesson() != null && subSkill.equals(QuizSelectionService.deriveSubSkill(q))) {
                return q.getLesson();
            }
        }
        return null;
    }

    private static boolean isEnglishSubject(Subject subject) {
        String name = subject.getName() == null ? "" : subject.getName();
        return name.toLowerCase().contains("english") || name.contains("الإنجليزية");
    }

    /**
     * Personalized-quiz feature (2026-05-27): per-subject skill-mastery
     * snapshot for the "My Skills" radar chart. Thin passthrough to
     * {@link SkillMasteryService} so the Flutter client has one quiz-namespaced
     * endpoint family.
     */
    public SkillMasteryResponse getSkillMastery(Long subjectId, Long studentId) {
        return skillMasteryService.getSkillScores(studentId, subjectId);
    }

    // Start a new attempt
    @Transactional
    public AttemptResponse startAttempt(Long quizId, Long studentId) {
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResourceNotFoundException("Quiz", quizId));
        if (isTeacherManagedQuiz(quiz)) {
            throw new BadRequestException("لا يمكن بدء هذا الاختبار من هذا المسار.");
        }

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        // Audit-4 fix H8 (2026-05-15): two near-simultaneous startAttempt calls
        // (e.g. an over-eager Flutter re-fetch on the home screen) could each
        // see "no IN_PROGRESS" and both insert a new row, double-counting
        // points on the eventual complete. Wrap in @Transactional and re-check
        // after the existence test; catch the constraint violation we expect
        // when a race winner exists and return its row instead. MySQL doesn't
        // support partial unique indexes natively so we can't push this into
        // the DB; the @Transactional + retry handles the demo-scale race.
        Optional<Attempt> inProgress = attemptRepository.findByStudentIdAndQuizIdAndStatus(
                studentId, quizId, AttemptStatus.IN_PROGRESS);
        if (inProgress.isPresent()) {
            return buildAttemptResponse(inProgress.get(), quiz);
        }

        // Create new attempt
        Attempt attempt = new Attempt();
        attempt.setStudent(student);
        attempt.setQuiz(quiz);
        attempt.setStatus(AttemptStatus.IN_PROGRESS);
        try {
            attempt = attemptRepository.save(attempt);
        } catch (org.springframework.dao.DataIntegrityViolationException race) {
            // Another concurrent request won. Reload the winner.
            log.warn("startAttempt race detected for student {} quiz {} — returning winning row",
                    studentId, quizId);
            attempt = attemptRepository.findByStudentIdAndQuizIdAndStatus(
                            studentId, quizId, AttemptStatus.IN_PROGRESS)
                    .orElseThrow(() -> race);
        }

        return AttemptResponse.builder()
                .attemptId(attempt.getId())
                .quizId(quizId)
                .status("IN_PROGRESS")
                .totalQuestions(quiz.getQuestions().size())
                .correctAnswers(0)
                .pointsEarned(0)
                .answers(new ArrayList<>())
                .build();
    }

    private boolean isTeacherManagedQuiz(Quiz quiz) {
        if (quiz.getCreatedByTeacher() != null) {
            return true;
        }
        if (quiz.getQuizType() == QuizType.TEACHER_ASSIGNED) {
            return true;
        }
        if (quiz.getStatus() != null) {
            return true;
        }
        if (quiz.getAssignments() != null && !quiz.getAssignments().isEmpty()) {
            return true;
        }
        return quiz.getGeneratedForStudentId() == null
                && quiz.getLesson() == null
                && quiz.getSubject() != null;
    }

    /**
     * Audit-4 fix C2 (2026-05-15): ensure {@code questionId} actually belongs
     * to the quiz the attempt is for. Previously the three submit-* paths
     * loaded any Question by ID — a malicious client could submit answers
     * for unrelated (easier) questions from another quiz and corrupt the
     * scoring aggregate. This helper centralises the check so every submit
     * path uses identical logic.
     *
     * <p>Uses a query against the M2M join table rather than walking
     * {@code attempt.getQuiz().getQuestions()} (which would lazily load
     * the full collection and add an N+1).
     */
    private Question requireQuestionInAttemptQuiz(Attempt attempt, Long questionId) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new ResourceNotFoundException("Question", questionId));
        Long quizId = attempt.getQuiz().getId();
        boolean belongs = quizRepository.findQuestionIdsByQuizId(quizId).contains(questionId);
        if (!belongs) {
            throw new BadRequestException(messages.get("error.attempt.questionNotInQuiz"));
        }
        return question;
    }

    // Submit an answer for one question
    @Transactional
    public SubmitAnswerResponse submitAnswer(Long attemptId, SubmitAnswerRequest request, Long studentId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new ResourceNotFoundException("Attempt", attemptId));

        if (!attempt.getStudent().getId().equals(studentId)) {
            throw new BadRequestException(messages.get("error.attempt.notYours"));
        }
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new BadRequestException(messages.get("error.attempt.alreadyCompleted"));
        }

        Question question = requireQuestionInAttemptQuiz(attempt, request.getQuestionId());

        // BUG-FIX (audit B2, 2026-04-29): the AI evaluation used to run twice —
        // once in evaluateAnswer() and once in generateFeedback() for the same
        // question. We now call Gemini at most once and pass the result down.
        Map<String, Object> aiResult = aiEvaluateIfShortAnswer(question, request);
        boolean isCorrect = evaluateAnswer(question, request, aiResult);
        String feedback = generateFeedback(question, request, isCorrect, aiResult);
        int pointsEarned = isCorrect ? quizConfig.getPointsPerCorrect() : 0;

        // Save student response
        StudentResponse response = new StudentResponse();
        response.setAttempt(attempt);
        response.setQuestion(question);
        response.setIsCorrect(isCorrect);
        response.setFeedback(feedback);
        response.setAudioRef(request.getAudioRef());

        if (question.getType() == QuestionType.SHORT_ANSWER) {
            response.setSpokenText(request.getSpokenText());
            response.setEvaluatedText(request.getAnswer());
        } else {
            response.setEvaluatedText(request.getAnswer());
        }

        responseRepository.save(response);

        return SubmitAnswerResponse.builder()
                .questionId(question.getId())
                .isCorrect(isCorrect)
                .feedback(feedback)
                .correctAnswer(question.getCorrectAnswer())
                .pointsEarned(pointsEarned)
                .build();
    }

    // Submit a pronunciation attempt: transcribe audio, score fuzzy match, persist response.
    @Transactional
    public PronunciationScoreResponse submitPronunciation(
            Long attemptId, Long questionId, byte[] audioBytes, String audioFilename,
            String language, Long studentId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new ResourceNotFoundException("Attempt", attemptId));

        if (!attempt.getStudent().getId().equals(studentId)) {
            throw new BadRequestException(messages.get("error.attempt.notYours"));
        }
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new BadRequestException(messages.get("error.attempt.alreadyCompleted"));
        }

        // Audit-4 fix C2 (2026-05-15): question must belong to this attempt's quiz.
        Question question = requireQuestionInAttemptQuiz(attempt, questionId);

        String expected = question.getCorrectAnswer();
        // Prefer language from client, but auto-detect from the expected answer
        // if the client didn't send one or sent the default "ar" for what is
        // clearly an English word (e.g. "Hello"). This keeps Flutter simple:
        // it can always pass "ar" and the backend will DTRT per question.
        String lang = (language != null && !language.isBlank())
                ? language
                : "ar";
        if ("ar".equals(lang) && !containsArabic(expected)) {
            lang = "en";
        }

        // Graceful fallback: if Gemini isn't configured (demo laptop without
        // GEMINI_API_KEY exported), don't 500 — hand back a friendly zero
        // score so the UI renders "lm asmaek jayedan" feedback and the
        // learner can retry. Nothing crashes; no StudentResponse persisted
        // since we didn't actually evaluate anything.
        if (!whisperService.isAvailable()) {
            log.warn("Pronunciation requested but Whisper/Gemini is not configured — returning fallback response");
            return PronunciationScoreResponse.builder()
                    .questionId(questionId)
                    .expectedText(expected)
                    .transcribedText("")
                    .score(0)
                    .rating(pronunciationScoringService.rating(0))
                    .feedback("خدمة النطق غير متاحة الآن. حاول لاحقاً.")
                    .isCorrect(false)
                    .pointsEarned(0)
                    .build();
        }

        // Feature B (2026-04-29): use the structured-JSON transcription path so
        // we can surface phoneme-level coaching to the child. Falls back gracefully
        // when Gemini returns plain text — `transcribed` is populated and the
        // phonemeErrors/guidance fields stay empty.
        com.springboot.manhaji.service.ai.PhonemeAnalysis analysis =
                whisperService.transcribeWithPhonemes(audioBytes, expected, lang,
                        WhisperService.audioMimeForFilename(audioFilename));
        String transcribed = analysis.transcribed();

        // Tier 4 (2026-07): READING passages score word-by-word (accuracy =
        // % of passage words found in the transcript) and return an ordered
        // per-word result list so the widget colors the passage in place.
        // Ordinary PRONUNCIATION keeps the whole-string phonetic score.
        int score;
        List<PronunciationScoreResponse.WordResult> wordResults = null;
        if (question.getType() == QuestionType.READING) {
            ReadingComparisonService.ComparisonResult cmp =
                    readingComparisonService.compare(expected, transcribed);
            score = cmp.accuracy();
            wordResults = cmp.wordResults();
        } else {
            score = pronunciationScoringService.score(expected, transcribed, lang);
        }
        String rating = pronunciationScoringService.rating(score);
        String feedback = pronunciationScoringService.feedback(score, expected);
        boolean isCorrect = pronunciationScoringService.isCorrect(score);
        int pointsEarned = isCorrect ? quizConfig.getPointsPerCorrect() : 0;

        StudentResponse response = new StudentResponse();
        response.setAttempt(attempt);
        response.setQuestion(question);
        response.setIsCorrect(isCorrect);
        response.setFeedback(feedback);
        response.setSpokenText(transcribed);
        response.setEvaluatedText(transcribed);
        responseRepository.save(response);

        return PronunciationScoreResponse.builder()
                .questionId(questionId)
                .expectedText(expected)
                .transcribedText(transcribed)
                .score(score)
                .rating(rating)
                .feedback(feedback)
                .isCorrect(isCorrect)
                .pointsEarned(pointsEarned)
                .phonemeErrors(analysis.phonemeErrors())
                .guidance(analysis.guidance())
                .wordResults(wordResults)
                .build();
    }

    // Submit a tracing attempt: tracing is scored client-side (CustomPainter heuristic),
    // so we trust the client-supplied score/isCorrect and persist a StudentResponse so
    // completeAttempt totals and teacher/parent dashboards reflect tracing activity.
    @Transactional
    public SubmitAnswerResponse submitTracingResult(
            Long attemptId, TracingSubmitRequest request, Long studentId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new ResourceNotFoundException("Attempt", attemptId));

        if (!attempt.getStudent().getId().equals(studentId)) {
            throw new BadRequestException(messages.get("error.attempt.notYours"));
        }
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new BadRequestException(messages.get("error.attempt.alreadyCompleted"));
        }

        // Audit-4 fix C2 (2026-05-15): question must belong to this attempt's quiz.
        Question question = requireQuestionInAttemptQuiz(attempt, request.getQuestionId());

        if (question.getType() != QuestionType.TRACING) {
            throw new BadRequestException("Question is not a tracing question");
        }

        // Audit-4 fix C3 (2026-05-15): tracing is scored client-side (no ML Kit
        // on the backend by design), but the previous code trusted any value
        // the client sent. Bound-check score/stars and clamp the booleans so a
        // modified client can't award itself unlimited points. If the values
        // are wildly out of range we refuse the submission outright.
        Integer rawScore = request.getScore();
        Integer rawStars = request.getStars();
        if (rawScore != null && (rawScore < 0 || rawScore > 100)) {
            throw new BadRequestException(messages.get("error.tracing.scoreOutOfRange"));
        }
        if (rawStars != null && (rawStars < 0 || rawStars > 3)) {
            throw new BadRequestException(messages.get("error.tracing.scoreOutOfRange"));
        }
        int safeScore = rawScore == null ? 0 : rawScore;
        int safeStars = rawStars == null ? 0 : rawStars;

        // Anchor correctness to the (server-validated) score, not the client's
        // boolean flag. ≥60 matches the pronunciation scoring threshold for
        // consistency across audio + handwriting paths.
        boolean isCorrect = safeScore >= 60;
        String feedback = request.getFeedback() != null ? request.getFeedback()
                : (isCorrect ? "أحسنت الكتابة!" : "استمر في التدريب");
        int pointsEarned = isCorrect ? quizConfig.getPointsPerCorrect() : 0;

        StudentResponse response = new StudentResponse();
        response.setAttempt(attempt);
        response.setQuestion(question);
        response.setIsCorrect(isCorrect);
        response.setFeedback(feedback);
        response.setEvaluatedText("score=" + safeScore + ",stars=" + safeStars);
        responseRepository.save(response);

        return SubmitAnswerResponse.builder()
                .questionId(question.getId())
                .isCorrect(isCorrect)
                .feedback(feedback)
                .correctAnswer(question.getCorrectAnswer())
                .pointsEarned(pointsEarned)
                .build();
    }

    // Complete the attempt and calculate final score
    @Transactional
    public AttemptResponse completeAttempt(Long attemptId, Long studentId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new ResourceNotFoundException("Attempt", attemptId));

        if (!attempt.getStudent().getId().equals(studentId)) {
            throw new BadRequestException(messages.get("error.attempt.notYours"));
        }
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new BadRequestException(messages.get("error.attempt.alreadyCompleted"));
        }

        Quiz quiz = attempt.getQuiz();
        List<StudentResponse> responses = responseRepository.findByAttemptId(attemptId);

        // Deduplicate: keep last response per question (handles retry submissions)
        LinkedHashMap<Long, StudentResponse> latestPerQuestion = new LinkedHashMap<>();
        for (StudentResponse r : responses) {
            latestPerQuestion.put(r.getQuestion().getId(), r);
        }
        Collection<StudentResponse> dedupedResponses = latestPerQuestion.values();

        // Calculate score from deduplicated responses
        int totalQuestions = quiz.getQuestions().size();
        int correctAnswers = (int) dedupedResponses.stream().filter(r -> Boolean.TRUE.equals(r.getIsCorrect())).count();
        double score = totalQuestions > 0 ? (correctAnswers * 100.0) / totalQuestions : 0;
        int pointsEarned = correctAnswers * quizConfig.getPointsPerCorrect();

        // Update attempt
        attempt.setStatus(AttemptStatus.GRADED);
        attempt.setScore(score);
        attempt.setSubmittedAt(LocalDateTime.now());
        attemptRepository.save(attempt);

        // Award points to student
        Student student = attempt.getStudent();
        student.setTotalPoints(student.getTotalPoints() + pointsEarned);
        studentRepository.save(student);

        // Update lesson progress. PERSONALIZED quizzes span a subject (no
        // single lesson), so skip per-lesson progress for them — their signal
        // is captured by the per-skill BKT update below instead.
        if (quiz.getLesson() != null) {
            updateLessonProgress(student, quiz.getLesson(), score);
        }

        // Knowledge Tracing: fold this attempt's graded answers into the
        // student's per-sub-skill mastery (BKT). Wrapped so an analytics
        // failure can never break scoring / point-award above. Uses the
        // deduped set (a retried question counts once) in insertion order
        // (= answer order, the documented ordering since StudentResponse has
        // no answered-at timestamp).
        try {
            skillMasteryService.recordResponses(
                    student.getId(), new ArrayList<>(dedupedResponses));
        } catch (Exception e) {
            log.warn("BKT mastery update failed for attempt {} (non-fatal): {}",
                    attemptId, e.getMessage());
        }

        // Build answer feedback list (deduplicated)
        List<AnswerFeedback> feedbacks = dedupedResponses.stream().map(r -> AnswerFeedback.builder()
                .questionId(r.getQuestion().getId())
                .questionText(r.getQuestion().getQuestionText())
                .studentAnswer(r.getEvaluatedText())
                .correctAnswer(r.getQuestion().getCorrectAnswer())
                .isCorrect(Boolean.TRUE.equals(r.getIsCorrect()))
                .feedback(r.getFeedback())
                .build()
        ).toList();

        return AttemptResponse.builder()
                .attemptId(attemptId)
                .quizId(quiz.getId())
                .status("GRADED")
                .score(score)
                .totalQuestions(totalQuestions)
                .correctAnswers(correctAnswers)
                .pointsEarned(pointsEarned)
                .submittedAt(attempt.getSubmittedAt())
                .answers(feedbacks)
                .build();
    }

    /**
     * Get a hint for a question. Post-review fix (2026-05-24): the previous
     * version looked up any question by ID — a logged-in student could enumerate
     * `/api/quiz/question/{id}/hint` for any of the 1,150+ Grade 1+2 questions
     * and burn Gemini quota with no relationship to a real quiz session. Now
     * the question must belong to a quiz the student has an IN_PROGRESS attempt
     * for. Mirrors the {@link #requireQuestionInAttemptQuiz} pattern.
     */
    public Map<String, Object> getHint(Long questionId, int level, Long studentId) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new ResourceNotFoundException("Question", questionId));

        requireQuestionInActiveAttempt(studentId, questionId);

        int maxLevel = quizConfig.getMaxHintLevel();
        level = Math.max(1, Math.min(maxLevel, level)); // Clamp 1..maxLevel
        String hint = geminiService.generateHint(
                question.getQuestionText(), question.getCorrectAnswer(), level, "ar");

        return Map.of(
                "hint", hint,
                "hintLevel", level,
                "remainingHints", maxLevel - level
        );
    }

    private void requireQuestionInActiveAttempt(Long studentId, Long questionId) {
        List<Attempt> active = attemptRepository.findByStudentIdAndStatus(
                studentId, AttemptStatus.IN_PROGRESS);
        for (Attempt a : active) {
            if (quizRepository.findQuestionIdsByQuizId(a.getQuiz().getId()).contains(questionId)) {
                return;
            }
        }
        throw new BadRequestException(messages.get("error.attempt.questionNotInQuiz"));
    }

    // --- Helper methods ---

    /**
     * For SHORT_ANSWER questions, run a single Gemini evaluation up front so the
     * result can be reused by both {@link #evaluateAnswer} and
     * {@link #generateFeedback}. Returns null when the type isn't SHORT_ANSWER,
     * Gemini isn't available, or the call failed — callers must handle null.
     *
     * <p>Audit fix B2 (2026-04-29): previously the Gemini call ran twice per
     * submission for the same input.
     */
    private Map<String, Object> aiEvaluateIfShortAnswer(Question question, SubmitAnswerRequest request) {
        if (question.getType() != QuestionType.SHORT_ANSWER) return null;
        if (!geminiService.isAvailable()) return null;
        String studentAnswer = (request.getAnswer() != null ? request.getAnswer() :
                                request.getSpokenText() != null ? request.getSpokenText() : "").trim();
        try {
            return geminiService.evaluateShortAnswer(
                    question.getQuestionText(), question.getCorrectAnswer().trim(), studentAnswer, "ar");
        } catch (Exception e) {
            log.warn("Gemini evaluation failed, falling back to string matching: {}", e.getMessage());
            return null;
        }
    }

    private boolean evaluateAnswer(Question question, SubmitAnswerRequest request,
                                    Map<String, Object> aiResult) {
        String correctAnswer = question.getCorrectAnswer().trim();
        String studentAnswer = (request.getAnswer() != null ? request.getAnswer() :
                               request.getSpokenText() != null ? request.getSpokenText() : "").trim();

        // TRUE_FALSE: compare canonically so the two languages are
        // interchangeable — "صح"≡"True", "خطأ"≡"False". English-subject
        // questions store True/False, Arabic-script subjects store صح/خطأ,
        // and the Flutter widget submits whichever matches the question's
        // language; this normalization makes scoring robust even if the
        // stored answer and the submitted value ever drift in language.
        if (question.getType() == QuestionType.TRUE_FALSE) {
            String c = canonicalTrueFalse(correctAnswer);
            String s = canonicalTrueFalse(studentAnswer);
            // If either side isn't a recognized TF token, fall back to a
            // literal compare (don't silently pass on garbage).
            if (c.isEmpty() || s.isEmpty()) {
                return correctAnswer.equalsIgnoreCase(studentAnswer);
            }
            return c.equals(s);
        }

        // MCQ + Tier-1 image/listen variants all score by exact match of the
        // chosen option against the correct answer (the picture is just a
        // presentation layer over the same option text).
        if (question.getType() == QuestionType.MCQ
                || question.getType() == QuestionType.IMAGE_MCQ
                || question.getType() == QuestionType.LISTEN_CHOOSE) {
            return correctAnswer.equalsIgnoreCase(studentAnswer);
        }

        // IMAGE_MATCH: the student submits the pairing as "left=right,left=right".
        // Correct iff the submitted mapping equals the correct mapping (order-
        // independent). The correct mapping lives in question.correctAnswer in
        // the same "left=right,..." form so scoring needs no extra parsing of
        // pairsJson.
        // DRAG_DROP (Tier 2) submits "target=token,..." — same format, same rule.
        if (question.getType() == QuestionType.IMAGE_MATCH
                || question.getType() == QuestionType.DRAG_DROP) {
            return matchPairsEqual(correctAnswer, studentAnswer);
        }

        // FILL_BLANK: same as short answer — normalize and compare
        // ORDERING: compare the ordered sequence as a string
        if (question.getType() == QuestionType.FILL_BLANK || question.getType() == QuestionType.ORDERING) {
            String normalizedCorrect = normalizeArabic(correctAnswer);
            String normalizedStudent = normalizeArabic(studentAnswer);
            if (normalizedCorrect.equals(normalizedStudent)) return true;
            if (normalizedStudent.contains(normalizedCorrect) ||
                normalizedCorrect.contains(normalizedStudent)) return true;
            return false;
        }

        // SHORT_ANSWER: prefer the AI result (computed once in submitAnswer); fall back to string matching
        if (question.getType() == QuestionType.SHORT_ANSWER) {
            if (aiResult != null && aiResult.get("isCorrect") instanceof Boolean isCorrectResult) {
                return isCorrectResult;
            }

            // Fallback: normalize Arabic text and compare
            String normalizedCorrect = normalizeArabic(correctAnswer);
            String normalizedStudent = normalizeArabic(studentAnswer);

            if (normalizedCorrect.equals(normalizedStudent)) return true;
            if (normalizedStudent.contains(normalizedCorrect) ||
                normalizedCorrect.contains(normalizedStudent)) return true;
        }

        return false;
    }

    /**
     * Maps a TRUE_FALSE answer (in either language) to a canonical token so
     * the two languages compare equal: صح/صحيح/true/yes/نعم → "TRUE",
     * خطأ/خطا/false/no/لا → "FALSE". Returns "" for anything unrecognized so
     * the caller can fall back to a literal compare.
     */
    private static String canonicalTrueFalse(String s) {
        if (s == null) return "";
        String t = s.trim().toLowerCase();
        switch (t) {
            case "صح":
            case "صحيح":
            case "true":
            case "نعم":
                return "TRUE";
            case "خطأ":
            case "خطا":
            case "false":
            case "لا":
                return "FALSE";
            default:
                return "";
        }
    }

    /**
     * IMAGE_MATCH equality: both the correct and submitted answers are
     * "left=right,left=right" strings. Returns true iff they describe the same
     * set of pairs, independent of order and surrounding whitespace.
     */
    private static boolean matchPairsEqual(String correct, String student) {
        java.util.Set<String> c = parsePairSet(correct);
        java.util.Set<String> s = parsePairSet(student);
        return !c.isEmpty() && c.equals(s);
    }

    private static java.util.Set<String> parsePairSet(String s) {
        java.util.Set<String> out = new java.util.HashSet<>();
        if (s == null || s.isBlank()) return out;
        for (String pair : s.split(",")) {
            String p = pair.trim();
            if (!p.isEmpty()) out.add(p.replaceAll("\\s+", ""));
        }
        return out;
    }

    private String normalizeArabic(String text) {
        if (text == null) return "";
        // BUG-FIX (audit B1, 2026-04-29):
        // The replacement strings used to be doubly-escaped backslash-u-NNNN
        // forms, which java.lang.String.replaceAll does NOT interpret as Unicode
        // escapes — the inserted bytes were 6 ASCII chars, not the Arabic letter.
        // The fix is to put the actual character directly in the source string.
        // Cf. PronunciationScoringService.normalizeArabic() which uses the
        // correct pattern via String.replace(char, char).
        return text
                .replaceAll("[\\u064B-\\u065F\\u0670]", "")  // Strip Arabic diacritics
                .replaceAll("[آأإ]", "ا") // أ/إ/آ → ا
                .replace('ة', 'ه')                  // ة → ه (use char-replace to avoid regex pitfalls)
                .replaceAll("\\s+", " ")
                .trim()
                .toLowerCase();
    }

    private String generateFeedback(Question question, SubmitAnswerRequest request, boolean isCorrect,
                                     Map<String, Object> aiResult) {
        // SHORT_ANSWER: prefer the feedback from the single AI evaluation
        // computed in submitAnswer(). Audit fix B2 (2026-04-29).
        if (question.getType() == QuestionType.SHORT_ANSWER
                && aiResult != null && aiResult.get("feedback") != null) {
            return (String) aiResult.get("feedback");
        }

        // Fallback static feedback
        if (isCorrect) {
            return "أحسنت! إجابة صحيحة 🌟";
        }
        return "إجابة خاطئة. الإجابة الصحيحة هي: " + question.getCorrectAnswer();
    }

    private void updateLessonProgress(Student student, Lesson lesson, double score) {
        Optional<Progress> existing = progressRepository.findByStudentIdAndLessonId(
                student.getId(), lesson.getId());

        Progress progress;
        if (existing.isPresent()) {
            progress = existing.get();
        } else {
            progress = new Progress();
            progress.setStudent(student);
            progress.setLesson(lesson);
        }

        progress.setMasteryLevel(score);
        progress.setLastAccessedAt(LocalDateTime.now());

        if (score >= quizConfig.getMasteryThreshold()) {
            progress.setCompletionStatus(CompletionStatus.MASTERED);
            progress.setCompletedAt(LocalDateTime.now());
        } else if (score >= quizConfig.getCompletionThreshold()) {
            progress.setCompletionStatus(CompletionStatus.COMPLETED);
            progress.setCompletedAt(LocalDateTime.now());
        } else {
            progress.setCompletionStatus(CompletionStatus.IN_PROGRESS);
        }

        progressRepository.save(progress);
    }

    /** Interactive types added after the original seed (tiers 1/2/4). */
    private static final java.util.Set<QuestionType> MEDIA_TYPES = java.util.Set.of(
            QuestionType.IMAGE_MCQ, QuestionType.LISTEN_CHOOSE,
            QuestionType.IMAGE_MATCH, QuestionType.DRAG_DROP, QuestionType.READING);

    private QuizResponse buildQuizResponse(Quiz quiz) {
        return buildQuizResponse(quiz, false);
    }

    /**
     * @param preserveQuestionOrder when {@code true}, render questions in the
     *        exact order they sit in {@code quiz.getQuestions()} — used by the
     *        PERSONALIZED "Challenge Me" quiz, whose order is a deliberate
     *        adaptive/pedagogical arc from {@code QuizSelectionService} that the
     *        default id-sort would otherwise throw away. LESSON quizzes pass
     *        {@code false} and keep the textbook-id ordering + media interleave.
     */
    private QuizResponse buildQuizResponse(Quiz quiz, boolean preserveQuestionOrder) {
        List<Question> ordered;
        if (preserveQuestionOrder) {
            ordered = new ArrayList<>(quiz.getQuestions());
        } else {
            // Base order: by ID (insertion/textbook order). The media types were
            // backfilled later, so their ids are the highest — a plain id sort
            // clumps ALL of them at the very end of the quiz where a student
            // rarely arrives. Interleave instead (2026-07-04): one media question
            // after every two classic ones. Deterministic, so the quiz order is
            // stable across requests.
            List<Question> sorted = quiz.getQuestions().stream()
                    .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                    .toList();
            List<Question> classic = new ArrayList<>();
            List<Question> media = new ArrayList<>();
            for (Question question : sorted) {
                (MEDIA_TYPES.contains(question.getType()) ? media : classic).add(question);
            }
            List<Question> mixed = new ArrayList<>(sorted.size());
            int mediaIdx = 0;
            for (int i = 0; i < classic.size(); i++) {
                mixed.add(classic.get(i));
                if (i % 2 == 1 && mediaIdx < media.size()) {
                    mixed.add(media.get(mediaIdx++));
                }
            }
            while (mediaIdx < media.size()) {
                mixed.add(media.get(mediaIdx++));
            }
            ordered = mixed;
        }

        List<QuestionResponse> questionResponses = ordered.stream()
                .map(this::buildQuestionResponse)
                .toList();

        // PERSONALIZED quizzes have no lesson (they span a subject), so the
        // lesson-derived fields are empty for them. LESSON quizzes read them
        // from their lesson as before.
        Lesson lesson = quiz.getLesson();
        List<String> lessonImageUrls = lesson != null
                ? parseImageUrls(lesson.getImageUrls())
                : Collections.emptyList();

        return QuizResponse.builder()
                .id(quiz.getId())
                .title(quiz.getTitle())
                .gamified(quiz.getGamified())
                .totalQuestions(quiz.getQuestions().size())
                .questions(questionResponses)
                .lessonContent(lesson != null ? lesson.getContent() : null)
                .lessonObjectives(lesson != null ? lesson.getObjectives() : null)
                .lessonImageUrls(lessonImageUrls)
                .build();
    }

    private List<String> parseImageUrls(String imageUrlsJson) {
        if (imageUrlsJson == null || imageUrlsJson.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(imageUrlsJson, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private QuestionResponse buildQuestionResponse(Question question) {
        List<String> options = null;
        if (question.getOptions() != null && !question.getOptions().isEmpty()) {
            try {
                options = objectMapper.readValue(question.getOptions(), new TypeReference<List<String>>() {});
            } catch (Exception e) {
                options = List.of();
            }
        }

        // For TRUE_FALSE, provide the options
        if (question.getType() == QuestionType.TRUE_FALSE && options == null) {
            options = List.of("صح", "خطأ");
        }

        // For ORDERING, provide the items to be ordered
        // options already contains the items from JSON

        // Tier 1: parse the parallel option-images array (IMAGE_MCQ / LISTEN_CHOOSE)
        // and the image-match pairs object, if present.
        List<String> optionImages = null;
        if (question.getOptionImages() != null && !question.getOptionImages().isEmpty()) {
            try {
                optionImages = objectMapper.readValue(
                        question.getOptionImages(), new TypeReference<List<String>>() {});
            } catch (Exception e) {
                optionImages = null;
            }
        }
        Object pairs = null;
        if (question.getPairsJson() != null && !question.getPairsJson().isEmpty()) {
            try {
                pairs = objectMapper.readValue(question.getPairsJson(), Object.class);
            } catch (Exception e) {
                pairs = null;
            }
        }

        return QuestionResponse.builder()
                .id(question.getId())
                .type(question.getType().name())
                .questionText(question.getQuestionText())
                .options(options)
                .difficultyLevel(question.getDifficultyLevel())
                .subSkill(question.getSubSkill())
                .imageUrl(question.getImageUrl())
                .audioUrl(question.getAudioUrl())
                .optionImages(optionImages)
                .pairsJson(pairs)
                .build();
    }

    private AttemptResponse buildAttemptResponse(Attempt attempt, Quiz quiz) {
        List<StudentResponse> responses = responseRepository.findByAttemptId(attempt.getId());
        int correctAnswers = (int) responses.stream()
                .filter(r -> Boolean.TRUE.equals(r.getIsCorrect())).count();

        return AttemptResponse.builder()
                .attemptId(attempt.getId())
                .quizId(quiz.getId())
                .status(attempt.getStatus().name())
                .score(attempt.getScore())
                .totalQuestions(quiz.getQuestions().size())
                .correctAnswers(correctAnswers)
                .pointsEarned(correctAnswers * quizConfig.getPointsPerCorrect())
                .submittedAt(attempt.getSubmittedAt())
                .build();
    }

    /** Arabic unicode block U+0600..U+06FF. */
    private boolean containsArabic(String text) {
        if (text == null) return false;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c >= 0x0600 && c <= 0x06FF) return true;
        }
        return false;
    }
}
