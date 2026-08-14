# Title: Runbook — Issue 3: Desktop Shortcuts Vanished
# Version: 1.0
# Date: 14/08/2026
# Author: Aravind
# Reviewed: self
# Status: draft
# Change: initial version from RCA

# Runbook — Issue 3: Desktop Shortcuts Vanished

## 1) Prerequisites

Complete this checklist before running any fix step.

### Access checklist
- [ ] Intune role: Intune Administrator or Endpoint Security Manager to edit assignments. [ELEVATED]
- [ ] Device access: local admin or approved remote support access on one affected device and one unaffected control device. [ELEVATED]
- [ ] Ticketing access: permission to read and update incident timeline and attachments.
- [ ] Change record access: permission to view Friday rollout change and deployment notes. [ELEVATED]

### Tools checklist
- [ ] Browser access to Intune Admin Center: https://intune.microsoft.com
- [ ] Event Viewer available on endpoint (`eventvwr.msc`).
- [ ] PowerShell 5.1 available on endpoint (`powershell.exe`).
- [ ] Access to IME log path: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.
- [ ] Access to Windows shortcut locations:
	- `C:\Users\Public\Desktop`
	- `%USERPROFILE%\Desktop`

### Mandatory information from end user
- [ ] User full name and username.
- [ ] Device name (from Settings -> System -> About, or from ticket if user cannot sign in).
- [ ] First time issue was seen (date/time and time zone).
- [ ] Exact missing shortcut names (for example Outlook, Teams, line-of-business app).
- [ ] Whether issue happened after restart, sign-out/sign-in, or first login of the day.
- [ ] Screenshot of desktop (if user can provide one).

### Required baseline references
- [ ] Approved corporate shortcut baseline list with shortcut name and target executable path.
- [ ] Friday deployment app/script name as shown in Intune.
- [ ] One unaffected control user/device in same business area for comparison.

## 2) Procedure

1. Open the incident ticket and set status to `Investigating`.
Expected result: Incident has active owner and tracking state.

2. Add end-user mandatory information to ticket fields (user, device, time, missing shortcut names, screenshot).
Expected result: Investigation input set is complete.

3. Open Intune Admin Center at `https://intune.microsoft.com` and go to `Apps` -> `All apps`.
Expected result: App catalog list is visible.

4. Select the Friday deployment app or script package by exact name from change record.
Expected result: Suspected deployment object is open.

5. Open `Assignments` tab for the selected object. [ELEVATED]
Expected result: Current Included/Excluded groups are visible.

6. Capture screenshot of current assignments and attach it to ticket as `pre-change-assignment-snapshot`. [ELEVATED]
Expected result: Rollback reference is preserved.

7. On one affected device, open File Explorer path `C:\Users\Public\Desktop`.
Expected result: Public desktop shortcut folder is open.

8. Run PowerShell command `Get-ChildItem "C:\Users\Public\Desktop" -Filter *.lnk | Select-Object Name,FullName | Sort-Object Name`.
Expected result: Public shortcut inventory is listed.

9. Export public inventory using `... | Export-Csv "$env:TEMP\public-desktop-shortcuts.csv" -NoTypeInformation`.
Expected result: Public inventory CSV is created.

10. Open File Explorer path `%USERPROFILE%\Desktop` on same affected device.
Expected result: User desktop shortcut folder is open.

11. Run PowerShell command `Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk | Select-Object Name,FullName | Sort-Object Name`.
Expected result: User shortcut inventory is listed.

12. Export user inventory using `... | Export-Csv "$env:TEMP\user-desktop-shortcuts.csv" -NoTypeInformation`.
Expected result: User inventory CSV is created.

13. Compare both CSV files with approved baseline list in a single table.
Expected result: Exact missing shortcut names are identified.

14. Open Event Viewer (`eventvwr.msc`) and go to `Windows Logs` -> `Application`.
Expected result: Application log is open for filtering.

15. Apply filter with incident time window and `Warning` + `Error` levels.
Expected result: Relevant app/package events are reduced to investigation window.

16. Open Event Viewer path `Applications and Services Logs` -> `Microsoft` -> `Windows` -> `GroupPolicy` -> `Operational`.
Expected result: Policy timing events around login are visible.

17. Filter GroupPolicy Operational log to incident time window.
Expected result: Policy-related timing in same window is visible.

18. Open file `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` in Notepad.
Expected result: IME execution log is open.

19. Search within IME log for Friday package/script name and incident timestamp.
Expected result: Deployment action timing overlap is confirmed or ruled out.

20. Return to Intune `Assignments` and add affected group to `Excluded groups` for the suspected deployment. [ELEVATED]
Expected result: Further shortcut-impact actions are blocked for affected cohort.

