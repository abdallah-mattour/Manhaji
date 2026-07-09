package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.PronunciationScoreResponse.WordResult;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Tier 4 (2026-07): word-level comparison between a READING passage and the
 * child's transcribed read-aloud. Ported from the team's reading prototype
 * (TextComparisonService) and adapted to emit an ordered per-word result list
 * so the Flutter widget can color the passage in place.
 *
 * <p>Algorithm: tokenize both texts on whitespace/punctuation, normalize each
 * token (strip tashkeel, unify hamza/alef variants, ة→ه, ى→ي, lowercase),
 * then greedily match each original word against the first unmatched
 * transcribed word. Accuracy = matched / total original words.
 */
@Service
public class ReadingComparisonService {

    /**
     * @param accuracy    0–100 percentage of passage words correctly read
     * @param totalWords  non-empty words in the passage (denominator)
     * @param wordResults one entry per passage word, in passage order
     */
    public record ComparisonResult(int accuracy, int totalWords, List<WordResult> wordResults) {}

    public ComparisonResult compare(String originalText, String recognizedText) {
        List<String> originalTokens = tokenize(originalText);
        List<String> recognizedTokens = tokenize(recognizedText);

        List<String> normalizedOriginal = originalTokens.stream().map(this::normalize).toList();
        List<String> normalizedRecognized = recognizedTokens.stream().map(this::normalize).toList();

        boolean[] recognizedMatched = new boolean[normalizedRecognized.size()];
        List<WordResult> results = new ArrayList<>(originalTokens.size());
        int correct = 0;
        int total = 0;

        for (int i = 0; i < normalizedOriginal.size(); i++) {
            String origNorm = normalizedOriginal.get(i);
            if (origNorm.isEmpty()) continue;
            total++;

            boolean found = false;
            for (int j = 0; j < normalizedRecognized.size(); j++) {
                if (!recognizedMatched[j] && normalizedRecognized.get(j).equals(origNorm)) {
                    recognizedMatched[j] = true;
                    found = true;
                    break;
                }
            }
            if (found) correct++;
            results.add(new WordResult(originalTokens.get(i), found));
        }

        int accuracy = total == 0 ? 0 : (int) Math.round((double) correct / total * 100.0);
        return new ComparisonResult(
                Math.max(0, Math.min(100, accuracy)),
                total,
                Collections.unmodifiableList(results));
    }

    private List<String> tokenize(String text) {
        if (text == null || text.isBlank()) return List.of();
        String collapsed = text.trim().replaceAll("\\s+", " ");
        return Arrays.stream(collapsed.split("[\\s\\p{Punct}،؟!.:;]+"))
                .filter(w -> !w.isEmpty())
                .toList();
    }

    /**
     * Same normalization family as {@code PronunciationScoringService} plus the
     * hamza-carrier unifications children commonly blur when reading aloud.
     */
    String normalize(String word) {
        if (word == null) return "";
        String t = word.trim().toLowerCase();
        t = t.replace("ـ", "");                    // tatweel
        t = t.replaceAll("[\\u064B-\\u065F\\u0670]", ""); // tashkeel + superscript alef
        t = t.replace('أ', 'ا');
        t = t.replace('إ', 'ا');
        t = t.replace('آ', 'ا');
        t = t.replace('ٱ', 'ا');
        t = t.replace('ؤ', 'و');
        t = t.replace('ئ', 'ي');
        t = t.replace('ة', 'ه');
        t = t.replace('ى', 'ي');
        t = t.replaceAll("[^\\p{L}\\p{N}]", "");
        return t;
    }
}
