# 🔐 Authentication Flow - مکمل گائیڈ (اردو)

## موجودہ فلو کا خلاصہ

### 1. **یوزر رولز اور رسائی کنٹرول**
```
┌─────────────┬──────────────────┬─────────────────────────────┐
│ رول         │ اکاؤنٹ بنانا     │ لاگ ان کا طریقہ              │
├─────────────┼──────────────────┼─────────────────────────────┤
│ Student     │ Principal        │ UserID/Email + Password     │
│ Teacher     │ Principal        │ UserID/Email + Password     │
│ Principal   │ Manual (Admin)   │ Email + Password            │
└─────────────┴──────────────────┴─────────────────────────────┘
```

### 2. **Authentication کا مکمل فلو**
```
Splash Screen
    ↓
Role منتخب کریں (Student/Teacher/Principal)
    ↓
Login Screen
    ├─→ Forgot Password → Firebase Reset Link + OTP → Login
    └─→ Credentials داخل کریں → Role Verify → Home Dashboard
```

---

## 🚀 Production کے لیے بہتریاں

### **مسئلہ 1: OTP Bypass Mode**
**موجودہ حالت:** `_allowOtpBypass = true` in `otp_screen.dart`

**حل:**
```dart
// lib/features/auth/views/otp_screen.dart
// Line 23: یہ تبدیل کریں
static const bool _allowOtpBypass = true;  // ❌ Development mode

// Production کے لیے یہ کریں
static const bool _allowOtpBypass = false; // ✅ Production mode
```

---

### **مسئلہ 2: Forgot Password کا فلو**

#### موجودہ Implementation:
1. یوزر email/userID داخل کرتا ہے
2. Firebase password reset link بھیجتا ہے
3. OTP بھیجا جاتا ہے لیکن صحیح طرح integrate نہیں
4. یوزر email link پر کلک کرتا ہے → Password reset

#### بہتر Production فلو:
1. یوزر email/userID داخل کرتا ہے
2. **Firebase reset link بھیجا جاتا ہے** (primary method)
3. **OTP verification کے لیے بھیجا جاتا ہے** (secondary security)
4. یوزر کو OTP verify کرنا ضروری ہے reset link استعمال کرنے سے پہلے
5. OTP verification کے بعد → یوزر email link پر کلک کرتا ہے → Password reset

---

## 📧 Firebase Email Integration

### **Firebase Email Extension Setup**

#### Step 1: Extension Install کریں
```bash
firebase ext:install firebase/firestore-send-email
```

#### Step 2: Configuration
```yaml
SMTP Connection URI: smtp://username:password@smtp.gmail.com:587
Default FROM address: noreply@yourschool.com
Default REPLY-TO address: support@yourschool.com
```

#### Step 3: Email Templates بنائیں
Firestore میں `/mail` collection میں document add کریں:

```javascript
{
  to: ['user@example.com'],
  message: {
    subject: 'Password Reset - School Management System',
    html: `
      <h2>Password Reset کی درخواست</h2>
      <p>اپنا password reset کرنے کے لیے نیچے دیے گئے link پر کلک کریں:</p>
      <a href="{{resetLink}}">Password Reset کریں</a>
      <p>آپ کا verification code: <strong>{{otp}}</strong></p>
      <p>یہ link 1 گھنٹے میں expire ہو جائے گا۔</p>
    `
  }
}
```

#### Step 4: OTP Service Update کریں
```dart
// lib/core/services/otp_service.dart میں
Future<String> generateAndSaveOtp({
  required String email,
  required String mode,
}) async {
  final otp = _generateOtp();
  final now = DateTime.now();
  
  // OTP save کریں
  await _firebaseService.firestore.collection('email_otps').doc(docId).set({
    'otp': otp,
    'email': email,
    'mode': mode,
    'createdAt': now.toIso8601String(),
    'expiresAt': now.add(Duration(minutes: 10)).toIso8601String(),
    'verified': false,
  });

  // ✅ Firebase Extension کے ذریعے email بھیجیں
  await _firebaseService.firestore.collection('mail').add({
    'to': [email],
    'message': {
      'subject': 'Verification Code - School Management System',
      'html': '''
        <div style="font-family: Arial, sans-serif;">
          <h2>آپ کا Verification Code</h2>
          <div style="font-size: 32px; font-weight: bold;">
            $otp
          </div>
          <p>یہ code 10 منٹ میں expire ہو جائے گا۔</p>
        </div>
      ''',
    },
  });

  return otp;
}
```

---

## 🔒 Security Best Practices

### 1. **Password کی ضروریات**
```
✅ کم از کم 8 حروف
✅ کم از کم 1 بڑا حرف (A-Z)
✅ کم از کم 1 چھوٹا حرف (a-z)
✅ کم از کم 1 نمبر (0-9)
✅ کم از کم 1 خاص علامت (!@#$%^&*)
```

### 2. **OTP Security**
```
✅ 4 ہندسوں کا secure random OTP
✅ 10 منٹ کی expiry
✅ صرف ایک بار استعمال (one-time use)
✅ Firestore میں encrypted storage
```

### 3. **Role-Based Access Control**
```
✅ Principal: صرف trusted UIDs access کر سکتے ہیں
✅ Teacher: Principal کے ذریعے بنایا جانا ضروری
✅ Student: Admission record سے link ہونا ضروری
✅ ہر login پر role verification
```

---

## 📱 یوزر Experience Flow

### **Student Login**
```
1. UserID داخل کریں (مثال: "ali_c3a_sci_12") یا Email
2. Password داخل کریں (principal نے دیا ہوا)
3. System role = Student verify کرتا ہے
4. Student Dashboard پر جائیں
```

