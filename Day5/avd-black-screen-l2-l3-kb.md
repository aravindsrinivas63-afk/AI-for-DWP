# AVD Black Screen Incident Knowledge Base (L2/L3)
Version Header: v 1.0, 07/08/2026, status : Draft
Version: v 1.0
Date: 07/08/2026
Status : Draft

## Background: what the system does and why it matter
Azure Virtual Desktop (AVD) host pool `POOL-FIN-01` provides Finance users with multi-session Windows desktops for daily business operations (line-of-business apps, shared drives, and regulated data workflows). Desktop rendering after sign-in depends on Desktop Window Manager (`dwm.exe`) and the host graphics driver stack. If DWM fails during session initialization, users can authenticate but receive a black screen, causing immediate productivity loss and incident volume spikes.

The environment includes a comparison pool (`POOL-FIN-02`) used as a control baseline. In this incident family, `POOL-FIN-01` received an overnight image update while `POOL-FIN-02` did not, which is the key diagnostic boundary.

## Symptom: what the engineer observers and what the user report
### What users report
- "I can sign in but only get a black screen."
- "Sometimes it recovers after 20-30 seconds, sometimes it disconnects and reconnects."
- Repeated session failures shortly after logon.

### What engineers observe
- `POOL-FIN-01` has concentrated black-screen reports after image rollout.
- `POOL-FIN-02` users continue to log on normally in the same time window.
- Session sequence on affected hosts commonly shows:
  - Successful logon (Event ID `21`)
  - `dwm.exe` crash in `igdumd64.dll` (Event ID `1000`)
  - Session disconnect (Event ID `40`)
  - DWM exit (Event ID `9009`)

## Root cause: the specific technical cause with the evidence that confirms it
The root cause is a graphics/display driver regression introduced in the updated `POOL-FIN-01` image, specifically `dwm.exe` faulting in `igdumd64.dll`.

### Confirming evidence
- Affected pool (`POOL-FIN-01`) repeatedly logs Application Error Event ID `1000` with:
  - `Faulting application name: dwm.exe`
  - `Faulting module name: igdumd64.dll`
  - `Exception code: 0xc0000005`
- Affected pool logs Desktop Window Manager Operational Event ID `9009` after the crash path.
- Affected pool logs TerminalServices-LocalSessionManager Event ID `40` disconnects following Event ID `21` successful logon.
- Comparison pool (`POOL-FIN-02`) shows Desktop Window Manager Event ID `9011` start success and no matching Event ID `1000` crash signature in the same period.

## Detection: exactly how to confirm this is the issue before acting
Target outcome: confirm or reject this incident signature in under 3 minutes.

1. Open the exact logs and check the exact events on one affected host in `POOL-FIN-01`
- Application log location (required): Event Viewer > Windows Logs > Application.
- Search Event ID: `1000`.
- Required fields in Event `1000` (General tab/message): `Faulting application name`, `Faulting module name`, `Exception code`.
- Positive match: `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll` (typically with `Exception code: 0xc0000005`).

2. Validate healthy control baseline on one host in `POOL-FIN-02`
- Log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational.
- Search Event ID: `9011`.
- Required baseline: Event `9011` present (DWM start success) on `POOL-FIN-02` control host, with no matching `Application` Event `1000` containing `dwm.exe` + `igdumd64.dll` in the same time window.

3. Optional correlation check on affected host (strong confidence)
- Log location: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
- Search Event IDs: `21` and `40`.
- Required pattern: Event `21` (logon succeeded) followed soon by Event `40` (disconnect) for the same session.

4. Fast PowerShell extraction (preferred over manual clicking)
Use this on an admin workstation with remote access to both hosts:

```powershell
$start = (Get-Date).AddHours(-2)
$affectedHost = "SHFIN-01-A"   # POOL-FIN-01 sample host
$controlHost  = "SHFIN-02-A"   # POOL-FIN-02 control host

# Affected host: Application log Event 1000 with required signature
Invoke-Command -ComputerName $affectedHost -ScriptBlock {
  Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Id = 1000; StartTime = $using:start } |
  Where-Object {
    $_.Message -match 'Faulting application name:\s*dwm.exe' -and
    $_.Message -match 'Faulting module name:\s*igdumd64\.dll'
  } |
  Select-Object TimeCreated, Id, MachineName, ProviderName, Message
}

# Control host: DWM Operational Event 9011 (healthy baseline)
Invoke-Command -ComputerName $controlHost -ScriptBlock {
  Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Desktop Window Manager/Operational'; Id = 9011; StartTime = $using:start } |
  Select-Object TimeCreated, Id, MachineName, ProviderName, Message
}
```

