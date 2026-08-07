# Title: AVD Black Screen After Logon Runbook (POOL-FIN-01)
# Version: 1.0
# Date: 07/08/2026
# Author: Aravind
# Reviewed: self
# Status: draft
# Change: initial version from RCA

# Runbook: FinBridge AVD Black Screen After Logon (POOL-FIN-01)

## Prerequisites

Use this checklist before you start. Do not proceed until every mandatory item is checked.

### Access Checklist

- [ ] [ELEVATED] I can sign in to Azure Portal in the production tenant.
- [ ] [ELEVATED] I can open Azure Virtual Desktop > Host pools > `POOL-FIN-01`.
- [ ] [ELEVATED] I can open Azure Virtual Desktop > Host pools > `POOL-FIN-02`.
- [ ] [ELEVATED] I can open Virtual machines for all `POOL-FIN-01` session hosts.
- [ ] [ELEVATED] I can create VM snapshots in the affected resource group.
- [ ] [ELEVATED] I can restart VMs in the affected resource group.
- [ ] I can open Log Analytics workspace and run KQL queries.

### Tooling Checklist

- [ ] Azure Portal is open in a browser.
- [ ] PowerShell 7+ opens successfully on your admin workstation.
- [ ] The `Az` module is installed (`Get-Module -ListAvailable Az`).
- [ ] Event Viewer can be opened on at least one affected session host (RDP or Bastion access).

### Mandatory End-User Information Checklist

- [ ] Primary affected username (UPN or `DOMAIN\\username`) is captured.
- [ ] At least one affected sign-in timestamp (with timezone) is captured.
- [ ] Affected AVD workspace/feed name is captured.
- [ ] Affected host pool name is confirmed as `POOL-FIN-01`.
- [ ] Affected client type is captured (Windows App, Remote Desktop client, web client).
- [ ] Symptom statement is captured exactly (for example: `black screen immediately after sign-in`).
- [ ] Whether the session eventually recovers is captured (`recovers` or `does not recover`).
- [ ] Screenshot or screen recording from one affected user is attached to the ticket.

### Mandatory Platform Information Checklist

- [ ] Subscription ID for affected host pool is captured.
- [ ] Resource group name for `POOL-FIN-01` hosts is captured.
- [ ] List of all `POOL-FIN-01` session host VM names is captured.
- [ ] Last known good image version ID (pre-incident update) is captured.
- [ ] Change record ID for the overnight image rollout is captured.
- [ ] Maintenance broadcast message text is approved for user communications.

## Procedure

