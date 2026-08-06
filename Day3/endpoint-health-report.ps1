[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

<#
Verify before running:
- Confirm outbound access to https://speed.cloudflare.com is permitted in your environment. The internet speed section performs a read-only download throughput test and may be blocked by proxy, firewall, or policy.
- Confirm the target endpoint uses Microsoft Defender. The script checks the WinDefend service name used on Windows client devices; environments with third-party AV may not expose this service.
- Confirm you have permission to read the System event log and installed update history on the target endpoint.
- Confirm quser.exe is available if you want a session-based logged-in user count; the script falls back to the current console user when quser is unavailable.
#>

function Write-Section {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Output ""
    Write-Output ("=" * 72)
    Write-Output $Title
    Write-Output ("=" * 72)
}

function Show-List {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    $InputObject | Format-List | Out-String -Width 240 | Write-Output
}

function Show-Table {
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    $InputObject | Format-Table -AutoSize | Out-String -Width 240 | Write-Output
}

function Convert-ToGigabytes {
    param(
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )

    return [math]::Round($Bytes / 1GB, 2)
}

function Get-PendingRebootStatus {
    # This section checks common Windows registry locations that indicate whether a reboot is pending.
    $rebootReasons = New-Object System.Collections.Generic.List[string]

    $registryChecks = @(
        @{
            Name = 'Component Based Servicing';
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending';
            Type = 'Path'
        },
        @{
            Name = 'Windows Update Auto Update';
            Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired';
            Type = 'Path'
        },
        @{
            Name = 'Pending File Rename Operations';
            Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager';
            Property = 'PendingFileRenameOperations';
            Type = 'Property'
        }
    )

    foreach ($check in $registryChecks) {
        if ($check.Type -eq 'Path') {
            if (Test-Path -LiteralPath $check.Path) {
                [void]$rebootReasons.Add($check.Name)
            }
            continue
        }

        try {
            $propertyValue = Get-ItemProperty -LiteralPath $check.Path -Name $check.Property -ErrorAction Stop
            if ($null -ne $propertyValue.$($check.Property)) {
                [void]$rebootReasons.Add($check.Name)
            }
        }
        catch {
        }
    }

    [pscustomobject]@{
        Pending = ($rebootReasons.Count -gt 0)
        Reasons = if ($rebootReasons.Count -gt 0) { $rebootReasons -join '; ' } else { 'None detected' }
    }
}

function Get-TopProcessesByWorkingSet {
    # This section returns the five processes using the most physical memory based on Working Set.
    Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 -Property ProcessName, Id,
            @{Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
}

function Get-TopProcessesByCpu {
    # This section returns the five processes with the highest cumulative CPU time reported by Get-Process.
    Get-Process |
        Where-Object { $null -ne $_.CPU } |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 -Property ProcessName, Id,
            @{Name = 'CpuSeconds'; Expression = { [math]::Round($_.CPU, 2) } }
}

function Get-RecentSystemErrors {
    # This section reads the last five Error entries from the Windows System event log.
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
        Select-Object TimeCreated, Id, ProviderName,
            @{Name = 'Message'; Expression = { ($_.Message -replace '\r?\n', ' ').Trim() } }
}

function Get-LoggedInUsersSummary {
    # This section counts users with local or remote sessions using quser when available, with a basic fallback when it is not.
    $quserCommand = Get-Command -Name quser.exe -ErrorAction SilentlyContinue
    if ($quserCommand) {
        $sessionLines = & $quserCommand.Source 2>$null | Select-Object -Skip 1
        $userNames = foreach ($line in $sessionLines) {
            $trimmedLine = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
                continue
            }

            $firstToken = ($trimmedLine -replace '^>', '').Split(@(' '), [System.StringSplitOptions]::RemoveEmptyEntries)[0]
            if (-not [string]::IsNullOrWhiteSpace($firstToken)) {
                $firstToken
            }
        }

        $distinctUsers = $userNames | Sort-Object -Unique
        return [pscustomobject]@{
            LoggedInUserCount = @($distinctUsers).Count
            Users = if (@($distinctUsers).Count -gt 0) { $distinctUsers -join ', ' } else { 'No active sessions detected' }
            Source = 'quser.exe'
        }
    }

    $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
    return [pscustomobject]@{
        LoggedInUserCount = if ([string]::IsNullOrWhiteSpace($currentUser)) { 0 } else { 1 }
        Users = if ([string]::IsNullOrWhiteSpace($currentUser)) { 'No interactive console user detected' } else { $currentUser }
        Source = 'Win32_ComputerSystem fallback'
    }
}

function Get-LastInstalledUpdate {
    # This section reports the most recent installed Windows update from the local update history available to Get-HotFix.
    $latestUpdate = Get-HotFix |
        Where-Object { $null -ne $_.InstalledOn } |
        Sort-Object -Property InstalledOn -Descending |
        Select-Object -First 1

    if ($null -eq $latestUpdate) {
        return [pscustomobject]@{
            HotFixId = 'Not found'
            InstalledOn = 'To verify'
            Description = 'No update history returned by Get-HotFix'
        }
    }

    return [pscustomobject]@{
        HotFixId = $latestUpdate.HotFixID
        InstalledOn = $latestUpdate.InstalledOn
        Description = $latestUpdate.Description
    }
}

function Test-InternetDownloadSpeed {
    # This section estimates download speed by reading a test payload over HTTPS without writing anything to disk.
    $testUrl = 'https://speed.cloudflare.com/__down?bytes=10000000'
    $request = $null
    $response = $null
    $stream = $null
    $stopwatch = $null

    try {
        $request = [System.Net.HttpWebRequest]::Create($testUrl)
        $request.Method = 'GET'
        $request.UserAgent = 'PowerShell-EndpointHealth-ReadOnly'
        $request.Timeout = 30000
        $request.ReadWriteTimeout = 30000
        $request.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore)

        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $buffer = New-Object byte[] 8192
        $totalBytes = 0L
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $totalBytes += $bytesRead
        }

        $stopwatch.Stop()

        if ($stopwatch.Elapsed.TotalSeconds -le 0) {
            throw 'Elapsed time measured as zero seconds.'
        }

        $megabitsPerSecond = [math]::Round((($totalBytes * 8) / 1MB) / $stopwatch.Elapsed.TotalSeconds, 2)

        return [pscustomobject]@{
            Status = 'Success'
            DownloadedMB = [math]::Round($totalBytes / 1MB, 2)
            DurationSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
            DownloadMbps = $megabitsPerSecond
            TestUrl = $testUrl
        }
    }
    catch {
        return [pscustomobject]@{
            Status = 'To verify'
            DownloadedMB = 'To verify'
            DurationSeconds = 'To verify'
            DownloadMbps = 'To verify'
            TestUrl = $testUrl
            Error = $_.Exception.Message
        }
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }

        if ($null -ne $response) {
            $response.Dispose()
        }
    }
}

