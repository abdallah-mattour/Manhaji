package com.springboot.manhaji.service.ai;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class PronunciationScoringService {

    public int score(String expected, String transcribed) {
        if (expected == null || expected.isBlank()) return 0;
        if (transcribed == null || transcribed.isBlank()) return 0;

        String a = normalize(expected);
        String b = normalize(transcribed);
        if (a.equals(b)) return 100;

        int distance = levenshtein(a, b);
        int maxLen = Math.max(a.length(), b.length());
        if (maxLen == 0) return 0;

        int similarity = (int) Math.round((1.0 - (double) distance / maxLen) * 100);
        return Math.max(0, Math.min(100, similarity));
    }

    public String rating(int score) {
        if (score >= 90) return "ممتاز";
        if (score >= 75) return "جيد جداً";
        if (score >= 60) return "جيد";
        if (score >= 40) return "حاول مرة أخرى";
        return "لم أسمعك جيداً";
    }

    public String feedback(int score, String expected) {
        if (score >= 90) return "نطق رائع! أحسنت.";
        if (score >= 75) return "نطق جيد جداً، استمر.";
        if (score >= 60) return "جيد، حاول النطق بوضوح أكثر.";
        if (score >= 40) return "كرر بعدي: " + expected;
        return "تأكد من النطق بصوت واضح.";
    }

    public boolean isCorrect(int score) {
        return score >= 60;
    }

    public int starsForScore(int score) {
        if (score >= 90) return 3;
        if (score >= 75) return 2;
        if (score >= 60) return 1;
        return 0;
    }

    private String normalize(String text) {
        String t = text.trim().toLowerCase();
        t = t.replaceAll("[\\u064B-\\u065F\\u0670]", "");
        t = t.replace('\u0623', '\u0627');
        t = t.replace('\u0625', '\u0627');
        t = t.replace('\u0622', '\u0627');
        t = t.replace('\u0629', '\u0647');
        t = t.replace('\u0649', '\u064A');
        t = t.replaceAll("[^\\p{L}\\p{N}]+", "");
        return t;
    }

    private int levenshtein(String a, String b) {
        int[] prev = new int[b.length() + 1];
        int[] curr = new int[b.length() + 1];
        for (int j = 0; j <= b.length(); j++) prev[j] = j;

        for (int i = 1; i <= a.length(); i++) {
            curr[0] = i;
            for (int j = 1; j <= b.length(); j++) {
                int cost = (a.charAt(i - 1) == b.charAt(j - 1)) ? 0 : 1;
                curr[j] = Math.min(Math.min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
            }
            int[] tmp = prev;
            prev = curr;
            curr = tmp;
        }
        return prev[b.length()];
    }
}
