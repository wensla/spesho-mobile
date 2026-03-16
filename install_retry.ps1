$env:JAVA_HOME = "F:\jdk17\jdk-17.0.14+7"
$env:ANDROID_HOME = "F:\android_sdk"
$env:ANDROID_SDK_ROOT = "F:\android_sdk"
$env:PATH = "F:\jdk17\jdk-17.0.14+7\bin;F:\android_sdk\cmdline-tools\latest\bin;F:\android_sdk\platform-tools;" + $env:PATH

$maxAttempts = 10
$attempt = 0
$success = $false

while ($attempt -lt $maxAttempts -and -not $success) {
    $attempt++
    Write-Host "===== Attempt $attempt of $maxAttempts at $(Get-Date -Format 'HH:mm:ss') ====="

    # Run sdkmanager
    $proc = Start-Process -FilePath "F:\android_sdk\cmdline-tools\latest\bin\sdkmanager.bat" `
        -ArgumentList "--sdk_root=F:\android_sdk", "--no_https", "system-images;android-35;google_apis;x86_64" `
        -RedirectStandardInput "F:\Dev\spesho\yes_input.txt" `
        -RedirectStandardOutput "F:\Dev\spesho\sdk_stdout.txt" `
        -RedirectStandardError "F:\Dev\spesho\sdk_stderr.txt" `
        -NoNewWindow -PassThru

    Write-Host "sdkmanager PID: $($proc.Id)"
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode

    # Check stderr for errors
    $stderr = Get-Content "F:\Dev\spesho\sdk_stderr.txt" -Raw -ErrorAction SilentlyContinue
    Write-Host "Exit code: $exitCode"
    if ($stderr) { Write-Host "STDERR: $stderr" }

    # Check if system image was installed
    $imgFiles = Get-ChildItem "F:\android_sdk\system-images\android-35\google_apis\x86_64" `
        -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".installer" }

    if ($imgFiles.Count -gt 0) {
        Write-Host "SUCCESS! System image installed with $($imgFiles.Count) files."
        $success = $true
    } else {
        Write-Host "System image still empty. Waiting 10s before retry..."
        Start-Sleep -Seconds 10
    }
}

if ($success) {
    Write-Host ""
    Write-Host "=== Creating AVD ==="
    "no" | & "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd `
        --name "Spesho_Pixel_35" `
        --package "system-images;android-35;google_apis;x86_64" `
        --device "pixel_6" `
        --force

    Write-Host ""
    Write-Host "AVD list:"
    & "F:\android_sdk\cmdline-tools\latest\bin\avdmanager.bat" list avd
    Write-Host "DONE! AVD is ready."
} else {
    Write-Host "FAILED after $maxAttempts attempts."
}
