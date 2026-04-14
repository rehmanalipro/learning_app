# Requirements Document

## Introduction

This feature introduces a class-based assignment system for the School Management Flutter app. Currently, teachers have no direct connection to a specific class, and all data (homework, attendance, results, quizzes, exam schedules) is stored without class-scoped ownership. This feature ties each teacher to a specific class and subject during registration, then uses that binding to automatically scope all assignments, attendance marking, and result entry to the teacher's class — eliminating the need to manually select or filter students one by one.

The three roles remain: **Student**, **Teacher**, and **Principal**. Students belong to a class. Each teacher owns one class+subject combination. The Principal has cross-class visibility over everything.

---

## Glossary

- **System**: The School Management Flutter application
- **Teacher**: A registered user with role `teacher`, assigned to one class and one subject
- **Student**: A registered user with role `student`, assigned to one class and section
- **Principal**: A registered user with role `principal`, with read access across all classes
- **Class**: A named group of students (e.g., "Class 1", "Class 2") identified by `className` and `section`
- **ClassBinding**: The association between a Teacher and their assigned `className`, `section`, and `subject`, stored in the `users` Firestore collection
- **ClassRoster**: The list of all Student user documents that share the same `className` and `section` as the Teacher's ClassBinding
- **BulkAssignment**: A single teacher action that creates one Firestore document targeting an entire class (identified by `className` + `section`), rather than per-student documents
- **ClassFilter**: A Firestore query predicate `where('className', isEqualTo, ...).where('section', isEqualTo, ...)` applied when loading data for a specific class
- **TeacherDashboard**: The teacher's home screen showing their class's students, attendance summary, and recent activity
- **Validator**: The input validation logic within forms and service methods

---

## Requirements

### Requirement 1: Teacher Class Registration

**User Story:** As a teacher, I want to register with my assigned class and subject, so that the system knows which class I manage.

#### Acceptance Criteria

1. WHEN a user registers with role `teacher`, THE System SHALL display a class selector (values: 1–10), a section selector (values: A, B, C), and a subject text field on the registration screen.
2. WHEN a teacher submits the registration form with `className`, `section`, and `subject` fields empty, THE Validator SHALL reject the submission and display a field-level error message for each empty field.
3. WHEN a teacher completes registration successfully, THE System SHALL store `className`, `section`, and `subject` fields in the teacher's `users` Firestore document alongside existing fields (`name`, `email`, `role`, `phone`).
4. THE System SHALL enforce that each `className` + `section` combination has at most one registered teacher at any time; IF a second teacher attempts to register for an already-claimed class+section, THEN THE System SHALL reject the registration and display the message "This class already has an assigned teacher."
5. WHEN a teacher logs in, THE System SHALL load the teacher's `className`, `section`, and `subject` from their `users` document and make these values available to all downstream services within the same session.

---

### Requirement 2: Class Roster Loading

**User Story:** As a teacher, I want to see all students in my class, so that I can manage them as a group.

#### Acceptance Criteria

1. WHEN the TeacherDashboard loads, THE System SHALL query the `users` collection with `role == 'student'`, `className == teacher.className`, and `section == teacher.section`, and display the resulting list as the ClassRoster.
2. WHILE the ClassRoster query is in progress, THE TeacherDashboard SHALL display a loading indicator.
3. IF the ClassRoster query returns zero results, THEN THE TeacherDashboard SHALL display the message "No students enrolled in your class yet."
4. THE ClassRoster SHALL display each student's `name`, `rollNumber`, and `email`.
5. WHEN the Principal views the student list, THE System SHALL load students across all classes without applying a ClassFilter.

---

### Requirement 3: Bulk Homework Assignment

**User Story:** As a teacher, I want to assign homework to my entire class with one action, so that I don't have to assign it to each student individually.

#### Acceptance Criteria

