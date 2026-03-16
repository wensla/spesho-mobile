@echo off
title Spesho - Full Setup
echo ========================================
echo   Spesho Products Management System
echo   Full Setup and Launch
echo ========================================
echo.

set ANDROID_HOME=F:\android_sdk
set JAVA_HOME=F:\jdk17\jdk-17.0.14+7
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\emulator;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin;%PATH%

:: Step 1: Check backend
echo [1/4] Checking backend...
curl -s http://localhost:5000/api/auth/login -X POST -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"admin123\"}" >nul 2>&1
if %errorlevel% equ 0 (
    echo       Backend already running
) else (
    echo       Starting backend...
    start "Spesho Backend" /B "%~dp0start_backend.bat"
    timeout /t 5 /nobreak >nul
)

:: Step 2: Check AVD
echo [2/4] Checking Android Virtual Device...
avdmanager.bat list avd | findstr "Spesho_Pixel_35" >nul 2>&1
if %errorlevel% neq 0 (
    echo       Creating AVD...
    echo no | avdmanager.bat create avd --name "Spesho_Pixel_35" --package "system-images;android-35;google_apis;x86_64" --device "pixel_6" --force
)
echo       AVD ready

:: Step 3: Start emulator
echo [3/4] Launching emulator...
start "Android Emulator" /B "%ANDROID_HOME%\emulator\emulator.exe" -avd Spesho_Pixel_35 -no-snapshot-load

echo       Waiting for emulator to boot (2-3 minutes)...
:WAIT_BOOT
timeout /t 15 /nobreak >nul
adb shell getprop sys.boot_completed 2>nul | findstr "1" >nul
if %errorlevel% neq 0 (
    echo       Still booting...
    goto WAIT_BOOT
)
echo       Emulator ready!

:: Step 4: Install and launch app
echo [4/4] Installing Spesho app...
adb install -r "%~dp0Spesho_v1.0.apk"
if %errorlevel% equ 0 (
    echo       App installed! Launching...
    adb shell am start -n com.spesho.app/.MainActivity
    echo.
    echo ========================================
    echo   Spesho is running!
    echo   Login: admin / admin123
    echo         salesperson / sales123
    echo ========================================
) else (
    echo       Install failed. Check error above.
)

pause
