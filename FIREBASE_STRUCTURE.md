# Firestore Collection Structure

This project should use the following top-level Firestore collections.

## Required Collections

### `users/`

Document id: `uid`

Suggested fields:
- `email`
- `name`
- `role`
- `phone`
- `className`
- `section`
- `programName`
- `imagePath`
- `createdAt`
- `updatedAt`

### `students/`

Document id: `studentId` or `uid`

Suggested fields:
- `name`
- `email`
- `rollNumber`
- `className`
- `section`
- `programName`
- `imagePath`
- `createdAt`
- `updatedAt`

### `teachers/`

Document id: `teacherId` or `uid`

Suggested fields:
- `name`
- `email`
- `phone`
- `subject`
- `department`
- `imagePath`
- `createdAt`
- `updatedAt`

### `attendance_entries/`

Document id: `attendanceId`

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

### `homework_assignments/`

Document id: `assignmentId`

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

### `homework_submissions/`

Document id: `submissionId`

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

### `results/`

Document id: `resultId`

Suggested fields:
- `studentId`
- `studentName`
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
- `createdAt`
- `updatedAt`

### `exam_schedules/`

Document id: `scheduleId`

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

### `school_data/`

Use a single document like `school_data/main`.

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

## Notes

- `school_data/` is now the preferred collection instead of `app_meta/school_data`.
- Teacher solution data is now stored inside `homework_assignments/` documents instead of a separate `homework_solutions/` collection.
- `quizzes/` and `quiz_attempts/` can still exist as optional feature collections if the quiz module is enabled.
