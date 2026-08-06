[CmdletBinding()]
param(
    [Parameter()]
    [string]$ComputerName = $env:COMPUTERNAME,

    [Parameter()]
    [string]$OutputFile,

    [Parameter()]
    [ValidateSet('Console', 'CSV', 'Both')]
    [string]$ReportFormat = 'Console'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

<#!
READ-ONLY GUARANTEE:
- This script only collects and reports disk/volume information.
- It never runs remediation or maintenance actions.
- It never invokes Defrag.exe, Optimize-Volume, Repair-Volume, Chkdsk, Trim,
  ReFS scrub, Storage Spaces repair, or any optimization task.
!#>

function Get-MediaTypeName {
    param(
        [Parameter()]
        [Nullable[int]]$MediaTypeCode,

        [Parameter()]
        [string]$FallbackMediaType
    )

    switch ($MediaTypeCode) {
        3 { return 'HDD' }
        4 { return 'SSD' }
        5 { return 'SCM' }
        default {
            if (-not [string]::IsNullOrWhiteSpace($FallbackMediaType)) {
                if ($FallbackMediaType -match 'SSD|Solid') { return 'SSD' }
                if ($FallbackMediaType -match 'HDD|Hard') { return 'HDD' }
            }

            return 'Unknown'
        }
    }
}

function Get-VolumeToDiskMap {
    param(
        [Parameter()]
        $CimSession
    )

    $map = @{}

    try {
        $assoc = Get-CimInstance -CimSession $CimSession -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='Disk #0, Partition #0'} WHERE AssocClass=Win32_LogicalDiskToPartition" -ErrorAction Stop
        $null = $assoc
    }
    catch {
        # Probe query intentionally ignored; mapping will be built from normal calls below.
    }

    try {
        $diskToPartition = Get-CimInstance -CimSession $CimSession -ClassName Win32_DiskDriveToDiskPartition -ErrorAction Stop
        $partitionToLogical = Get-CimInstance -CimSession $CimSession -ClassName Win32_LogicalDiskToPartition -ErrorAction Stop

        $partitionToDiskIndex = @{}
        foreach ($link in $diskToPartition) {
            $antecedent = [string]$link.Antecedent
            $dependent = [string]$link.Dependent

            $diskMatch = [regex]::Match($antecedent, 'PHYSICALDRIVE(?<idx>\d+)')
            $partitionMatch = [regex]::Match($dependent, 'DeviceID="(?<pid>[^"]+)"')
            if ($diskMatch.Success -and $partitionMatch.Success) {
                $partitionToDiskIndex[$partitionMatch.Groups['pid'].Value] = [int]$diskMatch.Groups['idx'].Value
            }
        }

        foreach ($link in $partitionToLogical) {
            $antecedent = [string]$link.Antecedent
            $dependent = [string]$link.Dependent

            $partitionMatch = [regex]::Match($antecedent, 'DeviceID="(?<pid>[^"]+)"')
            $logicalMatch = [regex]::Match($dependent, 'DeviceID="(?<ld>[A-Z]:)"')

            if ($partitionMatch.Success -and $logicalMatch.Success) {
                $pid = $partitionMatch.Groups['pid'].Value
                $logical = $logicalMatch.Groups['ld'].Value
                if ($partitionToDiskIndex.ContainsKey($pid)) {
                    $map[$logical] = $partitionToDiskIndex[$pid]
                }
            }
        }
    }
    catch {
        Write-Warning ('Unable to build volume-to-disk mapping: {0}' -f $_.Exception.Message)
    }

    return $map
}

function Get-DiskMediaMap {
    param(
        [Parameter()]
        $CimSession
    )

    $map = @{}

    try {
        $physicalDisks = Get-CimInstance -CimSession $CimSession -Namespace 'root/Microsoft/Windows/Storage' -ClassName MSFT_PhysicalDisk -ErrorAction Stop
        foreach ($disk in $physicalDisks) {
            if ($null -ne $disk.DeviceId) {
                $map[[int]$disk.DeviceId] = Get-MediaTypeName -MediaTypeCode ([Nullable[int]]$disk.MediaType) -FallbackMediaType $null
            }
        }
    }
    catch {
        try {
            $legacyDisks = Get-CimInstance -CimSession $CimSession -ClassName Win32_DiskDrive -ErrorAction Stop
            foreach ($disk in $legacyDisks) {
                if ($disk.Index -ne $null) {
                    $map[[int]$disk.Index] = Get-MediaTypeName -MediaTypeCode $null -FallbackMediaType ([string]$disk.MediaType)
                }
            }
        }
        catch {
            Write-Warning ('Unable to determine media type (SSD/HDD): {0}' -f $_.Exception.Message)
        }
    }

    return $map
}