5. Fast Azure CLI extraction from Log Analytics (cross-host confirmation)
Use this when host remote PowerShell is unavailable:

```bash
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "Event | where TimeGenerated >= ago(2h) | where Computer in~ ('SHFIN-01-A','SHFIN-02-A') | where EventID in (1000,9011) | where EventID != 1000 or (RenderedDescription contains 'dwm.exe' and RenderedDescription contains 'igdumd64.dll') | project TimeGenerated, Computer, EventID, RenderedDescription | order by TimeGenerated desc" \
  --output table
```

6. Decision rule before acting
- Confirm this incident only when both are true:
- `POOL-FIN-01` affected host has `Application` Event `1000` with `dwm.exe` + `igdumd64.dll`.
- `POOL-FIN-02` control host shows Event `9011` healthy baseline and no matching Event `1000` crash signature in the same period.

## Resolution: step-by-step fix with expected result after each step
Goal: complete containment and host recovery in 5-10 minutes using command-first actions.

0. Set working variables (PowerShell)
```powershell
$SubscriptionId = "<subscription-id>"
$ResourceGroup  = "<resource-group-containing-session-host-vms>"
$HostPoolName   = "POOL-FIN-01"
$ControlPool    = "POOL-FIN-02"
$WorkspaceRG    = "<resource-group-containing-avd-hostpool-object>"
$Hosts = @("SHFIN-01-A","SHFIN-01-B")
$ControlHost = "SHFIN-02-A"
Set-AzContext -Subscription $SubscriptionId
```

1. Drain pool traffic at exact host-pool setting
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > Session hosts > select host > `Allow new sessions` > set to `No` > Save.
- Fast PowerShell:
```powershell
foreach ($h in $Hosts) {
  $name = "$h.$HostPoolName"
  Update-AzWvdSessionHost -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -Name $name -AllowNewSession:$false
}
```
- Expected result: `Allow new sessions = No` on all `POOL-FIN-01` hosts.

2. Message and sign out active user sessions
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > User sessions > select all > `Send message` then `Sign out`.
- Fast PowerShell:
```powershell
$sessions = Get-AzWvdUserSession -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName
foreach ($s in $sessions) {
  Send-AzWvdUserSessionMessage -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -SessionHostName $s.SessionHostName -Id $s.Id -MessageTitle "Finance AVD maintenance" -MessageBody "You will be signed out in 2 minutes."
}
Start-Sleep -Seconds 15
foreach ($s in (Get-AzWvdUserSession -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName)) {
  Remove-AzWvdUserSession -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -SessionHostName $s.SessionHostName -Id $s.Id -Force
}
```
- Expected result: `User sessions` list for `POOL-FIN-01` is empty.

3. Capture safety snapshots before image rollback
- Azure portal path and option: Azure Portal > Virtual machines > `<affected-vm>` > Disks > OS disk > Create snapshot > Name `pre_fix_<hostname>_<yyyymmdd_hhmm>` > Review + create.
- Fast PowerShell:
```powershell
foreach ($h in $Hosts) {
  $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $h
  $osDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id
  $snapName = "pre_fix_{0}_{1}" -f $h, (Get-Date -Format "yyyyMMdd_HHmm")
  $cfg = New-AzSnapshotConfig -SourceUri $osDiskId -Location $vm.Location -CreateOption Copy
  New-AzSnapshot -ResourceGroupName $ResourceGroup -SnapshotName $snapName -Snapshot $cfg | Out-Null
}
```
- Expected result: one completed snapshot per affected VM.

4. Read known-good driver baseline from control host
- Azure portal path and option: Azure Portal > Virtual machines > `SHFIN-02-A` > Connect > Bastion/RDP > run `pnputil /enum-drivers`.
- Fast PowerShell:
```powershell
Invoke-Command -ComputerName $ControlHost -ScriptBlock {
  pnputil /enum-drivers | Select-String -Pattern "igdumd64.dll|Intel"
}
```
- Expected result: known-good Intel graphics package/version is recorded.

