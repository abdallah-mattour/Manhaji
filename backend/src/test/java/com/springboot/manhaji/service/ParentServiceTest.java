package com.springboot.manhaji.service;

import com.springboot.manhaji.dto.response.ParentDashboardResponse;
import com.springboot.manhaji.dto.response.StudentDetailResponse;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.AttemptStatus;
import com.springboot.manhaji.entity.enums.CompletionStatus;
import com.springboot.manhaji.entity.enums.Role;
import com.springboot.manhaji.exception.ResourceNotFoundException;
import com.springboot.manhaji.exception.UnauthorizedException;
import com.springboot.manhaji.repository.*;
import com.springboot.manhaji.service.support.ProgressMetrics;
import com.springboot.manhaji.support.TestMessages;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ParentServiceTest {

    @Mock private ParentRepository parentRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private ProgressRepository progressRepository;
    @Mock private AttemptRepository attemptRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private LessonRepository lessonRepository;

    private ParentService parentService;

    private Parent parent;
    private Student child;

    @BeforeEach
    void setUp() {
        ProgressMetrics metrics = new ProgressMetrics(subjectRepository, lessonRepository);
        parentService = new ParentService(
                parentRepository, studentRepository, progressRepository,
                attemptRepository, lessonRepository, metrics, TestMessages.create());

        parent = new Parent();
        parent.setId(100L);
        parent.setFullName("ولي الأمر");
        parent.setRole(Role.PARENT);

        child = new Student();
        child.setId(1L);
        child.setFullName("الطفل أحمد");
        child.setGradeLevel(1);
        child.setTotalPoints(50);
        child.setCurrentStreak(2);
        child.setParent(parent);
        child.setLastLoginAt(LocalDateTime.now().minusDays(1));
    }

    // ==================== getDashboard Tests ====================

    @Nested
    @DisplayName("getDashboard()")
    class GetDashboardTests {

        @Test
        @DisplayName("should return dashboard with children summaries")
        void getDashboardSuccess() {
            when(parentRepository.findById(100L)).thenReturn(Optional.of(parent));
            when(studentRepository.findByParentId(100L)).thenReturn(List.of(child));
            when(progressRepository.findByStudentId(1L)).thenReturn(List.of(
                    createProgress(CompletionStatus.COMPLETED, 85.0),
                    createProgress(CompletionStatus.IN_PROGRESS, 40.0)
            ));
            when(lessonRepository.findByGradeLevelOrderByOrderIndexAsc(1)).thenReturn(
                    List.of(new Lesson(), new Lesson(), new Lesson(), new Lesson(), new Lesson())
            );

            ParentDashboardResponse response = parentService.getDashboard(100L);

            assertThat(response.getParentId()).isEqualTo(100L);
            assertThat(response.getFullName()).isEqualTo("ولي الأمر");
            assertThat(response.getChildren()).hasSize(1);

            var childSummary = response.getChildren().get(0);
            assertThat(childSummary.getStudentId()).isEqualTo(1L);
            assertThat(childSummary.getFullName()).isEqualTo("الطفل أحمد");
            assertThat(childSummary.getLessonsCompleted()).isEqualTo(1);
            assertThat(childSummary.getTotalLessons()).isEqualTo(5);
            assertThat(childSummary.getTotalPoints()).isEqualTo(50);
        }

        @Test
        @DisplayName("should return empty children list when no students linked")
        void emptyChildrenList() {
            when(parentRepository.findById(100L)).thenReturn(Optional.of(parent));
            when(studentRepository.findByParentId(100L)).thenReturn(List.of());

            ParentDashboardResponse response = parentService.getDashboard(100L);

            assertThat(response.getChildren()).isEmpty();
        }

        @Test
        @DisplayName("should throw when parent not found")
        void parentNotFound() {
            when(parentRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> parentService.getDashboard(999L))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    // ==================== getChildDetail Tests ====================

    @Nested
    @DisplayName("getChildDetail()")
    class GetChildDetailTests {

        @Test
        @DisplayName("should return child detail when parent owns the child")
        void getChildDetailSuccess() {
            when(parentRepository.findById(100L)).thenReturn(Optional.of(parent));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(child));
            when(progressRepository.findByStudentId(1L)).thenReturn(List.of(
                    createProgress(CompletionStatus.COMPLETED, 90.0)
            ));
            when(attemptRepository.findByStudentIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(
                    createAttempt(AttemptStatus.GRADED, 88.0)
            ));
            when(subjectRepository.findByGradeLevel(1)).thenReturn(List.of());

            StudentDetailResponse detail = parentService.getChildDetail(100L, 1L);

            assertThat(detail.getStudentId()).isEqualTo(1L);
            assertThat(detail.getFullName()).isEqualTo("الطفل أحمد");
            assertThat(detail.getLessonsCompleted()).isEqualTo(1);
            assertThat(detail.getOverallMastery()).isEqualTo(90.0);
            assertThat(detail.getAverageScore()).isEqualTo(88.0);
        }

        @Test
        @DisplayName("should deny access to other parent's child")
        void denyAccessOtherParentChild() {
            Parent otherParent = new Parent();
            otherParent.setId(200L);

            Student otherChild = new Student();
            otherChild.setId(2L);
            otherChild.setFullName("طفل آخر");
            otherChild.setParent(otherParent); // belongs to different parent

            when(parentRepository.findById(100L)).thenReturn(Optional.of(parent));
            when(studentRepository.findById(2L)).thenReturn(Optional.of(otherChild));

            assertThatThrownBy(() -> parentService.getChildDetail(100L, 2L))
                    .isInstanceOf(UnauthorizedException.class)
                    .hasMessage("هذا الطالب ليس مرتبطاً بحسابك");
        }

        @Test
        @DisplayName("should deny access to unlinked student (null parent)")
        void denyAccessNullParent() {
            Student unlinkedChild = new Student();
            unlinkedChild.setId(3L);
            unlinkedChild.setParent(null); // no parent linked

            when(parentRepository.findById(100L)).thenReturn(Optional.of(parent));
            when(studentRepository.findById(3L)).thenReturn(Optional.of(unlinkedChild));

            assertThatThrownBy(() -> parentService.getChildDetail(100L, 3L))
                    .isInstanceOf(UnauthorizedException.class);
        }

        @Test
        @DisplayName("should calculate averages correctly with mixed scores")
        void calculateAveragesCorrectly() {
            when(parentRepository.findById(100L)).thenReturn(Optional.of(parent));
            when(studentRepository.findById(1L)).thenReturn(Optional.of(child));
            when(progressRepository.findByStudentId(1L)).thenReturn(List.of(
                    createProgress(CompletionStatus.COMPLETED, 80.0),
                    createProgress(CompletionStatus.COMPLETED, 60.0),
                    createProgress(CompletionStatus.IN_PROGRESS, 30.0)
            ));
            Attempt a1 = createAttempt(AttemptStatus.GRADED, 90.0);
            Attempt a2 = createAttempt(AttemptStatus.GRADED, 70.0);
            Attempt a3 = createAttempt(AttemptStatus.IN_PROGRESS, null); // not graded
            when(attemptRepository.findByStudentIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(a1, a2, a3));
            when(subjectRepository.findByGradeLevel(1)).thenReturn(List.of());

            StudentDetailResponse detail = parentService.getChildDetail(100L, 1L);

            assertThat(detail.getLessonsCompleted()).isEqualTo(2);
            assertThat(detail.getLessonsInProgress()).isEqualTo(1);
            // (80 + 60 + 30) / 3 = 56.67
            assertThat(detail.getOverallMastery()).isEqualTo(56.67);
            // Only graded: (90 + 70) / 2 = 80
            assertThat(detail.getAverageScore()).isEqualTo(80.0);
            assertThat(detail.getTotalAttempts()).isEqualTo(3);
        }
    }

    // ==================== Helpers ====================

    private Progress createProgress(CompletionStatus status, double mastery) {
        Progress p = new Progress();
        p.setCompletionStatus(status);
        p.setMasteryLevel(mastery);
        return p;
    }

    private Attempt createAttempt(AttemptStatus status, Double score) {
        Attempt a = new Attempt();
        a.setStatus(status);
        a.setScore(score);
        return a;
    }
}