### **Teacher Login**
```
1. UserID داخل کریں (مثال: "ahmed_t5b_math_emp123") یا Email
2. Password داخل کریں (principal نے دیا ہوا)
3. System role = Teacher verify کرتا ہے
4. Teacher Dashboard پر جائیں
```

### **Principal Login**
```
1. Email داخل کریں (صرف authorized principal email)
2. Password داخل کریں
3. System trusted principal UID verify کرتا ہے
4. Principal Dashboard پر جائیں
```

### **Forgot Password کا مکمل فلو**
```
1. Login screen پر "Forgot Password" پر کلک کریں
2. UserID یا Email داخل کریں
3. System دو چیزیں بھیجتا ہے:
   - Firebase password reset link (email میں)
   - OTP code (verification کے لیے)
4. یوزر اپنی email check کرتا ہے
5. OTP verification screen پر OTP داخل کریں
6. OTP verify ہونے کے بعد → Email میں reset link پر کلک کریں
7. Firebase page پر نیا password set کریں
8. App میں واپس آئیں اور نئے password سے login کریں
```

---

## 🛠️ Implementation Checklist

### **Phase 1: OTP Production Mode** ✅
- [ ] `otp_screen.dart` میں `_allowOtpBypass = false` set کریں
- [ ] OTP generation اور verification test کریں
- [ ] OTP expiry (10 منٹ) verify کریں
- [ ] One-time use enforcement test کریں

### **Phase 2: Firebase Email Extension** 📧
- [ ] Firebase Email Extension install کریں
- [ ] SMTP settings configure کریں (Gmail/SendGrid)
- [ ] Email templates بنائیں
- [ ] `otp_service.dart` update کریں emails trigger کرنے کے لیے
- [ ] Email delivery test کریں
- [ ] Firebase Console میں email logs monitor کریں

### **Phase 3: Improved Forgot Password** 🔐
- [ ] `forgot_password_screen.dart` کو improved version سے replace کریں
- [ ] مکمل flow test کریں: Email → OTP → Reset
- [ ] Rate limiting add کریں (max 3 attempts فی گھنٹہ)
- [ ] Email delivery status tracking add کریں

### **Phase 4: Security Hardening** 🛡️
- [ ] Firebase App Check enable کریں
- [ ] Login/signup پر reCAPTCHA add کریں
- [ ] 5 failed attempts کے بعد account lockout implement کریں
- [ ] IP-based rate limiting add کریں
- [ ] Firebase Security Rules audit logging enable کریں

### **Phase 5: Monitoring & Analytics** 📊
- [ ] Login success/failure rates track کریں
- [ ] OTP verification rates monitor کریں
- [ ] Suspicious activity کے لیے alerts set کریں
- [ ] Password reset attempts log کریں
- [ ] Email delivery success rates track کریں

---

## 🔧 Configuration Files

### **Firestore Security Rules**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // OTP collection - صرف server write کر سکتا ہے
    match /email_otps/{docId} {
      allow read: if request.auth != null && 
                     request.auth.token.email == resource.data.email;
      allow write: if request.auth != null;
    }
    
    // Mail collection - صرف authenticated users create کر سکتے ہیں
    match /mail/{docId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // صرف server
    }
    
    // Login directory - authenticated users read کر سکتے ہیں
    match /login_directory/{userId} {
      allow read: if request.auth != null;
      allow write: if false; // صرف server/admin
    }
  }
}
```

---

## 🐛 عام مسائل اور حل

### **مسئلہ 1: OTP موصول نہیں ہو رہا**
**وجہ:** Email extension configure نہیں یا SMTP credentials غلط ہیں
**حل:**
1. Firebase Console → Extensions → Email check کریں
2. SMTP settings verify کریں
3. Spam folder check کریں
4. Firebase Console → Firestore میں `mail` collection میں test document add کریں

### **مسئلہ 2: Password Reset Link Expired**
**وجہ:** Firebase کی default expiry 1 گھنٹہ ہے
**حل:**
- Firebase Console → Authentication → Templates → Password reset میں expiry time بڑھائیں
- یا forgot password flow سے نیا link بھیجیں

### **مسئلہ 3: Role Mismatch Error**
**وجہ:** یوزر غلط portal access کرنے کی کوشش کر رہا ہے
**حل:**
- پہلے سے `login_screen.dart` میں handle ہے
- Clear error دکھاتا ہے: "یہ account Student کے لیے ہے، Teacher کے لیے نہیں"

### **مسئلہ 4: UserID نہیں ملا**
**وجہ:** Login directory sync نہیں ہے
**حل:**
```dart
// Ensure provisionStudentAccount/provisionTeacherAccount
// login_directory entry بناتا ہے
await _firebaseService.firestore
    .collection('login_directory')
    .doc(generatedUserId.toLowerCase())
    .set({...});
```

---

## 🎯 اگلے قدم

1. **OTP Production Mode Enable کریں** (5 منٹ)
2. **Firebase Email Extension Setup کریں** (30 منٹ)
3. **Forgot Password Screen Replace کریں** (10 منٹ)
4. **مکمل Flow Test کریں** (1 گھنٹہ)
5. **Production میں Deploy کریں** (15 منٹ)

---

## 📞 مدد

مسائل یا سوالات کے لیے:
- Firebase Console logs check کریں
- Firestore security rules review کریں
- Firebase Emulator سے locally test کریں
- Firebase Extensions میں email delivery monitor کریں

---

**آخری تازہ کاری:** 14 اپریل، 2026
**ورژن:** 1.0.0
**مصنف:** Kiro AI Assistant
