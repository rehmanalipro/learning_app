# 🔐 Authentication Flow - Visual Diagrams

## 1. Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Student    │  │   Teacher    │  │  Principal   │         │
│  │   Portal     │  │   Portal     │  │   Portal     │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┘                 │
│                            │                                     │
│                   ┌────────▼────────┐                          │
│                   │  Auth Provider  │                          │
│                   │   (GetX State)  │                          │
│                   └────────┬────────┘                          │
└────────────────────────────┼─────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Firebase Auth  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌──────▼──────┐
│   Firestore    │  │  Email Extension│  │  OTP Service│
│   Database     │  │  (SMTP/Gmail)   │  │  (Custom)   │
└────────────────┘  └─────────────────┘  └─────────────┘
```

---

## 2. User Registration Flow

### Student Registration (Principal Creates)
```
┌──────────────┐
│  Principal   │
│  Dashboard   │
└──────┬───────┘
       │
       │ 1. Navigate to Admissions
       ▼
┌──────────────────────┐
│ Student Admission    │
│ Form                 │
│ - Name, DOB, Class   │
│ - Email, Phone       │
└──────┬───────────────┘
       │
       │ 2. Submit Form
       ▼
┌──────────────────────┐
│ Firebase Auth        │
│ Create Account       │
│ - Generate UserID    │
│ - Generate Password  │
└──────┬───────────────┘
       │
       │ 3. Save to Firestore
       ▼
┌──────────────────────┐
│ Collections Updated: │
│ - students           │
│ - student_profiles   │
│ - login_directory    │
└──────┬───────────────┘
       │
       │ 4. Send Credentials
       ▼
┌──────────────────────┐
│ Email to Student     │
│ UserID: ali_c3a_12   │
│ Password: Abc@1234   │
└──────────────────────┘
```

### Teacher Registration (Principal Creates)
```
┌──────────────┐
│  Principal   │
│  Dashboard   │
└──────┬───────┘
       │
       │ 1. Navigate to Teacher Accounts
       ▼
┌──────────────────────┐
│ Teacher Profile Form │
│ - Name, Subject      │
│ - Email, Phone       │
│ - Class, Section     │
└──────┬───────────────┘
       │
       │ 2. Submit Form
       ▼
┌──────────────────────┐
│ Firebase Auth        │
│ Create Account       │
│ - Generate UserID    │
│ - Generate Password  │
└──────┬───────────────┘
       │
       │ 3. Save to Firestore
       ▼
┌──────────────────────┐
│ Collections Updated: │
│ - teachers           │
│ - teacher_profiles   │
│ - login_directory    │
└──────┬───────────────┘
       │
       │ 4. Send Credentials
       ▼
┌──────────────────────┐
│ Email to Teacher     │
│ UserID: ahmed_t5b    │
│ Password: Xyz@5678   │
└──────────────────────┘
```

---

## 3. Login Flow

```
┌──────────────┐
│ Splash Screen│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Choose Role  │
│ - Student    │
│ - Teacher    │
│ - Principal  │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ Login Screen         │
│ - UserID/Email       │
│ - Password           │
└──────┬───────────────┘
       │
       │ Submit
       ▼
┌──────────────────────┐
│ Resolve Identifier   │
│ UserID → Email       │
│ (login_directory)    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Firebase Auth        │
│ signInWithEmail      │
└──────┬───────────────┘
       │
       ├─── Success ───┐
       │               │
       ▼               ▼
┌──────────────┐  ┌──────────────┐
│ Verify Role  │  │ Load Profile │
│ from         │  │ from         │
│ Firestore    │  │ Firestore    │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │ Role Match?     │
       ├─── Yes ─────────┤
       │                 │
       ▼                 ▼
┌──────────────────────────┐
│ Navigate to Dashboard    │
│ - Student → /student     │
│ - Teacher → /teacher     │
│ - Principal → /principal │
└──────────────────────────┘
       │
       │ Role Mismatch?
       ▼
┌──────────────────────┐
│ Show Error           │
│ "This account is for │
│ Student, not Teacher"│
└──────────────────────┘
```

---

## 4. Forgot Password Flow (Current)

```
┌──────────────┐
│ Login Screen │
└──────┬───────┘
       │
       │ Click "Forgot Password"
       ▼
┌──────────────────────┐
│ Forgot Password      │
│ Screen               │
│ - Enter UserID/Email │
└──────┬───────────────┘
       │
       │ Submit
       ▼
┌──────────────────────┐
│ Resolve Identifier   │
│ UserID → Email       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Firebase Auth        │
│ sendPasswordResetEmail│
└──────┬───────────────┘
       │
       ├─── Email Sent ───┐
       │                  │
       ▼                  ▼
┌──────────────┐  ┌──────────────┐
│ Generate OTP │  │ User's Email │
│ Save to      │  │ Inbox        │
│ Firestore    │  │ - Reset Link │
└──────┬───────┘  └──────────────┘
       │
       │ Show OTP in snackbar (dev mode)
       ▼