21. Save assignment change in Intune. [ELEVATED]
Expected result: Exclusion policy is active.

22. Recreate each missing shortcut on affected device using approved baseline target path only. [ELEVATED]
Expected result: Missing shortcuts are restored with correct target.

23. Sign out and sign back in on affected device.
Expected result: Restored shortcuts remain visible after sign-in.

24. Restart the affected device once.
Expected result: Restored shortcuts remain visible after reboot.

25. Repeat Steps 22 to 24 on one more affected device.
Expected result: Restoration approach is validated across at least two affected endpoints.

26. Attach CSV inventories, assignment screenshot, and relevant log screenshots to ticket.
Expected result: Evidence pack is complete for verification and audit.

## 3) Verification

1. Open Intune Admin Center at https://intune.microsoft.com and navigate to Apps -> All apps -> <Friday deployment app> -> Monitor -> Device install status. [ELEVATED]
Expected result: Device status for the suspected deployment is visible.

2. Filter by affected assignment group and click Export to download status CSV. [ELEVATED]
Expected result: CSV evidence of post-fix deployment state is saved.

3. On an affected endpoint, open PowerShell and run: `Get-ChildItem "C:\Users\Public\Desktop" -Filter *.lnk | Select-Object Name,Target | Sort-Object Name`.
Expected result: Public desktop shortcut list with targets is displayed.

4. On same endpoint, run: `Get-ChildItem "$env:USERPROFILE\Desktop" -Filter *.lnk | Select-Object Name,Target | Sort-Object Name`.
Expected result: User desktop shortcut list with targets is displayed.

5. Compare both lists to approved baseline list in the ticket attachment.
Expected result: All required shortcuts are present with correct targets.

6. Open Event Viewer (`eventvwr.msc`) and navigate to Windows Logs -> Application.
Expected result: Application event log is open.

7. Apply Filter Current Log with Level = Warning, Error and Logged = incident window.
Expected result: Relevant app/script events for incident window are isolated.

8. Open Event Viewer path Applications and Services Logs -> Microsoft -> Windows -> GroupPolicy -> Operational.
Expected result: GroupPolicy operational log is open.

9. Apply Filter Current Log with Logged = incident window and verify no new policy errors after fix time.
Expected result: No post-fix policy timing errors linked to shortcut disappearance.

10. Open IME log file at C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log and search for Friday app/script name after fix timestamp.
Expected result: No new shortcut-removal action appears post-fix.

11. Sign out and sign in on the affected endpoint, then restart once.
Expected result: Shortcuts persist across sign-in and reboot.

12. In ticketing system, filter new incidents by keyword "shortcut" for the next business-start window.
Expected result: No new spike from same cohort is observed.

## 4) Rollback

Use this section if the fix causes worse impact (for example wrong shortcuts, duplicate shortcuts, or broken links).

Target time for containment rollback: under 3 minutes.

1. Open Intune Admin Center at https://intune.microsoft.com and go to Apps -> All apps -> <Friday deployment app> -> Assignments. [ELEVATED]
Expected result: Assignment editor is open.

2. Click Edit and restore pre-change assignment groups from screenshot `pre-change-assignment-snapshot`, then click Review + save and Save. [ELEVATED]
Expected result: App assignment is reverted to last known scope.

3. Add affected group under Excluded groups and Save immediately. [ELEVATED]
Expected result: New rollout actions stop for affected users.

4. On one affected device, open File Explorer path C:\Users\Public\Desktop and delete only newly created wrong shortcuts. [ELEVATED]
Expected result: Wrong shared desktop shortcuts are removed.

5. On same device, open %USERPROFILE%\Desktop and delete only newly created wrong shortcuts. [ELEVATED]
Expected result: Wrong user desktop shortcuts are removed.

6. Recreate only approved baseline shortcuts from baseline list on same device. [ELEVATED]
Expected result: Desktop state returns to approved baseline.

7. Open IME log file at C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log and confirm no new execution entries for affected app after rollback timestamp.
Expected result: Rollback containment is confirmed by log evidence.

8. Update ticket status to Rollback in Progress and post message to service desk channel with rollback timestamp and affected-group exclusion.
Expected result: Support teams have immediate and actionable status.

## 5) Notes

- Edge case: A shortcut can exist but point to an old app path after migration; treat this as a broken shortcut and replace it.
- Edge case: Public Desktop may be correct while user Desktop is missing items; always check both locations.
- Warning: Do not bulk-delete all desktop shortcuts; remove only non-baseline items.
- Warning: Do not re-enable broad deployment scope until verification passes on at least two affected devices.
- Related incidents: Issue 1 login slowness/failure (same Friday cohort), deployment sequencing incidents, profile-initialization timing incidents.
