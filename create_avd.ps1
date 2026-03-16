$env:JAVA_HOME = "F:\jdk17\jdk-17.0.14+7"
$env:ANDROID_HOME = "F:\android_sdk"
$env:ANDROID_SDK_ROOT = "F:\android_sdk"
$env:PATH = "F:\jdk17\jdk-17.0.14+7\bin;F:\android_sdk\cmdline-tools\latest\bin;F:\android_sdk\platform-tools;F:\android_sdk\emulator;" + $env:PATH

Write-Host "Java version:"
& "F:\jdk17\jdk-17.0.14+7\bin\java.exe" -version

Write-Host ""
Write-Host "Listing available system images..."
& "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" list target

Write-Host ""
Write-Host "Creating AVD..."
"no" | & "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd `
    --name "Spesho_Pixel_35" `
    --package "system-images;android-35;google_apis;x86_64" `
    --device "pixel_6" `
    --force

Write-Host ""
Write-Host "Listing AVDs:"
& "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" list avd
