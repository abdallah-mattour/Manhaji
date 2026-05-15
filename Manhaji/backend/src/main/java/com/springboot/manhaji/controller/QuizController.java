package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.request.SubmitAnswerRequest;
import com.springboot.manhaji.dto.request.TracingSubmitRequest;
import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.dto.response.AttemptResponse;
import com.springboot.manhaji.dto.response.PronunciationScoreResponse;
import com.springboot.manhaji.dto.response.QuizResponse;
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
            @PathVariable Long lessonId) {
        QuizResponse quiz = quizService.getQuizByLesson(lessonId);
        return ResponseEntity.ok(ApiResponse.success(quiz));
    }

    // Start a new quiz attempt
    @PostMapping("/attempt/start/{quizId}")
    public ResponseEntity<ApiResponse<AttemptResponse>> startAttempt(
            @PathVariable Long quizId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        AttemptResponse attempt = quizService.startAttempt(quizId, studentId);
        return ResponseEntity.ok(ApiResponse.success(attempt));
    }

    // Submit answer for one question in an attempt
    @PostMapping("/attempt/{attemptId}/answer")
    public ResponseEntity<ApiResponse<SubmitAnswerResponse>> submitAnswer(
            @PathVariable Long attemptId,
            @Valid @RequestBody SubmitAnswerRequest request,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        SubmitAnswerResponse response = quizService.submitAnswer(attemptId, request, studentId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // Submit voice answer — transcribe audio then evaluate
    @PostMapping("/attempt/{attemptId}/voice-answer")
    public ResponseEntity<ApiResponse<SubmitAnswerResponse>> submitVoiceAnswer(
            @PathVariable Long attemptId,
            @RequestParam("audio") MultipartFile audioFile,
            @RequestParam("questionId") Long questionId,
            @RequestParam(value = "language", defaultValue = "ar") String language,
            Authentication authentication) {

        Long studentId = (Long) authentication.getPrincipal();
        requireAudioWithinLimit(audioFile);

        try {
            // Transcribe audio via Whisper
            String transcription = whisperService.transcribe(audioFile.getBytes(), language);
            log.info("Voice transcription for question {}: {}", questionId, transcription);

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
            @PathVariable Long attemptId,
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
            @PathVariable Long attemptId,
            @Valid @RequestBody TracingSubmitRequest request,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        SubmitAnswerResponse response = quizService.submitTracingResult(attemptId, request, studentId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // Get hint for a question
    @GetMapping("/question/{questionId}/hint")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHint(
            @PathVariable Long questionId,
            @RequestParam(defaultValue = "1") int level) {
        Map<String, Object> hint = quizService.getHint(questionId, level);
        return ResponseEntity.ok(ApiResponse.success(hint));
    }

    // Complete the attempt and get final results
    @PostMapping("/attempt/{attemptId}/complete")
    public ResponseEntity<ApiResponse<AttemptResponse>> completeAttempt(
            @PathVariable Long attemptId,
            Authentication authentication) {
        Long studentId = (Long) authentication.getPrincipal();
        AttemptResponse result = quizService.completeAttempt(attemptId, studentId);
        return ResponseEntity.ok(ApiResponse.success(result));
    }
}
