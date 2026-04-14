@echo off
echo ========================================
echo Building Release APK
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
call flutter clean

echo.
echo Step 2: Getting dependencies...
call flutter pub get

echo.
echo Step 3: Building release APK...
echo This may take 5-10 minutes...
call flutter build apk --release

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.

echo APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.

echo Copying APK to Desktop...
copy build\app\outputs\flutter-apk\app-release.apk %USERPROFILE%\Desktop\SchoolApp.apk

echo.
echo ========================================
echo APK copied to Desktop as SchoolApp.apk
echo ========================================
echo.
echo You can now share this APK via WhatsApp!
echo.

pause
