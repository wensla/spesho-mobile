@echo off
title Spesho Android Emulator
echo ========================================
echo   Spesho Products Management System
echo   Android Emulator Launcher
echo ========================================
echo.

set ANDROID_HOME=F:\android_sdk
set JAVA_HOME=F:\jdk17\jdk-17.0.14+7
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\emulator;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%

echo Launching emulator: Spesho_Pixel_35
echo This may take 1-2 minutes to boot...
echo.

start "Android Emulator" /B "%ANDROID_HOME%\emulator\emulator.exe" -avd Spesho_Pixel_35 -no-snapshot-load

echo Waiting for emulator to boot...
timeout /t 30 /nobreak > nul

:WAIT_BOOT
adb shell getprop sys.boot_completed 2>nul | findstr "1" > nul
if %errorlevel% neq 0 (
    echo Still booting... (checking every 10s)
    timeout /t 10 /nobreak > nul
    goto WAIT_BOOT
)

echo.
echo Emulator is ready!
echo.

echo Installing Spesho APK...
adb install -r "%~dp0Spesho_v1.0.apk"

if %errorlevel% equ 0 (
    echo.
    echo APK installed successfully!
    echo Launching Spesho app...
    adb shell am start -n com.spesho.app/.MainActivity
) else (
    echo Failed to install APK. Check if emulator is running.
)

pause
