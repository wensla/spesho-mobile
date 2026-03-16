$url = "https://dl.google.com/android/repository/sys-img/google_apis/x86_64-35_r09.zip"
$dest = "F:\android_sdk\.temp\x86_64-35_r09.zip"
$logFile = "F:\Dev\spesho\download_progress.log"

New-Item -ItemType Directory -Force -Path "F:\android_sdk\.temp" | Out-Null

# Get total size
$head = [System.Net.WebRequest]::Create($url)
$head.Method = "HEAD"
$resp = $head.GetResponse()
$totalBytes = $resp.ContentLength
$resp.Close()
"Total size: $totalBytes bytes ($([math]::Round($totalBytes/1MB,1)) MB)" | Tee-Object -FilePath $logFile -Append

# Resume if partial download exists
$startByte = 0
if (Test-Path $dest) {
    $startByte = (Get-Item $dest).Length
    "Resuming from byte $startByte ($([math]::Round($startByte/1MB,1)) MB already downloaded)" | Tee-Object -FilePath $logFile -Append
}

$maxRetries = 20
$retry = 0
$bufferSize = 1MB

while ($startByte -lt $totalBytes -and $retry -lt $maxRetries) {
    try {
        $req = [System.Net.WebRequest]::Create($url)
        $req.Method = "GET"
        $req.Timeout = 30000
        $req.ReadWriteTimeout = 60000
        if ($startByte -gt 0) {
            $req.AddRange($startByte)
        }

        $webResp = $req.GetResponse()
        $stream = $webResp.GetResponseStream()
        $fileStream = [System.IO.FileStream]::new($dest, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)

        $buffer = New-Object byte[] $bufferSize
        $downloaded = $startByte

        while ($true) {
            $read = $stream.Read($buffer, 0, $bufferSize)
            if ($read -eq 0) { break }
            $fileStream.Write($buffer, 0, $read)
            $downloaded += $read

            if (($downloaded - $startByte) % (50MB) -lt $bufferSize) {
                $pct = [math]::Round(($downloaded / $totalBytes) * 100, 1)
                $mbDone = [math]::Round($downloaded / 1MB, 1)
                $totalMb = [math]::Round($totalBytes / 1MB, 1)
                $msg = "$(Get-Date -Format 'HH:mm:ss') - $pct% ($mbDone / $totalMb MB)"
                $msg | Tee-Object -FilePath $logFile -Append
            }
        }

        $fileStream.Close()
        $stream.Close()
        $webResp.Close()
        $startByte = (Get-Item $dest).Length
        $retry = 0  # reset retry on success
        "Chunk complete. Total: $startByte bytes" | Out-File $logFile -Append

    } catch {
        if ($fileStream) { $fileStream.Close() }
        $startByte = if (Test-Path $dest) { (Get-Item $dest).Length } else { 0 }
        $retry++
        $errMsg = "$(Get-Date -Format 'HH:mm:ss') - Error (retry $retry/$maxRetries): $_"
        $errMsg | Tee-Object -FilePath $logFile -Append
        Start-Sleep -Seconds (5 * $retry)
    }
}

if ($startByte -ge $totalBytes) {
    "DOWNLOAD COMPLETE at $(Get-Date)" | Tee-Object -FilePath $logFile -Append
    "File: $dest ($([math]::Round($startByte/1MB,1)) MB)" | Tee-Object -FilePath $logFile -Append
} else {
    "DOWNLOAD FAILED after $maxRetries retries. Downloaded $startByte / $totalBytes bytes" | Tee-Object -FilePath $logFile -Append
}
