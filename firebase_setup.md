# Firebase Setup Guide

This project is now code-ready for Firebase Auth, Firestore, and Storage.

## Required Console Setup

Create or configure these Firebase products:

- Authentication
  - Enable `Email/Password`
- Firestore Database
  - Start in test mode first, then tighten rules
- Firebase Storage

## Required App Config

Replace placeholder values in:

- `lib/firebase_options.dart`

Make sure platform config files are present:

- Android: `android/app/google-services.json`
- iOS/macOS: `GoogleService-Info.plist`

## Firestore Collections

- `users`
- `students`
- `teachers`
- `attendance_entries`
- `homework_assignments`
- `homework_submissions`
- `results`
- `exam_schedules`
- `school_data`

- Recommended document:
  - `school_data/main`

## Storage Folders

- `profiles/...`
- `school/...`
- `homework/assignments/...`
- `homework/solutions/...`
- `exams/datesheets/...`

## Current Auth Flow

- Register creates Firebase Auth user
- Register writes Firestore `users/{uid}`
- Login signs in with Firebase Auth
- Splash checks existing session and auto-routes by Firestore role
- Forgot password sends Firebase reset email

## Homework Solution Migration

If old data still exists in `homework_solutions`, migrate it into
`homework_assignments` with:

```powershell
dart run tool/migrate_homework_solutions.dart
```

If you also want to delete old source documents after migration:

```powershell
dart run tool/migrate_homework_solutions.dart --delete-source
```
