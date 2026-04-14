# 🔐 Authentication Flow - Complete Guide

## Current Flow Overview

### 1. **User Roles & Access Control**
```
┌─────────────┬──────────────────┬─────────────────────────────┐
│ Role        │ Account Creation │ Login Method                │
├─────────────┼──────────────────┼─────────────────────────────┤
│ Student     │ Principal        │ UserID/Email + Password     │
│ Teacher     │ Principal        │ UserID/Email + Password     │
│ Principal   │ Manual (Admin)   │ Email + Password            │
└─────────────┴──────────────────┴─────────────────────────────┘
```

### 2. **Authentication Flow Diagram**
```
Splash Screen
    ↓
Choose Role (Student/Teacher/Principal)
    ↓
Login Screen
    ├─→ Forgot Password → Firebase Reset Link + OTP → Login
    └─→ Enter Credentials → Verify Role → Home Dashboard
```

---

## 🚀 Production-Level Improvements

### **Issue 1: OTP Bypass Mode**
**Current:** `_allowOtpBypass = true` in `otp_screen.dart`

**Fix:**
```dart
// lib/features/auth/views/otp_screen.dart
// Line 23: Change this
static const bool _allowOtpBypass = true;  // ❌ Development mode

// To this for production
static const bool _allowOtpBypass = false; // ✅ Production mode
```

---

### **Issue 2: Forgot Password Flow**

#### Current Implementation:
1. User enters email/userID
2. Firebase sends password reset link
3. OTP sent but not properly integrated
4. User clicks email link → Password reset

#### Improved Production Flow:
1. User enters email/userID
2. **Firebase reset link sent** (primary method)
3. **OTP sent for verification** (secondary security)
4. User must verify OTP before using reset link
5. After OTP verification → User clicks email link → Password reset

**Implementation:**
```dart
// Use the improved forgot_password_screen_improved.dart
// Replace current forgot_password_screen.dart with improved version
```

---

## 📧 Firebase Email Integration

### **Setup Firebase Email Extension**

#### Step 1: Install Trigger Email Extension
```bash
firebase ext:install firebase/firestore-send-email
```

#### Step 2: Configure Extension
```yaml
# Extension Configuration
SMTP Connection URI: smtp://username:password@smtp.gmail.com:587
Default FROM address: noreply@yourschool.com
Default REPLY-TO address: support@yourschool.com
```

#### Step 3: Create Email Templates Collection
```javascript
// Firestore: /mail/{docId}
{
  to: ['user@example.com'],
  message: {
    subject: 'Password Reset - School Management System',
    html: `
      <h2>Password Reset Request</h2>
      <p>Click the link below to reset your password:</p>
      <a href="{{resetLink}}">Reset Password</a>
      <p>Your verification code: <strong>{{otp}}</strong></p>
      <p>This link expires in 1 hour.</p>
    `
  }
}
```

#### Step 4: Update OTP Service
```dart
// lib/core/services/otp_service.dart
Future<String> generateAndSaveOtp({
  required String email,
  required String mode,
}) async {
  final otp = _generateOtp();
  final now = DateTime.now();
  final docId = '${email.replaceAll('@', '_').replaceAll('.', '_')}_$mode';

  // Save OTP
  await _firebaseService.firestore.collection(_collection).doc(docId).set({
    'otp': otp,
    'email': email,
    'mode': mode,
    'createdAt': now.toIso8601String(),
    'expiresAt': now.add(const Duration(minutes: _expiryMinutes)).toIso8601String(),
    'verified': false,
  });

  // ✅ Trigger email via Firebase Extension
  await _firebaseService.firestore.collection('mail').add({
    'to': [email],
    'message': {
      'subject': mode == 'forgotPassword' 
          ? 'Password Reset - School Management System'
          : 'Email Verification - School Management System',
      'html': '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #1E56CF;">Verification Code</h2>
          <p>Your verification code is:</p>
          <div style="background: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 8px;">
            $otp
          </div>
          <p style="color: #666; font-size: 14px;">This code expires in $_expiryMinutes minutes.</p>
          <p style="color: #666; font-size: 12px;">If you didn't request this, please ignore this email.</p>
        </div>
      ''',
    },
  });

  return otp;
}
```