5. Roll affected hosts back to known-good image state
- Azure portal path and option: Azure Portal > Virtual machines > `<affected-vm>` > Disks > `Swap OS disk` > Source type: `Managed disk` > select last-known-good disk/image baseline > Save.
- Fast Azure CLI (requires extension):
```bash
az extension add --name desktopvirtualization
```
- Fast PowerShell (example using disk swap):
```powershell
# Pre-create or identify known-good OS managed disk per host, then attach it
foreach ($h in $Hosts) {
  $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $h
  $knownGoodDiskId = "<managed-disk-id-for-$h-known-good-os>"
  $vm.StorageProfile.OsDisk.ManagedDisk.Id = $knownGoodDiskId
  Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm | Out-Null
}
```
- Expected result: each VM now references known-good OS disk/image baseline.

6. Restart affected hosts and wait for host-pool availability
- Azure portal path and option: Azure Portal > Virtual machines > `<affected-vm>` > Overview > Restart.
- Fast PowerShell:
```powershell
foreach ($h in $Hosts) { Restart-AzVM -ResourceGroupName $ResourceGroup -Name $h -NoWait }
```
- Expected result: VMs return `Running`, then Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > Session hosts shows status `Available`.

7. Re-enable two pilot hosts only
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > Session hosts > select 2 hosts > `Allow new sessions` = `Yes` > Save.
- Fast PowerShell:
```powershell
$pilot = $Hosts[0..1]
foreach ($h in $pilot) {
  Update-AzWvdSessionHost -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -Name "$h.$HostPoolName" -AllowNewSession:$true
}
```
- Expected result: only two hosts accept new sessions for pilot validation.

8. Open all hosts after clean pilot signal
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > Session hosts > select remaining hosts > `Allow new sessions` = `Yes`.
- Fast PowerShell:
```powershell
foreach ($h in $Hosts) {
  Update-AzWvdSessionHost -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -Name "$h.$HostPoolName" -AllowNewSession:$true
}
```
- Expected result: full `POOL-FIN-01` capacity restored.

## Verification: how to confirm the fix worked
Run all four checks before closure.

1. Verify host-pool settings and registration state
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > Session hosts.
- Check fields: `Status` must be `Available`; `Allow new sessions` must be `Yes` on intended hosts only.
- Fast PowerShell:
```powershell
Get-AzWvdSessionHost -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName |
  Select-Object Name, Status, AllowNewSession
```
- Pass condition: pilot hosts available and accepting sessions; no unexpected unavailable hosts.

2. Verify event signature is gone on affected hosts
- Exact log locations:
  - Event Viewer > Windows Logs > Application (Event ID `1000`)
  - Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager-Operational (Event ID `9009`)
- Fast PowerShell:
```powershell
$start = (Get-Date).AddMinutes(-30)
foreach ($h in $Hosts) {
  Invoke-Command -ComputerName $h -ScriptBlock {
    $s = $using:start
    $e1000 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$s } |
      Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64\.dll' }
    $e9009 = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$s }
    [pscustomobject]@{ Host=$env:COMPUTERNAME; Event1000MatchCount=$e1000.Count; Event9009Count=$e9009.Count }
  }
}
```
- Pass condition: `Event1000MatchCount = 0` and `Event9009Count = 0` for all remediated hosts.

3. Verify stable user sessions in host pool
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > User sessions.
- Check fields: active sessions increase normally; no rapid reconnect/disconnect.
- Fast PowerShell:
```powershell
Get-AzWvdUserSession -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName |
  Select-Object SessionHostName, UserPrincipalName, SessionState, CreateTime
```
- Pass condition: pilot sessions remain connected for 10+ minutes with no forced reconnect loops.

