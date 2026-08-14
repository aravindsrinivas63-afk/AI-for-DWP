# L2/L3 Knowledge Base - Issue 3 Desktop Shortcuts Vanished

v 1.0, 14/08/2026, status : Draft

## Background
Floor 6 migrated Windows 11 devices are managed through Intune. A Friday deployment changed app/script behavior and some users lost desktop shortcuts on Monday sign-in. This matters because users lose fast access to business apps, ticket volume increases, and repeated manual shortcut recreation causes more disruption.

## Symptom
Engineer observes:
- Missing shortcut files from one or both locations:
  - C:\Users\Public\Desktop
  - %USERPROFILE%\Desktop
- Timing aligns with first sign-in window after Friday rollout.
- Affected users are concentrated in one deployment cohort.

User reports:
- "My desktop shortcuts disappeared."
- "I can still use apps, but icons are gone."
- "The issue came back after restart or next login."

## Root cause
Most likely cause is deployment-related shortcut side effect during login initialization (app package, script, or policy sequence removed/replaced shortcuts or failed to recreate them).

Evidence that confirms this root cause:
- Time correlation: issue started after Friday rollout.
- Scope correlation: affected users align to rollout assignment.
- Technical trace: IntuneManagementExtension.log shows rollout activity in incident window.
- Comparison check: unaffected control device in non-target cohort keeps baseline shortcuts.

## Detection
Use this sequence before any fix action.

1. Open Azure portal path: https://portal.azure.com -> search Microsoft Intune -> Open -> Apps -> All apps -> select Friday deployment app -> Assignments.
Look for field: Included groups and Excluded groups.
Confirm whether affected users are in included scope.

2. Open endpoint Event Viewer: eventvwr.msc -> Windows Logs -> Application.
Filter fields:
- Logged: incident window
- Level: Warning, Error
- Event IDs: 1000, 1511 (if present)
Look for app/script errors or temporary profile behavior in same time window.

3. Open endpoint Event Viewer: eventvwr.msc -> System.
Filter fields:
- Logged: incident window
- Event IDs: 7036 (service state)
Look for Workstation service state timing around sign-in.

4. Open endpoint Event Viewer: eventvwr.msc -> Applications and Services Logs -> Microsoft -> Windows -> GroupPolicy -> Operational.
Filter fields:
- Logged: incident window
- Event IDs: 5312 and 8006 (if present)
Look for policy processing timing or failures aligned to shortcut loss.

5. Open log file location:
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
Search fields:
- Friday app/script name
- Timestamp around incident start
- Keywords: error, failed, exit code, script
Confirm rollout action overlap with shortcut-loss window.

6. Run shortcut inventory commands on affected and control devices:
- Get-ChildItem "C:\Users\Public\Desktop" -Filter *.lnk | Select-Object Name,FullName | Sort-Object Name
- Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk | Select-Object Name,FullName | Sort-Object Name
Compare results to approved baseline list.

Decision point:
Treat issue as confirmed rollout side effect when all are true:
- affected users are in deployment scope,
- log timing overlaps incident window,
- affected device misses baseline shortcuts,
- control device retains baseline shortcuts.

## Resolution
Perform in order. Each step has expected result.

1. Open Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> <Friday deployment app> -> Assignments -> Edit. [ELEVATED]
Expected result: assignment editor is open in less than 60 seconds.

2. Add affected group to Excluded groups and click Review + save -> Save. [ELEVATED]
Expected result: rollout is stopped for affected cohort immediately.

3. Capture assignment screenshot and attach to ticket as post-containment snapshot. [ELEVATED]
Expected result: rollback reference is preserved.

4. On affected endpoint, run PowerShell as admin and execute:
`$paths=@('C:\Users\Public\Desktop',"$env:USERPROFILE\Desktop"); foreach($p in $paths){Get-ChildItem $p -Filter *.lnk | Select Name,FullName}`
Expected result: current shortcut inventory is visible for both desktop locations.

5. Restore missing shortcuts from approved baseline list only into C:\Users\Public\Desktop and %USERPROFILE%\Desktop. [ELEVATED]
Expected result: all required shortcuts exist with correct names and targets.

6. Run quick target check:
`$paths=@('C:\Users\Public\Desktop',"$env:USERPROFILE\Desktop"); foreach($p in $paths){Get-ChildItem $p -Filter *.lnk | Select Name,Target}`
Expected result: each restored shortcut points to expected target path.

7. Sign out and sign in once; then restart once.
Expected result: shortcuts persist across sign-in and reboot.

8. Repeat steps 5-7 on one additional affected endpoint.
Expected result: fix is repeatable across at least two affected devices within 10 minutes.

## Verification
1. Open Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> <Friday deployment app> -> Monitor -> Device install status. [ELEVATED]
Expected result: affected devices show assignment behavior consistent with exclusion.

2. Export Device install status CSV for affected group. [ELEVATED]
Expected result: evidence file is saved for incident record.

