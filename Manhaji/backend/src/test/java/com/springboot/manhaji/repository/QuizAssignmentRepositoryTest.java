package com.springboot.manhaji.repository;

import com.springboot.manhaji.entity.*;
import com.springboot.manhaji.entity.enums.QuizAssignmentStudentStatus;
import com.springboot.manhaji.entity.enums.QuizStatus;
import com.springboot.manhaji.entity.enums.QuizType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:quiz_assignment_test;MODE=MySQL;DATABASE_TO_LOWER=TRUE;CASE_INSENSITIVE_IDENTIFIERS=TRUE",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@Transactional
class QuizAssignmentRepositoryTest {

    @Autowired private SchoolRepository schoolRepository;
    @Autowired private SubjectRepository subjectRepository;
    @Autowired private TeacherRepository teacherRepository;
    @Autowired private StudentRepository studentRepository;
    @Autowired private QuizRepository quizRepository;
    @Autowired private QuizAssignmentRepository quizAssignmentRepository;
    @Autowired private QuizAssignmentStudentRepository quizAssignmentStudentRepository;
    @Autowired private AttemptRepository attemptRepository;

    @Test
    @DisplayName("persists quiz assignment, assignment student, and nullable attempt assignment")
    void persistsAssignmentFoundation() {
        Fixture fixture = createFixture();

        QuizAssignment assignment = new QuizAssignment();
        assignment.setQuiz(fixture.quiz());
        assignment.setTeacher(fixture.teacher());
        assignment.setSubject(fixture.subject());
        assignment.setSchool(fixture.school());
        assignment.setGradeLevel(1);
        assignment.setMaxAttempts(2);
        assignment = quizAssignmentRepository.saveAndFlush(assignment);

        QuizAssignmentStudent assignedStudent = new QuizAssignmentStudent();
        assignedStudent.setQuizAssignment(assignment);
        assignedStudent.setStudent(fixture.student());
        assignedStudent = quizAssignmentStudentRepository.saveAndFlush(assignedStudent);

        Attempt oldFlowAttempt = new Attempt();
        oldFlowAttempt.setStudent(fixture.student());
        oldFlowAttempt.setQuiz(fixture.quiz());
        oldFlowAttempt = attemptRepository.saveAndFlush(oldFlowAttempt);

        Attempt assignedAttempt = new Attempt();
        assignedAttempt.setStudent(fixture.student());
        assignedAttempt.setQuiz(fixture.quiz());
        assignedAttempt.setQuizAssignment(assignment);
        assignedAttempt = attemptRepository.saveAndFlush(assignedAttempt);

        assertThat(quizAssignmentRepository.existsByQuizId(fixture.quiz().getId())).isTrue();
        assertThat(quizAssignmentStudentRepository.existsByQuizAssignmentIdAndStudentId(
                assignment.getId(), fixture.student().getId())).isTrue();
        assertThat(quizAssignmentStudentRepository.findByStudentIdAndStatus(
                fixture.student().getId(), QuizAssignmentStudentStatus.ASSIGNED))
                .extracting(QuizAssignmentStudent::getId)
                .containsExactly(assignedStudent.getId());
        assertThat(oldFlowAttempt.getQuizAssignment()).isNull();
        assertThat(assignedAttempt.getQuizAssignment().getId()).isEqualTo(assignment.getId());
    }

    @Test
    @DisplayName("assignment student pair is unique")
    void assignmentStudentPairIsUnique() {
        Fixture fixture = createFixture();
        QuizAssignment assignment = new QuizAssignment();
        assignment.setQuiz(fixture.quiz());
        assignment.setTeacher(fixture.teacher());
        assignment.setSubject(fixture.subject());
        assignment.setSchool(fixture.school());
        assignment.setGradeLevel(1);
        assignment = quizAssignmentRepository.saveAndFlush(assignment);

        QuizAssignmentStudent first = new QuizAssignmentStudent();
        first.setQuizAssignment(assignment);
        first.setStudent(fixture.student());
        quizAssignmentStudentRepository.saveAndFlush(first);

        QuizAssignmentStudent duplicate = new QuizAssignmentStudent();
        duplicate.setQuizAssignment(assignment);
        duplicate.setStudent(fixture.student());

        assertThatThrownBy(() -> quizAssignmentStudentRepository.saveAndFlush(duplicate))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private Fixture createFixture() {
        School school = new School();
        school.setName("مدرسة الاختبار");
        school = schoolRepository.saveAndFlush(school);

        Subject subject = new Subject();
        subject.setName("مادة الاختبار " + System.nanoTime());
        subject.setGradeLevel(1);
        subject = subjectRepository.saveAndFlush(subject);

        Teacher teacher = new Teacher();
        teacher.setFullName("أستاذة الاختبار");
        teacher.setEmail("teacher-" + System.nanoTime() + "@example.com");
        teacher.setPasswordHash("hash");
        teacher.setSchool(school);
        teacher = teacherRepository.saveAndFlush(teacher);

        Student student = new Student();
        student.setFullName("طالب الاختبار");
        student.setEmail("student-" + System.nanoTime() + "@example.com");
        student.setPasswordHash("hash");
        student.setSchool(school);
        student.setGradeLevel(1);
        student = studentRepository.saveAndFlush(student);

        Quiz quiz = new Quiz();
        quiz.setTitle("اختبار محفوظ");
        quiz.setGamified(false);
        quiz.setGeneratedFromLesson(false);
        quiz.setQuizType(QuizType.TEACHER_ASSIGNED);
        quiz.setStatus(QuizStatus.DRAFT);
        quiz.setSubject(subject);
        quiz.setCreatedByTeacher(teacher);
        quiz.setQuestions(List.of());
        quiz = quizRepository.saveAndFlush(quiz);

        return new Fixture(school, subject, teacher, student, quiz);
    }

    private record Fixture(
            School school,
            Subject subject,
            Teacher teacher,
            Student student,
            Quiz quiz) {
    }
}
