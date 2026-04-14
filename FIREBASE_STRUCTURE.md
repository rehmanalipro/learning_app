# Firestore Structure

This app should use principal-controlled student identity records as the source
of truth. Public signup is only for creating an account and linking it to an
existing admission record.

## Core Collections

### `principals/{uid}`

Purpose: the only trusted admin account for principal-only screens.

Suggested fields:
- `uid`
- `authUid`
- `email`
- `name`
- `role`
- `phone`
- `imagePath`
- `className`
- `section`
- `subject`
- `createdAt`
- `updatedAt`

Notes:
- Document id must be the same as the Firebase Auth uid.
- Keep only one principal document in production.
- Use the bootstrap script in `tool/bootstrap_principal.md` instead of manual
  app-side signup.

### `users/{uid}`

Purpose: authentication-facing account record for the signed-in user.

Suggested fields:
- `uid`
- `email`
- `name`
- `role`
- `phone`
- `className`
- `section`
- `subject`
- `rollNumber`
- `programName`
- `admissionNo`
- `dateOfBirth`
- `linkedStudentProfileId`
- `imagePath`
- `createdAt`
- `updatedAt`

Notes:
- For students, `className`, `section`, `rollNumber`, `programName`,
  `admissionNo`, and `linkedStudentProfileId` should be copied from
  `student_profiles`.
- Students should not be the source of truth for class identity.

### `student_profiles/{studentProfileId}`

Purpose: principal-managed master admission record.

Suggested fields:
- `admissionNo`
- `fullName`
- `fatherName`
- `dateOfBirth`
- `phone`
- `className`
- `section`
- `rollNumber`
- `programName`
- `status`
- `linkedUserUid`
- `linkedUserEmail`
- `createdBy`
- `createdAt`
- `updatedAt`

Notes:
- This is the primary identity for result, attendance, and roster flows.
- A student account should only be created when `admissionNo + dateOfBirth`
  matches an existing document here.

### `teacher_profiles/{teacherProfileId}`

Purpose: principal-managed teacher identity record.

Suggested fields:
- `name`
- `email`
- `phone`
- `employeeId`
- `status`
- `createdAt`
- `updatedAt`

### `teacher_assignments/{assignmentId}`

Purpose: class/section/subject permissions for a teacher.

Suggested fields:
- `teacherUid`
- `teacherProfileId`
- `teacherName`
- `className`
- `section`
- `subject`
- `session`
- `isClassTeacher`
- `isActive`
- `createdAt`
- `updatedAt`

Notes:
- A teacher can have multiple assignments.
- Result, homework, attendance, quiz, and exam posting should eventually use
  this collection instead of one fixed class binding.

## Academic Collections

### `results/{resultId}`

Purpose: one result row per student profile, subject, term, and exam type.

Suggested fields:
- `studentId`
- `studentUid`
- `studentName`
- `studentEmail`
- `admissionNo`
- `rollNumber`
- `className`
- `section`
- `courseCode`
- `subject`
- `creditHours`
- `score`
- `maxScore`
- `term`
- `examType`
- `teacherId`
- `teacherName`
- `remarks`
- `createdAt`
- `updatedAt`

Notes:
- `studentId` should store the `student_profiles` document id.
- `studentUid` is optional and only exists when the student has linked an
  account.

### `attendance_entries/{attendanceId}`

Suggested fields:
- `studentId`
- `studentName`
- `rollNumber`
- `className`
- `section`
- `email`
- `photoPath`
- `status`
- `submittedAt`
- `markedAt`
- `markedBy`

### `homework_assignments/{assignmentId}`

Suggested fields:
- `className`
- `section`
- `subject`
- `teacherId`
- `teacherName`
- `title`
- `details`
- `pdfName`
- `pdfPath`
- `dueDate`
- `createdAt`

### `homework_submissions/{submissionId}`

Suggested fields:
- `assignmentId`
- `studentId`
- `studentName`
- `className`
- `section`
- `subject`
- `teacherId`
- `teacherName`
- `answerText`
- `pdfName`
- `pdfPath`
- `status`
- `teacherRemarks`
- `submittedAt`
- `reviewedAt`

### `exam_schedules/{scheduleId}`

Suggested fields:
- `className`
- `section`
- `subject`
- `uploadedByName`
- `uploadedByRole`
- `examDate`
- `startMinutes`
- `endMinutes`
- `shiftLabel`
- `place`
- `blockName`
- `roomNumber`
- `seatLabel`
- `description`
- `dateSheetName`
- `dateSheetPath`
- `createdAt`

### `quizzes/{quizId}`

Suggested fields:
- `className`
- `section`
- `subject`
- `teacherId`
- `teacherName`
- `question`
- `options`
- `correctAnswer`
- `createdAt`

### `quiz_attempts/{attemptId}`

Suggested fields:
- `quizId`
- `studentId`
- `studentEmail`
- `studentName`
- `selectedAnswer`
- `isCorrect`
- `score`
- `submittedAt`

## School Collections

### `school_data/main`

Suggested fields:
- `announcement`
- `noticePosts`
- `schoolName`
- `schoolLocation`
- `schoolFounded`
- `publicationProfile`
- `emergencyContacts`
- `schoolImagePath`
- `notificationsEnabled`
- `darkModeEnabled`
- `readNoticeIdsByRole`

### `school_notices/{noticeId}`

Suggested fields:
- `title`
- `body`
- `authorName`
- `authorRole`
- `category`
- `scope`
- `className`
- `section`
- `createdAt`

## Current Implementation Slice

Implemented in code:
- `student_profiles`
- admission-linked student signup
- roster loading from `student_profiles` with legacy fallback to `users`
- result rows keyed by student profile id
- student profile screen made read-only for identity fields

Recommended next slice:
- `teacher_assignments` UI and enforcement
- principal assignment screen
- result sheet filters driven by teacher assignments instead of one fixed class
