package com.springboot.manhaji.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.dto.request.SubmitAnswerRequest;
import com.springboot.manhaji.dto.response.*;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.ai.GeminiService;
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
public class QuizService {

    private final QuizRepository quizRepository;
    private final QuestionRepository questionRepository;
    private final AttemptRepository attemptRepository;
    private final StudentResponseRepository responseRepository;
    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final ObjectMapper objectMapper;
    private final GeminiService geminiService;

    private static final int POINTS_PER_CORRECT = 10;

    // Get quiz for a lesson
    public QuizResponse getQuizByLesson(Long lessonId) {
        List<Quiz> quizzes = quizRepository.findByLessonId(lessonId);
        if (quizzes.isEmpty()) {
            throw new ResourceNotFoundException("Quiz", lessonId);
        }
        Quiz quiz = quizzes.get(0); // Get the first quiz for the lesson
        return buildQuizResponse(quiz);
    }

    // Start a new attempt
    @Transactional
    public AttemptResponse startAttempt(Long quizId, Long studentId) {
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResourceNotFoundException("Quiz", quizId));

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        // Check for existing IN_PROGRESS attempt
        Optional<Attempt> inProgress = attemptRepository.findByStudentIdAndQuizIdAndStatus(
                studentId, quizId, AttemptStatus.IN_PROGRESS);
        if (inProgress.isPresent()) {
            // Return existing in-progress attempt
            return buildAttemptResponse(inProgress.get(), quiz);
        }

        // Create new attempt
        Attempt attempt = new Attempt();
        attempt.setStudent(student);
        attempt.setQuiz(quiz);
        attempt.setStatus(AttemptStatus.IN_PROGRESS);
        attempt = attemptRepository.save(attempt);

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

    // Submit an answer for one question
    @Transactional
    public SubmitAnswerResponse submitAnswer(Long attemptId, SubmitAnswerRequest request, Long studentId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new ResourceNotFoundException("Attempt", attemptId));