1. WHEN a teacher creates a homework assignment, THE System SHALL pre-populate the `className` and `section` fields from the teacher's ClassBinding and make them read-only in the form.
2. WHEN a teacher submits a valid homework assignment form, THE System SHALL create a single `homework_assignments` document with `className`, `section`, `subject`, and `teacherName` fields set from the teacher's ClassBinding.
3. WHEN a student loads their homework list, THE System SHALL apply a ClassFilter (`className == student.className`, `section == student.section`) and return only assignments matching the student's class.
4. IF a student's `className` or `section` field is missing from their user document, THEN THE System SHALL display the message "Class information not found. Please contact your teacher."
5. THE System SHALL allow the Principal to view all homework assignments across all classes without a ClassFilter.

---

### Requirement 4: Class-Based Attendance Marking

**User Story:** As a teacher, I want to mark attendance for all students in my class at once, so that I can complete the daily attendance in one session.

#### Acceptance Criteria

1. WHEN a teacher opens the attendance screen, THE System SHALL load the ClassRoster and display each student with an attendance toggle (Present / Absent).
2. WHEN a teacher submits the attendance form, THE System SHALL create one `attendance_entries` document per student in the ClassRoster, each containing `studentName`, `rollNumber`, `className`, `section`, `email`, `date`, and `status`.
3. IF an `attendance_entries` document already exists for a given `studentId` and `date`, THEN THE System SHALL update the existing document's `status` field rather than creating a duplicate.
4. WHEN a student views their attendance, THE System SHALL apply a ClassFilter and return only entries where `email == student.email`.
5. THE System SHALL allow the Principal to view attendance entries across all classes without a ClassFilter.
6. WHEN a teacher submits attendance for a class of 50 students, THE System SHALL complete all Firestore writes within 10 seconds under normal network conditions.

---

### Requirement 5: Class-Based Result Entry

**User Story:** As a teacher, I want to enter results for all students in my class, so that each student can see their own result without me entering data separately per student.

#### Acceptance Criteria

1. WHEN a teacher opens the result entry screen, THE System SHALL load the ClassRoster and display each student with input fields for `score` and `maxScore`.
2. WHEN a teacher submits results, THE System SHALL upsert one `results` document per student using the student's `uid` as part of the document ID, with `className`, `section`, `subject`, `term`, and `examType` fields set from the teacher's ClassBinding and form inputs.
3. WHEN a student views their results, THE System SHALL apply a filter on `studentId == student.uid` and return only that student's result documents.
4. THE System SHALL allow the Principal to view all results across all classes without a student-level filter.

---

### Requirement 6: Class-Based Quiz Assignment

**User Story:** As a teacher, I want to create a quiz that is automatically visible to all students in my class, so that students don't need to be individually targeted.

#### Acceptance Criteria

1. WHEN a teacher creates a quiz, THE System SHALL pre-populate `className` and `section` from the teacher's ClassBinding and make them read-only.
2. WHEN a student loads the quiz list, THE System SHALL apply a ClassFilter and return only quizzes where `className == student.className` and `section == student.section`.
3. THE System SHALL allow the Principal to view all quizzes across all classes without a ClassFilter.

---

### Requirement 7: Class-Based Exam Schedule

**User Story:** As a teacher, I want to publish an exam schedule for my class, so that all students in my class see the same schedule automatically.

#### Acceptance Criteria

1. WHEN a teacher creates an exam schedule entry, THE System SHALL pre-populate `className` and `section` from the teacher's ClassBinding and make them read-only.
2. WHEN a student loads the exam schedule, THE System SHALL apply a ClassFilter and return only entries where `className == student.className` and `section == student.section`.
3. THE System SHALL allow the Principal to view all exam schedules across all classes without a ClassFilter.

---

### Requirement 8: Teacher Dashboard — Class Overview

**User Story:** As a teacher, I want a dashboard that shows my class at a glance, so that I can quickly see student count, today's attendance status, and recent assignments.

#### Acceptance Criteria