4. Verify control comparison remains healthy (`POOL-FIN-02`)
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-02` > Session hosts and user sessions.
- Fast PowerShell:
```powershell
$controlStart = (Get-Date).AddMinutes(-30)
Invoke-Command -ComputerName $ControlHost -ScriptBlock {
  $s = $using:controlStart
  $e9011 = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$s }
  $e1000 = Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$s } |
    Where-Object { $_.Message -match 'dwm.exe' -and $_.Message -match 'igdumd64\.dll' }
  [pscustomobject]@{ Host=$env:COMPUTERNAME; Event9011Count=$e9011.Count; Crash1000Count=$e1000.Count }
}
```
- Pass condition: `Event9011Count >= 1` and `Crash1000Count = 0` on control host.

## Rollback: what to do if the fix makes thing worse
Trigger rollback immediately if any occurs after remediation:
- New black-screen report in pilot or production users
- Reappearance of Event `1000` (`dwm.exe` + `igdumd64.dll`)
- Reappearance of Event `9009`

1. Re-drain impacted pool
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > Session hosts > select all > `Allow new sessions` = `No` > Save.
- Fast PowerShell:
```powershell
foreach ($h in $Hosts) {
  Update-AzWvdSessionHost -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -Name "$h.$HostPoolName" -AllowNewSession:$false
}
```
- Expected result: all new logons to `POOL-FIN-01` stop immediately.

2. Redirect users to healthy pool
- Azure portal path and option:
  - Azure Portal > Azure Virtual Desktop > Application groups > `<Finance-Desktop-POOL-FIN-01>` > Assignments > remove impacted user group.
  - Azure Portal > Azure Virtual Desktop > Application groups > `<Finance-Desktop-POOL-FIN-02>` > Assignments > add same user group.
- Fast Azure CLI:
```bash
FIN01_SCOPE=$(az desktopvirtualization applicationgroup show --resource-group <avd-rg> --name <Finance-Desktop-POOL-FIN-01> --query id -o tsv)
FIN02_SCOPE=$(az desktopvirtualization applicationgroup show --resource-group <avd-rg> --name <Finance-Desktop-POOL-FIN-02> --query id -o tsv)
az role assignment delete --assignee-object-id <aad-group-object-id> --role "Desktop Virtualization User" --scope "$FIN01_SCOPE"
az role assignment create --assignee-object-id <aad-group-object-id> --role "Desktop Virtualization User" --scope "$FIN02_SCOPE"
```
- Expected result: new user launches route to `POOL-FIN-02` app group path.

3. Force sign-out remaining affected sessions
- Azure portal path and option: Azure Portal > Azure Virtual Desktop > Host pools > `POOL-FIN-01` > User sessions > select all > `Sign out`.
- Fast PowerShell:
```powershell
Get-AzWvdUserSession -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName |
  ForEach-Object {
    Remove-AzWvdUserSession -ResourceGroupName $WorkspaceRG -HostPoolName $HostPoolName -SessionHostName $_.SessionHostName -Id $_.Id -Force
  }
