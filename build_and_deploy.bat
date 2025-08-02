@echo off
echo 🚀 Building and Deploying Banking Notification App...
echo.

echo 📱 Platform: Cross-platform (Android + iOS)
echo 🖥️  OS: Windows
echo.

echo 🧹 Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ Flutter clean failed!
    pause
    exit /b 1
)

echo 📦 Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Flutter pub get failed!
    pause
    exit /b 1
)

echo.
echo 📋 Build Options:
echo 1. Build Android APK
echo 2. Build iOS IPA (via Codemagic)
echo 3. Build both
echo.
set /p choice="Choose option (1-3): "

if "%choice%"=="1" goto :build_android
if "%choice%"=="2" goto :build_ios
if "%choice%"=="3" goto :build_both
goto :invalid_choice

:build_android
echo.
echo 🤖 Building Android APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ❌ Android build failed!
    pause
    exit /b 1
)
echo ✅ Android APK built successfully!
echo 📁 Location: build/app/outputs/flutter-apk/app-release.apk
goto :end

:build_ios
echo.
echo 🍎 Building iOS IPA via Codemagic...
echo.
echo 📋 Steps to deploy iOS:
echo 1. Push code to GitHub
echo 2. Connect to Codemagic
echo 3. Build automatically
echo 4. Download IPA
echo 5. Install via Sideloadly
echo.
echo 🔗 Codemagic: https://codemagic.io/
echo 🔗 Sideloadly: https://sideloadly.io/
echo.
goto :end

:build_both
echo.
echo 🤖 Building Android APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo ❌ Android build failed!
    pause
    exit /b 1
)
echo ✅ Android APK built successfully!

echo.
echo 🍎 For iOS, follow these steps:
echo 1. Push code to GitHub
echo 2. Connect to Codemagic
echo 3. Build automatically
echo 4. Download IPA
echo 5. Install via Sideloadly
echo.
goto :end

:invalid_choice
echo ❌ Invalid choice! Please choose 1, 2, or 3.
pause
exit /b 1

:end
echo.
echo 🎉 Build process completed!
echo.
echo 📱 Android APK: build/app/outputs/flutter-apk/app-release.apk
echo 🍎 iOS IPA: Download from Codemagic
echo.
pause 