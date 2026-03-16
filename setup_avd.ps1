$env:JAVA_HOME = "F:\jdk17\jdk-17.0.14+7"
$env:ANDROID_HOME = "F:\android_sdk"
$env:ANDROID_SDK_ROOT = "F:\android_sdk"
$env:PATH = "F:\jdk17\jdk-17.0.14+7\bin;F:\android_sdk\cmdline-tools\latest\bin;F:\android_sdk\platform-tools;F:\android_sdk\emulator;" + $env:PATH

Write-Host "Checking system image..."
$imgPath = "F:\android_sdk\system-images\android-35\google_apis\x86_64"
$files = Get-ChildItem $imgPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".installer" }

if ($files.Count -eq 0) {
    Write-Host "ERROR: System image not fully installed at $imgPath"
    Write-Host "Files found:"
    Get-ChildItem $imgPath
    exit 1
}

Write-Host "System image found. Creating AVD..."
"no" | & "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd `
    --name "Spesho_Pixel_35" `
    --package "system-images;android-35;google_apis;x86_64" `
    --device "pixel_6" `
    --force

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "AVD created successfully!"
    Write-Host ""
    Write-Host "Available AVDs:"
    & "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" list avd
} else {
    Write-Host "AVD creation failed with exit code $LASTEXITCODE"
}
