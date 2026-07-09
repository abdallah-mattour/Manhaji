package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.request.SubmitAnswerRequest;
import com.springboot.manhaji.dto.request.TracingSubmitRequest;
import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.PronunciationScoreResponse;
import com.springboot.manhaji.dto.response.QuizResponse;
import com.springboot.manhaji.dto.response.SkillMasteryResponse;
import com.springboot.manhaji.dto.response.SubmitAnswerResponse;
import com.springboot.manhaji.service.QuizService;
import com.springboot.manhaji.service.ai.WhisperService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/quiz")
@RequiredArgsConstructor
@Slf4j
public class QuizController {

    private final QuizService quizService;
    private final WhisperService whisperService;

    /**
     * Audit-3 fix (2026-05-15): Spring's global multipart cap is 50 MB to
     * accommodate eventual lesson image uploads, but a single pronunciation
     * recording from a Grade 1 student should be well under 10 seconds at
     * ~64 kbps webm/m4a ≈ 80 KB. Capping at 10 MB protects the Gemini
     * transcription path (which has its own undocumented size limit and
     * will silently time out on big payloads) and shields the demo from a
     * curious child who taps record and walks away for 10 minutes.
     */
    private static final long MAX_AUDIO_BYTES = 10L * 1024 * 1024;

    private static void requireAudioWithinLimit(MultipartFile audioFile) {
        if (audioFile == null || audioFile.isEmpty()) {
            throw new com.springboot.manhaji.exception.BadRequestException(
                    "ملف الصوت فارغ");
        }
        if (audioFile.getSize() > MAX_AUDIO_BYTES) {
            throw new com.springboot.manhaji.exception.BadRequestException(
                    "حجم التسجيل كبير جداً. التسجيل يجب أن يكون أقل من 10 ميغابايت.");
        }
    }

    // Get quiz for a lesson (with questions, no correct answers)
    @GetMapping("/lesson/{lessonId}")
    public ResponseEntity<ApiResponse<QuizResponse>> getQuizByLesson(
            @PathVariable("lessonId") Long lessonId) {
        QuizResponse quiz = quizService.getQuizByLesson(lessonId);
        return ResponseEntity.ok(ApiResponse.success(quiz));
    }

    /**
     * Tier A / A1 (2026-05-15): Practice Mode — adaptive question selection.
     * Returns the lesson's quiz but with questions reordered/picked by
     * {@code QuizSelectionService} based on the student's past performance.
     * Closes the FR-6 / UC-3 gap from the project proposal.
     *
     * <p>Separate endpoint so the existing fixed-order
     * {@link #getQuizByLesson} is untouched.
     */
    @GetMapping("/lesson/{lessonId}/adaptive")
    public ResponseEntity<ApiResponse<QuizResponse>> getAdaptiveQuiz(
            @PathVariable("lessonId") Long lessonId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        QuizResponse quiz = quizService.getAdaptiveQuizByLesson(lessonId, studentId);
        return ResponseEntity.ok(ApiResponse.success(quiz));
    }

    /**
     * Personalized-quiz feature (2026-05-27): generate a "Challenge Me" quiz
     * for one subject, targeting the student's weakest sub-skills via the
     * persisted BKT mastery model. Returns the same {@link QuizResponse} shape
     * as {@link #getQuizByLesson}, so the client starts an attempt on the
     * returned quiz id with the existing {@code /attempt/start/{quizId}} flow.
     */
    @PostMapping("/personalized/{subjectId}")
    public ResponseEntity<ApiResponse<QuizResponse>> generatePersonalizedQuiz(
            @PathVariable("subjectId") Long subjectId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        QuizResponse quiz = quizService.generatePersonalizedQuiz(subjectId, studentId);
        return ResponseEntity.ok(ApiResponse.success(quiz));
    }

    /**
     * Personalized-quiz feature (2026-05-27): per-subject skill-mastery
     * snapshot for the "My Skills" radar chart.
     */
    @GetMapping("/skills/{subjectId}")
    public ResponseEntity<ApiResponse<SkillMasteryResponse>> getSkillMastery(
            @PathVariable("subjectId") Long subjectId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        SkillMasteryResponse skills = quizService.getSkillMastery(subjectId, studentId);
        return ResponseEntity.ok(ApiResponse.success(skills));
    }

    // Start a new quiz attempt
    @PostMapping("/attempt/start/{quizId}")
    public ResponseEntity<ApiResponse<AttemptResponse>> startAttempt(
            @PathVariable("quizId") Long quizId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        AttemptResponse attempt = quizService.startAttempt(quizId, studentId);
        return ResponseEntity.ok(ApiResponse.success(attempt));
    }

