# Learning App Release Checklist

Yeh guide future testing aur store release ke liye hai. Is project ka current Android app id `com.synticai.learning_app` hai.

## 1. Sab se zaroori files

In 2 files ko hamesha safe rakhna:

- `android/keystore.properties`
- `android/app/learning_app_release.jks`

In dono ke baghair future Android updates same app par install nahi hongi.

`.jks` ko phone me install nahi karna hota. Yeh sirf app sign karne ke liye hoti hai.

## 2. Har nayi updated app bhejne se pehle

### Step 1: Version update karo

`pubspec.yaml` me version line hoti hai, example:

```yaml
version: 1.0.0+1
```

Agar aap nayi testing build ya nayi release bhej rahe ho to build number barhao:

```yaml
version: 1.0.0+2
```

Ya agar proper app update hai to:

```yaml
version: 1.0.1+2
```

Rule:

- `1.0.0` = user ko dikhne wali version
- `+1` = build number
- Har nayi APK/AAB ke liye `+` wala number barhana best hai

## 3. Android testing ke liye WhatsApp par bhejna

Yeh tab use karo jab aap kisi dost ko Android phone par testing ke liye app bhejna chahte ho.

### Command

```bash
flutter build apk --release
```

### Output file

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Dost ko kya bhejna hai

Sirf yeh file bhejni hai:

- `build/app/outputs/flutter-apk/app-release.apk`

### Important

- `.jks` file kabhi dost ko mat bhejna
- WhatsApp par APK ko document/file ki tarah bhejna
- Agar dost ke phone me purani signed app lagi hui hai, to nayi APK us par update ho jayegi
- Iske liye same package name aur same keystore hona chahiye
- Nayi build bhejte waqt build number barhana better hai

### Agar install/update issue aaye

Check karo:

- Kya nayi APK same project ki signed release build hai
- Kya `android/app/learning_app_release.jks` same wali hi use ho rahi hai
- Kya `pubspec.yaml` ka build number pehle se naya hai

## 4. Play Store release

Play Store ke liye APK ke bajaye AAB use hoti hai.

### Command

```bash
flutter build appbundle --release
```

### Output file

```text
build/app/outputs/bundle/release/app-release.aab
```

### Play Store steps

1. `pubspec.yaml` me version/build number update karo
2. Command chalao: `flutter build appbundle --release`
3. `app-release.aab` ko Google Play Console me upload karo
4. Same signing key use rehni chahiye

### Android future update rule

Har future Play Store update ke liye:

- same `applicationId`
- same release keystore
- naya build number

## 5. iPhone testing aur App Store

Yeh project me `ios/` folder maujood hai, lekin iPhone build aur App Store upload ke liye generally macOS + Xcode chahiye hota hai.

### Windows par kya ho sakta hai

- Aap Flutter code yahin Windows par update kar sakte ho
- iOS code bhi yahin tak ready kar sakte ho
- Final iPhone build aur App Store/TestFlight upload ke liye Mac chahiye hota hai

### iPhone testers ke liye best route

WhatsApp se iPhone app bhejna normal Android jaisa nahi hota.

Best option:

- TestFlight

### Mac par iOS release command

```bash
flutter build ipa --release
```

Uske baad upload usually Xcode ya Transporter se hota hai.

## 6. Aapke liye simple daily rule

Agar aap aglay 1 week code me changes karte rahoge aur updated app bhejni hogi, to Android ke liye yeh simple flow follow karo:

1. Code update karo
2. `pubspec.yaml` me build number barhao
3. `flutter build apk --release`
4. Nayi file `build/app/outputs/flutter-apk/app-release.apk` bhej do

Play Store ke liye:

1. Code update karo
2. Version/build number barhao
3. `flutter build appbundle --release`
4. `app-release.aab` upload karo

## 7. Best backup habit

In cheezon ka backup ek safe folder ya cloud me rakho:

- `android/keystore.properties`
- `android/app/learning_app_release.jks`
- release passwords

In me se kuch lose ho gaya to Android future updates mushkil ho sakti hain.
