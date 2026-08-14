[CmdletBinding()]
param(
    [string]$OutputRoot = "C:\ProgramData\DWP\Evidence",
    [string[]]$AppKeywords = @("Document", "Management", "FinBridge"),
    [int]$LogonWindowHours = 72,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    if ($script:RunLogPath) {
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

$runStamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runFolder = Join-Path $OutputRoot "Issue1-LoginPerf-$runStamp"
$script:RunLogPath = $null

if ($DryRun) {
    Write-Host "DryRun enabled. No files will be written."
    Write-Host "Would create output folder: $runFolder"
}
else {
    New-Item -Path $runFolder -ItemType Directory -Force | Out-Null
    $script:RunLogPath = Join-Path $runFolder "run.log"
    New-Item -Path $script:RunLogPath -ItemType File -Force | Out-Null
}

$script:Evidence = [ordered]@{}
$script:Errors = New-Object System.Collections.Generic.List[object]
$windowStart = (Get-Date).AddHours(-1 * $LogonWindowHours)

Write-Log "Floor 6 Issue 1 evidence collection started."
Write-Log "Top cause under test: deployment-linked startup contention / sequencing."
Write-Log "Window start: $windowStart"

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

Invoke-Check -Name 'PendingRebootSignals' -Script {
    [pscustomobject]@{
        CBSRebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
        WURebootRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        PendingFileRenameOps = [bool](Get-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations")
    }
}

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

$summary = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    TopCauseUnderTest = 'Deployment startup contention/sequencing from Friday app rollout'
    CollectionTime = Get-Date
    WindowHours = $LogonWindowHours
    ChecksExecuted = $script:Evidence.Keys.Count
    FailedChecks = $script:Errors.Count
    AppKeywords = ($AppKeywords -join ', ')
}

if ($DryRun) {
    Write-Host "DryRun summary:"
    $summary.GetEnumerator() | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Key, $_.Value) }
    Write-Host "Checks that would run:"
    $script:Evidence.Keys | ForEach-Object { Write-Host " - $_" }
    if ($script:Errors.Count -gt 0) {
        Write-Host "Errors encountered during DryRun checks:" -ForegroundColor Yellow
        $script:Errors | Format-Table -AutoSize
    }
    return
}

$summaryPath = Join-Path $runFolder "summary.txt"
$evidencePath = Join-Path $runFolder "evidence.json"
$errorPath = Join-Path $runFolder "errors.json"

$summaryLines = @(
    "Floor 6 Issue 1 Evidence Summary",
    "ComputerName: $($summary.ComputerName)",
    "TopCauseUnderTest: $($summary.TopCauseUnderTest)",
    "CollectionTime: $($summary.CollectionTime)",
    "WindowHours: $($summary.WindowHours)",
    "ChecksExecuted: $($summary.ChecksExecuted)",
    "FailedChecks: $($summary.FailedChecks)",
    "AppKeywords: $($summary.AppKeywords)"
)
$summaryLines | Set-Content -Path $summaryPath -Force

$script:Evidence | ConvertTo-Json -Depth 8 | Set-Content -Path $evidencePath -Force
$script:Errors | ConvertTo-Json -Depth 6 | Set-Content -Path $errorPath -Force

Write-Log "Evidence written to $runFolder"
Write-Log "Summary file: $summaryPath"
Write-Log "Done."