1. [ELEVATED] In Azure Portal, go to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01`.
   Expected result: The `POOL-FIN-01` host pool overview blade is open.

2. [ELEVATED] In `POOL-FIN-01`, open `Session hosts` and set `Allow new sessions` to `No` for each host using the row action menu.
   Expected result: Every host row shows `Allow new sessions: No`.

3. [ELEVATED] In `POOL-FIN-01`, open `User sessions` and select `Send message` with text `Finance AVD maintenance in progress. Session sign-out in 5 minutes.`.
   Expected result: Message submission completes with no portal error.

4. [ELEVATED] In `POOL-FIN-01` > `User sessions`, select each active session and click `Sign out`.
   Expected result: The active session count becomes `0`.

5. [ELEVATED] In Azure Portal, go to `Virtual machines` and filter by the resource group that contains `POOL-FIN-01` session hosts.
   Expected result: Only the affected session host VMs are listed.

6. [ELEVATED] For each affected VM, open `Disks` > click OS disk > `Create snapshot`, and name it `pre_fix_<hostname>_<yyyymmdd_hhmm>`.
   Expected result: One completed snapshot exists per affected VM in `Completed` provisioning state.

7. [ELEVATED] Connect to one healthy `POOL-FIN-02` host and open Event Viewer at `Windows Logs` > `Application`.
   Expected result: Application log is visible on the healthy host.

8. [ELEVATED] On that healthy host, run `pnputil /enum-drivers` in an elevated command prompt and record the Intel display driver package/version tied to `igdumd64.dll`.
   Expected result: A known-good display driver version is documented in the incident ticket.

9. [ELEVATED] In Azure Portal, go to `Virtual machines` > select one affected `POOL-FIN-01` host > `Disks` > `Swap OS disk`, and select the disk created from the last known good image version.
   Expected result: OS disk swap operation starts successfully for that VM.

10. [ELEVATED] Repeat the OS disk swap for each remaining affected `POOL-FIN-01` host VM.
    Expected result: All affected hosts are now pointed to last known good OS disks.

11. [ELEVATED] On each swapped `POOL-FIN-01` host, install or pin the known-good Intel display driver version from Step 8.
    Expected result: Driver version on each affected host matches the known-good baseline.

12. [ELEVATED] In Azure Portal, restart each affected `POOL-FIN-01` VM from `Virtual machines` > VM > `Overview` > `Restart`.
    Expected result: Each VM returns to `Running` with successful status checks.

13. [ELEVATED] In Azure Portal, return to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, and set `Allow new sessions` to `Yes` on exactly two hosts.
    Expected result: Exactly two hosts show `Allow new sessions: Yes`.

14. Ask two Finance pilot users to sign in to the AVD workspace and remain connected for 10 minutes.
    Expected result: Both users reach full desktop with no black screen or disconnect.

15. [ELEVATED] On each validation host, open Event Viewer at `Windows Logs` > `Application` and filter current log for Event ID `1000` where `Faulting application name` is `dwm.exe` and `Faulting module name` is `igdumd64.dll` in the last 15 minutes.
    Expected result: Filter returns zero matching events.

16. [ELEVATED] On each validation host, open Event Viewer at `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager-Operational` and filter for Event ID `9009` in the last 15 minutes.
    Expected result: Filter returns zero matching events.

17. [ELEVATED] In Azure Portal, open `Log Analytics workspaces` > select the workspace linked to AVD diagnostics > `Logs`, and run this KQL query over the last 30 minutes:
   ```kusto
   Event
   | where TimeGenerated >= ago(30m)
   | where Computer startswith "SHFIN-01" or Computer contains "POOL-FIN-01"
   | where EventID == 9009
      or (
         EventID == 1000
         and RenderedDescription contains "dwm.exe"
         and RenderedDescription contains "igdumd64.dll"
      )
   | project TimeGenerated, Computer, EventID, RenderedDescription
   | order by TimeGenerated desc
   ```
   Expected result: Query returns zero rows.

18. [ELEVATED] In `POOL-FIN-01` > `Session hosts`, set `Allow new sessions` to `Yes` on all remaining drained hosts.
    Expected result: All hosts in `POOL-FIN-01` are accepting sessions.

19. Update the incident ticket with snapshot IDs, swapped disk IDs, driver version, pilot test result, and log evidence.
    Expected result: Ticket has complete recovery evidence and is ready for closure approval.

## Verification

Run these checks in order before closure.

1. In Azure Portal, go to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `User sessions`.
   Expected result: At least 5 active sessions are visible after recovery window starts.

2. In `POOL-FIN-01` > `User sessions`, open each of the 5 test sessions and verify each session duration exceeds 10 minutes.
   Expected result: All 5 sessions stay connected for 10+ minutes.

3. On one validation host, open Event Viewer at `Windows Logs` > `Application` > `Filter Current Log...`.
   Expected result: Filter dialog opens.

4. In the filter dialog, set `Event sources` to `Application Error`, set `Event ID` to `1000`, and set `Logged` to `Last 30 minutes`.
   Expected result: Filtered Application log is displayed.

5. In filtered results, check `General` tab for each event and verify no event contains both `dwm.exe` and `igdumd64.dll`.
   Expected result: Zero matching crash events are present.

6. On the same host, open Event Viewer at `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager-Operational` > `Filter Current Log...`.
   Expected result: DWM Operational filter dialog opens.

7. In the filter dialog, set `Event ID` to `9009` and set `Logged` to `Last 30 minutes`.
   Expected result: Filtered DWM log is displayed.

8. In filtered DWM results, verify the result list is empty.
   Expected result: No Event 9009 is present in last 30 minutes.

9. In Azure Portal, go to `Log Analytics workspaces` > linked AVD workspace > `Logs`, and run this query:
   ```kusto
   Event
   | where TimeGenerated >= ago(30m)
   | where Computer startswith "SHFIN-01" or Computer contains "POOL-FIN-01"
   | where EventID == 9009
      or (
         EventID == 1000
         and RenderedDescription contains "dwm.exe"
         and RenderedDescription contains "igdumd64.dll"
      )
   | project TimeGenerated, Computer, EventID, RenderedDescription
   | order by TimeGenerated desc
   ```
   Expected result: Query returns zero rows.

10. In the service desk ticketing console, search open incidents using keyword `black screen` and filter queue `Finance` for the last 30 minutes.
    Expected result: No new Finance black-screen incidents are open.

Do not close the incident unless all 10 checks pass.

## Rollback

Target: complete containment rollback in under 3 minutes.

Trigger rollback immediately if any one condition is true:

- Any pilot user gets black screen after fix deployment.
- Any Event 1000 (`dwm.exe` + `igdumd64.dll`) reappears.
- Any Event 9009 reappears.

### 3-Minute Emergency Rollback

1. [ELEVATED] In Azure Portal, go to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, select all hosts, and click `Drain mode` or set `Allow new sessions` to `No`.
   Expected result: No new users can enter `POOL-FIN-01`.

2. [ELEVATED] In Azure Portal, go to `Azure Virtual Desktop` > `Application groups` > Finance desktop app group mapped to `POOL-FIN-01`, and remove assignment for the impacted user group.
   Expected result: New Finance logins stop targeting the impacted pool.

3. [ELEVATED] In Azure Portal, go to `Azure Virtual Desktop` > `Application groups` > matching Finance app group for `POOL-FIN-02`, and add assignment for the same user group.
   Expected result: New Finance logins are redirected to healthy `POOL-FIN-02`.

4. [ELEVATED] In `POOL-FIN-01` > `User sessions`, select all active sessions and click `Sign out`.
   Expected result: Active session count in `POOL-FIN-01` becomes `0`.

5. In the ticketing console, post customer update `Rollback activated: access moved to POOL-FIN-02 while POOL-FIN-01 remains drained.`
   Expected result: End-user communication timestamp is recorded.

6. [ELEVATED] In Azure Portal, go to `Log Analytics workspaces` > linked AVD workspace > `Logs` and run this query for the last 10 minutes:
   ```kusto
   Event
   | where TimeGenerated >= ago(10m)
   | where Computer startswith "SHFIN-01" or Computer contains "POOL-FIN-01"
   | where EventID == 9009
      or (
         EventID == 1000
         and RenderedDescription contains "dwm.exe"
         and RenderedDescription contains "igdumd64.dll"
      )
   | project TimeGenerated, Computer, EventID, RenderedDescription
   | order by TimeGenerated desc
   ```
   Expected result: Any returned rows are attached to the escalation note as rollback evidence.

7. [ELEVATED] In Azure Portal, create a `High` severity Azure support request from `Help + support` and include incident ID, affected host pool, and query output.
   Expected result: Escalation case ID is added to the ticket.

### Post-Containment Technical Restore (after emergency rollback)

1. [ELEVATED] Restore affected `POOL-FIN-01` VMs from `pre_fix_<hostname>_<yyyymmdd_hhmm>` snapshots.
   Expected result: Hosts return to known pre-fix disk state.

2. [ELEVATED] Restart restored VMs and verify registration in `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`.
   Expected result: Hosts show `Available` state.

## Notes

- Intermittent recovery (black screen clears after about 30 seconds) does not count as a fix; treat as failed until crash events stop.
- If `POOL-FIN-01` uses a VM Scale Set instead of standalone VMs, use the same sequence but perform image rollback and instance reimage at the scale set level.
- If policy blocks driver pinning, complete image rollback first and request emergency policy exception for driver version enforcement.
- Related incident family: Finance AVD black-screen events tied to image rollout boundaries.
- Related comparison case: `POOL-FIN-02` unaffected during the same window is a key control signal.