        if (!attempt.getStudent().getId().equals(studentId)) {
            throw new BadRequestException("هذه المحاولة لا تخصك");
        }
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new BadRequestException("هذه المحاولة مكتملة بالفعل");
        }

        Question question = questionRepository.findById(request.getQuestionId())
                .orElseThrow(() -> new ResourceNotFoundException("Question", request.getQuestionId()));

        // Evaluate the answer
        boolean isCorrect = evaluateAnswer(question, request);
        String feedback = generateFeedback(question, request, isCorrect);
        int pointsEarned = isCorrect ? POINTS_PER_CORRECT : 0;

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

    // Complete the attempt and calculate final score
    @Transactional
    public AttemptResponse completeAttempt(Long attemptId, Long studentId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new ResourceNotFoundException("Attempt", attemptId));

        if (!attempt.getStudent().getId().equals(studentId)) {
            throw new BadRequestException("هذه المحاولة لا تخصك");
        }
        if (attempt.getStatus() != AttemptStatus.IN_PROGRESS) {
            throw new BadRequestException("هذه المحاولة مكتملة بالفعل");
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
        int pointsEarned = correctAnswers * POINTS_PER_CORRECT;

        // Update attempt
        attempt.setStatus(AttemptStatus.GRADED);
        attempt.setScore(score);
        attempt.setSubmittedAt(LocalDateTime.now());
        attemptRepository.save(attempt);

        // Award points to student
        Student student = attempt.getStudent();
        student.setTotalPoints(student.getTotalPoints() + pointsEarned);
        studentRepository.save(student);

        // Update lesson progress
        updateLessonProgress(student, quiz.getLesson(), score);

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

    // Get hint for a question
    public Map<String, Object> getHint(Long questionId, int level) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new ResourceNotFoundException("Question", questionId));

        level = Math.max(1, Math.min(3, level)); // Clamp 1-3
        String hint = geminiService.generateHint(
                question.getQuestionText(), question.getCorrectAnswer(), level, "ar");

        return Map.of(
                "hint", hint,
                "hintLevel", level,
                "remainingHints", 3 - level
        );
    }

    // --- Helper methods ---

    private boolean evaluateAnswer(Question question, SubmitAnswerRequest request) {
        String correctAnswer = question.getCorrectAnswer().trim();
        String studentAnswer = (request.getAnswer() != null ? request.getAnswer() :
                               request.getSpokenText() != null ? request.getSpokenText() : "").trim();

        if (question.getType() == QuestionType.MCQ || question.getType() == QuestionType.TRUE_FALSE) {
            return correctAnswer.equalsIgnoreCase(studentAnswer);
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

        // SHORT_ANSWER: try Gemini AI evaluation first, fall back to string matching
        if (question.getType() == QuestionType.SHORT_ANSWER) {
            if (geminiService.isAvailable()) {
                try {
                    var result = geminiService.evaluateShortAnswer(
                            question.getQuestionText(), correctAnswer, studentAnswer, "ar");
                    if (result != null && result.get("isCorrect") instanceof Boolean isCorrectResult) {
                        return isCorrectResult;
                    }
                } catch (Exception e) {
                    log.warn("Gemini evaluation failed, falling back to string matching: {}", e.getMessage());
                }
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

    private String normalizeArabic(String text) {
        if (text == null) return "";
        return text
                .replaceAll("[\\u064B-\\u065F\\u0670]", "") // Remove Arabic diacritics
                .replaceAll("[\\u0622\\u0623\\u0625]", "\\u0627") // Normalize alef variants to alef
                .replaceAll("\\u0629", "\\u0647") // Normalize taa marbouta to ha
                .replaceAll("\\s+", " ")
                .trim()
                .toLowerCase();
    }

    private String generateFeedback(Question question, SubmitAnswerRequest request, boolean isCorrect) {
        // For SHORT_ANSWER with Gemini available, get AI-generated feedback
        if (question.getType() == QuestionType.SHORT_ANSWER && geminiService.isAvailable()) {
            try {
                String studentAnswer = request.getAnswer() != null ? request.getAnswer() :
                        request.getSpokenText() != null ? request.getSpokenText() : "";
                var result = geminiService.evaluateShortAnswer(
                        question.getQuestionText(), question.getCorrectAnswer(), studentAnswer, "ar");
                if (result != null && result.get("feedback") != null) {
                    return (String) result.get("feedback");
                }
            } catch (Exception e) {
                log.warn("Gemini feedback generation failed: {}", e.getMessage());
            }
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

        if (score >= 80) {
            progress.setCompletionStatus(CompletionStatus.MASTERED);
            progress.setCompletedAt(LocalDateTime.now());
        } else if (score >= 50) {
            progress.setCompletionStatus(CompletionStatus.COMPLETED);
            progress.setCompletedAt(LocalDateTime.now());
        } else {
            progress.setCompletionStatus(CompletionStatus.IN_PROGRESS);
        }

        progressRepository.save(progress);
    }

    private QuizResponse buildQuizResponse(Quiz quiz) {
        // Sort questions by ID to preserve insertion (textbook) order
        List<QuestionResponse> questionResponses = quiz.getQuestions().stream()
                .sorted((a, b) -> Long.compare(a.getId(), b.getId()))
                .map(this::buildQuestionResponse)
                .toList();

        List<String> lessonImageUrls = parseImageUrls(quiz.getLesson().getImageUrls());

        return QuizResponse.builder()
                .id(quiz.getId())
                .title(quiz.getTitle())
                .gamified(quiz.getGamified())
                .totalQuestions(quiz.getQuestions().size())
                .questions(questionResponses)
                .lessonContent(quiz.getLesson().getContent())
                .lessonObjectives(quiz.getLesson().getObjectives())
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

        return QuestionResponse.builder()
                .id(question.getId())
                .type(question.getType().name())
                .questionText(question.getQuestionText())
                .options(options)
                .difficultyLevel(question.getDifficultyLevel())
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
                .pointsEarned(correctAnswers * POINTS_PER_CORRECT)
                .submittedAt(attempt.getSubmittedAt())
                .build();
    }
}
