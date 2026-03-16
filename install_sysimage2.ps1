$env:JAVA_HOME = "F:\jdk17\jdk-17.0.14+7"
$env:ANDROID_HOME = "F:\android_sdk"
$env:ANDROID_SDK_ROOT = "F:\android_sdk"
$env:PATH = "F:\jdk17\jdk-17.0.14+7\bin;F:\android_sdk\cmdline-tools\latest\bin;F:\android_sdk\platform-tools;" + $env:PATH

$logFile = "F:\Dev\spesho\sdk_install.log"
"Starting install at $(Get-Date)" | Out-File $logFile

Write-Host "Installing system image..."
$process = Start-Process -FilePath "F:\android_sdk\cmdline-tools\latest\bin\sdkmanager.bat" `
    -ArgumentList '--sdk_root=F:\android_sdk', 'system-images;android-35;google_apis;x86_64' `
    -RedirectStandardInput "F:\Dev\spesho\yes_input.txt" `
    -RedirectStandardOutput "F:\Dev\spesho\sdk_stdout.txt" `
    -RedirectStandardError "F:\Dev\spesho\sdk_stderr.txt" `
    -NoNewWindow `
    -PassThru

Write-Host "sdkmanager PID: $($process.Id)"
"sdkmanager PID: $($process.Id)" | Out-File $logFile -Append

$process.WaitForExit()
$exitCode = $process.ExitCode
"Exit code: $exitCode at $(Get-Date)" | Out-File $logFile -Append

Write-Host "sdkmanager exit code: $exitCode"

Write-Host ""
Write-Host "STDOUT:"
Get-Content "F:\Dev\spesho\sdk_stdout.txt" -Tail 20

Write-Host ""
Write-Host "STDERR:"
Get-Content "F:\Dev\spesho\sdk_stderr.txt" -Tail 20
