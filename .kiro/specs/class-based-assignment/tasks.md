# Implementation Plan: Class-Based Assignment

## Overview

Introduce class-scoped ownership for teachers by adding a `ClassBindingService`, updating registration, and propagating the class filter through all data services and screens. Each task builds incrementally toward a fully wired feature.

## Tasks

- [x] 1. Create ClassBindingService
  - Create `lib/core/services/class_binding_service.dart` as a `GetxService`
  - Expose `Rx<String>` fields: `className`, `section`, `subject`
  - Add `loadFromUserData(Map<String, dynamic> userData)` to populate fields from a user document
  - Add `clear()` to reset all fields on logout
  - _Requirements: 1.5_

- [x] 2. Update teacher registration — add class fields
  - [x] 2.1 Update `RegisterScreen` to show `className` dropdown (values 1–10), `section` dropdown (A, B, C), and `subject` text field when `role == 'teacher'`
    - Mirror the existing student class/section dropdown pattern
    - Add validation: reject submission if any of the three fields is empty, show field-level error
    - _Requirements: 1.1, 1.2_

  - [x] 2.2 Pass `className`, `section`, `subject` through `FirebaseAuthProvider.signUp` and into the `users` Firestore document
    - Extend the `signUp` call in `_onSignup` to include teacher fields
    - Extend `FirebaseAuthProvider.signUp` signature to accept `subject`
    - _Requirements: 1.3_

  - [ ]* 2.3 Write unit tests for teacher registration validation
    - Test that empty className/section/subject each produce a field-level error
    - Test that valid teacher data passes validation
    - _Requirements: 1.1, 1.2_

- [x] 3. Load ClassBinding on teacher login
  - In the post-login flow (after `FirebaseAuthProvider.signIn` succeeds), call `FirebaseAuthProvider.loadCurrentUserData()` and pass the result to `ClassBindingService.loadFromUserData()`
  - Wire this in the login screen or a session-init helper so `ClassBindingService` is populated before any teacher screen loads
  - _Requirements: 1.5_

- [x] 4. Create ClassRosterService
  - Create `lib/core/services/class_roster_service.dart` as a `GetxService`
  - Add `Future<List<Map<String, dynamic>>> loadRoster({required String className, required String section})` that queries `users` collection filtered by `role == 'student'`, `className`, and `section`
  - Expose `RxList<Map<String, dynamic>> roster` and `RxBool isLoading`
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 5. Update HomeworkService — apply ClassFilter and pre-populate from ClassBinding
  - [x] 5.1 Add `loadForClass({required String className, required String section})` to `HomeworkService` that filters `assignments` by `className` and `section` after fetching
    - Students call this variant; teacher and principal call existing `loadAll()`
    - _Requirements: 3.3, 3.5_

  - [x] 5.2 Update teacher homework form to read `className`, `section`, `subject` from `ClassBindingService` and render them as read-only fields
    - Locate the teacher homework creation UI and replace editable class fields with read-only display
    - _Requirements: 3.1, 3.2_

  - [ ]* 5.3 Write unit tests for HomeworkService class filter
    - Test that `loadForClass` returns only assignments matching the given class+section
    - Test that assignments for other classes are excluded
    - _Requirements: 3.3_

- [x] 6. Update AttendanceService — bulk marking from ClassRoster
  - [x] 6.1 Add `bulkMarkAttendance({required List<Map<String, dynamic>> roster, required String date, required Map<String, AttendanceStatus> statusMap})` to `AttendanceService`
    - For each student in roster, upsert an `attendance_entries` document keyed by `studentId_date`
    - If document already exists for that key, update `status` only (Requirement 4.3)
    - _Requirements: 4.2, 4.3, 4.6_

  - [x] 6.2 Update teacher attendance screen to load ClassRoster via `ClassRosterService`, display each student with a Present/Absent toggle, and call `bulkMarkAttendance` on submit
    - Replace any manual student entry with the roster-driven list
    - _Requirements: 4.1, 4.2_

  - [ ]* 6.3 Write unit tests for bulkMarkAttendance
    - Test that one document is created per student
    - Test that a duplicate submission updates rather than creates a new document
    - _Requirements: 4.2, 4.3_

- [x] 7. Update ResultService — bulk entry from ClassRoster
  - [x] 7.1 Add `bulkUpsertResults({required List<Map<String, dynamic>> roster, required String className, required String section, required String subject, required String term, required String examType, required Map<String, ({double score, double maxScore})> scores})` to `ResultService`
    - Document ID pattern: `result_<studentUid>_<term>_<examType>`
    - _Requirements: 5.2_

  - [x] 7.2 Update teacher result entry screen to load ClassRoster, display each student with score/maxScore inputs, and call `bulkUpsertResults` on submit
    - Pre-populate `className`, `section`, `subject` from `ClassBindingService` as read-only
    - _Requirements: 5.1, 5.2_

  - [x] 7.3 Add `getByStudentId(String studentUid)` filter to `ResultService` for student view
    - Students see only their own results filtered by `studentId == uid`
    - _Requirements: 5.3_

  - [ ]* 7.4 Write unit tests for bulkUpsertResults
    - Test that one result document is upserted per student
    - Test that re-submitting updates the existing document
    - _Requirements: 5.2_

