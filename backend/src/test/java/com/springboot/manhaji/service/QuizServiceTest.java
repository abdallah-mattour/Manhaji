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
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.ai.GeminiService;
import com.springboot.manhaji.service.ai.PronunciationScoringService;
import com.springboot.manhaji.service.ai.WhisperService;
import com.springboot.manhaji.support.TestMessages;
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
    @Mock private GeminiService geminiService;
    @Mock private WhisperService whisperService;
    @Mock private PronunciationScoringService pronunciationScoringService;
    @Spy  private ObjectMapper objectMapper = new ObjectMapper();

    private QuizService quizService;

    private Student testStudent;
    private Quiz testQuiz;
    private Lesson testLesson;
    private Subject testSubject;

    @BeforeEach
    void setUp() {
        quizService = new QuizService(
                quizRepository, questionRepository, attemptRepository, responseRepository,
                studentRepository, progressRepository, objectMapper, geminiService,
                whisperService, pronunciationScoringService,
                TestMessages.create(), new QuizConfigProperties());

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
            when(geminiService.generateHint(anyString(), anyString(), eq(2), eq("ar")))
                    .thenReturn("حاول التفكير في أول حرف في الأبجدية");

            Map<String, Object> result = quizService.getHint(1L, 2);

            assertThat(result.get("hint")).isEqualTo("حاول التفكير في أول حرف في الأبجدية");
            assertThat(result.get("hintLevel")).isEqualTo(2);
            assertThat(result.get("remainingHints")).isEqualTo(1);
        }

        @Test
        @DisplayName("should clamp hint level to 1-3 range")
        void clampHintLevel() {
            Question question = testQuiz.getQuestions().get(0);
            when(questionRepository.findById(1L)).thenReturn(Optional.of(question));
            when(geminiService.generateHint(anyString(), anyString(), eq(3), eq("ar")))
                    .thenReturn("الإجابة هي: أ");

            Map<String, Object> result = quizService.getHint(1L, 10); // level 10 should clamp to 3

            assertThat(result.get("hintLevel")).isEqualTo(3);
            assertThat(result.get("remainingHints")).isEqualTo(0);
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
    }
}
