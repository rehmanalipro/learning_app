# ⚡ Quick Implementation Guide - 30 Minutes Setup

## 🎯 Goal
Production-ready authentication with Firebase email integration for password reset.

---

## ✅ Step 1: Enable OTP Production Mode (2 minutes)

### File: `lib/features/auth/views/otp_screen.dart`

**Change Line 23:**
```dart
// FROM:
static const bool _allowOtpBypass = true;

// TO:
static const bool _allowOtpBypass = false;
```

**Test:**
```bash
flutter run
# Try signup/login → OTP screen should require actual code
```

---

## ✅ Step 2: Replace Forgot Password Screen (3 minutes)

### Delete old file:
```bash
rm lib/features/auth/views/forgot_password_screen.dart
```

### Rename new file:
```bash
mv lib/features/auth/views/forgot_password_screen_improved.dart lib/features/auth/views/forgot_password_screen.dart
```

**Test:**
```bash
flutter run
# Go to Login → Forgot Password
# Should show improved UI with OTP verification step
```

---

## ✅ Step 3: Setup Firebase Email Extension (15 minutes)

### 3.1 Install Extension
```bash
# In your project root
firebase ext:install firebase/firestore-send-email
```

### 3.2 Configure SMTP (Gmail Example)

**Get Gmail App Password:**
1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification
3. Go to App Passwords
4. Generate password for "Mail"
5. Copy the 16-character password

**Configure Extension:**
```bash
# When prompted, enter:
SMTP Connection URI: smtp://your-email@gmail.com:your-app-password@smtp.gmail.com:587
Default FROM: noreply@yourschool.com
Default REPLY-TO: support@yourschool.com
Mail Collection: mail
```

### 3.3 Update OTP Service

**File: `lib/core/services/otp_service.dart`**

Add this method after `generateAndSaveOtp`:

```dart
Future<void> _sendOtpEmail({
  required String email,
  required String otp,
  required String mode,
}) async {
  final subject = mode == 'forgotPassword'
      ? 'Password Reset - School Management System'
      : mode == 'signup'
          ? 'Welcome - Verify Your Email'
          : 'Email Verification Required';

  final html = '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; }
        .header { text-align: center; color: #1E56CF; margin-bottom: 30px; }
        .otp-box { background: #f0f4ff; padding: 30px; text-align: center; border-radius: 8px; margin: 20px 0; }
        .otp-code { font-size: 36px; font-weight: bold; letter-spacing: 12px; color: #1E56CF; }
        .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔐 Verification Code</h1>
        </div>
        <p>Your verification code is:</p>
        <div class="otp-box">
          <div class="otp-code">$otp</div>
        </div>
        <p>This code will expire in <strong>10 minutes</strong>.</p>
        <p>If you didn't request this code, please ignore this email.</p>
        <div class="footer">
          <p>School Management System</p>
          <p>This is an automated email, please do not reply.</p>
        </div>
      </div>
    </body>
    </html>
  ''';

  await _firebaseService.firestore.collection('mail').add({
    'to': [email],
    'message': {
      'subject': subject,
      'html': html,
    },
    'createdAt': DateTime.now().toIso8601String(),
  });
}
```

**Update `generateAndSaveOtp` method:**

```dart
Future<String> generateAndSaveOtp({
  required String email,
  required String mode,
}) async {
  final otp = _generateOtp();
  final now = DateTime.now();
  final docId = '${email.replaceAll('@', '_').replaceAll('.', '_')}_$mode';

  await _firebaseService.firestore.collection(_collection).doc(docId).set({
    'otp': otp,
    'email': email,
    'mode': mode,
    'createdAt': now.toIso8601String(),
    'expiresAt': now.add(const Duration(minutes: _expiryMinutes)).toIso8601String(),
    'verified': false,
  });

  // ✅ Send email via Firebase Extension
  await _sendOtpEmail(email: email, otp: otp, mode: mode);

  return otp;
}
```

---

## ✅ Step 4: Update Firestore Security Rules (5 minutes)

**File: `firestore.rules`**

Add these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules...
    
    // OTP collection
    match /email_otps/{docId} {
      allow read: if request.auth != null && 
                     request.auth.token.email == resource.data.email;
      allow create, update: if request.auth != null;
      allow delete: if false;
    }
    
    // Mail collection (for Firebase Email Extension)
    match /mail/{docId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // Only server
    }
    
    // Login directory
    match /login_directory/{userId} {
      allow read: if request.auth != null;
      allow write: if false; // Only server/admin
    }
  }
}
```

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
```

