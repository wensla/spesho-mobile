@echo off
set JAVA_HOME=F:\jdk17\jdk-17.0.14+7
set ANDROID_HOME=F:\android_sdk
set ANDROID_SDK_ROOT=F:\android_sdk
set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\emulator;%PATH%

echo Creating AVD...
echo no | avdmanager.bat create avd --name "Spesho_Pixel_35" --package "system-images;android-35;google_apis;x86_64" --device "pixel_6" --force

echo.
echo Listing AVDs:
avdmanager.bat list avd