function Get-OptimizationEventInfo {
    param(
        [Parameter()]
        [string]$DriveLetter,

        [Parameter()]
        [string]$ComputerName
    )

    $result = [pscustomobject]@{
        LastOptimizationRun = $null
        OptimizationStatus  = 'Unknown'
    }

    $logName = 'Microsoft-Windows-Defrag/Operational'
    try {
        $events = Get-WinEvent -ComputerName $ComputerName -FilterHashtable @{ LogName = $logName; StartTime = (Get-Date).AddDays(-90) } -ErrorAction Stop

        $match = $events |
            Where-Object {
                $_.Message -match [regex]::Escape($DriveLetter) -or
                $_.Message -match [regex]::Escape($DriveLetter.TrimEnd(':'))
            } |
            Select-Object -First 1

        if ($null -ne $match) {
            $result.LastOptimizationRun = $match.TimeCreated
            $result.OptimizationStatus = $match.LevelDisplayName
        }
    }
    catch {
        # Defrag operational log can be disabled on some endpoints.
    }

    return $result
}

$reportTime = Get-Date
$cimSession = $null
$sessionCreated = $false

try {
    if ($ComputerName -ieq $env:COMPUTERNAME -or $ComputerName -ieq 'localhost' -or $ComputerName -eq '.') {
        $cimSession = New-CimSession -ComputerName $env:COMPUTERNAME
    }
    else {
        $cimSession = New-CimSession -ComputerName $ComputerName
    }
    $sessionCreated = $true
}
catch {
    Write-Error ('Unable to connect to computer {0}: {1}' -f $ComputerName, $_.Exception.Message)
    return
}

$records = New-Object System.Collections.Generic.List[object]
$totalDrives = 0
$healthyDrives = 0
$warningDrives = 0
$criticalDrives = 0

try {
    $volumes = Get-CimInstance -CimSession $cimSession -ClassName Win32_Volume -Filter "DriveType = 3" -ErrorAction Stop
}
catch {
    Write-Error ('Failed to retrieve disk volumes from {0}: {1}' -f $ComputerName, $_.Exception.Message)
    if ($sessionCreated -and $null -ne $cimSession) {
        Remove-CimSession -CimSession $cimSession
    }
    return
}

$volumeMap = Get-VolumeToDiskMap -CimSession $cimSession
$mediaMap = Get-DiskMediaMap -CimSession $cimSession

