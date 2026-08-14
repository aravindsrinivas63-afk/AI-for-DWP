# Title: Runbook — Issue 1: People Cannot Log In or Logon Is Extremely Slow
# Version: 1.0
# Date: 14/08/2026
# Author: Aravind
# Reviewed: self
# Status: draft
# Change: initial version from RCA

# Runbook — Issue 1: People Cannot Log In or Logon Is Extremely Slow

## Prerequisites

### Access and Permissions Checklist
- [ ] You have Intune admin access to view app deployment, assignment, and device status. [ELEVATED]
- [ ] You have permission to pause or narrow app assignment scope for the affected cohort. [ELEVATED]
- [ ] You have access to endpoint monitoring/log analytics used by the team for logon-time metrics. [ELEVATED]
- [ ] You have service desk/ticketing access to pull incident timestamps and user list.
- [ ] You have access to change records for the Friday deployment.

### Tools and Systems Checklist
- [ ] Microsoft Intune admin center.
- [ ] Endpoint performance/telemetry source (for logon duration and startup activity).
- [ ] Ticketing system (for affected-user and time-window validation).
- [ ] Cohort assignment export source (to confirm Floor 6 migrated Win11 cohort).

### Mandatory Incident Inputs Before Starting
- [ ] Exact affected floor/team and whether devices are migrated Win11 + Intune-managed.
- [ ] First symptom time and current symptom state (failure vs slow logon).
- [ ] Name/version of app deployed Friday and deployment assignment target.
- [ ] At least 5 impacted users or devices for baseline comparison.
- [ ] One unaffected control group (for example, non-migrated floor or non-targeted assignment group).

## Procedure

1. Open the incident ticket and record the first reported symptom timestamp.
Expected result: A confirmed incident start time is documented.

2. Export the current affected-user/device list from the ticketing system.
Expected result: A working affected list exists for correlation.

3. Open Intune and export the assignment target for the Friday Document Management deployment. [ELEVATED]
Expected result: A deployment-target cohort list is available.

4. Compare the affected list to the deployment-target cohort list.
Expected result: You can state whether affected users are concentrated in the Friday target cohort.

5. Pull logon-time telemetry for affected users during Monday business-start window.
Expected result: You have measured logon duration for the incident window.

6. Pull startup install/detection activity telemetry for the same users and time window.
Expected result: You have a count/timeline of install or detection events during sign-in.

7. Pull the same two telemetry views for the unaffected control group.
Expected result: You have a control baseline for logon duration and startup activity.

8. Compare affected vs control median logon time.
Expected result: A clear delta is identified or ruled out.

9. Compare affected vs control concurrent startup install/detection activity.
Expected result: A concurrency spike is identified or ruled out.

10. Pause or narrow the Friday deployment assignment for the affected cohort. [ELEVATED]
Expected result: New rollout pressure on the affected cohort is contained.

11. Prioritize active triage only for users currently blocked from logging in.
Expected result: Critical-access users are moved to front-of-queue support.

12. Re-sample logon-time telemetry 30 minutes after containment.
Expected result: Early post-mitigation trend is available.

13. Re-sample startup install/detection concurrency 30 minutes after containment.
Expected result: Reduction (or no reduction) in login-window startup pressure is visible.

14. Update the incident record with evidence, containment action, and current risk.
Expected result: The incident timeline and evidence are audit-ready.

15. Keep deployment contained until verification criteria in this runbook are met.
Expected result: No premature reintroduction of rollout pressure occurs.

## Verification

1. Open Intune Admin Center at `https://intune.microsoft.com` -> `Apps` -> `All apps` -> Friday Document Management app -> `Monitor` -> `Device install status`. [ELEVATED]
Expected result: Device install-state view is open for the exact app.

2. Set filter to affected Floor 6 device group and export status CSV from `Device install status`. [ELEVATED]
Expected result: Post-containment install-status evidence file is saved.

3. Open Entra Admin Center at `https://entra.microsoft.com` -> `Monitoring & health` -> `Sign-in logs` and filter by affected users and incident time window.
Expected result: User sign-in event list for the incident window is visible.

4. Export the filtered sign-in log results from Entra Sign-in logs.
Expected result: Sign-in evidence file is saved for incident record.

5. On one affected endpoint, open Event Viewer path `Windows Logs` -> `Application` and filter Event IDs `11707` and `11724` in incident window.
Expected result: MSI install success/failure timing around sign-in is visible.

6. On the same endpoint, open Event Viewer path `Applications and Services Logs` -> `Microsoft` -> `Windows` -> `User Profile Service` -> `Operational` and filter Event IDs `1`, `2`, and `1530`.
Expected result: Profile load timing and profile-related warnings are visible.

7. On the same endpoint, open file `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and search for app name plus incident timestamp.
Expected result: IME execution timing confirms whether app activity overlapped user logon.

8. Repeat Steps 5 to 7 on one unaffected control endpoint from non-impacted cohort.
Expected result: Control evidence set is available for side-by-side comparison.

9. Compare affected versus control for sign-in duration and startup-time app activity overlap.
Expected result: Mitigation effect is confirmed or disproved using matched evidence.

10. Open ticketing dashboard and filter queue for same symptom code during last 2 hours versus incident-start 2-hour window.
Expected result: New incident volume trend is objectively measured.

11. Record all verification artifacts (Intune CSV, Entra CSV, event screenshots, IME log excerpt, ticket trend) in incident timeline.
Expected result: Closure package is complete and auditable.

## Rollback

Use this section if containment worsens business impact (for example, critical app missing for active users).

Target completion time: under 3 minutes for initial service restoration action.

1. Open Intune Admin Center at `https://intune.microsoft.com` -> `Apps` -> `All apps` -> Friday Document Management app -> `Assignments`. [ELEVATED]
Expected result: Assignment editor is open for immediate change.

2. Click `Edit` under assignments and restore the last known working assignment group from the incident snapshot. [ELEVATED]
Expected result: Previous assignment scope is reinstated.

3. Remove affected Floor 6 group from `Required` assignment and keep only approved pilot group in `Required`. [ELEVATED]
Expected result: Broad impact is stopped while pilot path remains active.

4. Click `Review + save` then `Save`.
Expected result: Rollback assignment change is committed.

5. Open `Monitor` -> `Device install status` for the same app and confirm no new install attempts are starting on excluded Floor 6 devices. [ELEVATED]
Expected result: Rollback containment is active in monitoring view.

6. On one affected endpoint, open `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and confirm no fresh execution entries for this app after rollback timestamp.
Expected result: Endpoint confirms rollback took effect.

7. Post incident update in ticket with exact rollback timestamp, assignment change, and pilot-only scope.
Expected result: Stakeholders have precise rollback status and blast-radius statement.

8. If critical users still cannot work, assign temporary workaround ticket to service desk to provide manual access path per business continuity SOP.
Expected result: Business continuity is restored while engineering continues root-cause work.

## Notes
- This incident pattern is strongly time-bound to first business-day sign-in after a Friday rollout.
- Mixed symptoms (hard failure plus severe slowness) can come from the same startup contention mechanism.
- Always preserve one unaffected control cohort for evidence-based comparison.
- Do not reopen broad deployment until verification metrics are met and documented.
- Related records to link: incident RCA, closure note, and known-error entry for startup-time deployment contention.
- Warning: changing assignment scope without snapshot/export makes rollback slower and riskier.
