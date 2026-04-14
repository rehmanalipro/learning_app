@echo off
REM Firebase Email Extension Setup Script for Windows
REM This script automates the Firebase Email Extension installation

echo.
echo ========================================
echo Firebase Email Extension Setup
echo ========================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Firebase CLI not found!
    echo Install it with: npm install -g firebase-tools
    pause
    exit /b 1
)

echo [OK] Firebase CLI found
echo.

REM Login to Firebase
echo Logging in to Firebase...
call firebase login

echo.
echo Installing Firebase Email Extension...
echo.

REM Install extension
call firebase ext:install firebase/firestore-send-email

echo.
echo You will be prompted for configuration. Use these values:
echo.
echo SMTP Connection URI:
echo smtp://rehmanali.pk60@gmail.com:ibohbtlvlwjziphw@smtp.gmail.com:587
echo.
echo Default FROM:
echo rehmanali.pk60@gmail.com
echo.
echo Default REPLY-TO:
echo rehmanali.pk60@gmail.com
echo.
echo Mail Collection:
echo mail
echo.

pause

echo.
echo Deploying Firestore rules...
call firebase deploy --only firestore:rules

echo.
echo Deploying extension...
call firebase deploy --only extensions

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Test email sending in Firebase Console
echo 2. Check Extensions tab for logs
echo 3. Run your Flutter app: flutter run
echo.

pause