---

## ✅ Step 5: Test Complete Flow (5 minutes)

### Test 1: Signup with OTP
```
1. Run app: flutter run
2. Go to Register (if enabled for your role)
3. Fill form and submit
4. Check email for OTP
5. Enter OTP on verification screen
6. Should navigate to dashboard
```

### Test 2: Forgot Password
```
1. Go to Login screen
2. Click "Forgot Password"
3. Enter email/userID
4. Check email for:
   - Firebase password reset link
   - OTP code
5. Enter OTP on verification screen
6. Click Firebase reset link in email
7. Set new password
8. Return to app and login
```

### Test 3: Login
```
1. Enter credentials
2. Should login without OTP (only for signup/forgot password)
3. Navigate to role-based dashboard
```

---

## 🔍 Verification Checklist

- [ ] OTP bypass disabled (`_allowOtpBypass = false`)
- [ ] Forgot password screen replaced
- [ ] Firebase Email Extension installed
- [ ] SMTP configured (test email sent)
- [ ] OTP service updated to send emails
- [ ] Firestore rules deployed
- [ ] Signup flow tested (OTP received)
- [ ] Forgot password flow tested (email + OTP)
- [ ] Login flow tested (no OTP required)

---

## 🐛 Troubleshooting

### Email not received?
```bash
# Check Firebase Console
1. Go to Firestore → mail collection
2. Check document status
3. Look for 'delivery' field with error details

# Check SMTP settings
firebase ext:configure firestore-send-email
```

### OTP verification failing?
```dart
// Check Firestore → email_otps collection
// Verify:
// - OTP matches
// - expiresAt is in future
// - verified = false
```

### Role mismatch error?
```dart
// Check Firestore → students/teachers/principals collection
// Verify user document has correct 'role' field
```

---

## 📊 Monitor in Production

### Firebase Console Checks:
1. **Authentication** → Users (verify new signups)
2. **Firestore** → `mail` collection (email delivery status)
3. **Firestore** → `email_otps` collection (OTP generation)
4. **Extensions** → Email (delivery logs)

### Set up alerts:
```bash
# Firebase Console → Alerts
# Create alerts for:
# - Failed email deliveries
# - High OTP failure rate
# - Unusual login patterns
```

---

## 🚀 Production Deployment

```bash
# 1. Build release APK
flutter build apk --release

# 2. Build iOS
flutter build ios --release

# 3. Deploy Firebase rules
firebase deploy --only firestore:rules

# 4. Test on real device
flutter install --release

# 5. Monitor Firebase Console for 24 hours
```

---

## 📈 Performance Tips

### 1. Cache OTP locally (optional)
```dart
// For development/testing only
final prefs = await SharedPreferences.getInstance();
await prefs.setString('last_otp_$email', otp);
```

### 2. Rate limiting
```dart
// Add to forgot_password_screen.dart
int _resetAttempts = 0;
DateTime? _lastResetTime;

Future<void> _sendResetLink() async {
  if (_resetAttempts >= 3 && 
      _lastResetTime != null && 
      DateTime.now().difference(_lastResetTime!) < Duration(hours: 1)) {
    Get.snackbar('Too many attempts', 
      'Please wait 1 hour before trying again.');
    return;
  }
  
  _resetAttempts++;
  _lastResetTime = DateTime.now();
  
  // ... rest of code
}
```

### 3. Email template caching
```dart
// Create reusable templates in Firestore
// Collection: mail_templates
// Document: otp_verification
{
  subject: 'Verification Code',
  html: '...',
}

// Reference in code
final template = await _firebaseService.firestore
    .collection('mail_templates')
    .doc('otp_verification')
    .get();
```

---

## ✨ Done!

Your authentication system is now production-ready with:
- ✅ Secure OTP verification
- ✅ Firebase email integration
- ✅ Improved forgot password flow
- ✅ Role-based access control
- ✅ Security rules in place

**Total time:** ~30 minutes
**Next:** Monitor Firebase Console for 24 hours and adjust as needed.

---

**Questions?** Check `AUTHENTICATION_FLOW_GUIDE.md` for detailed documentation.
