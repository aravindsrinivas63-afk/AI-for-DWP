# FAULT-B Detailed RCA - Finance Team Cannot Access Shared Drives

## Document Control
- Incident ID: FAULT-B
- Incident Date: 2024-03-15
- RCA Authoring Date: 2026-08-07
- Affected Population: Finance users on DESKTOP-FB* devices (45 users)
- Data Sources: Intune Management Extension log, System log, migration change log

## Executive Summary
Finance users were unable to access shared drives after drive mapping delivery was migrated from a GPO logon script running in USER context to an Intune PowerShell script running in SYSTEM context. The script was not updated for SYSTEM-context behavior at login, and mapping to the Finance UNC path failed during execution. Group Policy itself processed successfully, confirming this was not a GPO failure.

## Impact
- Symptom: Finance team could not access shared drives.
- Scale: 45 users.
- Scope: Devices in Finance cohort (DESKTOP-FB*).

## Supporting Evidence

### Intune Management Extension Evidence
- 08:00:01 ScriptRunner Info: Executing Map-FinBridgeDrives.ps1.
- 08:00:02 ScriptRunner Info: Script context: SYSTEM account.
- 08:00:03 ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time.
- 08:00:03 ScriptRunner Error: Script Map-FinBridgeDrives.ps1 failed. Exit code 1. Error: Network name cannot be found.
- 08:00:04 ScriptRunner Info: No retry configured.

### System Log Evidence (DESKTOP-FB041)
- 08:00:05 Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06 GroupPolicy Event 1500: Group Policy settings processed successfully.
- 08:00:07 Ntfs Event 98 Warning: File system could not map drive letter S:. Drive letter has not been assigned.

### Change Record Evidence
- 2024-03-14 23:30 migration change note: Drive mapping moved from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context).
- Change note states script was not updated for SYSTEM context; UNC path mapping required runtime conditions not available to SYSTEM at login time.
- Source reference: DESKTOP-FB022.

## Timeline
- 2024-03-14 23:30: Drive mapping mechanism changed from GPO USER-context script to Intune SYSTEM-context script.
- 08:00:01: Map-FinBridgeDrives.ps1 starts.
- 08:00:02: Script confirms SYSTEM execution context.
- 08:00:03: UNC path access warning and script failure with "Network name cannot be found."
- 08:00:04: Log confirms no retry behavior.
- 08:00:05: Workstation service reports running.
- 08:00:06: Group Policy processed successfully (rules out GP failure as primary cause).
- 08:00:07: Drive letter S: mapping not assigned.

## Root Cause Statement
Primary root cause: Drive mapping implementation changed to Intune SYSTEM-context execution, but script logic and execution design were not updated to support successful shared-drive mapping under SYSTEM context at login. This caused mapping failure for the Finance UNC path and prevented assignment of the target drive letter.

Contributing factors:
- No retry configured in the script workflow.
- Change validation did not catch USER-context versus SYSTEM-context behavior differences before rollout.

## 5 Whys Analysis
1. Why could Finance users not access shared drives?
- The S: drive mapping failed and was not assigned.

2. Why did drive mapping fail?
- Map-FinBridgeDrives.ps1 failed at runtime with "Network name cannot be found" while trying to access \\finbridge-fs01\Finance.

3. Why did the script fail on that path at runtime?
- The script executed as SYSTEM at login and could not successfully complete the UNC-based mapping flow in that context.

4. Why was it running as SYSTEM instead of the prior behavior?
- Drive mapping was migrated from GPO USER-context logon script to Intune PowerShell script, which ran as SYSTEM.

5. Why did migration introduce this failure?
- The script was not updated and validated for SYSTEM-context execution characteristics before production rollout.

Systemic cause:
- Incomplete context-compatibility testing and deployment guardrails during migration of endpoint management mechanism.

## Resolution Approach
- Restore a working mapping method that aligns with user-session requirements for Finance drive access.
- Update drive-mapping implementation so execution context is appropriate for reliable UNC mapping.
- Add retry logic and explicit error handling for transient path/access timing failures.
- Validate on representative Finance endpoints before broad redeployment.

## Preventive Actions
1. Add migration gate for execution-context compatibility.
- Any move between GPO, Intune, scheduled task, or service execution paths must include documented USER versus SYSTEM behavior validation.

2. Add pre-production pilot checks.
- Verify mapping success for target UNC path and drive-letter assignment on pilot devices before full rollout.

3. Require resiliency controls in mapping scripts.
- Implement retries with backoff and deterministic logging for path resolution and mapping outcomes.

4. Add operational monitoring.
- Alert on recurring signatures: script exit code 1 for Map-FinBridgeDrives.ps1, "Network name cannot be found," and drive-letter assignment failures.

5. Update runbook and change template.
- Add mandatory checklist items for script context, dependency readiness, rollback criteria, and post-change user validation.

## Validation Criteria for Closure
- Shared drives accessible for affected Finance users.
- Mapping script completes successfully in intended execution context.
- Drive letter S: assigned consistently on validated sample endpoints.
- No recurrence of the recorded failure signatures after corrective rollout.
