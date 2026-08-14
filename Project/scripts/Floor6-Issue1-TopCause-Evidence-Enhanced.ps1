[CmdletBinding()]
param(
    [string]$OutputRoot = "C:\ProgramData\DWP\Evidence",
    [string[]]$AppKeywords = @("Document", "Management", "FinBridge"),
    [int]$LogonWindowHours = 72,
    [switch]$DryRun,
    [switch]$Rollback,
    [switch]$RollbackOnError = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# SECTION: Runtime state used for summary, safe writes, and rollback.
$script:RunLogPath = $null
$script:Evidence = [ordered]@{}
$script:Errors = New-Object System.Collections.Generic.List[object]
$script:FileWriteResults = New-Object System.Collections.Generic.List[object]
$script:RollbackActions = New-Object System.Collections.Generic.List[object]
$script:RollbackFolder = $null
$script:RunFolder = Join-Path $OutputRoot "Issue1-LoginPerf-Latest"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    if ($script:RunLogPath -and -not $DryRun) {
        Add-Content -Path $script:RunLogPath -Value $line
    }
}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$Script
    )

    Write-Log "Starting check: $Name"
    try {
        $result = & $Script
        $script:Evidence[$Name] = $result
        Write-Log "Completed check: $Name"
    }
    catch {
        $err = $_.Exception.Message
        Write-Log "Check failed: $Name :: $err" 'ERROR'
        $script:Errors.Add([pscustomobject]@{
            Check = $Name
            Error = $err
        }) | Out-Null
    }
}

function Get-RegValue {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    }
    catch {
        $null
    }
}

function New-RollbackCheckpoint {
    if ($DryRun) {
        Write-Log "DryRun: rollback checkpoint not created."
        return
    }

    $script:RollbackFolder = Join-Path $script:RunFolder ("rollback-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    New-Item -Path $script:RollbackFolder -ItemType Directory -Force | Out-Null
    Write-Log "Rollback checkpoint folder: $script:RollbackFolder"
}

function Write-ManagedFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [string]$Label = 'OutputFile'
    )

    if ($DryRun) {
        Write-Log "DryRun: would write file [$Label] at $Path"
        $script:FileWriteResults.Add([pscustomobject]@{
            Label = $Label
            Path = $Path
            Status = 'DryRunSkipped'
            Error = $null
        }) | Out-Null
        return $true
    }

    try {
        $parent = Split-Path -Path $Path -Parent
        if (-not (Test-Path $parent)) {
            New-Item -Path $parent -ItemType Directory -Force | Out-Null
        }

        if (Test-Path $Path) {
            $backupName = [IO.Path]::GetFileName($Path) + ".bak"
            $backupPath = Join-Path $script:RollbackFolder $backupName
            Copy-Item -Path $Path -Destination $backupPath -Force

            $script:RollbackActions.Add([pscustomobject]@{
                Type = 'RestoreBackup'
                OriginalPath = $Path
                BackupPath = $backupPath
            }) | Out-Null
        }
        else {
            $script:RollbackActions.Add([pscustomobject]@{
                Type = 'DeleteNewFile'
                OriginalPath = $Path
                BackupPath = $null
            }) | Out-Null
        }

        Set-Content -Path $Path -Value $Content -Force

        $script:FileWriteResults.Add([pscustomobject]@{
            Label = $Label
            Path = $Path
            Status = 'Written'
            Error = $null
        }) | Out-Null
        return $true
    }
    catch {
        $err = $_.Exception.Message
        $script:FileWriteResults.Add([pscustomobject]@{
            Label = $Label
            Path = $Path
            Status = 'Failed'
            Error = $err
        }) | Out-Null

        $script:Errors.Add([pscustomobject]@{
            Check = "FileWrite:$Label"
            Error = $err
        }) | Out-Null

        Write-Log "File write failed [$Label]: $err" 'ERROR'
        return $false
    }
}

function Invoke-Rollback {
    if ($DryRun) {
        Write-Log "DryRun: rollback skipped because no files were changed."
        return
    }

    Write-Log "Starting rollback using in-memory checkpoint actions." 'WARN'

    foreach ($action in ($script:RollbackActions | Select-Object -Reverse)) {
        try {
            if ($action.Type -eq 'RestoreBackup' -and (Test-Path $action.BackupPath)) {
                Copy-Item -Path $action.BackupPath -Destination $action.OriginalPath -Force
                Write-Log "Rolled back file from backup: $($action.OriginalPath)"
            }
            elseif ($action.Type -eq 'DeleteNewFile' -and (Test-Path $action.OriginalPath)) {
                Remove-Item -Path $action.OriginalPath -Force
                Write-Log "Removed newly created file: $($action.OriginalPath)"
            }
        }
        catch {
            Write-Log ("Rollback action failed for {0}: {1}" -f $action.OriginalPath, $_.Exception.Message) 'ERROR'
        }
    }

    Write-Log "Rollback completed." 'WARN'
}

