# FAULT-B Communications Pack (Three Audiences)

## Audience 1 - Non-Technical Executive (Under 80 Words)
Your access and data are safe. On 2024-03-15, Finance shared-drive access failed for 45 users after a script change moved drive mapping from a user sign-in method to a system-level method that was not updated for that context. Group Policy was working; the drive map script failed and S: was not assigned. We are restoring a user-session compatible mapping method and adding retry/error controls. No action is needed from you.

## Audience 2 - Affected End-User Team (Under 100 Words)
Hi team - your access and data are safe. On 2024-03-15, shared drives failed for Finance users because the drive-mapping method was changed overnight and the new script ran in a different context it was not updated for, so the Finance path could not be reached and drive S: was not assigned; Group Policy itself was successful. IT is restoring a user-session compatible mapping method and adding retry/error handling. If you see this again, report that S: is missing and mention "Map-FinBridgeDrives.ps1 network name cannot be found" to IT Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: FAULT-B, 2024-03-15, Finance cohort (DESKTOP-FB*), 45 users impacted.

Root cause:
- Drive mapping moved 2024-03-14 23:30 from GPO logon script (USER) to Intune PowerShell script (SYSTEM).
- Script was not updated/validated for SYSTEM-context runtime at login.
- Result: UNC mapping to \\finbridge-fs01\Finance failed; S: not assigned.

Exact action taken (RCA resolution path):
- Restore a working drive-mapping method aligned to user-session requirements.
- Update mapping implementation to appropriate execution context for reliable UNC mapping.
- Add retry and explicit error handling for transient path/access timing failures.
- Validate on representative Finance endpoints before broad redeployment.

Config/detail evidence:
- Intune log:
  - 08:00:01 execute Map-FinBridgeDrives.ps1
  - 08:00:02 context SYSTEM
  - 08:00:03 warning path not accessible from SYSTEM
  - 08:00:03 exit code 1, "Network name cannot be found"
  - 08:00:04 no retry configured
- System log (DESKTOP-FB041):
  - 08:00:05 SCM 7036 Workstation service running
  - 08:00:06 GroupPolicy 1500 success (not a GP fault)
  - 08:00:07 Ntfs 98 S: not assigned
- Change note source: DESKTOP-FB022 migration entry confirms USER->SYSTEM move and missing SYSTEM-context update.

Verification step:
- Confirm closure criteria from RCA:
  - Shared drives accessible for affected users.
  - Mapping script succeeds in intended context.
  - S: assigned consistently on validated sample endpoints.
  - No recurrence of exit code 1 / "Network name cannot be found" / drive assignment failure.

Preventive action needed:
- Add migration gate for USER vs SYSTEM compatibility checks.
- Add pilot validation for UNC mapping and drive-letter assignment pre-rollout.
- Require retries/backoff and deterministic logging in mapping scripts.
- Monitor recurring signatures: Map-FinBridgeDrives.ps1 exit code 1, "Network name cannot be found," and S: assignment failures.
- Update runbook/change template with script-context, dependency, rollback, and post-change validation checkpoints.
