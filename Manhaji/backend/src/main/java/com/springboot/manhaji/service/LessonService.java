package com.springboot.manhaji.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.dto.response.LessonResponse;
import com.springboot.manhaji.dto.response.LessonSummaryResponse;
import com.springboot.manhaji.dto.response.SubjectResponse;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.exception.BadRequestException;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import com.springboot.manhaji.repository.StudentRepository;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final ProgressRepository progressRepository;
    private final StudentRepository studentRepository;
    private final ObjectMapper objectMapper;

    /**
     * Post-review fix (2026-05-24): the previous implementation ran
     * {@code findByStudentIdAndLessonId} once per lesson in every subject —
     * for Grade 1 that's ~112 progress queries per home-screen load. Now we
     * pull the student's Progress rows once and index them by lessonId, then
     * iterate in memory.
     */
    public List<SubjectResponse> getSubjectsByGrade(Integer gradeLevel, Long studentId) {
        List<Subject> subjects = subjectRepository.findByGradeLevel(gradeLevel);
        Map<Long, Progress> progressByLessonId = loadProgressByLessonId(studentId);

        return subjects.stream().map(subject -> {
            List<Lesson> lessons = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subject.getId());
            long completed = lessons.stream()
                    .map(l -> progressByLessonId.get(l.getId()))
                    .filter(p -> p != null
                            && (p.getCompletionStatus() == CompletionStatus.COMPLETED
                            || p.getCompletionStatus() == CompletionStatus.MASTERED))
                    .count();
            return SubjectResponse.builder()
                    .id(subject.getId())
                    .name(subject.getName())
                    .gradeLevel(subject.getGradeLevel())
                    .totalLessons(lessons.size())
                    .completedLessons((int) completed)
                    .build();
        }).toList();
    }

    public List<LessonSummaryResponse> getLessonsBySubject(Long subjectId, Long studentId) {
        List<Lesson> lessons = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subjectId);
        Map<Long, Progress> progressByLessonId = loadProgressByLessonId(studentId);

        return lessons.stream().map(lesson -> {
            Progress progress = progressByLessonId.get(lesson.getId());
            return LessonSummaryResponse.builder()
                    .id(lesson.getId())
                    .title(lesson.getTitle())
                    .orderIndex(lesson.getOrderIndex())
                    .semesterNumber(lesson.getSemesterNumber() != null ? lesson.getSemesterNumber() : 1)
                    .completionStatus(progress != null
                            ? progress.getCompletionStatus()
                            : CompletionStatus.NOT_STARTED)
                    .masteryLevel(progress != null ? progress.getMasteryLevel() : 0.0)
                    .build();
        }).toList();
    }

    public LessonResponse getLessonDetail(Long lessonId, Long studentId) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson", lessonId));

        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new ResourceNotFoundException("Student", studentId));

        // Post-review fix (2026-05-24): block Progress creation for lessons
        // outside the student's grade. Previously a Grade 1 student could
        // request /api/lessons/{aGrade4LessonId} and seed a Progress row in
        // Grade 4 content, silently polluting teacher analytics. Doesn't bite
        // today (only Grade 1+2 are seeded) but matters the moment Grade 3/4
        // ship.
        if (lesson.getGradeLevel() != null
                && student.getGradeLevel() != null
                && !lesson.getGradeLevel().equals(student.getGradeLevel())) {
            throw new BadRequestException(
                    "هذا الدرس ليس لصفك. يرجى اختيار درس من صفك.");
        }

        // Create or update progress record
        Progress progress = progressRepository.findByStudentIdAndLessonId(studentId, lessonId)
                .orElseGet(() -> {
                    Progress p = new Progress();
                    p.setStudent(student);
                    p.setLesson(lesson);
                    p.setCompletionStatus(CompletionStatus.IN_PROGRESS);
                    return p;
                });
        progress.setLastAccessedAt(LocalDateTime.now());
        if (progress.getCompletionStatus() == CompletionStatus.NOT_STARTED) {
            progress.setCompletionStatus(CompletionStatus.IN_PROGRESS);
        }
        progressRepository.save(progress);

        List<String> imageUrlList = parseImageUrls(lesson.getImageUrls());

        return LessonResponse.builder()
                .id(lesson.getId())
                .title(lesson.getTitle())
                .content(lesson.getContent())
                .audioUrl(lesson.getAudioUrl())
                .imageUrls(imageUrlList)
                .objectives(lesson.getObjectives())
                .orderIndex(lesson.getOrderIndex())
                .semesterNumber(lesson.getSemesterNumber() != null ? lesson.getSemesterNumber() : 1)
                .subjectId(lesson.getSubject().getId())
                .subjectName(lesson.getSubject().getName())
                .gradeLevel(lesson.getGradeLevel())
                .totalQuestions(lesson.getQuestions().size())
                .build();
    }

    private Map<Long, Progress> loadProgressByLessonId(Long studentId) {
        return progressRepository.findByStudentId(studentId).stream()
                .collect(Collectors.toMap(
                        p -> p.getLesson().getId(),
                        p -> p,
                        (a, b) -> b));
    }

    private List<String> parseImageUrls(String imageUrlsJson) {
        if (imageUrlsJson == null || imageUrlsJson.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(imageUrlsJson, new TypeReference<>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }
}
