package com.springboot.manhaji.controller;

import com.springboot.manhaji.dto.response.ApiResponse;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Question;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.service.ai.TtsService;
import com.springboot.manhaji.service.FileStorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/audio")
@RequiredArgsConstructor
@Slf4j
public class AudioController {

    private final TtsService ttsService;
    private final FileStorageService fileStorageService;
    private final LessonRepository lessonRepository;
    private final QuestionRepository questionRepository;

    @PostMapping("/lesson/{lessonId}/narrate")
    public ResponseEntity<ApiResponse<Map<String, String>>> narrateLesson(@PathVariable Long lessonId) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson", lessonId));

        // The exact text we'd synthesize, computed up front so the cache
        // fingerprint matches the audio byte-for-byte (title + content,
        // capped at 5000 chars for the TTS provider).
        String textToSpeak = lesson.getTitle() + ". " + lesson.getContent();
        if (textToSpeak.length() > 5000) {
            textToSpeak = textToSpeak.substring(0, 5000);
        }

        // Content-fingerprinted cache (2026-06-08): serve the cached narration
        // only while it still matches the current lesson text; regenerate when
        // the title/content is edited. See AudioController.readQuestion.
        String fingerprint = ttsService.speechFingerprint(textToSpeak);
        if (isCacheFresh(lesson.getAudioUrl(), lesson.getAudioTextHash(), fingerprint)) {
            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("audioUrl", lesson.getAudioUrl())));
        }

        if (!ttsService.isAvailable()) {
            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("message", "خدمة النطق غير متوفرة حالياً")));
        }

        try {
            // Determine language from subject
            String language = detectLanguage(lesson);

            byte[] audio = ttsService.synthesize(textToSpeak, language);
            if (audio == null) {
                return ResponseEntity.ok(ApiResponse.success(
                        Map.of("message", "فشل في إنشاء الصوت")));
            }

            // Save audio file
            String filename = "lesson_" + lessonId + ".mp3";
            String audioUrl = fileStorageService.saveAudio(audio, filename);

            // Update lesson with audio URL + fingerprint
            lesson.setAudioUrl(audioUrl);
            lesson.setAudioTextHash(fingerprint);
            lessonRepository.save(lesson);

            log.info("Generated audio for lesson {}: {}", lessonId, audioUrl);
            return ResponseEntity.ok(ApiResponse.success(Map.of("audioUrl", audioUrl)));

        } catch (Exception e) {
            log.error("Failed to generate audio for lesson {}: {}", lessonId, e.getMessage());
            return ResponseEntity.internalServerError().body(ApiResponse.error("حدث خطأ في إنشاء الصوت"));
        }
    }

    @PostMapping("/question/{questionId}/read")
    public ResponseEntity<ApiResponse<Map<String, Object>>> readQuestion(@PathVariable Long questionId) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new ResourceNotFoundException("Question", questionId));

        // Post-review fix (2026-05-24): cache the generated audio URL on the
        // Question. Previously every speaker-button tap regenerated the same
        // mp3 and hit the TTS provider — unbounded cost amplification, since a
        // kid can tap the speaker as many times as they want.
        //
        // Content-fingerprinted cache (2026-06-08): serve the cached clip only
        // while it still matches the current question text. When the text is
        // edited (the FILL_BLANK "___" sanitizer, a TF/RTL rewrite, any future
        // curriculum fix) the stored hash diverges and we regenerate instead
        // of serving stale audio — no manual cache-clearing needed.
        String fingerprint = ttsService.speechFingerprint(question.getQuestionText());
        if (isCacheFresh(question.getAudioUrl(), question.getAudioTextHash(), fingerprint)) {
            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("audioUrl", question.getAudioUrl())));
        }

        if (!ttsService.isAvailable()) {
            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("message", "خدمة النطق غير متوفرة حالياً")));
        }

        try {
            // Detect language from the question text itself — any character in
            // the Arabic unicode block ⇒ Arabic voice. Previously hardcoded
            // to "ar", so English questions came out with Arabic phonemes.
            String language = containsArabic(question.getQuestionText()) ? "ar" : "en";
            byte[] audio = ttsService.synthesize(question.getQuestionText(), language);
            if (audio == null) {
                return ResponseEntity.ok(ApiResponse.success(
                        Map.of("message", "فشل في إنشاء الصوت")));
            }

            String filename = "question_" + questionId + ".mp3";
            String audioUrl = fileStorageService.saveAudio(audio, filename);

            question.setAudioUrl(audioUrl);
            question.setAudioTextHash(fingerprint);
            questionRepository.save(question);

            return ResponseEntity.ok(ApiResponse.success(
                    Map.of("audioUrl", audioUrl)));

        } catch (Exception e) {
            log.error("Failed to generate audio for question {}: {}", questionId, e.getMessage());
            return ResponseEntity.internalServerError().body(ApiResponse.error("حدث خطأ في إنشاء الصوت"));
        }
    }

    @GetMapping("/tts/status")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> getTtsStatus() {
        return ResponseEntity.ok(ApiResponse.success(
                Map.of("available", ttsService.isAvailable())));
    }

    /**
     * Whether a cached audio clip can be served as-is, or must be regenerated.
     *
     * <p>Three cases:
     * <ul>
     *   <li><b>No clip</b> ({@code audioUrl} null/blank) → not fresh; generate.</li>
     *   <li><b>Authored asset</b> (URL not under {@code uploads/audio/}) →
     *       always fresh. These are bundled reciter / native-speaker files set
     *       at authoring time; they have no TTS fingerprint and must never be
     *       overwritten by synthesis.</li>
     *   <li><b>TTS-generated clip</b> (URL under {@code uploads/audio/}) → fresh
     *       only while the stored fingerprint matches the current text's
     *       fingerprint. A null stored hash (clip generated before this feature)
     *       never matches, forcing a one-time regeneration that self-heals any
     *       pre-existing stale audio.</li>
     * </ul>
     */
    private static boolean isCacheFresh(String audioUrl, String storedHash, String currentFingerprint) {
        if (audioUrl == null || audioUrl.isBlank()) {
            return false;
        }
        if (!audioUrl.startsWith("uploads/audio/")) {
            // Authored asset — serve it untouched, regardless of fingerprint.
            return true;
        }
        // TTS-generated clip — fresh iff the fingerprint still matches.
        return storedHash != null && storedHash.equals(currentFingerprint);
    }

    private String detectLanguage(Lesson lesson) {
        String subjectName = lesson.getSubject().getName();
        if (subjectName.contains("English") || subjectName.contains("الإنجليزية")) {
            return "en";
        }
        return "ar";
    }

    /** Any character in the Arabic unicode block ⇒ Arabic. */
    private static boolean containsArabic(String text) {
        if (text == null) return false;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c >= 0x0600 && c <= 0x06FF) return true;
        }
        return false;
    }
}
