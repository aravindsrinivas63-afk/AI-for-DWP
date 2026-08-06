<#
Purpose:
Collect and display a quick endpoint health snapshot:
- Computer name and total physical memory
- C: drive free space
- Top 5 processes by memory usage
- Recent System error events
- Count of stale (unused for 90+ days) non-special user profiles

Author:
Unknown (refactored for readability by GitHub Copilot)

How to run:
From PowerShell in this folder:
	.\inherited.ps1
#>

# Get core computer system details (for example, name and total physical memory).
$computerSystem = Get-CimInstance Win32_ComputerSystem
# Get free space on the C: drive in bytes.
$cDriveFreeBytes = (Get-PSDrive C).Free
# Get the top 5 running processes by working set memory (highest first).
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5
# Get up to 10 recent System log entries, then keep only error-level events (Level 2).
$recentSystemErrorEvents = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }
# Get non-special user profiles that have not been used in the last 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90) }

# Display the computer name and total physical memory value.
Write-Host $computerSystem.Name $computerSystem.TotalPhysicalMemory
# Convert free bytes to gigabytes, round to 2 decimals, and display the result.
Write-Host ([math]::Round($cDriveFreeBytes / 1GB, 2)) 'GB free'
# Display each of the top memory-consuming process names and their working set.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }
# Display timestamp and message text for each recent System error event.
$recentSystemErrorEvents | ForEach-Object { Write-Host $_.TimeCreated $_.Message }
# If stale profiles exist, display a summary count.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }
