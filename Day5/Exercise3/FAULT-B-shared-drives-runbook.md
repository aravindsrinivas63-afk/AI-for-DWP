# Title: FAULT-B Finance Shared Drive Access Failure Runbook
- Version: 2.0
- Date: 07/08/2026
- Author: Aravind
- Reviewed: self
- Status: draft
- Change: initial version from RCA

# Runbook: FAULT-B Finance Shared Drive Access Failure

## Prerequisites
- [ ] [ELEVATED] You can sign in to Microsoft Intune admin center (`https://intune.microsoft.com`) with rights to edit and assign PowerShell scripts.
- [ ] [ELEVATED] You can change assignments for the active script `Map-FinBridgeDrives.ps1`.
- [ ] You have one currently affected pilot device name (example pattern: `DESKTOP-FB*`) and the primary affected user UPN.
- [ ] You can sign in interactively to the pilot device using the affected Finance user account.
- [ ] [ELEVATED] You have local admin access on the pilot device to read Intune Management Extension logs.
- [ ] You can open Event Viewer on the pilot device and view `Windows Logs > System`.
- [ ] You know the expected mapping target `\\finbridge-fs01\Finance` and expected drive letter `S:`.
- [ ] Mandatory end-user details collected: first failure time, screenshot/error text, whether `S:` is missing or present-but-inaccessible, and pilot availability window.
- [ ] Mandatory service-desk details collected: incident/ticket ID and confirmation that Finance scope is affected.

## Procedure
1. [ELEVATED] In Intune admin center, go to `Devices > Scripts and remediations > Platform scripts`.
Expected result: The platform script list is displayed.

2. [ELEVATED] Open the script object named `Map-FinBridgeDrives.ps1`.
Expected result: The script overview page opens.

3. [ELEVATED] Open `Properties` for `Map-FinBridgeDrives.ps1`.
Expected result: Script settings and assignment options are visible.

4. [ELEVATED] Export or copy the current script content to a local rollback file.
Expected result: A pre-change script backup file is saved.

5. [ELEVATED] Open the `Assignments` tab for `Map-FinBridgeDrives.ps1`.
Expected result: Current included/excluded Azure AD groups are visible.

6. [ELEVATED] Capture a screenshot of the current assignment groups.
Expected result: A rollback reference of assignment scope is saved.

7. [ELEVATED] Remove Finance target groups from the failing SYSTEM-context deployment and save.
Expected result: Finance targets are no longer assigned to the failing deployment.

8. [ELEVATED] Create a new deployment in `Devices > Scripts and remediations > Platform scripts` for corrected user-session mapping.
Expected result: A new script object for corrected mapping is created.

9. [ELEVATED] Configure the new script to map drive letter `S:` to `\\finbridge-fs01\Finance`.
Expected result: Script content explicitly contains the required drive letter and UNC path.

10. [ELEVATED] Add retry logic to the new script so mapping is retried after an initial failure.
Expected result: Script content contains retry behavior and explicit failure logging.

11. [ELEVATED] Assign the new corrected script to a pilot Finance test group only.
Expected result: Pilot group is targeted and broad rollout is not yet active.

12. In Intune admin center, go to `Devices > Windows > Windows devices`.
Expected result: Windows device inventory is displayed.

13. Open the affected pilot device record.
Expected result: The device details pane opens.

14. Select `Sync` on the pilot device page.
Expected result: A sync action is queued for that device.

15. Sign in to the pilot device as the affected Finance user.
Expected result: User session starts successfully.

16. Open File Explorer and check `This PC` for drive `S:`.
Expected result: Drive `S:` is present.

17. Open drive `S:` in File Explorer.
Expected result: `\\finbridge-fs01\Finance` opens.

18. On the pilot device, open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad.
Expected result: The log file opens and can be searched.

19. Search the log for `Map-FinBridgeDrives.ps1` entries after the sync timestamp.
Expected result: A recent script run entry is present.

20. Search the same log for `Exit code: 1`.
Expected result: No new `Exit code: 1` is found after the corrected run.

21. Search the same log for `Network name cannot be found`.
Expected result: No new match is found after the corrected run.

22. Open Event Viewer and navigate to `Event Viewer (Local) > Windows Logs > System`.
Expected result: System log entries are visible.

23. Filter current System log for source `Ntfs` and Event ID `98` for the post-fix time window.
Expected result: No new `Ntfs` Event ID `98` appears after pilot validation.

24. [ELEVATED] Assign the corrected script to the full Finance target group.
Expected result: Corrected mapping deployment is active for all intended Finance users/devices.

## Verification
1. In Intune admin center, go to `Devices > Windows > Windows devices` and open the first validated Finance device.
Expected result: Device page opens for verification actions.

2. On the device page, open `Monitor > Device action status`.
Expected result: Recent `Sync` and script-related actions show `Succeeded` or `Completed`.

3. Sign in on that device with an affected Finance user account.
Expected result: User sign-in completes without new shared-drive error prompts.

4. Open `File Explorer > This PC` and check for `S:`.
Expected result: `S:` is visible.

5. Open `S:` in File Explorer.
Expected result: `\\finbridge-fs01\Finance` opens and folder contents load.

6. Open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad.
Expected result: Log file opens and latest execution window is readable.

7. Search that log for `Map-FinBridgeDrives.ps1` after the latest sync timestamp.
Expected result: A recent script execution entry exists.

8. Search that same log for `Exit code: 1`.
Expected result: No new `Exit code: 1` is present after fix deployment.

9. Search that same log for `Network name cannot be found`.
Expected result: No new match is present after fix deployment.

10. Open `Event Viewer (Local) > Windows Logs > System` and filter for `Ntfs` and Event ID `98` in the post-fix window.
Expected result: No new `Ntfs` Event ID `98` appears after validation login.

11. Repeat Steps 1-10 for two more Finance sample devices.
Expected result: All three sampled devices show consistent success.

12. Obtain verbal or ticket confirmation from affected Finance users that access is restored.
Expected result: User confirmation is captured for closure evidence.

## Rollback
1. [ELEVATED] In Intune admin center, go to `Devices > Scripts and remediations > Platform scripts`, open the corrected script, open `Assignments`, remove Finance groups, and click `Save`.

2. [ELEVATED] In the same `Platform scripts` page, open the pre-change script backup object, open `Assignments`, add the original Finance groups captured in the pre-change screenshot, and click `Save`.

3. In Intune admin center, go to `Devices > Windows > Windows devices`, open the pilot device, and click `Sync`.

4. On the pilot device, sign in as the affected Finance user and open `File Explorer > This PC`.

5. On the pilot device, open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and confirm a new run entry exists for the reassigned pre-change deployment window.

6. If pilot behavior is still degraded, capture the exact current timestamp and escalate immediately with pilot device name and log snippet from `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.

## Notes
- This incident pattern is not a Group Policy failure pattern when GroupPolicy Event 1500 shows success.
- Primary fault signatures from RCA are SYSTEM-context script run, `Exit code: 1`, and `Network name cannot be found` for `Map-FinBridgeDrives.ps1`.
- Related records: FAULT-B scope hypothesis, FAULT-B detailed RCA, FAULT-B known-error record, and FAULT-B closure note.
- Edge case: If `S:` exists but points to the wrong path, treat it as a mapping target integrity issue and keep incident open.
