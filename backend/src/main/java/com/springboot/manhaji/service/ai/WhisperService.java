package com.springboot.manhaji.service.ai;

import com.springboot.manhaji.config.AiConfigProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class WhisperService {

    private final AiConfigProperties aiConfig;
    private final WebClient.Builder webClientBuilder;

    private static final String WHISPER_URL = "https://api.openai.com/v1/audio/transcriptions";

    public boolean isAvailable() {
        return aiConfig.getWhisper().isConfigured();
    }

    /**
     * Transcribe audio bytes to text using OpenAI Whisper.
     *
     * @param audioData the audio file bytes
     * @param language  language code ("ar" for Arabic, "en" for English)
     * @return transcribed text, or an error message if unavailable
     */
    public String transcribe(byte[] audioData, String language) {
        if (!isAvailable()) {
            return "خدمة التعرف على الصوت غير متوفرة حالياً";
        }

        try {
            MultipartBodyBuilder builder = new MultipartBodyBuilder();
            builder.part("file", new ByteArrayResource(audioData) {
                @Override
                public String getFilename() {
                    return "audio.webm";
                }
            }).contentType(MediaType.APPLICATION_OCTET_STREAM);
            builder.part("model", "whisper-1");
            builder.part("language", language);

            String responseJson = webClientBuilder.build()
                    .post()
                    .uri(WHISPER_URL)
                    .header("Authorization", "Bearer " + aiConfig.getWhisper().getApiKey())
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(BodyInserters.fromMultipartData(builder.build()))
                    .retrieve()
                    .bodyToMono(String.class)
                    .block(java.time.Duration.ofSeconds(30));

            return extractTranscription(responseJson);
        } catch (Exception e) {
            log.error("Whisper transcription failed: {}", e.getMessage());
            return "حدث خطأ في التعرف على الصوت. حاول مرة أخرى.";
        }
    }

    @SuppressWarnings("unchecked")
    private String extractTranscription(String json) {
        try {
            var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            Map<String, Object> response = mapper.readValue(json, Map.class);
            return (String) response.get("text");
        } catch (Exception e) {
            log.error("Failed to parse Whisper response: {}", e.getMessage());
            return "حدث خطأ في معالجة الصوت";
        }
    }
}