1. WHEN the TeacherDashboard loads, THE System SHALL display the teacher's `className`, `section`, and `subject` as a header.
2. THE TeacherDashboard SHALL display the total number of students in the ClassRoster.
3. THE TeacherDashboard SHALL display the count of students marked present and absent for the current date.
4. THE TeacherDashboard SHALL display the three most recently created homework assignments for the teacher's class.
5. IF no attendance has been submitted for the current date, THEN THE TeacherDashboard SHALL display the message "Attendance not marked yet for today."

---

### Requirement 9: Principal Cross-Class Visibility

**User Story:** As a principal, I want to view data across all classes, so that I can monitor the entire school without being restricted to one class.

#### Acceptance Criteria

1. WHEN the Principal views any list screen (homework, attendance, results, quizzes, exam schedules), THE System SHALL load all documents from the respective Firestore collection without applying a ClassFilter.
2. THE Principal dashboard SHALL display a class selector that allows filtering the view to a specific `className` + `section` combination.
3. WHEN the Principal selects a specific class from the class selector, THE System SHALL apply a ClassFilter and display only data for that class.
4. WHEN the Principal deselects the class filter, THE System SHALL revert to showing all data across all classes.

---

### Requirement 10: Firestore Security Rules — Class Scoping

**User Story:** As a system administrator, I want Firestore security rules to enforce class-based data access, so that students cannot read data from other classes.

#### Acceptance Criteria

1. THE System SHALL enforce that a student can only read `homework_assignments`, `quizzes`, and `exam_schedules` documents where the document's `className` and `section` match the student's own `className` and `section` stored in their `users` document.
2. THE System SHALL enforce that a teacher can only create or update `homework_assignments`, `attendance_entries`, `results`, `quizzes`, and `exam_schedules` documents where the document's `className` and `section` match the teacher's ClassBinding stored in their `users` document.
3. THE System SHALL allow the Principal to read and write all documents in all collections without class-level restrictions.
4. IF a student attempts to read a document from a different class, THEN THE System SHALL deny the request with a Firestore permission-denied error.

---

### Requirement 11: Class-Based Homework Solution

**User Story:** As a teacher, I want to send a homework solution only to my own class students, so that solutions are not visible to other classes.

#### Acceptance Criteria

1. WHEN a teacher posts a homework solution, THE System SHALL pre-populate `className` and `section` from the teacher's ClassBinding and make them read-only.
2. WHEN a student loads the solutions list, THE System SHALL apply a ClassFilter (`className == student.className`, `section == student.section`) and return only solutions matching the student's class.
3. THE System SHALL NOT allow a teacher to post a solution targeting a class other than their own ClassBinding.
4. THE System SHALL allow the Principal to view all solutions across all classes without a ClassFilter.

---

### Requirement 12: Notice & Events — Role-Based Publishing

**User Story:** As a principal, I want to publish notices and events visible to all students and teachers school-wide, so that important announcements reach everyone. As a teacher, I want to post class-specific notices visible only to my class students.

#### Acceptance Criteria

1. WHEN the Principal publishes a notice or event, THE System SHALL store it in `school_data/main` with `scope: 'school'` and display it to ALL students and ALL teachers across every class.
2. WHEN a teacher publishes a notice, THE System SHALL store it in `school_data/main` with `scope: 'class'`, `className`, and `section` fields set from the teacher's ClassBinding.
3. WHEN a student loads the Notice & Events screen, THE System SHALL display:
   - All notices with `scope: 'school'`
   - Notices with `scope: 'class'` where `className == student.className` AND `section == student.section`
4. WHEN a teacher loads the Notice & Events screen, THE System SHALL display:
   - All notices with `scope: 'school'`
   - Notices with `scope: 'class'` where `className == teacher.className` AND `section == teacher.section`
5. THE System SHALL NOT allow a teacher to publish a notice with `scope: 'school'`; only the Principal can publish school-wide notices.
6. THE System SHALL NOT allow a student to publish any notice or event.
7. WHEN the Principal views the Notice & Events screen, THE System SHALL display all notices regardless of `scope`, `className`, or `section`.