```
- Expected result: `POOL-FIN-01` user sessions list is empty.

4. Restore pre-fix snapshots if required
- Azure portal path and option: Azure Portal > Virtual machines > `<affected-vm>` > Disks > `Swap OS disk` > select disk recreated from `pre_fix_<hostname>_<yyyymmdd_hhmm>` snapshot > Save.
- Fast PowerShell:
```powershell
foreach ($h in $Hosts) {
  $snap = Get-AzSnapshot -ResourceGroupName $ResourceGroup | Where-Object { $_.Name -like "pre_fix_${h}_*" } | Sort-Object TimeCreated -Descending | Select-Object -First 1
  $diskName = "rollback-osdisk-$h-$(Get-Date -Format yyyyMMddHHmm)"
  $diskCfg = New-AzDiskConfig -Location $snap.Location -CreateOption Copy -SourceResourceId $snap.Id
  $disk = New-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -Disk $diskCfg
  $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $h
  $vm.StorageProfile.OsDisk.ManagedDisk.Id = $disk.Id
  Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm | Out-Null
  Restart-AzVM -ResourceGroupName $ResourceGroup -Name $h -NoWait
}
```
- Expected result: hosts run from pre-fix rollback disk state.

5. Escalate with evidence package
- Azure portal path and option: Azure Portal > Help + support > Create a support request > Service: `Azure Virtual Desktop` > Problem type: `Session host` > Severity: `High`.
- Action: attach host list, Event `1000/9009/9011` evidence, and rollback timestamps.
- Expected result: Azure support case ID added to incident record.

## Preventive: the specific change to process or tooling that stop this recurring
1. Introduce ring-based image promotion with enforced gate
- Owner: release engineer; Timing: during deployment (canary ring before broad rollout).
- Pass/Fail signal: in first 60 minutes on canary hosts, count(Event 1000 with dwm.exe + igdumd64.dll) = 0 and count(Event 9009) = 0; fail if either count >= 1.
- Failure action: automatic promotion block, change manager notified, incident opened, rollback to last known-good image baseline.
- Mode: automated [REQUIRES: release pipeline gate + Log Analytics query check task].

2. Add automated crash-signature alerting
- Owner: DWP engineer; Timing: during deployment and first 2 hours after deployment.
- Pass/Fail signal: alert rule fires if Event 1000 signature count >= 1 in 5 minutes, or Event 9009 count >= 3 in 5 minutes per host; pass is zero alerts in window.
- Failure action: auto-page service desk lead and release engineer, drain affected hosts, stop further rollout.
- Mode: automated [REQUIRES: Azure Monitor Scheduled Query Rules + action group integration].

3. Enforce graphics-driver baseline control
- Owner: image owner; Timing: before deployment (image publish stage).
- Pass/Fail signal: driver inventory exactly matches approved manifest version and hash for Intel display stack; fail on any mismatch or unsigned package.
- Failure action: pipeline fails publish, CAB exception required to proceed, release engineer cannot promote image.
- Mode: automated [REQUIRES: image pipeline driver inventory and hash validation step].

4. Mandatory cross-pool comparison checkpoint
- Owner: change manager; Timing: after deployment (first post-deploy hour).
- Pass/Fail signal: POOL-FIN-01 shows Event 1000 signature count = 0 and Event 9009 count = 0; POOL-FIN-02 shows Event 9011 >= 1 and signature Event 1000 count = 0.
- Failure action: change cannot be closed, rollback decision invoked, L2/L3 bridge remains active until green comparison evidence is attached.
- Mode: manual with query evidence upload; automation note: auto-attach workbook snapshot to change record [REQUIRES: ITSM-Log Analytics connector].

5. Maintain rapid rollback readiness
- Owner: change manager; Timing: before deployment (T-24h readiness check).
- Pass/Fail signal: 100% of targeted hosts have pre-change snapshot available and last known-good image version retrievable; fail if any host/image missing.
- Failure action: change window blocked until gaps are fixed; emergency rollback route documented in ticket before go-live.
- Mode: automated audit + manual sign-off [REQUIRES: scheduled compliance report for snapshot/image retention].

6. Pre-deployment smoke test gate
- Owner: release engineer; Timing: before deployment.
- Pass/Fail signal: 2 test logons on canary host complete with no Event 1000 signature and no Event 9009 within 15 minutes; fail if any black screen or matching event occurs.
- Failure action: release not started, image sent back to image owner for rebuild and re-test.
- Mode: manual today; automation note: scripted synthetic logon test with event scrape [REQUIRES: synthetic logon runner].

7. In-flight rollout monitoring window
- Owner: DWP engineer; Timing: during deployment.
- Pass/Fail signal: every 5 minutes, per-host query shows Event 1000 signature count = 0 and Event 9009 count < 3; fail if thresholds breached once.
- Failure action: immediate host drain on breached host, halt ring expansion, notify service desk lead.
- Mode: automated [REQUIRES: per-host alert dimension in Log Analytics alert rule].

8. Post-deployment validation gate for change closure
- Owner: change manager; Timing: after deployment.
- Pass/Fail signal: for 30 minutes post-open, POOL-FIN-01 has zero signature Event 1000 and zero Event 9009, and stable sessions with no repeated Event 40 after Event 21.
- Failure action: change remains open, rollback or remediation task created, closure approval denied.
- Mode: manual evidence review; automation note: generate closure checklist from query outputs [REQUIRES: ITSM template automation].

9. Explicit rollback trigger threshold
- Owner: service desk lead; Timing: during and after deployment.
- Pass/Fail signal: trigger rollback when any one condition occurs: 2 or more black-screen tickets in 10 minutes, or Event 1000 signature >= 1, or Event 9009 >= 3 per host in 5 minutes.
- Failure action: execute rollback runbook immediately, re-route users to POOL-FIN-02, open major incident bridge.
- Mode: manual trigger from automated alerts; automation note: webhook to runbook orchestration [REQUIRES: alert-to-runbook automation].

10. Knowledge update and control feedback loop
- Owner: image owner; Timing: after deployment (within 1 business day of incident/change).
- Pass/Fail signal: runbook, L2/L3 KB, and release checklist updated with new signatures, thresholds, and decision tree; fail if any artifact not updated by SLA.
- Failure action: problem record remains open and next image change cannot enter CAB approval.
- Mode: manual [REQUIRES: problem-management workflow enforcing documentation SLA].

## Related: other incidents or KB article this connects to
- FinBridge AVD incident RCA family and evidence pack:
  - `finbridge-avd-black-screen-rca.md`
  - `finbridge-avd-black-screen-rca-resolution.md`
  - `finbridge-avd-black-screen-final-rca.md`
  - `finbridge-avd-black-screen-known-error-record.md`
- Operational runbook used for remediation execution:
  - `avd-black-screen-runbook.md`
- L1 self-service guidance for end users:
  - `avd-black-screen-l1-self-service-kb.md`