---

## 🔒 Security Best Practices

### 1. **Password Requirements**
```dart
// Already implemented in register_screen.dart
✅ Minimum 8 characters
✅ At least 1 uppercase letter
✅ At least 1 lowercase letter
✅ At least 1 digit
✅ At least 1 special character (!@#$%^&*(),.?":{}|<>)
```

### 2. **OTP Security**
```dart
// lib/core/services/otp_service.dart
✅ 4-digit secure random OTP
✅ 10-minute expiry
✅ One-time use (marked as verified after use)
✅ Stored in Firestore with encryption at rest
```

### 3. **Role-Based Access Control**
```dart
// lib/features/auth/providers/firebase_auth_provider.dart
✅ Principal: Only trusted UIDs can access
✅ Teacher: Must be created by principal
✅ Student: Must link to admission record
✅ Role verification on every login
```

### 4. **Account Provisioning**
```dart
// Student account creation by principal
✅ Auto-generated unique UserID
✅ Strong password generation
✅ Email verification required
✅ Linked to admission record
✅ Login directory for UserID → Email mapping
```

---

## 📱 User Experience Flow

### **Student Login**
```
1. Enter UserID (e.g., "ali_c3a_sci_12") or Email
2. Enter Password (provided by principal)
3. System verifies role = Student
4. Navigate to Student Dashboard
```

### **Teacher Login**
```
1. Enter UserID (e.g., "ahmed_t5b_math_emp123") or Email
2. Enter Password (provided by principal)
3. System verifies role = Teacher
4. Navigate to Teacher Dashboard
```

### **Principal Login**
```
1. Enter Email (only authorized principal email)
2. Enter Password
3. System verifies trusted principal UID
4. Navigate to Principal Dashboard
```

### **Forgot Password Flow**
```
1. Click "Forgot Password" on login screen
2. Enter UserID or Email
3. System sends:
   - Firebase password reset link to email
   - OTP code for verification
4. User checks email for both
5. Enter OTP on verification screen
6. After OTP verified → Click email reset link
7. Set new password on Firebase page
8. Return to app and login with new password
```

---

## 🛠️ Implementation Checklist

### **Phase 1: OTP Production Mode** ✅
- [ ] Set `_allowOtpBypass = false` in `otp_screen.dart`
- [ ] Test OTP generation and verification
- [ ] Verify OTP expiry (10 minutes)
- [ ] Test one-time use enforcement

### **Phase 2: Firebase Email Extension** 📧
- [ ] Install Firebase Email Extension
- [ ] Configure SMTP settings (Gmail/SendGrid)
- [ ] Create email templates
- [ ] Update `otp_service.dart` to trigger emails
- [ ] Test email delivery
- [ ] Monitor email logs in Firebase Console

### **Phase 3: Improved Forgot Password** 🔐
- [ ] Replace `forgot_password_screen.dart` with improved version
- [ ] Test complete flow: Email → OTP → Reset
- [ ] Add rate limiting (max 3 attempts per hour)
- [ ] Add email delivery status tracking

### **Phase 4: Security Hardening** 🛡️
- [ ] Enable Firebase App Check
- [ ] Add reCAPTCHA on login/signup
- [ ] Implement account lockout after 5 failed attempts
- [ ] Add IP-based rate limiting
- [ ] Enable Firebase Security Rules audit logging

### **Phase 5: Monitoring & Analytics** 📊
- [ ] Track login success/failure rates
- [ ] Monitor OTP verification rates
- [ ] Set up alerts for suspicious activity
- [ ] Log password reset attempts
- [ ] Track email delivery success rates

