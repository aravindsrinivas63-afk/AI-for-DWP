[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Path = 'C:\Program Files',

    [Parameter()]
    [ValidateRange(1, 1048576)]
    [int]$ThresholdMB = 100,

    [Parameter()]
    [string]$OutputFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$scanStart = Get-Date
$thresholdBytes = [int64]$ThresholdMB * 1MB
$totalFilesScanned = 0
$totalLargeBytes = [int64]0
$largeFiles = New-Object System.Collections.Generic.List[object]
$scanErrors = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error ('Path not found: {0}' -f $Path)
    return
}

$resolvedPath = (Resolve-Path -LiteralPath $Path).Path

Write-Output ('Large File Finder started at: {0}' -f $scanStart)
Write-Output ('Scan Path: {0}' -f $resolvedPath)
Write-Output ('ThresholdMB: {0}' -f $ThresholdMB)
Write-Output ''

$gciErrors = @()
$allFiles = Get-ChildItem -LiteralPath $resolvedPath -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +gciErrors

foreach ($errorRecord in $gciErrors) {
    $scanErrors.Add($errorRecord.ToString())
}

$totalCandidates = @($allFiles).Count
$currentIndex = 0

foreach ($file in $allFiles) {
    $currentIndex++
    $totalFilesScanned++

    if (($currentIndex % 200 -eq 0) -or ($currentIndex -eq $totalCandidates)) {
        $percentComplete = if ($totalCandidates -gt 0) {
            [int](($currentIndex / $totalCandidates) * 100)
        }
        else {
            0
        }

        Write-Progress -Activity 'Scanning files for large items' -Status ('Scanned {0} of {1} files. Matches: {2}' -f $currentIndex, $totalCandidates, $largeFiles.Count) -PercentComplete $percentComplete
    }

    try {
        if ($file.Length -ge $thresholdBytes) {
            $sizeBytes = [int64]$file.Length
            $sizeMB = [Math]::Round($sizeBytes / 1MB, 2)
            $totalLargeBytes += $sizeBytes

            $largeFiles.Add([pscustomobject]@{
                    'File Name'     = $file.Name
                    'Full Path'     = $file.FullName
                    'Size in MB'    = $sizeMB
                    'Created Date'  = $file.CreationTime
                    'Modified Date' = $file.LastWriteTime
                    'SizeBytes'     = $sizeBytes
                })
        }
    }
    catch {
        $scanErrors.Add(('File processing error for {0}: {1}' -f $file.FullName, $_.Exception.Message))
    }
}

Write-Progress -Activity 'Scanning files for large items' -Completed

$sorted = $largeFiles | Sort-Object -Property SizeBytes -Descending
$displayResults = $sorted | Select-Object 'File Name', 'Full Path', 'Size in MB', 'Created Date', 'Modified Date'

if (@($displayResults).Count -gt 0) {
    Write-Output 'Large files found (largest first):'
    Write-Output ''
    $displayResults | Format-Table -AutoSize
}
else {
    Write-Output 'No files matched the threshold.'
}

if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
    try {
        $displayResults | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8
        Write-Output ''
        Write-Output ('CSV report saved to: {0}' -f $OutputFile)
    }
    catch {
        $scanErrors.Add(('CSV export error: {0}' -f $_.Exception.Message))
        Write-Warning ('Failed to write CSV report to {0}' -f $OutputFile)
    }
}

$scanEnd = Get-Date
$duration = $scanEnd - $scanStart
$totalLargeMB = [Math]::Round($totalLargeBytes / 1MB, 2)
$totalLargeGB = [Math]::Round($totalLargeBytes / 1GB, 3)

Write-Output ''
Write-Output 'Summary:'
[pscustomobject]@{
    'Total files scanned'        = $totalFilesScanned
    'Number of large files found' = @($displayResults).Count
    'Total size of large files'  = ('{0} MB ({1} GB)' -f $totalLargeMB, $totalLargeGB)
    'Scan start time'            = $scanStart
    'Scan end time'              = $scanEnd
    'Scan duration'              = $duration.ToString()
} | Format-List

if ($scanErrors.Count -gt 0) {
    Write-Output ''
    Write-Warning ('The scan completed with {0} non-terminating errors (for example access denied).' -f $scanErrors.Count)
}