┌──────────────────────┐
│ OTP Screen           │
│ - Enter 4-digit code │
└──────┬───────────────┘
       │
       │ Verify OTP
       ▼
┌──────────────────────┐
│ OTP Service          │
│ Check Firestore      │
│ - Code matches?      │
│ - Not expired?       │
│ - Not used?          │
└──────┬───────────────┘
       │
       ├─── Valid ────┐
       │              │
       ▼              ▼
┌──────────────┐  ┌──────────────┐
│ Mark as Used │  │ Navigate to  │
│ in Firestore │  │ Login Screen │
└──────────────┘  └──────────────┘
```

---

## 5. Forgot Password Flow (Improved - Production)

```
┌──────────────┐
│ Login Screen │
└──────┬───────┘
       │
       │ Click "Forgot Password"
       ▼
┌──────────────────────┐
│ Forgot Password      │
│ Screen (Improved)    │
│ - Enter UserID/Email │
└──────┬───────────────┘
       │
       │ Submit
       ▼
┌──────────────────────┐
│ Resolve Identifier   │
│ UserID → Email       │
└──────┬───────────────┘
       │
       ├─────────────────────────┐
       │                         │
       ▼                         ▼
┌──────────────────┐    ┌──────────────────┐
│ Firebase Auth    │    │ Generate OTP     │
│ sendPasswordReset│    │ Save to Firestore│
└──────┬───────────┘    └──────┬───────────┘
       │                       │
       │                       ▼
       │              ┌──────────────────┐
       │              │ Firebase Email   │
       │              │ Extension        │
       │              │ - Send OTP Email │
       │              └──────┬───────────┘
       │                     │
       ▼                     ▼
┌─────────────────────────────────┐
│ User's Email Inbox              │
│ 1. Firebase Reset Link          │
│ 2. OTP Code (separate email)    │
└──────┬──────────────────────────┘
       │
       │ User checks email
       ▼
┌──────────────────────┐
│ App: OTP Screen      │
│ - Enter 4-digit code │
└──────┬───────────────┘
       │
       │ Verify OTP
       ▼
┌──────────────────────┐
│ OTP Service          │
│ Verify from Firestore│
└──────┬───────────────┘
       │
       ├─── Valid ────┐
       │              │
       ▼              ▼
┌──────────────┐  ┌──────────────────┐
│ Show Success │  │ User clicks      │
│ Message      │  │ Firebase Reset   │
│              │  │ Link in Email    │
└──────────────┘  └──────┬───────────┘
                         │
                         ▼
                  ┌──────────────────┐
                  │ Firebase Web Page│
                  │ - Enter New Pass │
                  └──────┬───────────┘
                         │
                         ▼
                  ┌──────────────────┐
                  │ Password Updated │
                  │ in Firebase Auth │
                  └──────┬───────────┘
                         │
                         ▼
                  ┌──────────────────┐
                  │ Return to App    │
                  │ Login with New   │
                  │ Password         │
                  └──────────────────┘
```

---

## 6. OTP Verification Flow

```
┌──────────────────────┐
│ OTP Screen           │
│ [_] [_] [_] [_]      │
└──────┬───────────────┘
       │
       │ User enters 4 digits
       ▼
┌──────────────────────┐
│ Validate Input       │
│ - All 4 digits?      │
└──────┬───────────────┘
       │
       │ Yes
       ▼
┌──────────────────────┐
│ Call verifyEmailOtp  │
│ - email              │
│ - otp                │
│ - mode               │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Firestore Query      │
│ Collection: email_otps│
│ Doc: email_mode      │
└──────┬───────────────┘
       │
       ├─── Document Found ───┐
       │                      │
       ▼                      ▼
┌──────────────┐      ┌──────────────┐
│ Check Fields │      │ Validate:    │
│ - otp        │      │ - Code match?│
│ - expiresAt  │      │ - Not expired│
│ - verified   │      │ - Not used?  │
└──────┬───────┘      └──────┬───────┘
       │                     │
       │                     │
       ├─── All Valid ───────┤
       │                     │
       ▼                     ▼
┌──────────────────────────────┐
│ Update Document              │
│ verified: true               │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ Return Success               │
│ Navigate based on mode:      │
│ - signup → Dashboard         │
│ - forgotPassword → Login     │
└──────────────────────────────┘
```

---

## 7. Email Sending Flow (Firebase Extension)

```
┌──────────────────────┐
│ App Code             │
│ generateAndSaveOtp() │
└──────┬───────────────┘
       │
       │ 1. Generate OTP
       ▼
┌──────────────────────┐
│ Save to Firestore    │
│ Collection:          │
│ email_otps           │
└──────┬───────────────┘
       │
       │ 2. Create mail document
       ▼