# SECTION: Support explicit rollback mode to restore latest backups and remove new output files.
if ($Rollback) {
    if (-not (Test-Path $script:RunFolder)) {
        Write-Host "No run folder found at $script:RunFolder. Nothing to roll back."
        return
    }

    $latestRollbackFolder = Get-ChildItem -Path $script:RunFolder -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'rollback-*' } |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if (-not $latestRollbackFolder) {
        Write-Host "No rollback checkpoint folders were found in $script:RunFolder."
        return
    }

    $rollbackFolderPath = $latestRollbackFolder.FullName
    Write-Host "Applying rollback from checkpoint: $rollbackFolderPath"

    $knownOutputs = @(
        (Join-Path $script:RunFolder 'summary.txt'),
        (Join-Path $script:RunFolder 'evidence.json'),
        (Join-Path $script:RunFolder 'errors.json'),
        (Join-Path $script:RunFolder 'run.log')
    )

    foreach ($outputFile in $knownOutputs) {
        $backupPath = Join-Path $rollbackFolderPath ([IO.Path]::GetFileName($outputFile) + '.bak')
        try {
            if (Test-Path $backupPath) {
                Copy-Item -Path $backupPath -Destination $outputFile -Force
                Write-Host "Restored: $outputFile"
            }
            elseif (Test-Path $outputFile) {
                Remove-Item -Path $outputFile -Force
                Write-Host "Removed (no backup available): $outputFile"
            }
        }
        catch {
            Write-Host "Rollback failed for $outputFile :: $($_.Exception.Message)"
        }
    }

    Write-Host "Rollback mode complete."
    return
}

# SECTION: Prepare deterministic output location for idempotent execution.
if ($DryRun) {
    Write-Host "DryRun enabled. No files will be written."
    Write-Host "Would use output folder: $script:RunFolder"
}
else {
    New-Item -Path $script:RunFolder -ItemType Directory -Force | Out-Null
    $script:RunLogPath = Join-Path $script:RunFolder "run.log"
    Set-Content -Path $script:RunLogPath -Value "" -Force
    New-RollbackCheckpoint
}

$windowStart = (Get-Date).AddHours(-1 * $LogonWindowHours)

Write-Log "Floor 6 Issue 1 evidence collection started."
Write-Log "Top cause under test: deployment-linked startup contention / sequencing."
Write-Log "Window start: $windowStart"

# SECTION: Gather baseline device and operating system context.
Invoke-Check -Name 'DeviceContext' -Script {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem

    [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $cs.Domain
        Model = $cs.Model
        Manufacturer = $cs.Manufacturer
        TotalRAMGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        BuildNumber = $os.BuildNumber
        Version = $os.Version
        LastBoot = $os.LastBootUpTime
        CollectionTime = (Get-Date)
    }
}

# SECTION: Check reboot-related registry indicators that can affect login performance.
Invoke-Check -Name 'PendingRebootSignals' -Script {
    [pscustomobject]@{
        CBSRebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
        WURebootRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        PendingFileRenameOps = [bool](Get-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations")
    }
}

# SECTION: Identify recently installed applications that match rollout keywords.
Invoke-Check -Name 'RecentlyInstalledApps' -Script {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = foreach ($p in $paths) {
        Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -and $_.DisplayVersion
            } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
    }

    $apps |
        Sort-Object DisplayName -Unique |
        Where-Object {
            $name = $_.DisplayName
            foreach ($k in $AppKeywords) {
                if ($name -match [regex]::Escape($k)) { return $true }
            }
            return $false
        }
}

# SECTION: Capture top CPU processes and autostart services to estimate startup pressure.
Invoke-Check -Name 'StartupPressureTopProcesses' -Script {
    Get-Process -ErrorAction SilentlyContinue |
        Sort-Object CPU -Descending |
        Select-Object -First 25 Name, Id, CPU, WS, PM, StartTime
}

Invoke-Check -Name 'StartupServicesState' -Script {
    Get-Service |
        Where-Object { $_.StartType -in @('Automatic', 'AutomaticDelayedStart') } |
        Select-Object Name, DisplayName, Status, StartType |
        Sort-Object Status, Name
}

# SECTION: Find scheduled tasks that may be tied to deployment or management agents.
Invoke-Check -Name 'ScheduledTasksLikelyDeploymentRelated' -Script {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue

    $tasks |
        Where-Object {
            $line = ($_.TaskName + ' ' + $_.TaskPath)
            foreach ($k in $AppKeywords) {
                if ($line -match [regex]::Escape($k)) { return $true }
            }
            return ($line -match 'Intune|Company|IME|Deploy|Install')
        } |
        Select-Object TaskName, TaskPath, State
}

# SECTION: Collect operational event logs relevant to boot and logon performance.
Invoke-Check -Name 'DiagnosticsPerformanceEvents' -Script {
    Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'
        StartTime = $windowStart
    } -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -in 100,101,102,103,109,110,200,201 } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message -First 200
}

Invoke-Check -Name 'SecurityLogonFailureAndLockout' -Script {
    Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625,4740
        StartTime = $windowStart
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message -First 200
}

