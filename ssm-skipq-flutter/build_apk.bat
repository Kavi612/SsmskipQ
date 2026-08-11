@echo off
REM Build SkipQ APK for Android
cd /d "%~dp0"
echo.
echo === Building SkipQ APK ===
echo.
flutter pub get
if errorlevel 1 goto fail
flutter build apk --release --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
if errorlevel 1 goto fail
echo.
echo SUCCESS! APK is here:
echo %cd%\build\app\outputs\flutter-apk\app-release.apk
explorer build\app\outputs\flutter-apk
goto end

:fail
echo.
echo Build failed. Read START_HERE.md for help.
pause
exit /b 1

:end
pause
