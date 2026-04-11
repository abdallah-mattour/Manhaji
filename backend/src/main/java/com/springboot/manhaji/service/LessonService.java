package com.springboot.manhaji.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.springboot.manhaji.dto.response.LessonResponse;
import com.springboot.manhaji.dto.response.LessonSummaryResponse;
import com.springboot.manhaji.dto.response.SubjectResponse;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Progress;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.enums.CompletionStatus;
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
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final SubjectRepository subjectRepository;
    private final LessonRepository lessonRepository;
    private final ProgressRepository progressRepository;
    private final StudentRepository studentRepository;
    private final ObjectMapper objectMapper;

    public List<SubjectResponse> getSubjectsByGrade(Integer gradeLevel, Long studentId) {
        List<Subject> subjects = subjectRepository.findByGradeLevel(gradeLevel);
        return subjects.stream().map(subject -> {
            List<Lesson> lessons = lessonRepository.findBySubjectIdOrderByOrderIndexAsc(subject.getId());
            long completed = lessons.stream()
                    .filter(lesson -> {
                        Optional<Progress> p = progressRepository.findByStudentIdAndLessonId(studentId, lesson.getId());
                        return p.isPresent() && (p.get().getCompletionStatus() == CompletionStatus.COMPLETED
                                || p.get().getCompletionStatus() == CompletionStatus.MASTERED);
                    })
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
        return lessons.stream().map(lesson -> {
            Optional<Progress> progress = progressRepository.findByStudentIdAndLessonId(studentId, lesson.getId());
            return LessonSummaryResponse.builder()
                    .id(lesson.getId())
                    .title(lesson.getTitle())
                    .orderIndex(lesson.getOrderIndex())
                    .semesterNumber(lesson.getSemesterNumber() != null ? lesson.getSemesterNumber() : 1)
                    .completionStatus(progress.map(Progress::getCompletionStatus).orElse(CompletionStatus.NOT_STARTED))
                    .masteryLevel(progress.map(Progress::getMasteryLevel).orElse(0.0))
                    .build();
        }).toList();
    }

    public LessonResponse getLessonDetail(Long lessonId, Long studentId) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResourceNotFoundException("Lesson", lessonId));

        // Create or update progress record
        Progress progress = progressRepository.findByStudentIdAndLessonId(studentId, lessonId)
                .orElseGet(() -> {
                    Progress p = new Progress();
                    p.setStudent(studentRepository.findById(studentId)
                            .orElseThrow(() -> new ResourceNotFoundException("Student", studentId)));
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
