[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Disable,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [string]$ProgramName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$script:AuditTimestamp = Get-Date
$script:ComputerName = $env:COMPUTERNAME
$script:UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$script:DisabledCount = 0
$script:Warnings = New-Object System.Collections.Generic.List[string]

if ($Disable -and [string]::IsNullOrWhiteSpace($ProgramName)) {
    throw 'ProgramName is required when -Disable is used.'
}

function Add-WarningMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $script:Warnings.Add($Message)
    Write-Warning $Message
}

function Get-StartupFolderLocations {
    return @(
        [pscustomobject]@{ Scope = 'CurrentUser'; Source = 'Startup Folder (Current User)'; Path = [Environment]::GetFolderPath('Startup') },
        [pscustomobject]@{ Scope = 'AllUsers'; Source = 'Startup Folder (All Users)'; Path = [Environment]::GetFolderPath('CommonStartup') }
    )
}

function Get-StartupFolderEntries {
    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($location in Get-StartupFolderLocations) {
        try {
            if ([string]::IsNullOrWhiteSpace($location.Path)) {
                Add-WarningMessage -Message ('Startup folder path unavailable for {0}.' -f $location.Source)
                continue
            }

            if (-not (Test-Path -LiteralPath $location.Path)) {
                continue
            }

            $files = Get-ChildItem -LiteralPath $location.Path -File -Force -ErrorAction Stop
            foreach ($file in $files) {
                $enabled = $true
                $displayName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

                if ($file.Extension.ToLowerInvariant() -eq '.disabled') {
                    $enabled = $false
                    $displayName = $file.Name -replace '\.disabled$', ''
                }

                $entries.Add([pscustomobject]@{
                        Name          = $displayName
                        CommandPath   = $file.FullName
                        StartupSource = $location.Source
                        Status        = if ($enabled) { 'Enabled' } else { 'Disabled' }
                        SourceType    = 'StartupFolder'
                        Scope         = $location.Scope
                        FilePath      = $file.FullName
                        RegistryPath  = $null
                        ValueName     = $null
                        RawValue      = $null
                    })
            }
        }
        catch {
            Add-WarningMessage -Message ('Could not enumerate {0}: {1}' -f $location.Source, $_.Exception.Message)
            continue
        }
    }

    return $entries
}