Invoke-Check -Name 'GroupPolicyOperationalSignals' -Script {
    Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-GroupPolicy/Operational'
        StartTime = $windowStart
    } -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -in 4000,4001,5312,5313,5320,5326,8000,8001 } |
    Select-Object TimeCreated, Id, LevelDisplayName, Message -First 200
}

Invoke-Check -Name 'UserProfileServiceSignals' -Script {
    Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ProviderName = 'Microsoft-Windows-User Profiles Service'
        StartTime = $windowStart
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message -First 200
}

# SECTION: Extract deployment-related snippets from Intune Management Extension logs.
Invoke-Check -Name 'IntuneManagementExtensionLogSlice' -Script {
    $imeLog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
    if (-not (Test-Path $imeLog)) {
        return [pscustomobject]@{ Exists = $false; Path = $imeLog }
    }

    $raw = Get-Content -Path $imeLog -ErrorAction SilentlyContinue
    if (-not $raw) {
        return [pscustomobject]@{ Exists = $true; Path = $imeLog; Lines = @() }
    }

    $pattern = ($AppKeywords + @('Install','Detection','Retry','Failed','Exit code','ScriptRunner','Win32App')) -join '|'

    $hits = $raw |
        Select-String -Pattern $pattern -SimpleMatch:$false |
        Select-Object -Last 400 |
        ForEach-Object { $_.Line }

    [pscustomobject]@{
        Exists = $true
        Path = $imeLog
        MatchingLines = $hits
    }
}

# SECTION: Build a boot and successful logon timeline for correlation.
Invoke-Check -Name 'BootAndLogonTimeline' -Script {
    $boot = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ID = 12
        StartTime = $windowStart
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, ProviderName, Message -First 20

    $logon = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4624
        StartTime = $windowStart
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message -First 100

    [pscustomobject]@{
        BootEvents = $boot
        LogonSuccessEvents = $logon
    }
}

# SECTION: Generate final execution summary and decide whether rollback is required.
$summary = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    TopCauseUnderTest = 'Deployment startup contention/sequencing from Friday app rollout'
    CollectionTime = Get-Date
    WindowHours = $LogonWindowHours
    ChecksExecuted = $script:Evidence.Keys.Count
    FailedChecks = $script:Errors.Count
    FileWrites = $script:FileWriteResults.Count
    FileWriteFailures = ($script:FileWriteResults | Where-Object { $_.Status -eq 'Failed' }).Count
    AppKeywords = ($AppKeywords -join ', ')
    OutputFolder = $script:RunFolder
    DryRun = [bool]$DryRun
}

if ($DryRun) {
    Write-Host "DryRun summary:"
    $summary.GetEnumerator() | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }
    Write-Host "Checks that ran:"
    $script:Evidence.Keys | ForEach-Object { Write-Host " - $_" }
    if ($script:Errors.Count -gt 0) {
        Write-Host "Errors encountered during DryRun checks:" -ForegroundColor Yellow
        $script:Errors | Format-Table -AutoSize
    }
    return
}

$summaryPath = Join-Path $script:RunFolder "summary.txt"
$evidencePath = Join-Path $script:RunFolder "evidence.json"
$errorPath = Join-Path $script:RunFolder "errors.json"

$summaryLines = @(
    "Floor 6 Issue 1 Evidence Summary",
    "ComputerName: $($summary.ComputerName)",
    "TopCauseUnderTest: $($summary.TopCauseUnderTest)",
    "CollectionTime: $($summary.CollectionTime)",
    "WindowHours: $($summary.WindowHours)",
    "ChecksExecuted: $($summary.ChecksExecuted)",
    "FailedChecks: $($summary.FailedChecks)",
    "FileWrites: $($summary.FileWrites)",
    "FileWriteFailures: $($summary.FileWriteFailures)",
    "AppKeywords: $($summary.AppKeywords)",
    "OutputFolder: $($summary.OutputFolder)",
    "DryRun: $($summary.DryRun)"
) -join [Environment]::NewLine

$fileWriteSucceeded = $true

if (-not (Write-ManagedFile -Path $summaryPath -Content $summaryLines -Label 'Summary')) {
    $fileWriteSucceeded = $false
}

$evidenceJson = $script:Evidence | ConvertTo-Json -Depth 8
if (-not (Write-ManagedFile -Path $evidencePath -Content $evidenceJson -Label 'EvidenceJson')) {
    $fileWriteSucceeded = $false
}

$errorJson = $script:Errors | ConvertTo-Json -Depth 6
if (-not (Write-ManagedFile -Path $errorPath -Content $errorJson -Label 'ErrorsJson')) {
    $fileWriteSucceeded = $false
}

if (-not $fileWriteSucceeded -and $RollbackOnError) {
    Write-Log "One or more file writes failed; rollback has been requested." 'WARN'
    Invoke-Rollback
}

Write-Host "Run Summary"
Write-Host "-----------"
$summary.GetEnumerator() | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }
Write-Host "File Write Results"
Write-Host "------------------"
$script:FileWriteResults | Format-Table -AutoSize

Write-Log "Evidence collection complete."
