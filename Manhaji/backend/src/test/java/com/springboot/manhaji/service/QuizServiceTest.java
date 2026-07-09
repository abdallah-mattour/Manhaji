package com.springboot.manhaji.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.config.QuizConfigProperties;
import com.springboot.manhaji.dto.request.SubmitAnswerRequest;
import com.springboot.manhaji.dto.request.TracingSubmitRequest;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.QuizResponse;
import com.springboot.manhaji.dto.response.SubmitAnswerResponse;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.entity.enums.QuizStatus;
import com.springboot.manhaji.entity.enums.QuizType;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.ai.GeminiService;
import com.springboot.manhaji.service.ai.PronunciationScoringService;
import com.springboot.manhaji.service.ai.WhisperService;
import com.springboot.manhaji.infrastructure.TestMessages;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class QuizServiceTest {

    @Mock private QuizRepository quizRepository;
    @Mock private QuestionRepository questionRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private StudentResponseRepository responseRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private ProgressRepository progressRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private GeminiService geminiService;
    @Mock private WhisperService whisperService;
    @Mock private PronunciationScoringService pronunciationScoringService;
    @Mock private com.springboot.manhaji.service.QuizSelectionService quizSelectionService;
    @Mock private com.springboot.manhaji.service.SkillMasteryService skillMasteryService;
    @Spy  private ObjectMapper objectMapper = new ObjectMapper();

    private QuizService quizService;

    private Student testStudent;
    private Quiz testQuiz;
    private Lesson testLesson;
    private Subject testSubject;

    @BeforeEach
    void setUp() {
        // Tier 4: ReadingComparisonService is pure string logic with no
        // dependencies — pass a real instance instead of a mock so READING
        // submissions exercise the actual word matcher.
        quizService = new QuizService(
                quizRepository, questionRepository, attemptRepository, responseRepository,
                studentRepository, progressRepository, subjectRepository, objectMapper,
                geminiService, whisperService, pronunciationScoringService,
                new ReadingComparisonService(),
                quizSelectionService, skillMasteryService,
                TestMessages.create(), new QuizConfigProperties());

        // Audit-4 fix C2 (2026-05-15): every submit-* path now verifies that
        // the question belongs to the attempt's quiz. Default the mock to
        // return all question IDs used in this test class so existing tests
        // don't have to be touched individually. The dedicated C2 regression
        // test overrides this mock with a narrower list to assert rejection.
        org.mockito.Mockito.lenient()
                .when(quizRepository.findQuestionIdsByQuizId(any()))
                .thenReturn(List.of(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 12L, 13L, 14L, 15L,
                        77L, 78L, 79L, 99L));

        testSubject = new Subject();
        testSubject.setId(1L);
        testSubject.setName("اللغة العربية");

        testLesson = new Lesson();
        testLesson.setId(1L);
        testLesson.setTitle("الدرس الأول");
        testLesson.setContent("محتوى الدرس");
        testLesson.setSubject(testSubject);
        testLesson.setGradeLevel(1);

        testStudent = new Student();
        testStudent.setId(1L);
        testStudent.setFullName("طالب اختبار");
        testStudent.setTotalPoints(0);
        testStudent.setCurrentStreak(0);
        testStudent.setGradeLevel(1);

        testQuiz = new Quiz();
        testQuiz.setId(1L);
        testQuiz.setTitle("اختبار الدرس الأول");
        testQuiz.setLesson(testLesson);
        testQuiz.setGamified(true);

        Question q1 = new Question();
        q1.setId(1L);
        q1.setType(QuestionType.MCQ);
        q1.setQuestionText("ما هو الحرف الأول؟");
        q1.setCorrectAnswer("أ");
        q1.setOptions("[\"أ\", \"ب\", \"ت\", \"ث\"]");
        q1.setDifficultyLevel(1);

        Question q2 = new Question();
        q2.setId(2L);
        q2.setType(QuestionType.TRUE_FALSE);
        q2.setQuestionText("الشمس تشرق من الشرق");
        q2.setCorrectAnswer("صح");
        q2.setDifficultyLevel(1);

        testQuiz.setQuestions(List.of(q1, q2));
    }

    // ==================== getQuizByLesson Tests ====================

    @Nested
    @DisplayName("getQuizByLesson()")
    class GetQuizByLessonTests {

        @Test
        @DisplayName("should return quiz with questions (no correct answers)")
        void getQuizSuccess() {
            when(quizRepository.findByLessonId(1L)).thenReturn(List.of(testQuiz));

            QuizResponse response = quizService.getQuizByLesson(1L);

            assertThat(response.getId()).isEqualTo(1L);
            assertThat(response.getTitle()).isEqualTo("اختبار الدرس الأول");
            assertThat(response.getTotalQuestions()).isEqualTo(2);
            assertThat(response.getQuestions()).hasSize(2);
            assertThat(response.getQuestions().get(0).getType()).isEqualTo("MCQ");
        }

        @Test
        @DisplayName("should throw when no quiz found for lesson")
        void getQuizNotFound() {
            when(quizRepository.findByLessonId(999L)).thenReturn(List.of());

            assertThatThrownBy(() -> quizService.getQuizByLesson(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // ==================== startAttempt Tests ====================

    @Nested
    @DisplayName("startAttempt()")
    class StartAttemptTests {

        @Test
        @DisplayName("should create new attempt if none in progress")
        void startNewAttempt() {
            when(quizRepository.findById(1L)).thenReturn(Optional.of(testQuiz));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(testStudent));
            when(attemptRepository.findByStudentIdAndQuizIdAndStatus(1L, 1L, AttemptStatus.IN_PROGRESS))
                    .thenReturn(Optional.empty());
            when(attemptRepository.save(any())).thenAnswer(inv -> {
                Attempt a = inv.getArgument(0);
                a.setId(10L);
                return a;
            });

            AttemptResponse response = quizService.startAttempt(1L, 1L);

            assertThat(response.getAttemptId()).isEqualTo(10L);
            assertThat(response.getQuizId()).isEqualTo(1L);
            assertThat(response.getStatus()).isEqualTo("IN_PROGRESS");
            assertThat(response.getTotalQuestions()).isEqualTo(2);
            assertThat(response.getCorrectAnswers()).isZero();

            ArgumentCaptor<Attempt> attemptCaptor = ArgumentCaptor.forClass(Attempt.class);
            verify(attemptRepository).save(attemptCaptor.capture());
            assertThat(attemptCaptor.getValue().getQuizAssignment()).isNull();
        }

        @Test
        @DisplayName("should return existing in-progress attempt")
        void returnExistingAttempt() {
            Attempt existing = new Attempt();
            existing.setId(5L);
            existing.setStudent(testStudent);
            existing.setQuiz(testQuiz);
            existing.setStatus(AttemptStatus.IN_PROGRESS);

            when(quizRepository.findById(1L)).thenReturn(Optional.of(testQuiz));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(testStudent));
            when(attemptRepository.findByStudentIdAndQuizIdAndStatus(1L, 1L, AttemptStatus.IN_PROGRESS))
                    .thenReturn(Optional.of(existing));
            when(responseRepository.findByAttemptId(5L)).thenReturn(List.of());

            AttemptResponse response = quizService.startAttempt(1L, 1L);

            assertThat(response.getAttemptId()).isEqualTo(5L);
            verify(attemptRepository, never()).save(any()); // should not create new
        }

        @Test
        @DisplayName("personalized quiz still starts through generic start")
        void personalizedQuizStillStarts() {
            Quiz personalized = new Quiz();
            personalized.setId(99L);
            personalized.setTitle("تحدَّ نفسك");
            personalized.setQuizType(QuizType.PERSONALIZED);
            personalized.setSubject(testSubject);
            personalized.setGeneratedForStudentId(1L);
            personalized.setLesson(null);
            personalized.setQuestions(testQuiz.getQuestions());

            when(quizRepository.findById(99L)).thenReturn(Optional.of(personalized));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(testStudent));
            when(attemptRepository.findByStudentIdAndQuizIdAndStatus(1L, 99L, AttemptStatus.IN_PROGRESS))
                    .thenReturn(Optional.empty());
            when(attemptRepository.save(any())).thenAnswer(inv -> {
                Attempt a = inv.getArgument(0);
                a.setId(21L);
                return a;
            });

            AttemptResponse response = quizService.startAttempt(99L, 1L);

            assertThat(response.getAttemptId()).isEqualTo(21L);
            assertThat(response.getQuizId()).isEqualTo(99L);
            assertThat(response.getStatus()).isEqualTo("IN_PROGRESS");
        }

        @Test
        @DisplayName("teacher-created draft quiz cannot start through generic start")
        void teacherDraftQuizCannotStartThroughGenericStart() {
            Teacher teacher = new Teacher();
            teacher.setId(44L);
            Quiz teacherQuiz = new Quiz();
            teacherQuiz.setId(88L);
            teacherQuiz.setTitle("اختبار المعلم");
            teacherQuiz.setQuizType(QuizType.TEACHER_ASSIGNED);
            teacherQuiz.setCreatedByTeacher(teacher);
            teacherQuiz.setStatus(QuizStatus.DRAFT);
            teacherQuiz.setSubject(testSubject);
            teacherQuiz.setLesson(null);
            teacherQuiz.setQuestions(testQuiz.getQuestions());

            when(quizRepository.findById(88L)).thenReturn(Optional.of(teacherQuiz));

            assertThatThrownBy(() -> quizService.startAttempt(88L, 1L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("لا يمكن بدء هذا الاختبار");
            verifyNoInteractions(studentRepository);
            verify(attemptRepository, never()).save(any());
        }

        @Test
        @DisplayName("subject-only teacher quiz shape cannot start through generic start")
        void subjectOnlyTeacherQuizShapeCannotStartThroughGenericStart() {
            Quiz subjectOnly = new Quiz();
            subjectOnly.setId(89L);
            subjectOnly.setTitle("اختبار محفوظ");
            subjectOnly.setQuizType(QuizType.LESSON);
            subjectOnly.setSubject(testSubject);
            subjectOnly.setLesson(null);
            subjectOnly.setGeneratedForStudentId(null);
            subjectOnly.setQuestions(testQuiz.getQuestions());

            when(quizRepository.findById(89L)).thenReturn(Optional.of(subjectOnly));

            assertThatThrownBy(() -> quizService.startAttempt(89L, 1L))
                    .isInstanceOf(BadRequestException.class);
            verifyNoInteractions(studentRepository);
            verify(attemptRepository, never()).save(any());
        }

        @Test
        @DisplayName("quiz with assignment records cannot start through generic start")
        void assignedQuizCannotStartThroughGenericStart() {
            Quiz assignedQuiz = new Quiz();
            assignedQuiz.setId(90L);
            assignedQuiz.setTitle("اختبار منشور");
            assignedQuiz.setQuizType(QuizType.LESSON);
            assignedQuiz.setLesson(testLesson);
            assignedQuiz.setQuestions(testQuiz.getQuestions());

            QuizAssignment assignment = new QuizAssignment();
            assignment.setId(12L);
            assignment.setQuiz(assignedQuiz);
            assignedQuiz.setAssignments(List.of(assignment));

            when(quizRepository.findById(90L)).thenReturn(Optional.of(assignedQuiz));

            assertThatThrownBy(() -> quizService.startAttempt(90L, 1L))
                    .isInstanceOf(BadRequestException.class);
            verifyNoInteractions(studentRepository);
            verify(attemptRepository, never()).save(any());
        }
    }

    // ==================== submitAnswer Tests ====================

    @Nested
    @DisplayName("submitAnswer()")
    class SubmitAnswerTests {

        private Attempt inProgressAttempt;

        @BeforeEach
        void setUp() {
            inProgressAttempt = new Attempt();
            inProgressAttempt.setId(10L);
            inProgressAttempt.setStudent(testStudent);
            inProgressAttempt.setQuiz(testQuiz);
            inProgressAttempt.setStatus(AttemptStatus.IN_PROGRESS);
        }

        @Test
        @DisplayName("should accept correct MCQ answer")
        void correctMcqAnswer() {
            Question mcq = testQuiz.getQuestions().get(0);

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(1L);
            request.setAnswer("أ");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(1L)).thenReturn(Optional.of(mcq));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
            assertThat(response.getPointsEarned()).isEqualTo(10);
            assertThat(response.getCorrectAnswer()).isEqualTo("أ");
        }

        @Test
        @DisplayName("should reject wrong MCQ answer")
        void wrongMcqAnswer() {
            Question mcq = testQuiz.getQuestions().get(0);

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(1L);
            request.setAnswer("ب");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(1L)).thenReturn(Optional.of(mcq));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isFalse();
            assertThat(response.getPointsEarned()).isZero();
        }

        @Test
        @DisplayName("should accept correct TRUE_FALSE answer")
        void correctTrueFalseAnswer() {
            Question tf = testQuiz.getQuestions().get(1);

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(2L);
            request.setAnswer("صح");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(2L)).thenReturn(Optional.of(tf));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
        }

        @Test
        @DisplayName("should accept English TRUE_FALSE answer (True/False)")
        void correctEnglishTrueFalseAnswer() {
            // English-subject TF questions store "True"/"False" and the Flutter
            // widget submits "True"/"False" to match. Regression guard for the
            // bug where English TF was unanswerable (submitted صح vs stored True).
            Question enTf = new Question();
            enTf.setId(99L);
            enTf.setType(QuestionType.TRUE_FALSE);
            enTf.setQuestionText("We say 'Hello' to greet people.");
            enTf.setCorrectAnswer("True");

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(99L);
            request.setAnswer("True");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(enTf));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
        }

        @Test
        @DisplayName("TRUE_FALSE compares across languages (صح ≡ True)")
        void trueFalseCrossLanguage() {
            // Safety net: a stored Arabic "صح" with a submitted English "True"
            // (or vice-versa) still scores correct via canonical normalization.
            Question tf = new Question();
            tf.setId(99L);
            tf.setType(QuestionType.TRUE_FALSE);
            tf.setQuestionText("الشمس تشرق من الشرق");
            tf.setCorrectAnswer("صح");

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(99L);
            request.setAnswer("True"); // different language than stored answer

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tf));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
        }

        @Test
        @DisplayName("should reject submission from different student")
        void rejectOtherStudentSubmission() {
            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(1L);
            request.setAnswer("أ");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));

            assertThatThrownBy(() -> quizService.submitAnswer(10L, request, 999L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessage("هذه المحاولة لا تخصك");
        }

        @Test
        @DisplayName("should reject submission on graded attempt")
        void rejectGradedAttemptSubmission() {
            inProgressAttempt.setStatus(AttemptStatus.GRADED);

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(1L);
            request.setAnswer("أ");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));

            assertThatThrownBy(() -> quizService.submitAnswer(10L, request, 1L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessage("هذه المحاولة مكتملة بالفعل");
        }

        @Test
        @DisplayName("should evaluate FILL_BLANK with Arabic normalization")
        void fillBlankWithArabicNormalization() {
            Question fillBlank = new Question();
            fillBlank.setId(3L);
            fillBlank.setType(QuestionType.FILL_BLANK);
            fillBlank.setQuestionText("أكمل: الـ___ تشرق من الشرق");
            fillBlank.setCorrectAnswer("شمس");

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(3L);
            request.setAnswer("شمس");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(3L)).thenReturn(Optional.of(fillBlank));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
        }

        @Test
        @DisplayName("audit B1 regression: FILL_BLANK with alef-hamza (إجابة) accepts plain alef (اجابة)")
        void fillBlankNormalizeAlefVariants() {
            // Before audit fix B1, normalizeArabic used a doubly-escaped backslash-u
            // form in its replaceAll() second arg, which Java does NOT interpret as a
            // Unicode escape. Result: "إجابة" stayed as-is and never matched "اجابة".
            Question fillBlank = new Question();
            fillBlank.setId(7L);
            fillBlank.setType(QuestionType.FILL_BLANK);
            fillBlank.setQuestionText("أكمل: ___ صحيحة");
            fillBlank.setCorrectAnswer("اجابة"); // canonical: plain alef + ta marbuta

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(7L);
            request.setAnswer("إجابة"); // alef-hamza-below + ta marbuta

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(7L)).thenReturn(Optional.of(fillBlank));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
        }

        @Test
        @DisplayName("audit B2 regression: SHORT_ANSWER submit calls Gemini.evaluateShortAnswer ONCE")
        void shortAnswerCallsGeminiOnce() {
            // Before audit fix B2, evaluateAnswer() and generateFeedback() each
            // invoked geminiService.evaluateShortAnswer() for the same input —
            // doubling API cost and latency on every short-answer submission.
            Question shortAnswer = new Question();
            shortAnswer.setId(11L);
            shortAnswer.setType(QuestionType.SHORT_ANSWER);
            shortAnswer.setQuestionText("ما اسم رسولنا؟");
            shortAnswer.setCorrectAnswer("محمد");

            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(11L);
            request.setAnswer("محمد ﷺ");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(inProgressAttempt));
            when(questionRepository.findById(11L)).thenReturn(Optional.of(shortAnswer));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
            when(geminiService.isAvailable()).thenReturn(true);
            when(geminiService.evaluateShortAnswer(anyString(), anyString(), anyString(), anyString()))
                    .thenReturn(Map.of("isCorrect", true, "feedback", "أحسنت! 🌟"));

            SubmitAnswerResponse response = quizService.submitAnswer(10L, request, 1L);

            assertThat(response.isCorrect()).isTrue();
            assertThat(response.getFeedback()).isEqualTo("أحسنت! 🌟");
            // The whole point of this regression: exactly ONE Gemini call.
            verify(geminiService, times(1))
                    .evaluateShortAnswer(anyString(), anyString(), anyString(), anyString());
        }
    }

    // ==================== completeAttempt Tests ====================

    @Nested
    @DisplayName("completeAttempt()")
    class CompleteAttemptTests {

        @Test
        @DisplayName("should calculate score and award points on completion")
        void completeWithFullScore() {
            Attempt attempt = new Attempt();
            attempt.setId(10L);
            attempt.setStudent(testStudent);
            attempt.setQuiz(testQuiz);
            attempt.setStatus(AttemptStatus.IN_PROGRESS);

            StudentResponse r1 = new StudentResponse();
            r1.setQuestion(testQuiz.getQuestions().get(0));
            r1.setIsCorrect(true);
            r1.setEvaluatedText("أ");

            StudentResponse r2 = new StudentResponse();
            r2.setQuestion(testQuiz.getQuestions().get(1));
            r2.setIsCorrect(true);
            r2.setEvaluatedText("صح");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(attempt));
            when(responseRepository.findByAttemptId(10L)).thenReturn(List.of(r1, r2));
            when(attemptRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
            when(studentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
            when(progressRepository.findByStudentIdAndLessonId(1L, 1L)).thenReturn(Optional.empty());
            when(progressRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            AttemptResponse response = quizService.completeAttempt(10L, 1L);

            assertThat(response.getStatus()).isEqualTo("GRADED");
            assertThat(response.getScore()).isEqualTo(100.0);
            assertThat(response.getCorrectAnswers()).isEqualTo(2);
            assertThat(response.getTotalQuestions()).isEqualTo(2);
            assertThat(response.getPointsEarned()).isEqualTo(20); // 2 * 10

            // Verify student got points
            ArgumentCaptor<Student> studentCaptor = ArgumentCaptor.forClass(Student.class);
            verify(studentRepository).save(studentCaptor.capture());
            assertThat(studentCaptor.getValue().getTotalPoints()).isEqualTo(20);
        }

        @Test
        @DisplayName("should set MASTERED status for score >= 80")
        void masteredProgressOnHighScore() {
            Attempt attempt = new Attempt();
            attempt.setId(10L);
            attempt.setStudent(testStudent);
            attempt.setQuiz(testQuiz);
            attempt.setStatus(AttemptStatus.IN_PROGRESS);

            // 2/2 correct = 100%
            StudentResponse r1 = new StudentResponse();
            r1.setQuestion(testQuiz.getQuestions().get(0));
            r1.setIsCorrect(true);
            StudentResponse r2 = new StudentResponse();
            r2.setQuestion(testQuiz.getQuestions().get(1));
            r2.setIsCorrect(true);

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(attempt));
            when(responseRepository.findByAttemptId(10L)).thenReturn(List.of(r1, r2));
            when(attemptRepository.save(any())).thenReturn(attempt);
            when(studentRepository.save(any())).thenReturn(testStudent);
            when(progressRepository.findByStudentIdAndLessonId(1L, 1L)).thenReturn(Optional.empty());
            when(progressRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            quizService.completeAttempt(10L, 1L);

            ArgumentCaptor<Progress> progressCaptor = ArgumentCaptor.forClass(Progress.class);
            verify(progressRepository).save(progressCaptor.capture());
            assertThat(progressCaptor.getValue().getCompletionStatus()).isEqualTo(CompletionStatus.MASTERED);
        }

        @Test
        @DisplayName("should set IN_PROGRESS status for score < 50")
        void inProgressOnLowScore() {
            Attempt attempt = new Attempt();
            attempt.setId(10L);
            attempt.setStudent(testStudent);
            attempt.setQuiz(testQuiz);
            attempt.setStatus(AttemptStatus.IN_PROGRESS);

            // 0/2 correct = 0%
            StudentResponse r1 = new StudentResponse();
            r1.setQuestion(testQuiz.getQuestions().get(0));
            r1.setIsCorrect(false);
            StudentResponse r2 = new StudentResponse();
            r2.setQuestion(testQuiz.getQuestions().get(1));
            r2.setIsCorrect(false);

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(attempt));
            when(responseRepository.findByAttemptId(10L)).thenReturn(List.of(r1, r2));
            when(attemptRepository.save(any())).thenReturn(attempt);
            when(studentRepository.save(any())).thenReturn(testStudent);
            when(progressRepository.findByStudentIdAndLessonId(1L, 1L)).thenReturn(Optional.empty());
            when(progressRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            quizService.completeAttempt(10L, 1L);

            ArgumentCaptor<Progress> progressCaptor = ArgumentCaptor.forClass(Progress.class);
            verify(progressRepository).save(progressCaptor.capture());
            assertThat(progressCaptor.getValue().getCompletionStatus()).isEqualTo(CompletionStatus.IN_PROGRESS);
        }

        @Test
        @DisplayName("should deduplicate responses keeping latest per question")
        void deduplicateResponses() {
            Attempt attempt = new Attempt();
            attempt.setId(10L);
            attempt.setStudent(testStudent);
            attempt.setQuiz(testQuiz);
            attempt.setStatus(AttemptStatus.IN_PROGRESS);

            // Student answered q1 twice: first wrong, then correct
            StudentResponse r1First = new StudentResponse();
            r1First.setQuestion(testQuiz.getQuestions().get(0));
            r1First.setIsCorrect(false);
            r1First.setEvaluatedText("ب");

            StudentResponse r1Second = new StudentResponse();
            r1Second.setQuestion(testQuiz.getQuestions().get(0));
            r1Second.setIsCorrect(true);
            r1Second.setEvaluatedText("أ");

            StudentResponse r2 = new StudentResponse();
            r2.setQuestion(testQuiz.getQuestions().get(1));
            r2.setIsCorrect(true);
            r2.setEvaluatedText("صح");

            when(attemptRepository.findById(10L)).thenReturn(Optional.of(attempt));
            when(responseRepository.findByAttemptId(10L)).thenReturn(List.of(r1First, r1Second, r2));
            when(attemptRepository.save(any())).thenReturn(attempt);
            when(studentRepository.save(any())).thenReturn(testStudent);
            when(progressRepository.findByStudentIdAndLessonId(anyLong(), anyLong())).thenReturn(Optional.empty());
            when(progressRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            AttemptResponse response = quizService.completeAttempt(10L, 1L);

            // Should count 2 correct (deduped: r1Second + r2), not 3 responses
            assertThat(response.getCorrectAnswers()).isEqualTo(2);
            assertThat(response.getTotalQuestions()).isEqualTo(2);
            assertThat(response.getScore()).isEqualTo(100.0);
        }

        @Test
        @DisplayName("personalized quiz (null lesson) completes without touching lesson Progress")
        void personalizedQuizCompletesWithoutLessonProgress() {
            // A PERSONALIZED quiz has no lesson — completeAttempt must NOT call
            // updateLessonProgress (which dereferences lesson) and must NOT throw.
            Quiz personalized = new Quiz();
            personalized.setId(99L);
            personalized.setTitle("تحدَّ نفسك — اللغة العربية");
            personalized.setQuizType(com.springboot.manhaji.entity.enums.QuizType.PERSONALIZED);
            personalized.setLesson(null); // the key: no lesson
            personalized.setSubject(testSubject);
            personalized.setQuestions(testQuiz.getQuestions());

            Attempt attempt = new Attempt();
            attempt.setId(11L);
            attempt.setStudent(testStudent);
            attempt.setQuiz(personalized);
            attempt.setStatus(AttemptStatus.IN_PROGRESS);

            StudentResponse r1 = new StudentResponse();
            r1.setQuestion(personalized.getQuestions().get(0));
            r1.setIsCorrect(true);
            StudentResponse r2 = new StudentResponse();
            r2.setQuestion(personalized.getQuestions().get(1));
            r2.setIsCorrect(true);

            when(attemptRepository.findById(11L)).thenReturn(Optional.of(attempt));
            when(responseRepository.findByAttemptId(11L)).thenReturn(List.of(r1, r2));
            when(attemptRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
            when(studentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            AttemptResponse response = quizService.completeAttempt(11L, 1L);

            assertThat(response.getStatus()).isEqualTo("GRADED");
            assertThat(response.getScore()).isEqualTo(100.0);
            // Critical: no lesson Progress write for a lesson-less quiz.
            verify(progressRepository, org.mockito.Mockito.never()).save(any());
            // BKT still fired (analytics hook is independent of lesson Progress).
            verify(skillMasteryService).recordResponses(eq(1L), any());
        }
    }

    // ==================== getHint Tests ====================

    @Nested
    @DisplayName("getHint()")
    class GetHintTests {

        @Test
        @DisplayName("should return hint with clamped level")
        void getHintSuccess() {
            Question question = testQuiz.getQuestions().get(0);
            when(questionRepository.findById(1L)).thenReturn(Optional.of(question));
            Attempt active = new Attempt();
            active.setStudent(testStudent);
            active.setQuiz(testQuiz);
            active.setStatus(AttemptStatus.IN_PROGRESS);
            when(attemptRepository.findByStudentIdAndStatus(1L, AttemptStatus.IN_PROGRESS))
                    .thenReturn(List.of(active));
            when(geminiService.generateHint(anyString(), anyString(), eq(2), eq("ar")))
                    .thenReturn("حاول التفكير في أول حرف في الأبجدية");

            Map<String, Object> result = quizService.getHint(1L, 2, 1L);

            assertThat(result.get("hint")).isEqualTo("حاول التفكير في أول حرف في الأبجدية");
            assertThat(result.get("hintLevel")).isEqualTo(2);
            assertThat(result.get("remainingHints")).isEqualTo(1);
        }

        @Test
        @DisplayName("should clamp hint level to 1-3 range")
        void clampHintLevel() {
            Question question = testQuiz.getQuestions().get(0);
            when(questionRepository.findById(1L)).thenReturn(Optional.of(question));
            Attempt active = new Attempt();
            active.setStudent(testStudent);
            active.setQuiz(testQuiz);
            active.setStatus(AttemptStatus.IN_PROGRESS);
            when(attemptRepository.findByStudentIdAndStatus(1L, AttemptStatus.IN_PROGRESS))
                    .thenReturn(List.of(active));
            when(geminiService.generateHint(anyString(), anyString(), eq(3), eq("ar")))
                    .thenReturn("الإجابة هي: أ");

            Map<String, Object> result = quizService.getHint(1L, 10, 1L); // level 10 → clamp to 3

            assertThat(result.get("hintLevel")).isEqualTo(3);
            assertThat(result.get("remainingHints")).isEqualTo(0);
        }

        @Test
        @DisplayName("should reject hint when caller has no active attempt for the question's quiz")
        void rejectHintWithoutActiveAttempt() {
            Question question = testQuiz.getQuestions().get(0);
            when(questionRepository.findById(1L)).thenReturn(Optional.of(question));
            when(attemptRepository.findByStudentIdAndStatus(1L, AttemptStatus.IN_PROGRESS))
                    .thenReturn(List.of()); // no active attempt

            assertThatThrownBy(() -> quizService.getHint(1L, 2, 1L))
                    .isInstanceOf(BadRequestException.class);
            verify(geminiService, never()).generateHint(anyString(), anyString(), anyInt(), anyString());
        }
    }

    // ==================== submitTracingResult Tests ====================

    @Nested
    @DisplayName("submitTracingResult()")
    class SubmitTracingResultTests {

        private Attempt tracingAttempt;
        private Question tracingQuestion;

        @BeforeEach
        void seedTracing() {
            tracingAttempt = new Attempt();
            tracingAttempt.setId(50L);
            tracingAttempt.setStudent(testStudent);
            tracingAttempt.setQuiz(testQuiz);
            tracingAttempt.setStatus(AttemptStatus.IN_PROGRESS);

            tracingQuestion = new Question();
            tracingQuestion.setId(99L);
            tracingQuestion.setType(QuestionType.TRACING);
            tracingQuestion.setQuestionText("ر");
            tracingQuestion.setCorrectAnswer("ر");
            tracingQuestion.setDifficultyLevel(1);
        }

        @Test
        @DisplayName("should persist a correct tracing response with points")
        void persistCorrect() {
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(95);
            req.setStars(3);
            req.setIsCorrect(true);
            req.setFeedback("أحسنت الكتابة!");

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tracingQuestion));
            when(responseRepository.save(any(StudentResponse.class))).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitTracingResult(50L, req, 1L);

            assertThat(response.getQuestionId()).isEqualTo(99L);
            assertThat(response.isCorrect()).isTrue();
            assertThat(response.getPointsEarned()).isGreaterThan(0);
            assertThat(response.getFeedback()).contains("أحسنت");

            ArgumentCaptor<StudentResponse> captor = ArgumentCaptor.forClass(StudentResponse.class);
            verify(responseRepository).save(captor.capture());
            StudentResponse saved = captor.getValue();
            assertThat(saved.getIsCorrect()).isTrue();
            assertThat(saved.getEvaluatedText()).contains("score=95").contains("stars=3");
        }

        @Test
        @DisplayName("should persist a wrong tracing response with zero points")
        void persistWrong() {
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(30);
            req.setStars(0);
            req.setIsCorrect(false);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tracingQuestion));
            when(responseRepository.save(any(StudentResponse.class))).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitTracingResult(50L, req, 1L);

            assertThat(response.isCorrect()).isFalse();
            assertThat(response.getPointsEarned()).isZero();
            verify(responseRepository).save(any(StudentResponse.class));
        }

        @Test
        @DisplayName("should reject non-tracing question type")
        void rejectNonTracingQuestion() {
            Question mcq = testQuiz.getQuestions().get(0); // MCQ
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(mcq.getId());
            req.setScore(80);
            req.setStars(2);
            req.setIsCorrect(true);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(mcq.getId())).thenReturn(Optional.of(mcq));

            assertThatThrownBy(() -> quizService.submitTracingResult(50L, req, 1L))
                    .isInstanceOf(BadRequestException.class);
            verify(responseRepository, never()).save(any());
        }

        @Test
        @DisplayName("should reject submission to another student's attempt")
        void rejectWrongStudent() {
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(80);
            req.setStars(2);
            req.setIsCorrect(true);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));

            assertThatThrownBy(() -> quizService.submitTracingResult(50L, req, 999L))
                    .isInstanceOf(BadRequestException.class);
            verify(responseRepository, never()).save(any());
        }

        @Test
        @DisplayName("should reject submission to a completed attempt")
        void rejectCompletedAttempt() {
            tracingAttempt.setStatus(AttemptStatus.GRADED);
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(80);
            req.setStars(2);
            req.setIsCorrect(true);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));

            assertThatThrownBy(() -> quizService.submitTracingResult(50L, req, 1L))
                    .isInstanceOf(BadRequestException.class);
            verify(responseRepository, never()).save(any());
        }

        @Test
        @DisplayName("audit C3 regression: tracing score outside 0..100 is rejected")
        void rejectsTracingScoreOutOfRange() {
            // Audit-4 fix C3: previously the client could send score=99999
            // and the backend would store it unmodified, breaking analytics.
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(150);    // out of range
            req.setStars(2);
            req.setIsCorrect(true);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tracingQuestion));

            assertThatThrownBy(() -> quizService.submitTracingResult(50L, req, 1L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Tracing score");
            verify(responseRepository, never()).save(any());
        }

        @Test
        @DisplayName("audit C3 regression: tracing stars outside 0..3 is rejected")
        void rejectsTracingStarsOutOfRange() {
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(80);
            req.setStars(99);     // out of range
            req.setIsCorrect(true);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tracingQuestion));

            assertThatThrownBy(() -> quizService.submitTracingResult(50L, req, 1L))
                    .isInstanceOf(BadRequestException.class);
            verify(responseRepository, never()).save(any());
        }

        @Test
        @DisplayName("audit C3 regression: client isCorrect=true with low score is overridden to false")
        void clientIsCorrectIgnoredWhenScoreLow() {
            // Audit-4 fix C3: anchor correctness to the server-validated score
            // rather than trusting the client's boolean. A modified client
            // sending score=30 + isCorrect=true used to receive points.
            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(30);     // below the ≥60 threshold
            req.setStars(0);
            req.setIsCorrect(true); // client lies

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tracingQuestion));
            when(responseRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubmitAnswerResponse response = quizService.submitTracingResult(50L, req, 1L);

            assertThat(response.isCorrect()).isFalse();
            assertThat(response.getPointsEarned()).isZero();
        }

        @Test
        @DisplayName("audit C2 regression: tracing submission with question outside attempt's quiz is rejected")
        void rejectsQuestionNotInQuiz() {
            // Audit-4 fix C2: override the default permissive mock so the
            // question (99L) is NOT in the quiz's question list.
            org.mockito.Mockito.when(quizRepository.findQuestionIdsByQuizId(any()))
                    .thenReturn(List.of(1L, 2L, 3L)); // 99L deliberately excluded

            TracingSubmitRequest req = new TracingSubmitRequest();
            req.setQuestionId(99L);
            req.setScore(80);
            req.setStars(2);
            req.setIsCorrect(true);

            when(attemptRepository.findById(50L)).thenReturn(Optional.of(tracingAttempt));
            when(questionRepository.findById(99L)).thenReturn(Optional.of(tracingQuestion));

            assertThatThrownBy(() -> quizService.submitTracingResult(50L, req, 1L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("does not belong");
            verify(responseRepository, never()).save(any());
        }
    }

    // ==================== submitPronunciation fallback Tests ====================

    @Nested
    @DisplayName("submitPronunciation() — Gemini unavailable fallback")
    class SubmitPronunciationFallbackTests {

        private Attempt pronAttempt;
        private Question pronQuestion;

        @BeforeEach
        void seedPron() {
            pronAttempt = new Attempt();
            pronAttempt.setId(70L);
            pronAttempt.setStudent(testStudent);
            pronAttempt.setQuiz(testQuiz);
            pronAttempt.setStatus(AttemptStatus.IN_PROGRESS);

            pronQuestion = new Question();
            pronQuestion.setId(77L);
            pronQuestion.setType(QuestionType.PRONUNCIATION);
            pronQuestion.setQuestionText("رمان");
            pronQuestion.setCorrectAnswer("رمان");
            pronQuestion.setDifficultyLevel(1);
        }

        @Test
        @DisplayName("should return friendly fallback response when Gemini API key missing")
        void gracefulWhenGeminiUnavailable() {
            when(attemptRepository.findById(70L)).thenReturn(Optional.of(pronAttempt));
            when(questionRepository.findById(77L)).thenReturn(Optional.of(pronQuestion));
            when(whisperService.isAvailable()).thenReturn(false);

            var response = quizService.submitPronunciation(70L, 77L, new byte[]{1, 2, 3}, "ar", 1L);

            assertThat(response).isNotNull();
            assertThat(response.getScore()).isZero();
            assertThat(response.isCorrect()).isFalse();
            assertThat(response.getFeedback()).contains("غير متاحة");
            // No transcription attempted, no DB write.
            verify(whisperService, never()).transcribe(any(), any());
            verify(responseRepository, never()).save(any());
        }

        @Test
        @DisplayName("should pass language code to pronunciation scorer")
        void passesLanguageToScorer() {
            Question englishQuestion = new Question();
            englishQuestion.setId(78L);
            englishQuestion.setType(QuestionType.PRONUNCIATION);
            englishQuestion.setQuestionText("apple");
            englishQuestion.setCorrectAnswer("apple");
            englishQuestion.setDifficultyLevel(1);

            when(attemptRepository.findById(70L)).thenReturn(Optional.of(pronAttempt));
            when(questionRepository.findById(78L)).thenReturn(Optional.of(englishQuestion));
            when(whisperService.isAvailable()).thenReturn(true);
            // Feature B (2026-04-29): QuizService now calls transcribeWithPhonemes.
            when(whisperService.transcribeWithPhonemes(any(), eq("apple"), eq("en")))
                    .thenReturn(new com.springboot.manhaji.service.ai.PhonemeAnalysis(
                            "apple", java.util.List.of(), null));
            when(pronunciationScoringService.score("apple", "apple", "en")).thenReturn(100);
            when(pronunciationScoringService.rating(100)).thenReturn("ممتاز");
            when(pronunciationScoringService.feedback(100, "apple")).thenReturn("نطق رائع! أحسنت.");
            when(pronunciationScoringService.isCorrect(100)).thenReturn(true);

            var response = quizService.submitPronunciation(70L, 78L, new byte[]{1, 2, 3}, "en", 1L);

            assertThat(response.getScore()).isEqualTo(100);
            assertThat(response.isCorrect()).isTrue();
            verify(pronunciationScoringService).score("apple", "apple", "en");
            verify(whisperService).transcribeWithPhonemes(any(), eq("apple"), eq("en"));
        }

        @Test
        @DisplayName("Feature B: phoneme errors + guidance from Gemini flow into the response")
        void surfacesPhonemeCoaching() {
            Question arabicQuestion = new Question();
            arabicQuestion.setId(79L);
            arabicQuestion.setType(QuestionType.PRONUNCIATION);
            arabicQuestion.setQuestionText("رمان");
            arabicQuestion.setCorrectAnswer("رمان");
            arabicQuestion.setDifficultyLevel(1);

            when(attemptRepository.findById(70L)).thenReturn(Optional.of(pronAttempt));
            when(questionRepository.findById(79L)).thenReturn(Optional.of(arabicQuestion));
            when(whisperService.isAvailable()).thenReturn(true);
            when(whisperService.transcribeWithPhonemes(any(), eq("رمان"), eq("ar")))
                    .thenReturn(new com.springboot.manhaji.service.ai.PhonemeAnalysis(
                            "لمان",
                            java.util.List.of("ر"),
                            "ركّز على صوت الراء من الحلق"));
            when(pronunciationScoringService.score("رمان", "لمان", "ar")).thenReturn(45);
            when(pronunciationScoringService.rating(45)).thenReturn("حاول مرة أخرى");
            when(pronunciationScoringService.feedback(45, "رمان")).thenReturn("ركز على الحروف.");
            when(pronunciationScoringService.isCorrect(45)).thenReturn(false);

            var response = quizService.submitPronunciation(70L, 79L, new byte[]{1, 2, 3}, "ar", 1L);

            assertThat(response.getTranscribedText()).isEqualTo("لمان");
            assertThat(response.getPhonemeErrors()).containsExactly("ر");
            assertThat(response.getGuidance()).isEqualTo("ركّز على صوت الراء من الحلق");
        }
    }
}
