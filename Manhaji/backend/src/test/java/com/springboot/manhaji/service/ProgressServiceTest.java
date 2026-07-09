package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.ProgressSummaryResponse;
import com.springboot.manhaji.dto.response.RecentActivityResponse;
import com.springboot.manhaji.entity.Attempt;
import com.springboot.manhaji.entity.Lesson;
import com.springboot.manhaji.entity.Quiz;
import com.springboot.manhaji.entity.Student;
import com.springboot.manhaji.entity.Subject;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.repository.AttemptRepository;
import com.springboot.manhaji.repository.LessonRepository;
import com.springboot.manhaji.repository.ProgressRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProgressServiceTest {

    @Mock private StudentRepository studentRepository;
    @Mock private ProgressRepository progressRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private LessonRepository lessonRepository;

    private ProgressService service;
    private Student student;
    private Subject arabic;

    @BeforeEach
    void setUp() {
        service = new ProgressService(
                studentRepository,
                progressRepository,
                attemptRepository,
                subjectRepository,
                lessonRepository);

        student = new Student();
        student.setId(1L);
        student.setFullName("Student One");
        student.setGradeLevel(1);
        student.setTotalPoints(100);
        student.setCurrentStreak(2);

        arabic = new Subject();
        arabic.setId(100L);
        arabic.setName("اللغة العربية");
        arabic.setGradeLevel(1);
    }

    private void stubSummaryCollaborators(List<Attempt> attempts) {
        when(studentRepository.findById(1L)).thenReturn(Optional.of(student));
        when(progressRepository.findByStudentId(1L)).thenReturn(List.of());
        when(attemptRepository.findByStudentIdOrderByCreatedAtDesc(1L)).thenReturn(attempts);
        when(lessonRepository.findByGradeLevelOrderByOrderIndexAsc(1)).thenReturn(List.of());
        when(subjectRepository.findByGradeLevel(1)).thenReturn(List.of());
    }

    private Attempt gradedAttempt(Quiz quiz, double score) {
        Attempt attempt = new Attempt();
        attempt.setId(9L);
        attempt.setQuiz(quiz);
        attempt.setStatus(AttemptStatus.GRADED);
        attempt.setScore(score);
        attempt.setSubmittedAt(LocalDateTime.of(2026, 7, 6, 10, 0));
        return attempt;
    }

    @Test
    @DisplayName("summary resolves subject from lesson for legacy lesson quizzes")
    void summaryResolvesSubjectFromLessonForLessonQuizzes() {
        Lesson lesson = new Lesson();
        lesson.setId(200L);
        lesson.setTitle("حرف الراء");
        lesson.setSubject(arabic);
        Quiz lessonQuiz = new Quiz();
        lessonQuiz.setId(50L);
        lessonQuiz.setTitle("اختبار الدرس");
        lessonQuiz.setLesson(lesson);
        lessonQuiz.setSubject(null);
        stubSummaryCollaborators(List.of(gradedAttempt(lessonQuiz, 80.0)));

        ProgressSummaryResponse summary = service.getProgressSummary(1L);

        assertThat(summary.getRecentActivity())
                .extracting(RecentActivityResponse::getSubjectName)
                .containsExactly("اللغة العربية");
    }

    @Test
    @DisplayName("summary does not throw for teacher-assigned quiz with null lesson")
    void summaryDoesNotThrowForTeacherAssignedQuizWithNullLesson() {
        Quiz teacherQuiz = new Quiz();
        teacherQuiz.setId(51L);
        teacherQuiz.setTitle("اختبار ديمو: حروف اللغة العربية");
        teacherQuiz.setLesson(null);
        teacherQuiz.setSubject(arabic);
        stubSummaryCollaborators(List.of(gradedAttempt(teacherQuiz, 100.0)));

        ProgressSummaryResponse summary = service.getProgressSummary(1L);

        assertThat(summary.getTotalQuizzesTaken()).isEqualTo(1);
        assertThat(summary.getAverageQuizScore()).isEqualTo(100.0);
        assertThat(summary.getRecentActivity()).hasSize(1);
        RecentActivityResponse activity = summary.getRecentActivity().get(0);
        assertThat(activity.getType()).isEqualTo("QUIZ_COMPLETED");
        assertThat(activity.getSubjectName()).isEqualTo("اللغة العربية");
    }

    @Test
    @DisplayName("summary falls back to null subject when quiz has no lesson and no subject")
    void summaryFallsBackToNullSubjectWhenQuizHasNoLessonAndNoSubject() {
        Quiz orphanQuiz = new Quiz();
        orphanQuiz.setId(52L);
        orphanQuiz.setTitle("اختبار بدون مادة");
        orphanQuiz.setLesson(null);
        orphanQuiz.setSubject(null);
        stubSummaryCollaborators(List.of(gradedAttempt(orphanQuiz, 60.0)));

        ProgressSummaryResponse summary = service.getProgressSummary(1L);

        assertThat(summary.getRecentActivity()).hasSize(1);
        assertThat(summary.getRecentActivity().get(0).getSubjectName()).isNull();
    }
}
