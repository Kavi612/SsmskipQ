@echo off
REM Run SkipQ Flutter app on emulator or connected phone
cd /d "%~dp0"
echo.
echo === SkipQ Flutter ===
echo.
flutter pub get
if errorlevel 1 goto fail
echo.
echo Starting app... (first run can take 10-15 minutes)
echo.
flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
if errorlevel 1 goto fail
goto end

:fail
echo.
echo Something failed. Read START_HERE.md for help.
pause
exit /b 1

:end
pause