┌──────────────────────┐
│ Firestore Collection │
│ mail                 │
│ {                    │
│   to: [email],       │
│   message: {         │
│     subject: "...",  │
│     html: "..."      │
│   }                  │
│ }                    │
└──────┬───────────────┘
       │
       │ 3. Extension triggers
       ▼
┌──────────────────────┐
│ Firebase Email       │
│ Extension            │
│ - Reads document     │
│ - Connects to SMTP   │
└──────┬───────────────┘
       │
       │ 4. Send via SMTP
       ▼
┌──────────────────────┐
│ Gmail SMTP Server    │
│ smtp.gmail.com:587   │
└──────┬───────────────┘
       │
       │ 5. Deliver email
       ▼
┌──────────────────────┐
│ User's Email Inbox   │
│ - OTP Code           │
│ - Formatted HTML     │
└──────┬───────────────┘
       │
       │ 6. Update status
       ▼
┌──────────────────────┐
│ Firestore Document   │
│ mail/{docId}         │
│ delivery: {          │
│   state: "SUCCESS",  │
│   attempts: 1        │
│ }                    │
└──────────────────────┘
```

---

## 8. Security Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Security Layers                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 1: Firebase Authentication                      │
│  ✓ Email/Password verification                         │
│  ✓ Secure token generation                             │
│  ✓ Session management                                  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 2: Role-Based Access Control                    │
│  ✓ Role verification on login                          │
│  ✓ Collection-based separation                         │
│  ✓ Trusted UID list for Principal                      │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 3: OTP Verification                             │
│  ✓ 4-digit secure random code                          │
│  ✓ 10-minute expiry                                    │
│  ✓ One-time use enforcement                            │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 4: Firestore Security Rules                     │
│  ✓ Read/write permissions                              │
│  ✓ Data validation                                     │
│  ✓ User-specific access                                │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 5: Password Requirements                        │
│  ✓ Minimum 8 characters                                │
│  ✓ Mixed case + numbers + special chars                │
│  ✓ Auto-generated for principal-created accounts       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 9. Data Flow - Student Account Creation

```
Principal Dashboard
        │
        │ 1. Fill admission form
        ▼
┌─────────────────────────────────────┐
│ Student Profile Data                │
│ - fullName: "Ali Ahmed"             │
│ - className: "3"                    │
│ - section: "A"                      │
│ - rollNumber: "12"                  │
│ - admissionNo: "2024-001"           │
│ - dateOfBirth: "2015-01-15"         │
│ - studentEmail: "ali@example.com"   │
└─────────────┬───────────────────────┘
              │
              │ 2. Generate credentials
              ▼
┌─────────────────────────────────────┐
│ Auto-Generated                      │
│ - UserID: "ali_c3a_sci_12"          │
│ - Password: "Abc@1234Xyz"           │
└─────────────┬───────────────────────┘
              │
              │ 3. Create Firebase Auth account
              ▼
┌─────────────────────────────────────┐
│ Firebase Authentication             │
│ - email: ali@example.com            │
│ - password: Abc@1234Xyz             │
│ - uid: "abc123xyz..."               │
└─────────────┬───────────────────────┘
              │
              │ 4. Save to multiple collections
              ├──────────────┬──────────────┬──────────────┐
              ▼              ▼              ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ students     │  │student_profiles│ │login_directory│ │ mail         │
│ /ali_c3a_12  │  │ /profile_id   │  │ /ali_c3a_12  │  │ /mail_id     │
│              │  │               │  │              │  │              │
│ uid          │  │ linkedUserUid │  │ email        │  │ to: [email]  │
│ email        │  │ generatedUserId│  │ userId       │  │ message:     │
│ userId       │  │ fullName      │  │ uid          │  │   subject    │
│ name         │  │ className     │  │ role         │  │   html       │
│ role         │  │ section       │  │              │  │              │
│ className    │  │ rollNumber    │  │              │  │              │
│ section      │  │ admissionNo   │  │              │  │              │
│ rollNumber   │  │ dateOfBirth   │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## 10. Error Handling Flow

```
┌──────────────┐
│ User Action  │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ Try Operation        │
│ - Login              │
│ - Signup             │
│ - Password Reset     │
└──────┬───────────────┘
       │
       ├─── Success ───┐
       │               │
       │               ▼
       │        ┌──────────────┐
       │        │ Continue Flow│
       │        └──────────────┘
       │
       ├─── Error ─────┐
       │               │
       ▼               ▼
┌──────────────┐  ┌──────────────────┐
│ Catch Error  │  │ Error Types:     │
│              │  │ - Auth error     │
│              │  │ - Network error  │
│              │  │ - Validation err │
└──────┬───────┘  └──────────────────┘
       │
       ▼
┌──────────────────────┐
│ Parse Error Message  │
│ - User-friendly text │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Show Snackbar        │
│ - Error message      │
│ - Suggested action   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Log to Console       │
│ - For debugging      │
└──────────────────────┘
```

---

**Visual Guide Complete!**
Use these diagrams to understand the complete authentication flow.
