# 🚀 Quick Reference Card

## 📧 Your SMTP Credentials

```
Email: rehmanali.pk60@gmail.com
Password: ibohbtlvlwjziphw
SMTP: smtp.gmail.com:587
Connection: smtp://rehmanali.pk60@gmail.com:ibohbtlvlwjziphw@smtp.gmail.com:587
```

---

## ⚡ Quick Deploy Commands

```bash
# 1. Deploy rules
firebase deploy --only firestore:rules

# 2. Install extension
firebase ext:install firebase/firestore-send-email

# 3. Deploy extension
firebase deploy --only extensions

# 4. Test app
flutter run
```

---

## 🧪 Quick Test

### Test Email:
```bash
# Add to Firestore 'mail' collection:
{
  "to": ["your-email@gmail.com"],
  "message": {
    "subject": "Test",
    "html": "<h1>Test</h1>"
  }
}
```

### Test OTP:
```bash
flutter run
# Login → Forgot Password → Enter email → Check inbox
```

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| `FINAL_SETUP_STEPS.md` | Deployment guide |
| `IMPLEMENTATION_COMPLETE.md` | What was done |
| `firebase-email-extension-config.md` | SMTP config |
| `setup-email-extension.bat` | Windows setup |
| `setup-email-extension.sh` | Linux/Mac setup |

---

## 🔍 Quick Checks

### Firebase Console:
- Extensions → Email (logs)
- Firestore → mail (delivery status)
- Firestore → email_otps (OTP records)

### App Testing:
- Student login ✓
- Teacher login ✓
- Principal login ✓
- Forgot password ✓
- OTP verification ✓

---

## 🐛 Quick Fixes

### Email not sending?
```bash
firebase ext:logs firestore-send-email
```

### OTP not working?
Check Firestore → email_otps collection

### Extension not installed?
```bash
firebase ext:list
firebase ext:install firebase/firestore-send-email
```

---

## 📞 Quick Support

1. Check `FINAL_SETUP_STEPS.md`
2. Check Firebase Console logs
3. Run `flutter run --verbose`
4. Check Firestore collections

---

**Status:** ✅ Ready to Deploy
**Time:** ~25 minutes total
