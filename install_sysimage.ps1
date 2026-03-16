$env:JAVA_HOME = "F:\jdk17\jdk-17.0.14+7"
$env:ANDROID_HOME = "F:\android_sdk"
$env:ANDROID_SDK_ROOT = "F:\android_sdk"
$env:PATH = "F:\jdk17\jdk-17.0.14+7\bin;F:\android_sdk\cmdline-tools\latest\bin;F:\android_sdk\platform-tools;" + $env:PATH

Write-Host "Installing system image (this may take 5-15 minutes, ~1.5GB download)..."
"y" | & "F:\android_sdk\cmdline-tools\latest\bin\sdkmanager.bat" `
    --sdk_root="F:\android_sdk" `
    "system-images;android-35;google_apis;x86_64"

Write-Host ""
Write-Host "Done! Checking installation..."
Get-ChildItem "F:\android_sdk\system-images\android-35\google_apis\x86_64" | Select-Object Name