foreach ($vol in $volumes) {
    try {
        $totalDrives++

        $driveLetter = if ([string]::IsNullOrWhiteSpace($vol.DriveLetter)) { '(No Letter)' } else { $vol.DriveLetter }
        $volumeLabel = if ([string]::IsNullOrWhiteSpace($vol.Label)) { '(No Label)' } else { $vol.Label }
        $fileSystem = if ([string]::IsNullOrWhiteSpace($vol.FileSystem)) { 'Unknown' } else { $vol.FileSystem }

        $capacity = [int64]($vol.Capacity)
        $free = [int64]($vol.FreeSpace)
        $used = $capacity - $free

        $totalGB = if ($capacity -gt 0) { [Math]::Round($capacity / 1GB, 2) } else { 0 }
        $freeGB = if ($free -ge 0) { [Math]::Round($free / 1GB, 2) } else { 0 }
        $usedGB = if ($used -ge 0) { [Math]::Round($used / 1GB, 2) } else { 0 }
        $freePct = if ($capacity -gt 0) { [Math]::Round(($free / $capacity) * 100, 2) } else { 0 }

        $health = 'Healthy'
        if ($freePct -lt 10) {
            $health = 'Critical'
            $criticalDrives++
        }
        elseif ($freePct -lt 15) {
            $health = 'Warning'
            $warningDrives++
        }
        else {
            $healthyDrives++
        }

        if ($fileSystem -eq 'RAW' -or $fileSystem -eq 'Unknown') {
            $health = 'Warning'
            if ($criticalDrives -gt 0 -and $freePct -lt 10) {
                # Keep as critical if already critical due to space.
            }
            elseif ($health -ne 'Critical') {
                $healthyDrives = [Math]::Max(0, $healthyDrives - 1)
                $warningDrives++
            }
        }

        $diskType = 'Unknown'
        if ($driveLetter -ne '(No Letter)' -and $volumeMap.ContainsKey($driveLetter)) {
            $diskIdx = $volumeMap[$driveLetter]
            if ($mediaMap.ContainsKey($diskIdx)) {
                $diskType = $mediaMap[$diskIdx]
            }
        }

        $optInfo = if ($driveLetter -ne '(No Letter)') {
            Get-OptimizationEventInfo -DriveLetter $driveLetter -ComputerName $ComputerName
        }
        else {
            [pscustomobject]@{ LastOptimizationRun = $null; OptimizationStatus = 'Unknown' }
        }

        $records.Add([pscustomobject]@{
                ComputerName          = $ComputerName
                DriveLetter           = $driveLetter
                VolumeLabel           = $volumeLabel
                FileSystem            = $fileSystem
                TotalSizeGB           = $totalGB
                FreeSpaceGB           = $freeGB
                UsedSpaceGB           = $usedGB
                FreeSpacePercent      = $freePct
                DiskType              = $diskType
                LastOptimizationRun   = $optInfo.LastOptimizationRun
                OptimizationStatus    = $optInfo.OptimizationStatus
                HealthStatus          = $health
                Inaccessible          = $false
                Notes                 = if ($fileSystem -eq 'RAW' -or $fileSystem -eq 'Unknown') { 'RAW or unsupported file system detected.' } else { '' }
            })
    }
    catch {
        Write-Warning ('Could not process drive {0}: {1}' -f $vol.DriveLetter, $_.Exception.Message)

        $records.Add([pscustomobject]@{
                ComputerName          = $ComputerName
                DriveLetter           = if ([string]::IsNullOrWhiteSpace($vol.DriveLetter)) { '(Unknown)' } else { $vol.DriveLetter }
                VolumeLabel           = '(Unknown)'
                FileSystem            = '(Unknown)'
                TotalSizeGB           = 0
                FreeSpaceGB           = 0
                UsedSpaceGB           = 0
                FreeSpacePercent      = 0
                DiskType              = 'Unknown'
                LastOptimizationRun   = $null
                OptimizationStatus    = 'Unknown'
                HealthStatus          = 'Warning'
                Inaccessible          = $true
                Notes                 = ('Inaccessible: {0}' -f $_.Exception.Message)
            })
        $warningDrives++
    }
}

$sorted = $records | Sort-Object -Property FreeSpacePercent, DriveLetter
$sorted = $sorted | Sort-Object -Property @{ Expression = { [double]($_.UsedSpaceGB) }; Descending = $true }

if ($ReportFormat -eq 'Console' -or $ReportFormat -eq 'Both') {
    Write-Output ''
    Write-Output ('Disk Health Report for {0}' -f $ComputerName)
    Write-Output ('Generated: {0}' -f $reportTime)
    Write-Output ''

    $sorted |
        Select-Object DriveLetter, VolumeLabel, FileSystem, TotalSizeGB, FreeSpaceGB, UsedSpaceGB, FreeSpacePercent, HealthStatus, DiskType, LastOptimizationRun, OptimizationStatus, Inaccessible, Notes |
        Format-Table -AutoSize

    Write-Output ''
    Write-Output 'Summary:'
    [pscustomobject]@{
        ComputerName             = $ComputerName
        TotalDrivesDiscovered    = $totalDrives
        HealthyDrives            = $healthyDrives
        WarningDrives            = $warningDrives
        CriticalDrives           = $criticalDrives
        ReportGenerationTime     = $reportTime
    } | Format-List
}

if ($ReportFormat -eq 'CSV' -or $ReportFormat -eq 'Both') {
    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $OutputFile = Join-Path -Path (Get-Location).Path -ChildPath ('DiskHealthReport_{0}.csv' -f $stamp)
    }

    try {
        $sorted |
            Select-Object ComputerName, DriveLetter, VolumeLabel, FileSystem, TotalSizeGB, FreeSpaceGB, UsedSpaceGB, FreeSpacePercent, HealthStatus, DiskType, LastOptimizationRun, OptimizationStatus, Inaccessible, Notes |
            Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8

        if ($ReportFormat -eq 'CSV' -or $ReportFormat -eq 'Both') {
            Write-Output ('CSV report written to: {0}' -f $OutputFile)
        }
    }
    catch {
        Write-Warning ('Failed to export CSV report: {0}' -f $_.Exception.Message)
    }
}

if ($sessionCreated -and $null -ne $cimSession) {
    Remove-CimSession -CimSession $cimSession
}
