# FAULT-B Finance Shared Drive Access Failure KB (L2/L3)
Version: v 1.0
Date: 07/08/2026
Status: Draft

## Background
Finance users require drive S: mapped to \\finbridge-fs01\Finance at sign-in to access shared working files. When mapping fails, users cannot open team documents, monthly close activities stall, and incidents rise quickly across the Finance population.

## Symptom
Engineer observes:
1. Drive S: is missing in File Explorer > This PC, or S: is present but not accessible.
2. Intune script activity is present for Map-FinBridgeDrives.ps1 on affected devices.
3. Errors appear in Intune Management Extension log during mapping window.

User reports:
1. Shared Finance drive disappeared after sign-in.
2. Access to Finance folder path fails.
3. Re-sign-in does not restore access.

## Root Cause
The mapping script Map-FinBridgeDrives.ps1 executed in SYSTEM context for Finance targets instead of user session context, causing drive mapping to fail for user-visible drive S:.

Evidence confirming root cause:
1. IntuneManagementExtension.log on affected device shows script run for Map-FinBridgeDrives.ps1 with failure string Exit code: 1.
2. Same log window contains Network name cannot be found for the mapping attempt.
3. GroupPolicy Operational Event ID 1500 indicates policy processing success, reducing likelihood of Group Policy failure.
4. System log may show Ntfs Event ID 98 around impact window, supporting mapping/storage path access abnormality.

## Detection
Complete this fast path in under 3 minutes before taking action.

1. On one affected POOL-FIN-01 machine, open Event Viewer (Local) > Windows Logs > Application.
Expected result: Application log is open on the affected machine.

2. In Application log, select Filter Current Log and set Event IDs to 1000,9009 and Logged to Last 1 hour.
Expected result: Filtered list shows only Event 1000 and Event 9009 entries for the last hour.

3. Open Event 1000 entries and check General message fields Faulting application name and Faulting module name.
Expected result: Faulting application name is dwm.exe and Faulting module name is igdumd64.dll.

4. Open Event 9009 entries and check Source and message text.
Expected result: Source is Desktop Window Manager and event occurs in the same time window as Event 1000.

5. On unaffected control machine in POOL-FIN-02, open Event Viewer (Local) > Windows Logs > Application and filter Event ID 9011 for Last 1 hour.
Expected result: Event 9011 is present, confirming healthy Desktop Window Manager start baseline on POOL-FIN-02.

6. Run this PowerShell command on an affected POOL-FIN-01 machine to extract required evidence quickly:
PowerShell:
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-1) } |
Where-Object { $_.Message -match 'dwm.exe|igdumd64.dll|Desktop Window Manager' } |
Select-Object TimeCreated, MachineName, Id, ProviderName, LevelDisplayName, Message |
Format-List
Expected result: Output shows Event 1000 with igdumd64.dll and correlated Event 9009 in the same window.

7. Run this PowerShell command on an unaffected POOL-FIN-02 machine to confirm healthy baseline:
PowerShell:
Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-1) } |
Select-Object TimeCreated, MachineName, Id, ProviderName, LevelDisplayName, Message |
Format-List
Expected result: Output shows Event 9011 entries and no repeating Event 1000 with igdumd64.dll.

8. Run this Azure CLI query to compare both pools centrally from Log Analytics (replace <workspace-id>):
Azure CLI:
az monitor log-analytics query --workspace <workspace-id> --analytics-query "Event | where TimeGenerated >= ago(1h) | where EventID in (1000,9009,9011) | where Computer contains 'POOL-FIN-01' or Computer contains 'POOL-FIN-02' | project TimeGenerated, Computer, EventID, Source, RenderedDescription | order by TimeGenerated desc" --output table
Expected result: POOL-FIN-01 shows Event 1000 plus Event 9009 pattern with igdumd64.dll in description, while POOL-FIN-02 shows Event 9011 healthy baseline.

9. Confirm incident match criteria before remediation.
Expected result: Diagnosis is confirmed only when all three are true: Event 1000 with igdumd64.dll on POOL-FIN-01, Event 9009 in same window on POOL-FIN-01, and Event 9011 healthy baseline on POOL-FIN-02.

## Resolution
Apply this sequence for POOL-FIN-01.

1. ELEVATED: In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts.
Expected result: Session host list for POOL-FIN-01 is visible.

2. ELEVATED: In POOL-FIN-01 > Session hosts, set Allow new sessions = No for all hosts.
Expected result: All POOL-FIN-01 hosts show Allow new sessions as No.

3. ELEVATED: In Azure Portal, open Virtual machines > filter Name starts with SHFIN-01 and resource group for POOL-FIN-01.
Expected result: Only affected POOL-FIN-01 VMs are listed.

4. ELEVATED: For each affected VM, open Disks > OS disk > Create snapshot.
Expected result: Snapshot provisioning state is Succeeded for each VM.