---

## 🔧 Configuration Files

### **Firestore Security Rules**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // OTP collection - only server can write
    match /email_otps/{docId} {
      allow read: if request.auth != null && 
                     request.auth.token.email == resource.data.email;
      allow write: if request.auth != null;
    }
    
    // Mail collection - only authenticated users can create
    match /mail/{docId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // Only server
    }
    
    // Login directory - read only for authenticated users
    match /login_directory/{userId} {
      allow read: if request.auth != null;
      allow write: if false; // Only server/admin
    }
  }
}
```

### **Firebase Email Extension Config**
```json
{
  "name": "firestore-send-email",
  "version": "0.1.23",
  "params": {
    "SMTP_CONNECTION_URI": "smtp://username:password@smtp.gmail.com:587",
    "SMTP_PASSWORD": "your-app-password",
    "DEFAULT_FROM": "noreply@yourschool.com",
    "DEFAULT_REPLY_TO": "support@yourschool.com",
    "MAIL_COLLECTION": "mail",
    "TEMPLATES_COLLECTION": "mail_templates"
  }
}
```

---

## 📈 Performance Optimization

### **1. Caching Strategy**
```dart
// Cache user data after login
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_role', role);
await prefs.setString('user_id', userId);
await prefs.setString('last_login', DateTime.now().toIso8601String());
```

### **2. Offline Support**
```dart
// Enable Firestore offline persistence
await FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### **3. Lazy Loading**
```dart
// Load user profile data only when needed
Future<void> _loadUserProfile() async {
  if (_profileCache != null) return _profileCache;
  _profileCache = await _firebaseService.getUserData(uid);
}
```

---

## 🐛 Common Issues & Solutions

### **Issue 1: OTP Not Received**
**Cause:** Email extension not configured or SMTP credentials invalid
**Solution:**
1. Check Firebase Console → Extensions → Email
2. Verify SMTP settings
3. Check spam folder
4. Test with Firebase Console → Firestore → Add document to `mail` collection

### **Issue 2: Password Reset Link Expired**
**Cause:** Firebase default expiry is 1 hour
**Solution:**
```dart
// Increase expiry time in Firebase Console
// Authentication → Templates → Password reset
// Or send new link via forgot password flow
```

### **Issue 3: Role Mismatch Error**
**Cause:** User trying to access wrong portal
**Solution:**
```dart
// Already handled in login_screen.dart
// Shows clear error: "This account is for Student, not Teacher"
```

### **Issue 4: UserID Not Found**
**Cause:** Login directory not synced
**Solution:**
```dart
// Ensure provisionStudentAccount/provisionTeacherAccount
// creates login_directory entry
await _firebaseService.firestore
    .collection('login_directory')
    .doc(generatedUserId.toLowerCase())
    .set({...});
```

---

## 📚 Additional Resources

### **Firebase Documentation**
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Email Extension](https://firebase.google.com/products/extensions/firestore-send-email)

### **Flutter Packages**
- `firebase_auth: ^4.15.0` - Authentication
- `cloud_firestore: ^4.13.0` - Database
- `get: ^4.6.6` - State management & routing

### **Testing Tools**
- Firebase Emulator Suite for local testing
- Postman for API testing
- Firebase Console for monitoring

---

## 🎯 Next Steps

1. **Enable OTP Production Mode** (5 minutes)
2. **Setup Firebase Email Extension** (30 minutes)
3. **Replace Forgot Password Screen** (10 minutes)
4. **Test Complete Flow** (1 hour)
5. **Deploy to Production** (15 minutes)

---

## 📞 Support

For issues or questions:
- Check Firebase Console logs
- Review Firestore security rules
- Test with Firebase Emulator locally
- Monitor email delivery in Firebase Extensions

---

**Last Updated:** April 14, 2026
**Version:** 1.0.0
**Author:** Kiro AI Assistant