- [x] 8. Update QuizService — apply ClassFilter
  - [x] 8.1 Update teacher quiz creation form to read `className` and `section` from `ClassBindingService` and render them as read-only
    - _Requirements: 6.1_

  - [x] 8.2 Update student quiz loading to call `quizzesForClass(className, section)` using the student's own class data
    - Student's `className`/`section` come from their `users` document loaded at login
    - _Requirements: 6.2_

- [x] 9. Update ExamScheduleService — apply ClassFilter
  - [x] 9.1 Update teacher exam schedule creation form to read `className` and `section` from `ClassBindingService` and render them as read-only
    - _Requirements: 7.1_

  - [x] 9.2 Update student exam schedule loading to call `schedulesForClass(className, section)` using the student's own class data
    - _Requirements: 7.2_

- [x] 10. Update NoticePostModel and SchoolDataService — scope-based notices
  - [x] 10.1 Add `scope` (`'school'` | `'class'`), `className`, and `section` fields to `NoticePostModel` — update `toMap`, `fromMap`, and `copyWith`
    - Default `scope` to `'school'` for backward compatibility with existing documents
    - _Requirements: 12.1, 12.2_

  - [x] 10.2 Update `SchoolDataService.publishNotice` to accept `scope`, `className`, and `section` parameters and store them on the `NoticePostModel`
    - _Requirements: 12.1, 12.2_

  - [x] 10.3 Add `noticesForRole({required String role, String? className, String? section})` helper to `SchoolDataService`
    - Returns all `scope: 'school'` notices plus `scope: 'class'` notices matching the given class+section
    - Principal (no class filter) receives all notices
    - _Requirements: 12.3, 12.4, 12.7_

  - [ ]* 10.4 Write unit tests for notice filtering logic
    - Test that a student only sees school-wide + their own class notices
    - Test that a teacher only sees school-wide + their own class notices
    - Test that the principal sees all notices
    - _Requirements: 12.3, 12.4, 12.7_

- [x] 11. Update teacher screens — read-only class fields and dashboard header
  - [x] 11.1 Update `TeacherScreen` (or teacher dashboard widget) to display `className`, `section`, and `subject` from `ClassBindingService` as a header
    - Show total student count from `ClassRosterService.roster.length`
    - Show present/absent counts for today from `AttendanceService`
    - Show three most recent homework assignments for the teacher's class
    - Display "Attendance not marked yet for today." when no entries exist for today
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x] 11.2 Update notice publish UI for teacher role
    - Pre-populate `className`/`section` from `ClassBindingService`, make them read-only
    - Force `scope: 'class'` for teacher-published notices; hide the school-wide option
    - _Requirements: 12.2, 12.5_

- [x] 12. Update student screens — apply ClassFilter
  - [x] 12.1 Load student's own `className` and `section` from their `users` document after login and store in a lightweight `StudentSessionService` (or reuse `ClassBindingService` with a student variant)
    - _Requirements: 3.3, 4.4, 6.2, 7.2_

  - [x] 12.2 Update student homework, quiz, exam schedule, and notice screens to use the student's class data when calling the respective service filter methods
    - Show "Class information not found. Please contact your teacher." if `className`/`section` are missing
    - _Requirements: 3.3, 3.4, 6.2, 7.2, 12.3_

- [x] 13. Update Firestore security rules — class-scoped access
  - Add helper functions `userClassName()` and `userSection()` that read from the caller's `users` document
  - Update `homework_assignments`, `quizzes`, `exam_schedules` read rules: student can only read if `resource.data.className == userClassName() && resource.data.section == userSection()`
  - Update `homework_assignments`, `attendance_entries`, `results`, `quizzes`, `exam_schedules` write rules: teacher can only write if document's `className`/`section` match teacher's ClassBinding
  - Update `school_data` write rule: allow teacher to write (for class-scoped notices); restrict `scope: 'school'` writes to principal only
  - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 14. Register new services in main.dart
  - Import and `Get.put` `ClassBindingService` and `ClassRosterService` in `bootstrapApp()`
  - Ensure registration order: `ClassBindingService` before any service that depends on it
  - _Requirements: 1.5_

- [x] 15. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- `ClassBindingService` is the single source of truth for a teacher's class context; all teacher forms read from it
- Student class context follows the same pattern but is loaded from the student's own `users` document
- Principal screens skip all ClassFilter calls and load full collections