function Get-RegistryRunLocations {
    return @(
        [pscustomobject]@{ Scope = 'CurrentUser'; Source = 'Registry Run (HKCU)'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' },
        [pscustomobject]@{ Scope = 'LocalMachine'; Source = 'Registry Run (HKLM)'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' },
        [pscustomobject]@{ Scope = 'LocalMachineWow6432'; Source = 'Registry Run (HKLM WOW6432Node)'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' }
    )
}

function Get-RegistryRunEntries {
    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($location in Get-RegistryRunLocations) {
        try {
            if (-not (Test-Path -LiteralPath $location.Path)) {
                continue
            }

            $item = Get-ItemProperty -Path $location.Path -ErrorAction Stop
            foreach ($property in $item.PSObject.Properties) {
                if ($property.Name -match '^PS(Path|ParentPath|ChildName|Drive|Provider)$') {
                    continue
                }

                $value = [string]$property.Value
                if ([string]::IsNullOrWhiteSpace($value)) {
                    continue
                }

                $entries.Add([pscustomobject]@{
                        Name          = $property.Name
                        CommandPath   = $value
                        StartupSource = $location.Source
                        Status        = 'Enabled'
                        SourceType    = 'Registry'
                        Scope         = $location.Scope
                        FilePath      = $null
                        RegistryPath  = $location.Path
                        ValueName     = $property.Name
                        RawValue      = $value
                    })
            }
        }
        catch {
            Add-WarningMessage -Message ('Could not enumerate {0}: {1}' -f $location.Source, $_.Exception.Message)
            continue
        }
    }

    return $entries
}

function Get-DisableCandidates {
    $all = @()
    $all += Get-RegistryRunEntries
    $all += Get-StartupFolderEntries
    return $all
}

function Disable-RegistryEntry {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupRoot = 'HKCU:\Software\DWP\StartupProgramAuditor\RegistryBackup'
    $backupLeaf = '{0}_{1}' -f ($Entry.ValueName -replace '[^a-zA-Z0-9_\-]', '_'), $stamp
    $backupPath = Join-Path -Path $backupRoot -ChildPath $backupLeaf

    if ($DryRun) {
        Write-Output ('[DryRun] Would disable registry startup entry: {0}' -f $Entry.Name)
        Write-Output ('[DryRun] Would back up to registry location: {0}' -f $backupPath)
        return
    }

    try {
        New-Item -Path $backupPath -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $backupPath -Name 'OriginalRegistryPath' -Value $Entry.RegistryPath -PropertyType String -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $backupPath -Name 'OriginalValueName' -Value $Entry.ValueName -PropertyType String -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $backupPath -Name 'CommandPath' -Value $Entry.RawValue -PropertyType String -Force -ErrorAction Stop | Out-Null
        New-ItemProperty -Path $backupPath -Name 'BackupTimestamp' -Value (Get-Date).ToString('s') -PropertyType String -Force -ErrorAction Stop | Out-Null

        Remove-ItemProperty -Path $Entry.RegistryPath -Name $Entry.ValueName -ErrorAction Stop

        $script:DisabledCount++
        Write-Output ('Disabled registry startup entry: {0}' -f $Entry.Name)
        Write-Output ('Registry backup location: {0}' -f $backupPath)
    }
    catch {
        Add-WarningMessage -Message ('Failed to disable registry entry {0}: {1}' -f $Entry.Name, $_.Exception.Message)
    }
}

function Disable-StartupFolderEntry {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupRoot = Join-Path -Path $env:ProgramData -ChildPath 'DWP\StartupProgramAuditor\StartupFolderBackup'
    $backupPath = Join-Path -Path $backupRoot -ChildPath $stamp

    if ($DryRun) {
        $fileNamePreview = [System.IO.Path]::GetFileName($Entry.FilePath)
        $destinationPreview = Join-Path -Path $backupPath -ChildPath $fileNamePreview
        Write-Output ('[DryRun] Would disable startup folder entry: {0}' -f $Entry.Name)
        Write-Output ('[DryRun] Would move file to backup location: {0}' -f $destinationPreview)
        return
    }

    try {
        if (-not (Test-Path -LiteralPath $Entry.FilePath)) {
            Add-WarningMessage -Message ('Startup folder entry not found: {0}' -f $Entry.FilePath)
            return
        }

        New-Item -ItemType Directory -Path $backupPath -Force -ErrorAction Stop | Out-Null

        $fileName = [System.IO.Path]::GetFileName($Entry.FilePath)
        $destination = Join-Path -Path $backupPath -ChildPath $fileName

        Move-Item -LiteralPath $Entry.FilePath -Destination $destination -Force -ErrorAction Stop

        $script:DisabledCount++
        Write-Output ('Disabled startup folder entry: {0}' -f $Entry.Name)
        Write-Output ('Startup folder backup location: {0}' -f $destination)
    }
    catch {
        Add-WarningMessage -Message ('Failed to disable startup folder entry {0}: {1}' -f $Entry.Name, $_.Exception.Message)
    }
}

function Show-ReportSummary {
    param(
        [Parameter(Mandatory = $true)]
        [int]$FoundCount
    )

    Write-Output ''
    Write-Output 'Report Summary:'
    [pscustomobject]@{
        'Audit timestamp'                 = $script:AuditTimestamp
        'Computer name'                   = $script:ComputerName
        'User name'                       = $script:UserName
        'Number of startup programs found' = $FoundCount
        'Number disabled during execution' = $script:DisabledCount
    } | Format-List
}

# Default mode: audit startup folders only.
$startupEntries = @(Get-StartupFolderEntries)
$foundCount = $startupEntries.Count

if (-not $Disable) {
    if ($foundCount -eq 0) {
        Write-Output 'No startup folder entries found.'
    }
    else {
        $startupEntries |
            Sort-Object -Property Name, StartupSource |
            Select-Object @{ Name = 'Program Name'; Expression = { $_.Name } },
            @{ Name = 'Command/Executable Path'; Expression = { $_.CommandPath } },
            @{ Name = 'Startup Source'; Expression = { $_.StartupSource } },
            @{ Name = 'Status'; Expression = { $_.Status } } |
            Format-Table -AutoSize

        Write-Output ''
        Write-Output ('Total startup entries found: {0}' -f $foundCount)
    }

    Show-ReportSummary -FoundCount $foundCount
    return
}

# Disable mode: search registry Run keys and startup folders.
$candidates = @(Get-DisableCandidates)
$matching = @($candidates | Where-Object { $_.Name -ieq $ProgramName })

if ($matching.Count -eq 0) {
    Write-Output ('No startup entry found matching ProgramName: {0}' -f $ProgramName)
    Show-ReportSummary -FoundCount $foundCount
    return
}

if ($matching.Count -gt 1) {
    Add-WarningMessage -Message ('Multiple entries matched ProgramName "{0}". Only the first match will be disabled.' -f $ProgramName)
}

$target = $matching | Select-Object -First 1

if ($DryRun) {
    Write-Output 'DryRun mode enabled: no startup entries will be changed.'
}

if ($target.SourceType -eq 'Registry') {
    Disable-RegistryEntry -Entry $target
}
elseif ($target.SourceType -eq 'StartupFolder') {
    Disable-StartupFolderEntry -Entry $target
}
else {
    Add-WarningMessage -Message ('Unsupported startup source for entry {0}' -f $target.Name)
}

Show-ReportSummary -FoundCount $foundCount
