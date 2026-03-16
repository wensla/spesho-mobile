$url = "https://dl.google.com/android/repository/sys-img/google_apis/x86_64-35_r09.zip"
$totalSize = 1738815903
$existingFile = "F:\android_sdk\.temp\x86_64-35_r09.zip"
$existingSize = (Get-Item $existingFile).Length
$tmpDir = "F:\android_sdk\.temp\parts"
$logFile = "F:\Dev\spesho\parallel_dl.log"

New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

"=== Parallel Download at $(Get-Date) ===" | Tee-Object $logFile -Append
"Existing: $existingSize bytes, Total: $totalSize bytes" | Tee-Object $logFile -Append

$remaining = $totalSize - $existingSize
$numParts = 4
$partSize = [math]::Ceiling($remaining / $numParts)

"Remaining: $remaining bytes, split into $numParts parts of ~$partSize bytes each" | Tee-Object $logFile -Append

# Launch parallel curl downloads
$jobs = @()
for ($i = 0; $i -lt $numParts; $i++) {
    $startByte = $existingSize + ($i * $partSize)
    $endByte   = [math]::Min($existingSize + (($i + 1) * $partSize) - 1, $totalSize - 1)
    $partFile  = "$tmpDir\part$i.bin"

    "Starting part $i : bytes $startByte-$endByte to $partFile" | Tee-Object $logFile -Append

    $job = Start-Job -ScriptBlock {
        param($url, $startByte, $endByte, $partFile)
        & curl.exe -L --retry 20 --retry-delay 3 --retry-max-time 0 `
            -H "Range: bytes=$startByte-$endByte" `
            -o $partFile `
            $url 2>&1
    } -ArgumentList $url, $startByte, $endByte, $partFile

    $jobs += @{ Job = $job; Part = $i; Start = $startByte; End = $endByte; File = $partFile }
}

"All $numParts downloads started. Waiting for completion..." | Tee-Object $logFile -Append

# Monitor until all done
while ($true) {
    $done = $jobs | Where-Object { $_.Job.State -in @("Completed", "Failed") }
    $running = $jobs | Where-Object { $_.Job.State -eq "Running" }

    $status = "$(Get-Date -Format 'HH:mm:ss') - $($done.Count)/$numParts done, $($running.Count) running"
    # Print sizes of completed part files
    foreach ($j in $jobs) {
        $sz = if (Test-Path $j.File) { [math]::Round((Get-Item $j.File).Length/1MB,1) } else { 0 }
        $expected = [math]::Round(($j.End - $j.Start + 1)/1MB, 1)
        $status += " | p$($j.Part):${sz}/${expected}MB"
    }
    $status | Tee-Object $logFile -Append

    if ($done.Count -eq $numParts) { break }
    Start-Sleep -Seconds 30
}

# Check all parts succeeded
$allOk = $true
foreach ($j in $jobs) {
    $result = Receive-Job -Job $j.Job
    $state = $j.Job.State
    if ($state -ne "Completed") {
        "FAILED: part $($j.Part) state=$state" | Tee-Object $logFile -Append
        $allOk = $false
    }
    $actualSize = if (Test-Path $j.File) { (Get-Item $j.File).Length } else { 0 }
    $expectedSize = $j.End - $j.Start + 1
    if ($actualSize -ne $expectedSize) {
        "SIZE MISMATCH part $($j.Part): got $actualSize, expected $expectedSize" | Tee-Object $logFile -Append
        $allOk = $false
    }
}

if (-not $allOk) {
    "Some parts failed. Check log." | Tee-Object $logFile -Append
    exit 1
}

"All parts downloaded. Assembling final file..." | Tee-Object $logFile -Append

# Assemble: append parts in order to existing file
$outStream = [System.IO.FileStream]::new($existingFile, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)
for ($i = 0; $i -lt $numParts; $i++) {
    $partFile = "$tmpDir\part$i.bin"
    "Appending part $i ($partFile)..." | Tee-Object $logFile -Append
    $partBytes = [System.IO.File]::ReadAllBytes($partFile)
    $outStream.Write($partBytes, 0, $partBytes.Length)
}
$outStream.Close()

$finalSize = (Get-Item $existingFile).Length
"Assembly complete. Final size: $finalSize bytes (expected $totalSize)" | Tee-Object $logFile -Append

if ($finalSize -eq $totalSize) {
    "DOWNLOAD COMPLETE!" | Tee-Object $logFile -Append
    # Cleanup parts
    Remove-Item $tmpDir -Recurse -Force
} else {
    "WARNING: Size mismatch! $finalSize vs $totalSize" | Tee-Object $logFile -Append
}