    // Submit answer for one question in an attempt
    @PostMapping("/attempt/{attemptId}/answer")
    public ResponseEntity<ApiResponse<SubmitAnswerResponse>> submitAnswer(
            @PathVariable("attemptId") Long attemptId,
            @Valid @RequestBody SubmitAnswerRequest request,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        SubmitAnswerResponse response = quizService.submitAnswer(attemptId, request, studentId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // Submit voice answer — transcribe audio then evaluate
    @PostMapping("/attempt/{attemptId}/voice-answer")
    public ResponseEntity<ApiResponse<SubmitAnswerResponse>> submitVoiceAnswer(
            @PathVariable("attemptId") Long attemptId,
            @RequestParam("audio") MultipartFile audioFile,
            @RequestParam("questionId") Long questionId,
            @RequestParam(value = "language", defaultValue = "ar") String language,
            Authentication authentication) {

        Long studentId = (Long) authentication.getPrincipal();
        requireAudioWithinLimit(audioFile);

        try {
            // Transcribe audio via Whisper
            String transcription = whisperService.transcribe(audioFile.getBytes(), language);
            // Audit-4 fix H4 (2026-05-15): do NOT log the transcription content.
            // Student utterances are PII; in a school deployment this could leak
            // child voice content into log aggregators. Just log a length proxy.
            log.info("Voice transcription complete for question {} ({} chars)", questionId,
                    transcription == null ? 0 : transcription.length());

            // Build answer request with transcribed text
            SubmitAnswerRequest request = new SubmitAnswerRequest();
            request.setQuestionId(questionId);
            request.setAnswer(transcription);
            request.setSpokenText(transcription);

            SubmitAnswerResponse response = quizService.submitAnswer(attemptId, request, studentId);
            return ResponseEntity.ok(ApiResponse.success(response));

        } catch (Exception e) {
            log.error("Voice answer failed for attempt {}: {}", attemptId, e.getMessage());
            return ResponseEntity.internalServerError().body(
                    ApiResponse.error("حدث خطأ في معالجة الصوت"));
        }
    }

    // Submit a pronunciation attempt — transcribe audio then score phonetic similarity
    @PostMapping("/attempt/{attemptId}/pronunciation")
    public ResponseEntity<ApiResponse<PronunciationScoreResponse>> submitPronunciation(
            @PathVariable("attemptId") Long attemptId,
            @RequestParam("audio") MultipartFile audioFile,
            @RequestParam("questionId") Long questionId,
            @RequestParam(value = "language", defaultValue = "ar") String language,
            Authentication authentication) {

        Long studentId = (Long) authentication.getPrincipal();
        requireAudioWithinLimit(audioFile);

        try {
            PronunciationScoreResponse response = quizService.submitPronunciation(
                    attemptId, questionId, audioFile.getBytes(), language, studentId);
            return ResponseEntity.ok(ApiResponse.success(response));
        } catch (Exception e) {
            log.error("Pronunciation scoring failed for attempt {}: {}", attemptId, e.getMessage());
            return ResponseEntity.internalServerError().body(
                    ApiResponse.error("حدث خطأ في تقييم النطق"));
        }
    }

    // Submit a tracing attempt — client-scored, persists StudentResponse for dashboards
    @PostMapping("/attempt/{attemptId}/tracing")
    public ResponseEntity<ApiResponse<SubmitAnswerResponse>> submitTracing(
            @PathVariable("attemptId") Long attemptId,
            @Valid @RequestBody TracingSubmitRequest request,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        SubmitAnswerResponse response = quizService.submitTracingResult(attemptId, request, studentId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // Get hint for a question — must belong to an active attempt the caller owns.
    @GetMapping("/question/{questionId}/hint")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHint(
            @PathVariable("questionId") Long questionId,
            @RequestParam(name = "level", defaultValue = "1") int level,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        Map<String, Object> hint = quizService.getHint(questionId, level, studentId);
        return ResponseEntity.ok(ApiResponse.success(hint));
    }

    // Complete the attempt and get final results
    @PostMapping("/attempt/{attemptId}/complete")
    public ResponseEntity<ApiResponse<AttemptResponse>> completeAttempt(
            @PathVariable("attemptId") Long attemptId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        AttemptResponse result = quizService.completeAttempt(attemptId, studentId);
        return ResponseEntity.ok(ApiResponse.success(result));
    }
}