5. ELEVATED: For each affected VM, open Virtual machines > <VM> > Disks > Swap OS disk and select the last known good disk/image baseline.
Expected result: OS disk swap operation completes successfully.

6. ELEVATED: Restart each affected VM from Virtual machines > <VM> > Overview > Restart.
Expected result: VM power state returns to Running and status checks pass.

7. ELEVATED: In Azure Portal, return to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and set Allow new sessions = Yes on exactly two hosts.
Expected result: Two POOL-FIN-01 hosts accept new sessions for pilot validation.

8. Ask two pilot users to sign in to POOL-FIN-01 and stay connected for 10 minutes.
Expected result: No black screen and no disconnect loop for both pilot users.

9. ELEVATED: If pilot is successful, set Allow new sessions = Yes on remaining POOL-FIN-01 hosts.
Expected result: Full POOL-FIN-01 capacity is restored.

Fast command path (PowerShell, Az modules):
```powershell
# Variables
$rg = "<pool-fin-01-rg>"
$sub = "<subscription-id>"
$pool = "POOL-FIN-01"
$hosts = @("SHFIN-01-A","SHFIN-01-B")

Set-AzContext -Subscription $sub

# Drain POOL-FIN-01
foreach ($h in $hosts) {
	Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name "$h.$pool" -AllowNewSession:$false
}

# Restart affected VMs after disk rollback/swap
foreach ($h in $hosts) {
	Restart-AzVM -ResourceGroupName $rg -Name $h -NoWait
}

# Re-open two pilot hosts
Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name "SHFIN-01-A.$pool" -AllowNewSession:$true
Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name "SHFIN-01-B.$pool" -AllowNewSession:$true
```

## Verification
1. In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions.
Expected result: New user sessions are active on POOL-FIN-01 without immediate disconnect.

2. On two validation hosts, open Event Viewer (Local) > Windows Logs > Application and filter Event IDs 1000,9009 for Last 30 minutes.
Expected result: No new Event 1000 (dwm.exe with igdumd64.dll) and no Event 9009 are present.

3. On one control host in POOL-FIN-02, open Event Viewer (Local) > Windows Logs > Application and filter Event ID 9011 for Last 30 minutes.
Expected result: Event 9011 is present, confirming healthy baseline remains intact.

4. In Azure Portal, open Monitor > Logs (or Log Analytics workspace linked to AVD) and run cross-pool check.
Expected result: Query shows error pattern absent in POOL-FIN-01 after fix and healthy 9011 in POOL-FIN-02.

Fast command path (Azure CLI):
```bash
az monitor log-analytics query \
	--workspace <workspace-id> \
	--analytics-query "Event | where TimeGenerated >= ago(30m) | where EventID in (1000,9009,9011) | where Computer contains 'POOL-FIN-01' or Computer contains 'POOL-FIN-02' | project TimeGenerated, Computer, EventID, Source, RenderedDescription | order by TimeGenerated desc" \
	--output table
```

5. In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and confirm all production hosts are set to Allow new sessions = Yes.
Expected result: POOL-FIN-01 is fully restored to service.

## Rollback
Use rollback immediately if any pilot user still gets black screen or Event 1000/9009 reappears.

1. ELEVATED: In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and set Allow new sessions = No for all hosts.
Expected result: New user entry into POOL-FIN-01 is blocked.

2. ELEVATED: In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions and sign out all active sessions.
Expected result: Active session count reaches 0.

3. ELEVATED: In Azure Portal, open Virtual machines > each affected SHFIN-01 VM > Disks > Swap OS disk and switch back to the pre-change disk/snapshot baseline.
Expected result: Each VM is returned to pre-fix disk state.

4. ELEVATED: Restart each rolled-back VM from Virtual machines > <VM> > Overview > Restart.
Expected result: Rolled-back VMs return to Running.

5. ELEVATED: In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and verify host status is Available while still drained.
Expected result: Hosts are healthy but not accepting new sessions.

Fast command path (PowerShell, Az modules):
```powershell
$rg = "<pool-fin-01-rg>"
$pool = "POOL-FIN-01"
$hosts = @("SHFIN-01-A","SHFIN-01-B")

# Immediate containment
foreach ($h in $hosts) {
	Update-AzWvdSessionHost -ResourceGroupName $rg -HostPoolName $pool -Name "$h.$pool" -AllowNewSession:$false
}

# Restart after OS disk rollback/swap
foreach ($h in $hosts) {
	Restart-AzVM -ResourceGroupName $rg -Name $h -NoWait
}
```

6. ELEVATED: Run post-rollback event check from Log Analytics to confirm pattern is contained.
Expected result: No new user-impact wave starts on POOL-FIN-01 while rollback state is active.

