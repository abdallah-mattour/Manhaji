package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.LearningPathResponse;
import com.springboot.manhaji.entity.LearningPath;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.LearningPathRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.springboot.manhaji.service.ai.GeminiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LearningPathService {

    private final StudentRepository studentRepository;
    private final ProgressRepository progressRepository;
    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final LearningPathRepository learningPathRepository;
    private final GeminiService geminiService;
    private final ObjectMapper objectMapper;

    @Transactional
    public LearningPathResponse generatePath(Long studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        String weakAreas = buildWeakAreas(student);
        String completedLessons = buildCompletedLessons(student);

        String aiResponse = geminiService.generateLearningPath(
                student.getFullName(), student.getGradeLevel(), weakAreas, completedLessons);

        // `learning_paths.recommendations` is a MySQL JSON column — the value
        // MUST be valid JSON or the INSERT fails with "Invalid JSON text".
        // Gemini wraps JSON in ```json``` fences and sometimes returns prose,
        // so: strip fences, then verify it actually parses; if not (or no AI),
        // use the Jackson-built fallback which is guaranteed valid JSON.
        String recommendations = asValidJson(aiResponse);
        if (recommendations == null) {
            recommendations = buildFallbackRecommendations(student);
        }

        LearningPath path = learningPathRepository.findByStudentId(studentId)
                .orElse(new LearningPath());
        path.setStudent(student);
        path.setRecommendations(recommendations);
        path = learningPathRepository.save(path);

        return toResponse(path);
    }

    public LearningPathResponse getPath(Long studentId) {
        LearningPath path = learningPathRepository.findByStudentId(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("LearningPath for student", studentId));
        return toResponse(path);
    }

    private String buildWeakAreas(Student student) {
        List<Progress> progressRecords = progressRepository.findByStudentId(student.getId());
        List<Subject> subjects = subjectRepository.findByGradeLevel(student.getGradeLevel());

        Map<Long, List<Progress>> bySubject = progressRecords.stream()
                .filter(p -> p.getLesson() != null && p.getLesson().getSubject() != null)
                .collect(Collectors.groupingBy(p -> p.getLesson().getSubject().getId()));

        StringBuilder sb = new StringBuilder();
        for (Subject subject : subjects) {
            List<Progress> sp = bySubject.getOrDefault(subject.getId(), List.of());
            double avg = sp.stream()
                    .mapToDouble(p -> p.getMasteryLevel() == null ? 0.0 : p.getMasteryLevel())
                    .average().orElse(0.0);
            if (avg < 60) {
                sb.append(String.format("%s (إتقان %.0f%%)\n", subject.getName(), avg));
            }
        }
        return sb.isEmpty() ? "لا توجد مواضيع ضعيفة" : sb.toString();
    }

    private String buildCompletedLessons(Student student) {
        // MASTERED counts as completed (see ProgressMetrics.countCompleted) —
        // otherwise a top student who aced every lesson looks like she did
        // nothing, and the learning-path AI recommends what she's already done.
        List<Progress> completed = progressRepository.findByStudentId(student.getId()).stream()
                .filter(p -> p.getCompletionStatus() == CompletionStatus.COMPLETED
                        || p.getCompletionStatus() == CompletionStatus.MASTERED)
                .toList();
        if (completed.isEmpty()) return "لا توجد دروس مكتملة بعد";

        return completed.stream()
                .filter(p -> p.getLesson() != null)
                .map(p -> p.getLesson().getTitle())
                .collect(Collectors.joining("، "));
    }

    /**
     * Returns the AI response as valid JSON, or {@code null} if it can't be
     * used. Strips ```json``` fences then parses to confirm validity — required
     * because {@code recommendations} is a MySQL JSON column that rejects any
     * non-JSON text (the cause of the "Invalid JSON text" INSERT crash).
     */
    private String asValidJson(String aiResponse) {
        if (aiResponse == null) return null;
        String cleaned = GeminiService.stripJsonFences(aiResponse);
        if (cleaned.isBlank()) return null;
        try {
            // Must be a JSON object/array, not a bare string or prose.
            var node = objectMapper.readTree(cleaned);
            if (node.isObject() || node.isArray()) {
                return cleaned;
            }
            return null;
        } catch (Exception e) {
            log.warn("Learning-path AI response is not valid JSON, using fallback: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Builds the fallback recommendations as guaranteed-valid JSON via Jackson
     * (the previous String.format approach emitted a Java list literal —
     * {@code [a, b]} with no quotes — which is invalid JSON and crashed the
     * INSERT into the JSON column).
     */
    private String buildFallbackRecommendations(Student student) {
        List<Progress> progressRecords = progressRepository.findByStudentId(student.getId());
        List<Lesson> allLessons = lessonRepository
                .findByGradeLevelOrderByOrderIndexAsc(student.getGradeLevel());

        List<Long> completedIds = progressRecords.stream()
                .filter(p -> (p.getCompletionStatus() == CompletionStatus.COMPLETED
                        || p.getCompletionStatus() == CompletionStatus.MASTERED) && p.getLesson() != null)
                .map(p -> p.getLesson().getId())
                .toList();

        List<Lesson> pending = allLessons.stream()
                .filter(l -> !completedIds.contains(l.getId()))
                .limit(5)
                .toList();

        ObjectNode root = objectMapper.createObjectNode();

        // reviewLessons: the next pending lessons, shaped like the AI output so
        // the Flutter client renders them identically.
        ArrayNode reviewLessons = root.putArray("reviewLessons");
        for (Lesson l : pending) {
            ObjectNode item = reviewLessons.addObject();
            item.put("subject", l.getSubject() != null ? l.getSubject().getName() : "");
            item.put("topic", l.getTitle());
            item.put("reason", "الدرس التالي في خطتك");
        }

        ArrayNode activities = root.putArray("activities");
        activities.add("راجع الدروس التي أكملتها لتثبيت المعلومة");
        activities.add("جرّب اختبار \"تحدَّ نفسك\" لقياس مستواك");

        ArrayNode tips = root.putArray("tips");
        tips.add("تعلّم القليل كل يوم أفضل من الكثير مرة واحدة");
        tips.add("لا تتردد في إعادة الاستماع للدرس عند الحاجة");

        try {
            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            // Unreachable for a plain ObjectNode, but keep a safe literal.
            return "{\"reviewLessons\":[],\"activities\":[],\"tips\":[]}";
        }
    }

    private LearningPathResponse toResponse(LearningPath path) {
        return LearningPathResponse.builder()
                .id(path.getId())
                .studentId(path.getStudent().getId())
                .studentName(path.getStudent().getFullName())
                .recommendations(path.getRecommendations())
                .generatedAt(path.getGeneratedAt())
                .build();
    }
}
