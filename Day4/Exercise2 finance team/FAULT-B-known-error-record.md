Symptom: Finance users cannot access shared drives because drive letter S: is not assigned. Users experience failed shared-drive access during login/startup period.

Cause: The verified root cause is a migration from a USER-context GPO logon script to a SYSTEM-context Intune PowerShell script without updating the script for SYSTEM-context behavior. The mapping script then failed to map \\finbridge-fs01\Finance.

Scope: The incident affected Finance users on DESKTOP-FB* devices, with 45 users impacted. This record is scoped to the Finance shared-drive mapping failure pattern documented in FAULT-B.

Workaround: Restore service immediately by using a user-session compatible drive-mapping method and rerunning mapping for affected users. Confirm S: assignment after rerun.

Permanent fix: Implement the mapping in the correct execution context for reliable UNC access and add retry/error handling to the mapping workflow. Validate the updated mapping method on representative Finance endpoints before broad rollout.

How to spot it: Check Intune Management Extension ScriptRunner entries showing Map-FinBridgeDrives.ps1 executed as SYSTEM, then failed with exit code 1 and "Network name cannot be found," plus "No retry configured." Correlate with System log signals: Service Control Manager Event 7036, GroupPolicy Event 1500 (successful GP), and Ntfs Event 98 stating S: could not be mapped/not assigned.