Fast command path (Azure CLI):
```bash
az monitor log-analytics query \
	--workspace <workspace-id> \
	--analytics-query "Event | where TimeGenerated >= ago(15m) | where Computer contains 'POOL-FIN-01' | where EventID in (1000,9009) | project TimeGenerated, Computer, EventID, RenderedDescription | order by TimeGenerated desc" \
	--output table
```

## Preventive
Strengthened controls (do not skip):

1. USER/SYSTEM split control (existing): Owner: release engineer. Timing: before deployment.
Pass: two separate script objects exist, naming pattern USER-MAP-* and SYSTEM-BASE-*; Fail: any mixed-purpose object.
Signal: Intune Platform scripts list shows exactly one purpose per object; Failure action: change manager blocks release.
Mode: Manual today. Automation note: enforce naming/purpose check via Graph API pre-check job.

2. Assignment guardrail (existing): Owner: change manager. Timing: during deployment approval.
Pass: Finance production group assignment allowed only if script name contains USER-MAP and second-person approval is recorded; Fail otherwise.
Signal: approval record + assignment diff in change ticket; Failure action: remove assignment immediately and reopen CAB decision.
Mode: Manual. Automation note: policy rule to deny assignment change when naming/approval metadata is missing. [REQUIRES: Intune assignment policy enforcement process]

3. Pilot ring gate (existing): Owner: DWP engineer. Timing: during deployment.
Pass: 5 pilot devices for 60 minutes with 0 new "Exit code: 1" and 0 "Network name cannot be found" entries; Fail: count >= 1.
Signal: IntuneManagementExtension.log counts per pilot device; Failure action: stop rollout and execute rollback section.
Mode: Manual today. Automation note: scheduled parser to aggregate pilot log error counts and gate expansion.

4. Script telemetry standard (existing): Owner: image owner. Timing: before deployment.
Pass: script writes timestamp, user context, target path, and final status SUCCESS/FAIL per run; Fail: any field missing.
Signal: random sample of 3 executions in IntuneManagementExtension.log contains all required fields; Failure action: reject script from release.
Mode: Manual review. Automation note: static lint rule for required Write-Output markers in script PR checks.

5. Closure evidence gate (existing): Owner: service desk lead. Timing: after deployment.
Pass: closure includes 3-device verification plus POOL-FIN-02 control comparison evidence; Fail: any evidence missing.
Signal: ticket checklist all true before status can move to Resolved; Failure action: ticket returned to implementing engineer.
Mode: Manual. Automation note: ticket workflow field validation before closure transition.

6. Pre-deployment smoke test gate (added): Owner: DWP engineer. Timing: before deployment.
Pass: test account on pre-prod maps S: to \\finbridge-fs01\Finance in < 30 seconds with no error strings; Fail otherwise.
Signal: one successful open of S: and 0 matches for "Exit code: 1" in test run logs; Failure action: release engineer cancels production deployment.
Mode: Manual today. Automation note: scripted synthetic logon + drive-open check in pre-prod.

7. In-flight monitoring alert (added): Owner: service desk lead. Timing: during deployment window.
Pass: Event 1000 + igdumd64.dll count on POOL-FIN-01 remains 0 and Event 9009 count remains 0 in 15-minute windows; Fail: count >= 1.
Signal: Log Analytics query scheduled every 5 minutes with threshold alert; Failure action: trigger major incident bridge and drain POOL-FIN-01.
Mode: Automated. [REQUIRES: Log Analytics scheduled alert rule]

8. Post-deployment validation gate (added): Owner: DWP engineer. Timing: after deployment.
Pass: three Finance devices open S: successfully and Application log shows no new Event 1000/9009 for 30 minutes; Fail otherwise.
Signal: validation checklist plus exported event query results attached to change record; Failure action: keep change open and run rollback.
Mode: Manual with command output evidence.

9. Rollback trigger threshold (added): Owner: change manager. Timing: during and after deployment.
Pass: no rollback triggers met; Fail trigger if any one occurs: two pilot failures, or Event 1000/9009 >= 1 after change.
Signal: pilot result table + Log Analytics event count; Failure action: execute rollback in under 3 minutes and notify stakeholders.
Mode: Semi-automated. Automation note: alert-to-runbook integration to auto-create rollback task. [REQUIRES: alert-to-ITSM integration]

10. Knowledge update control (added): Owner: release engineer. Timing: after incident closure.
Pass: runbook, L1 KB, and L2/L3 KB updated within 2 business days with new detection/resolution evidence; Fail: any document missing update.
Signal: document version/date delta and peer-review comment recorded in change ticket; Failure action: keep problem record open until completed.
Mode: Manual. Automation note: closure checklist requiring document links and updated version fields.

## Related
1. FAULT-B runbook: FAULT-B-shared-drives-runbook.md.
2. FAULT-B L1 article: FAULT-B-shared-drives-l1-self-service-kb.md.
3. Related RCA/records: FAULT-B scope hypothesis, detailed RCA, known-error record, and closure note.