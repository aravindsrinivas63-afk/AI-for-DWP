[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(0, 36500)]
    [int]$DaysOld = 0,

    [Parameter()]
    [string[]]$Path = @(
        $env:TEMP,
        (Join-Path -Path $env:WINDIR -ChildPath 'Temp')
    ),

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [string]$RollbackPath,

    [Parameter()]
    [string]$LogDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

<#
This script safely cleans temp files on Windows endpoints.
- DryRun prints the files that would be removed without changing anything.
- DaysOld controls the age cutoff for cleanup.
- Rollback restores files from the quarantine area created by a cleanup run.
#>

if ($DryRun -and $Rollback) {
    throw 'DryRun and Rollback cannot be used together.'
}

# This section creates the working folders used for logs, rollback metadata, and quarantined files.
$scriptBase = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { (Get-Location).Path } else { $PSScriptRoot }
$resolvedLogDirectory = if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
    Join-Path -Path $scriptBase -ChildPath 'TempCleanupLogs'
}
else {
    $LogDirectory
}

New-Item -ItemType Directory -Path $resolvedLogDirectory -Force | Out-Null

$runStamp = Get-Date -Format 'yyyyMMdd_HHmmssfff'
$script:LogFile = Join-Path -Path $resolvedLogDirectory -ChildPath ("TempCleanup_{0}.log" -f $runStamp)
$script:StateRoot = Join-Path -Path $resolvedLogDirectory -ChildPath 'State'
$script:RunStateRoot = Join-Path -Path $script:StateRoot -ChildPath $runStamp
$script:QuarantineRoot = Join-Path -Path $script:RunStateRoot -ChildPath 'Quarantine'
$script:ManifestPath = Join-Path -Path $script:RunStateRoot -ChildPath 'rollback-manifest.json'

New-Item -ItemType Directory -Path $script:QuarantineRoot -Force | Out-Null

# This section writes timestamped messages to the console and to the log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $entry = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Level, $Message
    Add-Content -LiteralPath $script:LogFile -Value $entry
    Write-Output $entry
}

# This section normalizes a path so later comparisons and restores are reliable.
function Get-NormalizedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    return [System.IO.Path]::GetFullPath($InputPath)
}

# This section converts a root path into a matching prefix for path comparisons.
function Get-RootPrefix {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    $fullPath = Get-NormalizedPath -InputPath $InputPath
    if ($fullPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        return $fullPath
    }

    return $fullPath + [System.IO.Path]::DirectorySeparatorChar
}

# This section finds the best matching cleanup root for a file.
function Get-MatchingRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$NormalizedRoots
    )

    $normalizedFilePath = Get-NormalizedPath -InputPath $FilePath
    $matchedIndex = -1
    $matchedRoot = $null
    $matchedLength = 0

    for ($index = 0; $index -lt $NormalizedRoots.Count; $index++) {
        $currentRoot = $NormalizedRoots[$index]
        if ($normalizedFilePath.StartsWith($currentRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            if ($currentRoot.Length -ge $matchedLength) {
                $matchedIndex = $index
                $matchedRoot = $currentRoot
                $matchedLength = $currentRoot.Length
            }
        }
    }

    return [pscustomobject]@{
        Index = $matchedIndex
        Root = $matchedRoot
    }
}

# This section calculates the relative path used inside quarantine storage.
function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$RootPrefix
    )

    $normalizedFilePath = Get-NormalizedPath -InputPath $FilePath
    if ($normalizedFilePath.Length -le $RootPrefix.Length) {
        return [System.IO.Path]::GetFileName($normalizedFilePath)
    }

    return $normalizedFilePath.Substring($RootPrefix.Length)
}

# This section returns cleanup candidates from either a directory or a single file path.
function Get-CleanupCandidates {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,

        [Parameter(Mandatory = $true)]
        [datetime]$Cutoff
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        Write-Log -Level 'WARN' -Message ("Skipping missing path: {0}" -f $RootPath)
        return @()
    }

    $item = Get-Item -LiteralPath $RootPath -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        Write-Log -Level 'WARN' -Message ("Skipping unreadable path: {0}" -f $RootPath)
        return @()
    }

    if ($item.PSIsContainer) {
        return Get-ChildItem -LiteralPath $RootPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $Cutoff }
    }

    if ($item.LastWriteTime -lt $Cutoff) {
        return @($item)
    }

    return @()
}

# This section locates the latest rollback manifest when the operator does not provide one.
function Get-LatestRollbackManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StateRoot
    )

    if (-not (Test-Path -LiteralPath $StateRoot)) {
        return $null
    }

    return Get-ChildItem -LiteralPath $StateRoot -Filter 'rollback-manifest.json' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object -Property FullName -Descending |
        Select-Object -First 1
}

# This section records the selected settings so the run is easy to audit later.
Write-Log -Message 'Temp file cleanup script started.'
Write-Log -Message ("Mode: {0}" -f ($(if ($Rollback) { 'Rollback' } elseif ($DryRun) { 'DryRun' } else { 'Cleanup' })))
Write-Log -Message ("DaysOld cutoff: {0}" -f $DaysOld)
Write-Log -Message ("Target paths: {0}" -f ($Path -join ', '))
Write-Log -Message ("Log file: {0}" -f $script:LogFile)

# This section initializes summary counters for the final report.
$summary = [ordered]@{
    Mode = if ($Rollback) { 'Rollback' } elseif ($DryRun) { 'DryRun' } else { 'Cleanup' }
    Scanned = 0
    Eligible = 0
    Deleted = 0
    Restored = 0
    SkippedLocked = 0
    SkippedMissing = 0
    Errors = 0
}

# This section restores files from quarantine when rollback mode is requested.
if ($Rollback) {
    $manifestToUse = $null
    if (-not [string]::IsNullOrWhiteSpace($RollbackPath)) {
        if (Test-Path -LiteralPath $RollbackPath) {
            $manifestToUse = Get-Item -LiteralPath $RollbackPath -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Log -Level 'ERROR' -Message ("Rollback path not found: {0}" -f $RollbackPath)
            $summary.Errors++
        }
    }
    else {
        $manifestToUse = Get-LatestRollbackManifest -StateRoot $script:StateRoot
    }

    if ($null -eq $manifestToUse) {
        Write-Log -Level 'WARN' -Message 'No rollback manifest was found, so there is nothing to restore.'
    }
    else {
        Write-Log -Message ("Using rollback manifest: {0}" -f $manifestToUse.FullName)

        try {
            $manifestData = Get-Content -LiteralPath $manifestToUse.FullName -Raw | ConvertFrom-Json
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Failed to read rollback manifest: {0}" -f $_.Exception.Message)
            $summary.Errors++
            $manifestData = $null
        }

        if ($null -ne $manifestData) {
            foreach ($entry in @($manifestData)) {
                $summary.Scanned++

                try {
                    if ([string]::IsNullOrWhiteSpace($entry.BackupPath) -or [string]::IsNullOrWhiteSpace($entry.SourcePath)) {
                        Write-Log -Level 'WARN' -Message 'Skipping incomplete rollback entry.'
                        $summary.SkippedMissing++
                        continue
                    }

                    if (Test-Path -LiteralPath $entry.SourcePath) {
                        Write-Log -Message ("Rollback skipped because the source already exists: {0}" -f $entry.SourcePath)
                        continue
                    }

                    if (-not (Test-Path -LiteralPath $entry.BackupPath)) {
                        Write-Log -Level 'WARN' -Message ("Rollback backup is missing: {0}" -f $entry.BackupPath)
                        $summary.SkippedMissing++
                        continue
                    }

                    $destinationDirectory = Split-Path -Path $entry.SourcePath -Parent
                    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
                        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
                    }

                    Move-Item -LiteralPath $entry.BackupPath -Destination $entry.SourcePath -ErrorAction Stop
                    $summary.Restored++
                    Write-Log -Level 'SUCCESS' -Message ("Restored file: {0}" -f $entry.SourcePath)
                }
                catch [System.IO.IOException] {
                    $summary.SkippedLocked++
                    Write-Log -Level 'WARN' -Message ("Rollback skipped for a file that appears locked or unavailable: {0}" -f $entry.BackupPath)
                }
                catch [System.UnauthorizedAccessException] {
                    $summary.SkippedLocked++
                    Write-Log -Level 'WARN' -Message ("Rollback skipped due to access restrictions: {0}" -f $entry.BackupPath)
                }
                catch {
                    $summary.Errors++
                    Write-Log -Level 'ERROR' -Message ("Rollback failed for {0}: {1}" -f $entry.BackupPath, $_.Exception.Message)
                }
            }
        }
    }
}
else {
    # This section computes the age cutoff and processes each file independently.
    $cutoff = (Get-Date).AddDays(-$DaysOld)
    $normalizedRoots = New-Object 'System.Collections.Generic.List[string]'

    foreach ($root in $Path) {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        [void]$normalizedRoots.Add((Get-RootPrefix -InputPath $root))
    }

    $manifestEntries = New-Object System.Collections.Generic.List[object]

    foreach ($rootPath in $Path) {
        if ([string]::IsNullOrWhiteSpace($rootPath)) {
            continue
        }

        Write-Log -Message ("Scanning path: {0}" -f $rootPath)

        $candidates = Get-CleanupCandidates -RootPath $rootPath -Cutoff $cutoff
        foreach ($file in $candidates) {
            $summary.Scanned++
            $summary.Eligible++

            if ($DryRun) {
                Write-Log -Message ("[DRY-RUN] Would delete: {0}" -f $file.FullName)
                Write-Output ("Would delete: {0}" -f $file.FullName)
                continue
            }

            try {
                $match = Get-MatchingRoot -FilePath $file.FullName -NormalizedRoots $normalizedRoots
                if ($match.Index -lt 0 -or [string]::IsNullOrWhiteSpace($match.Root)) {
                    $summary.Errors++
                    Write-Log -Level 'ERROR' -Message ("Could not resolve a cleanup root for: {0}" -f $file.FullName)
                    continue
                }

                $relativePath = Get-RelativePath -FilePath $file.FullName -RootPrefix $match.Root
                $quarantineRootForPath = Join-Path -Path $script:QuarantineRoot -ChildPath ("Root{0}" -f $match.Index)
                $backupPath = Join-Path -Path $quarantineRootForPath -ChildPath $relativePath
                $backupParent = Split-Path -Path $backupPath -Parent

                if (-not (Test-Path -LiteralPath $backupParent)) {
                    New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
                }

                Move-Item -LiteralPath $file.FullName -Destination $backupPath -ErrorAction Stop
                $summary.Deleted++

                $manifestEntries.Add([pscustomobject]@{
                    SourcePath = $file.FullName
                    BackupPath = $backupPath
                    OriginalRoot = $rootPath
                    DeletedOn = Get-Date
                    LastWriteTime = $file.LastWriteTime
                    LengthBytes = $file.Length
                }) | Out-Null

                Write-Log -Level 'SUCCESS' -Message ("Moved to quarantine: {0}" -f $file.FullName)
            }
            catch [System.IO.IOException] {
                $summary.SkippedLocked++
                Write-Log -Level 'WARN' -Message ("Skipped locked or in-use file: {0}" -f $file.FullName)
            }
            catch [System.UnauthorizedAccessException] {
                $summary.SkippedLocked++
                Write-Log -Level 'WARN' -Message ("Skipped access-restricted file: {0}" -f $file.FullName)
            }
            catch {
                $summary.Errors++
                Write-Log -Level 'ERROR' -Message ("Failed to process {0}: {1}" -f $file.FullName, $_.Exception.Message)
            }
        }
    }

    if (-not $DryRun) {
        if ($manifestEntries.Count -gt 0) {
            $manifestEntries | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $script:ManifestPath
            Write-Log -Message ("Rollback manifest written to: {0}" -f $script:ManifestPath)
        }
        else {
            Write-Log -Message 'No eligible files were moved, so no rollback manifest was created.'
        }
    }
}

# This section writes the final summary so the operator can verify the outcome quickly.
Write-Log -Message 'Cleanup run complete.'
Write-Log -Message ("Scanned items: {0}" -f $summary.Scanned)
Write-Log -Message ("Eligible items: {0}" -f $summary.Eligible)
Write-Log -Message ("Files deleted or restored: {0}" -f ($(if ($Rollback) { $summary.Restored } else { $summary.Deleted })))
Write-Log -Message ("Locked or in-use items skipped: {0}" -f $summary.SkippedLocked)
Write-Log -Message ("Missing or unavailable items skipped: {0}" -f $summary.SkippedMissing)
Write-Log -Message ("Errors: {0}" -f $summary.Errors)

return [pscustomobject]@{
    Mode = $summary.Mode
    DaysOld = $DaysOld
    Scanned = $summary.Scanned
    Eligible = $summary.Eligible
    Deleted = $summary.Deleted
    Restored = $summary.Restored
    SkippedLocked = $summary.SkippedLocked
    SkippedMissing = $summary.SkippedMissing
    Errors = $summary.Errors
    LogFile = $script:LogFile
    ManifestPath = $script:ManifestPath
}
