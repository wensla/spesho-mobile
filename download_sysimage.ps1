$url = "https://dl.google.com/android/repository/sys-img/google_apis/x86_64-35_r09.zip"
$dest = "F:\android_sdk\.temp\x86_64-35_r09.zip"
$finalDir = "F:\android_sdk\system-images\android-35\google_apis\x86_64"

# Ensure temp dir exists
New-Item -ItemType Directory -Force -Path "F:\android_sdk\.temp" | Out-Null

Write-Host "Starting BITS download of Android system image (~1.66GB)..."
Write-Host "Destination: $dest"
Write-Host "Time: $(Get-Date)"

# Remove stale BITS job if exists
Get-BitsTransfer -Name "AndroidSysImg" -ErrorAction SilentlyContinue | Remove-BitsTransfer

# Start BITS transfer (handles connection resets automatically)
$bitsJob = Start-BitsTransfer -Source $url -Destination $dest `
    -DisplayName "AndroidSysImg" `
    -Description "Android 35 x86_64 System Image" `
    -Asynchronous

Write-Host "BITS Job ID: $($bitsJob.JobId)"
Write-Host "Monitoring download progress..."

# Monitor until complete
while ($bitsJob.JobState -notin @("Transferred", "Error")) {
    $bitsJob = Get-BitsTransfer -JobId $bitsJob.JobId
    $state = $bitsJob.JobState

    if ($state -eq "Transferring") {
        $transferred = $bitsJob.BytesTransferred
        $total = $bitsJob.BytesTotal
        if ($total -gt 0) {
            $pct = [math]::Round(($transferred / $total) * 100, 1)
            $mb = [math]::Round($transferred / 1MB, 1)
            $totalMb = [math]::Round($total / 1MB, 1)
            Write-Host "  Progress: $pct% ($mb MB / $totalMb MB) at $(Get-Date -Format 'HH:mm:ss')"
        }
    } elseif ($state -eq "TransientError") {
        Write-Host "  Transient error - BITS will auto-retry at $(Get-Date -Format 'HH:mm:ss')"
        Resume-BitsTransfer -BitsJob $bitsJob -ErrorAction SilentlyContinue
    } else {
        Write-Host "  State: $state at $(Get-Date -Format 'HH:mm:ss')"
    }

    Start-Sleep -Seconds 30
}

$finalState = $bitsJob.JobState
Write-Host ""
Write-Host "Final state: $finalState at $(Get-Date)"

if ($finalState -eq "Transferred") {
    Complete-BitsTransfer -BitsJob $bitsJob
    Write-Host "Download complete! Extracting system image..."

    # Extract to system-images directory
    Write-Host "Extracting $dest..."
    Expand-Archive -Path $dest -DestinationPath "F:\android_sdk\.temp\sysimg_extract" -Force

    # Find extracted folder
    $extracted = Get-ChildItem "F:\android_sdk\.temp\sysimg_extract" | Select-Object -First 1
    Write-Host "Extracted to: $($extracted.FullName)"
    Write-Host "Contents:"
    Get-ChildItem $extracted.FullName | Select-Object Name

    # Move files to final location
    Write-Host "Moving to $finalDir..."
    if (Test-Path $finalDir) {
        Get-ChildItem $finalDir | Where-Object { $_.Name -ne ".installer" } | Remove-Item -Recurse -Force
    }

    Get-ChildItem $extracted.FullName | ForEach-Object {
        Copy-Item $_.FullName -Destination $finalDir -Recurse -Force
        Write-Host "  Copied: $($_.Name)"
    }

    # Also create source.properties if not present
    $srcProps = "$finalDir\source.properties"
    if (-not (Test-Path $srcProps)) {
        @"
Pkg.Desc=Google APIs Intel x86_64 Atom System Image
Pkg.UserSrc=false
Pkg.Revision=9
AndroidVersion.ApiLevel=35
SystemImage.TagId=google_apis
SystemImage.TagDisplay=Google APIs
Abi=x86_64
"@ | Out-File $srcProps -Encoding UTF8
    }

    Write-Host ""
    Write-Host "System image installed! Files:"
    Get-ChildItem $finalDir | Select-Object Name, Length

    # Cleanup
    Remove-Item $dest -Force -ErrorAction SilentlyContinue
    Remove-Item "F:\android_sdk\.temp\sysimg_extract" -Recurse -Force -ErrorAction SilentlyContinue

} else {
    Write-Host "ERROR: Download failed! State=$finalState"
    if ($bitsJob.ErrorDescription) {
        Write-Host "Error: $($bitsJob.ErrorDescription)"
    }
    Get-BitsTransfer -JobId $bitsJob.JobId | Remove-BitsTransfer
}