3. On validated endpoints, run inventory commands:
`Get-ChildItem 'C:\Users\Public\Desktop' -Filter *.lnk | Select Name,Target | Sort Name`
`Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk | Select Name,Target | Sort Name`
Expected result: shortcut names/targets match approved baseline list exactly.

4. Open log file C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log and search for Friday app/script name after fix timestamp.
Expected result: no post-fix removal/error sequence appears for shortcut actions.

5. Open Event Viewer path: Applications and Services Logs -> Microsoft -> Windows -> GroupPolicy -> Operational and filter Logged = post-fix window.
Expected result: no new policy timing failures linked to shortcut disappearance.

6. Check ticket queue for "shortcut" incidents in next business-start window.
Expected result: no new incident spike from same cohort.

## Rollback
Use if fix makes situation worse. Target: first containment action under 3 minutes.

1. Open Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> <Friday deployment app> -> Assignments -> Edit. [ELEVATED]
Expected result: assignment editor opens in under 60 seconds.

2. Restore previous assignment from pre-change snapshot, keep affected group in Excluded groups, then click Review + save -> Save. [ELEVATED]
Expected result: previous scope is restored while impacted cohort stays protected.

3. On one affected endpoint, delete only wrong shortcuts from C:\Users\Public\Desktop and %USERPROFILE%\Desktop. [ELEVATED]
Expected result: failed-fix shortcut artifacts are removed.

4. Recreate approved baseline shortcuts only (same names and targets as baseline list). [ELEVATED]
Expected result: desktop returns to known-good shortcut state.

5. Run immediate check command:
`$paths=@('C:\Users\Public\Desktop',"$env:USERPROFILE\Desktop"); foreach($p in $paths){Get-ChildItem $p -Filter *.lnk | Select Name,Target}`
Expected result: shortcut state is valid right after rollback.

6. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log and confirm no new failed execution sequence after rollback timestamp.
Expected result: rollback containment is confirmed by log evidence.

7. Set incident status to Rollback in Progress and send service desk update with timestamp, cohort, and current workaround.
Expected result: support team has immediate execution status and user guidance.

## Preventive
1. Pre-deployment shortcut baseline gate
- Owner: release engineer; Timing: before deployment; Type: automated [REQUIRES: baseline inventory job + baseline manifest in repo].
- Signal: 100% match of *.lnk names/targets between pilot devices (`C:\Users\Public\Desktop`, `%USERPROFILE%\Desktop`) and approved baseline CSV.
- Pass/Fail: pass only at 100%; fail if any missing, extra, or wrong-target shortcut is detected.
- If fail: block production assignment change and open defect ticket to DWP engineer with diff report attached.

2. In-flight rollout monitoring for shortcut loss
- Owner: DWP engineer; Timing: during rollout and first business-start window; Type: automated alert + manual triage [REQUIRES: log alert rule].
- Signal: IntuneManagementExtension.log error count > 10 in 30 minutes on pilot OR "shortcut" tickets > 2 in 30 minutes.
- Pass/Fail: pass when both metrics stay below thresholds for 2 continuous hours.
- If fail: hold rollout immediately, exclude affected group, and notify change manager within 15 minutes.

3. Post-deployment persistence check
- Owner: service desk lead; Timing: after deployment, before change closure; Type: manual (can be automated later).
- Signal: on at least 2 pilot devices, baseline shortcuts remain present after sign-out/sign-in and one reboot; 0 new related tickets in next start window.
- Pass/Fail: pass only when persistence and ticket criteria both pass.
- If fail: keep change open, reopen incident, and reassign to DWP engineer for containment.

4. Script/policy safeguard for shortcut handling
- Owner: release engineer; Timing: before deployment; Type: automated gate in package/script review [REQUIRES: CI/static check for delete actions].
- Signal: package/script contains no shortcut delete/replace command unless approved allow-list file is referenced.
- Pass/Fail: pass when allow-list reference exists and command scope matches approved list exactly.
- If fail: reject package promotion and require corrected package plus peer review sign-off.

5. Rollback trigger and knowledge update
- Owner: change manager; Timing: during rollout (trigger) and after incident closure (knowledge update); Type: manual trigger + checklist update.
- Signal: trigger rollback if missing-shortcut incidents >= 3 in 30 minutes or any business-critical team reports repeated recurrence after reboot.
- Pass/Fail: pass when rollback decision is logged within 15 minutes and KB/runbook checklist is updated within 1 business day.
- If fail: freeze similar deployments and escalate to service desk lead and release engineer for governance review.

## Related
- issue3-desktop-shortcuts-vanished-runbook.md
- issue3-desktop-shortcuts-vanished-l1-self-service.md
- issue3-desktop-shortcuts-vanished-rca.md
- issue1-login-slow-or-failure-runbook.md
- cross-issue-hypothesis-matrix.md
