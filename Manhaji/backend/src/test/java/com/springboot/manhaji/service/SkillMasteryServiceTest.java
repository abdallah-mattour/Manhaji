package com.springboot.manhaji.service;

import com.springboot.manhaji.config.BktConfigProperties;
import com.springboot.manhaji.dto.response.SkillMasteryResponse;
import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.QuestionType;
import com.springboot.manhaji.repository.QuestionRepository;
import com.springboot.manhaji.repository.StudentResponseRepository;
import com.springboot.manhaji.repository.SkillMasteryRepository;
import com.springboot.manhaji.repository.StudentRepository;
import com.springboot.manhaji.repository.SubjectRepository;
import com.springboot.manhaji.service.ai.BktEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * Verifies that {@link SkillMasteryService} folds graded responses into
 * persisted BKT state correctly, and that the read path returns the full
 * axis set for the radar chart.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("SkillMasteryService — BKT ingest + read")
class SkillMasteryServiceTest {

    @Mock private SkillMasteryRepository skillMasteryRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private QuestionRepository questionRepository;
    @Mock private StudentResponseRepository studentResponseRepository;

    private SkillMasteryService service;
    private BktConfigProperties bktConfig;

    private Student student;
    private Subject subject;
    private Lesson lesson;

    @BeforeEach
    void setUp() {
        bktConfig = new BktConfigProperties();
        BktEngine engine = new BktEngine(bktConfig);
        service = new SkillMasteryService(
                skillMasteryRepository, studentRepository, subjectRepository,
                questionRepository, studentResponseRepository, engine, bktConfig);

        subject = new Subject();
        subject.setId(7L);
        subject.setName("الرياضيات");

        lesson = new Lesson();
        lesson.setId(1L);
        lesson.setSubject(subject);

        student = new Student();
        student.setId(5L);
    }

    private Question question(long id, QuestionType type, String subSkill) {
        Question q = new Question();
        q.setId(id);
        q.setType(type);
        q.setSubSkill(subSkill);
        q.setLesson(lesson);
        return q;
    }

    private StudentResponse response(Question q, boolean correct) {
        StudentResponse r = new StudentResponse();
        r.setQuestion(q);
        r.setIsCorrect(correct);
        return r;
    }

    @Test
    @DisplayName("folding a correct answer creates a row above the P(L0) prior")
    void recordCreatesRowAbovePrior() {
        when(studentRepository.findById(5L)).thenReturn(Optional.of(student));
        when(skillMasteryRepository.findByStudentIdAndSubjectIdAndSubSkill(
                anyLong(), anyLong(), any())).thenReturn(Optional.empty());

        Question q = question(1L, QuestionType.SHORT_ANSWER, "computation");
        service.recordResponses(5L, List.of(response(q, true)));

        // Capture what was saved.
        var captor = org.mockito.ArgumentCaptor.forClass(Iterable.class);
        org.mockito.Mockito.verify(skillMasteryRepository).saveAll(captor.capture());
        @SuppressWarnings("unchecked")
        List<SkillMastery> saved = new ArrayList<>();
        ((Iterable<SkillMastery>) captor.getValue()).forEach(saved::add);

        assertThat(saved).hasSize(1);
        SkillMastery sm = saved.get(0);
        assertThat(sm.getSubSkill()).isEqualTo("computation");
        assertThat(sm.getPMastery()).isGreaterThan(bktConfig.getPInit());
        assertThat(sm.getObservationCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("multiple responses on the same skill compound into one row")
    void multipleResponsesCompound() {
        when(studentRepository.findById(5L)).thenReturn(Optional.of(student));
        when(skillMasteryRepository.findByStudentIdAndSubjectIdAndSubSkill(
                anyLong(), anyLong(), any())).thenReturn(Optional.empty());

        Question q1 = question(1L, QuestionType.SHORT_ANSWER, "computation");
        Question q2 = question(2L, QuestionType.SHORT_ANSWER, "computation");
        service.recordResponses(5L, List.of(response(q1, true), response(q2, true)));

        var captor = org.mockito.ArgumentCaptor.forClass(Iterable.class);
        org.mockito.Mockito.verify(skillMasteryRepository).saveAll(captor.capture());
        List<SkillMastery> saved = new ArrayList<>();
        ((Iterable<SkillMastery>) captor.getValue()).forEach(saved::add);

        // Both responses hit the same (subject, sub-skill) cell → one row,
        // two observations.
        assertThat(saved).hasSize(1);
        assertThat(saved.get(0).getObservationCount()).isEqualTo(2);
    }

    @Test
    @DisplayName("getSkillScores returns every subject sub-skill, defaulting unseen ones to the prior")
    void readReturnsFullAxisSet() {
        when(subjectRepository.findById(7L)).thenReturn(Optional.of(subject));
        // Subject teaches two sub-skills via its questions.
        when(questionRepository.findAllBySubjectIdWithLesson(7L)).thenReturn(List.of(
                question(1L, QuestionType.MCQ, "recognition"),
                question(2L, QuestionType.SHORT_ANSWER, "computation")));
        // Student only has a persisted row for one of them.
        SkillMastery existing = new SkillMastery();
        existing.setSubject(subject);
        existing.setSubSkill("computation");
        existing.setPMastery(0.80);
        existing.setObservationCount(4);
        when(skillMasteryRepository.findByStudentIdAndSubjectId(5L, 7L))
                .thenReturn(List.of(existing));

        SkillMasteryResponse resp = service.getSkillScores(5L, 7L);

        assertThat(resp.getSubjectId()).isEqualTo(7L);
        assertThat(resp.getSkills()).hasSize(2);
        // The unseen skill defaults to the prior with zero observations.
        var recognition = resp.getSkills().stream()
                .filter(s -> s.getSubSkill().equals("recognition")).findFirst().orElseThrow();
        assertThat(recognition.getPMastery()).isEqualTo(bktConfig.getPInit());
        assertThat(recognition.getObservationCount()).isZero();
        // The practised skill reflects its persisted value.
        var computation = resp.getSkills().stream()
                .filter(s -> s.getSubSkill().equals("computation")).findFirst().orElseThrow();
        assertThat(computation.getPMastery()).isEqualTo(0.80);
        assertThat(computation.getObservationCount()).isEqualTo(4);
    }
}