Write-Section -Title 'Pre-Run Verification Notes'
# This section prints the items that should be confirmed before relying on all parts of the report.
@(
    'Verify outbound access to https://speed.cloudflare.com is permitted before using the internet speed test.',
    'Verify the endpoint uses Microsoft Defender if you expect the WinDefend service to be present.',
    'Verify you have permission to read the System event log and update history.',
    'Verify quser.exe is available if you need a full session-based logged-in user count.'
)

Write-Section -Title 'System Uptime'
# This section reports the time since the operating system last booted.
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$uptimeSpan = (Get-Date) - $operatingSystem.LastBootUpTime
Show-List ([pscustomobject]@{
    LastBootTime = $operatingSystem.LastBootUpTime
    UptimeDays = [math]::Floor($uptimeSpan.TotalDays)
    UptimeHours = $uptimeSpan.Hours
    UptimeMinutes = $uptimeSpan.Minutes
})

Write-Section -Title 'Free Disk Space'
# This section lists free and total space for each fixed local disk.
Show-Table (Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' |
    Select-Object DeviceID, VolumeName,
        @{Name = 'FreeSpaceGB'; Expression = { Convert-ToGigabytes -Bytes $_.FreeSpace } },
        @{Name = 'TotalSpaceGB'; Expression = { Convert-ToGigabytes -Bytes $_.Size } },
        @{Name = 'PercentFree'; Expression = { if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } else { 0 } } })

Write-Section -Title 'Pending Reboot Status'
# This section reports whether common registry indicators show a pending reboot requirement.
Show-List (Get-PendingRebootStatus)

Write-Section -Title 'Top 5 Processes By Memory (Working Set)'
# This section shows the five processes using the most memory at the time the script runs.
Show-Table (Get-TopProcessesByWorkingSet)

Write-Section -Title 'Top 5 Processes By CPU'
# This section shows the five processes with the highest cumulative CPU time at the time the script runs.
Show-Table (Get-TopProcessesByCpu)

Write-Section -Title 'Last 5 System Log Errors'
# This section retrieves the five most recent Error entries from the System event log.
Show-Table (Get-RecentSystemErrors)

Write-Section -Title 'Internet Speed'
# This section estimates internet download speed using a read-only HTTPS download test.
Show-List (Test-InternetDownloadSpeed)

Write-Section -Title 'Microsoft Defender Service Status'
# This section checks whether the Microsoft Defender Antivirus service is present and running.
$defenderService = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
if ($null -eq $defenderService) {
    Show-List ([pscustomobject]@{
        ServiceName = 'WinDefend'
        Status = 'To verify'
        Detail = 'Microsoft Defender service not found on this endpoint'
    })
}
else {
    Show-List ([pscustomobject]@{
        ServiceName = $defenderService.Name
        DisplayName = $defenderService.DisplayName
        Status = $defenderService.Status
    })
}

Write-Section -Title 'Logged-In User Count'
# This section reports how many user sessions are currently logged in and which method was used to count them.
Show-List (Get-LoggedInUsersSummary)

Write-Section -Title 'Last Windows Update'
# This section reports the most recent installed update returned by the local Windows update history.
Show-List (Get-LastInstalledUpdate)