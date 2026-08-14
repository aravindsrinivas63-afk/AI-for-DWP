# Version Header
v 1.0, 14/08/2026, status : Draft

# L2/L3 Knowledge Base — Issue1: Login Failure or Severe Logon Delay

## Background: what the system does and why it matter
Floor 6 migrated Windows 11 endpoints receive apps and policies through Microsoft Intune. During user sign-in, the Intune Management Extension, policy processing, profile loading, and app install/detection can overlap. If startup-time app workload is too heavy during business-start login windows, users can hit sign-in failure or severe desktop delay. This matters because it blocks workforce start-of-day operations and creates high ticket spikes.

## symptom: what the engineer observers and what the user report
Engineer observes:
- Concentrated impact on migrated Win11, Intune-managed cohort after Friday rollout.
- Monday business-start spike in failed or very slow logons.
- Device/app status shows startup-time install or detection churn on impacted devices.

User reports:
- "I cannot log in" or "I log in but desktop takes many minutes to load."
- Issue started at first workday login after recent app rollout.

## root cause: the specific technical cause with the evidence that confirms it
Primary technical cause is deployment-linked startup contention: Friday Document Management app rollout increased login-window install/detection and sequencing load, delaying or interrupting logon readiness on affected devices.

Evidence that confirms this cause:
- Affected-user cohort strongly overlaps the deployment assignment group.
- Entra sign-in logs show higher interruption/failure in the same incident window.
- Endpoint evidence shows login-window app activity overlap (IME log and MSI/User Profile Service events).
- Post-containment metrics improve after narrowing/pausing the deployment scope.

## Detection: exactly how to confirm this is the issue before acting- include specific event ids, log locations and what to look for
Target detection time: under 3 minutes. Use one affected user/device sample plus one control user/device.

1. T+0:00 to T+0:45 | Entra sign-in failure cluster check
- Log location: https://entra.microsoft.com -> Monitoring & health -> Sign-in logs.
- Event IDs: N/A (Entra sign-in logs use status/error fields, not Windows Event IDs).
- Filter setup: Date = incident window (last 2 hours or incident +/- 30 min); Users = affected sample + control sample.
- Fields to inspect: User, Status, Error code, Date, Device ID.
- Confirming signal: affected sample shows failed/interrupted sign-ins clustered in window while control sample does not.

2. T+0:45 to T+1:30 | Intune assignment/install overlap check
- Log location: https://intune.microsoft.com -> Apps -> All apps -> Friday Document Management app -> Monitor -> Device install status.
- Event IDs: N/A (grid record source).
- Filter setup: Device name = affected sample device.
- Fields to inspect: Assignment group, Install status, Error code, Last check-in.
- Confirming signal: affected device is in rollout target and has install/detection state updates around symptom time.

3. T+1:30 to T+2:15 | Endpoint installer event check
- Log location: Event Viewer -> Windows Logs -> Application.
- Event IDs to filter: 11707, 11724.
- Fields to inspect: TimeCreated, EventID, ProviderName, Message.
- Confirming signal: MsiInstaller events for Friday app align with login window on affected device.

4. T+2:15 to T+2:45 | Endpoint profile stress check
- Log location: Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> User Profile Service -> Operational.
- Event IDs to filter: 1, 2, 1530.
- Fields to inspect: TimeCreated, EventID, Level, Message, User SID.
- Confirming signal: profile load/unload warnings/errors overlap the same login window.

5. T+2:45 to T+3:00 | IME overlap spot-check
- Log location: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log.
- Event IDs: N/A (text log).
- Search/fields: app name, Timestamp, Detection state, Install start/stop, Result/Exit code.
- Confirming signal: IME install/detection actions for target app overlap failed/slow sign-in window.

Detection decision (binary):
- Confirm Issue1 if steps 1, 2, and at least one of steps 3 to 5 show aligned timing with incident window.
- Do not confirm yet if steps 1 or 2 fail; extend evidence window to 24 hours and escalate for non-deployment causes.

## Resolution: step-by-step fix with expected result after each step - include specific portal/console paths
Target containment: 5 to 10 minutes.

1. T+0:00 to T+1:00 | Open required consoles
- Azure portal path 1: https://portal.azure.com -> search Microsoft Intune -> Open -> Apps -> All apps -> Friday Document Management app -> Assignments.
- Azure portal path 2: https://portal.azure.com -> search Microsoft Intune -> Open -> Apps -> All apps -> Friday Document Management app -> Monitor -> Device install status.
- Action: keep Assignments and Device install status open in separate tabs.
- Expected result: change and validation views are ready without extra navigation.

2. T+1:00 to T+3:00 | Apply minimum containment change
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Assignments -> Edit.
- Action: remove affected Floor 6 group from broad Required assignment; keep only approved pilot group in Required.
- Expected result: rollout pressure is removed from impacted cohort while pilot service remains.

3. T+3:00 to T+4:00 | Commit and preserve rollback evidence
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Assignments -> Review + save -> Save.
- Action: save change and capture assignment screenshot/export with timestamp.
- Expected result: containment is active and rollback reference is preserved.

4. T+4:00 to T+6:00 | Confirm no new install wave on affected cohort
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Monitor -> Device install status.
- Action: filter by affected device group and compare Last check-in/install state after containment timestamp.
- Expected result: no fresh install progression starts on excluded affected cohort.

5. T+6:00 to T+8:00 | Confirm endpoint overlap reduction on one affected device
- Azure portal path: https://portal.azure.com -> search Microsoft Intune -> Open -> Devices -> All devices -> select affected device.
- Action: on endpoint, check IME log plus Event Viewer (Application 11707/11724) for next login cycle.
- Expected result: reduced login-window install overlap signal.

6. T+8:00 to T+10:00 | Record operational state
- Azure portal path: https://portal.azure.com -> search Microsoft Intune -> Open.
- Action: update ticket with change time, group removed, pilot scope retained, and immediate effect.
- Expected result: auditable incident timeline and ready handoff state.

## Verification: how to confirm the fix worked
Complete within 3 to 5 minutes after containment.

1. Assignment containment verification
- Console path: https://intune.microsoft.com -> Apps -> All apps -> Friday Document Management app -> Assignments.
- Pass condition: affected Floor 6 group is absent from broad Required assignment.

2. Intune rollout suppression verification
- Console path: https://intune.microsoft.com -> Apps -> All apps -> Friday Document Management app -> Monitor -> Device install status.
- Pass condition: excluded affected cohort shows no new install progression after containment timestamp.

3. Sign-in health verification
- Console path: https://entra.microsoft.com -> Monitoring & health -> Sign-in logs.
- Filter and fields: affected sample users, last 30 minutes, Status, Error code, Date, Device ID.
- Pass condition: failed/interrupted sign-ins trend down versus pre-containment window.

4. Endpoint evidence verification
- Log locations: Event Viewer Application (11707/11724), User Profile Service Operational (1/2/1530), IME log at C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log.
- Pass condition: reduced login-window app activity overlap and fewer profile-load warnings on sampled affected devices.

5. Service trend verification
- Console path: incident ticket dashboard by symptom code.
- Pass condition: new ticket inflow for same symptom declines in next business-start interval.

## Rollback: what to do if the fix makes thing worse- be specific
Use only if containment removed critical business functionality.

Target first restore action: under 3 minutes.

1. T+0:00 to T+0:45 | Open rollback context
- Azure portal path: https://portal.azure.com -> search Microsoft Intune -> Open -> Apps -> All apps -> Friday Document Management app -> Assignments.
- Action: set ticket to Rollback in Progress and load pre-change assignment snapshot.
- Expected result: exact restore input is available.

2. T+0:45 to T+2:00 | Restore last known scope to pilot-first
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Assignments -> Edit.
- Action: restore previous assignment but keep only pilot in Required first.
- Expected result: critical path recovers without re-exposing full cohort.

3. T+2:00 to T+2:45 | Commit rollback
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Assignments -> Review + save -> Save.
- Action: apply and timestamp rollback change.
- Expected result: assignment returns to known-good pilot-first state.

4. T+2:45 to T+4:00 | Validate rollback in monitoring
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Monitor -> Device install status.
- Action: confirm pilot behavior stabilizes and excluded cohorts are not receiving fresh install wave.
- Expected result: rollback effect is confirmed with controlled blast radius.

5. T+4:00 to T+5:00 | Re-contain if recurrence appears
- Azure portal path: https://portal.azure.com -> Microsoft Intune -> Apps -> All apps -> Friday Document Management app -> Assignments -> Edit.
- Action: if recurrence appears on pilot, immediately re-remove broader scope and return to contained state.
- Expected result: service impact is limited and escalation-ready.

## Preventive: the specific change to process or tooling that stop this recurring
1. Startup performance gate for Win11 app releases
- Owner/Timing/Type: release engineer | before deployment | manual (automation path: pipeline smoke job) [REQUIRES: release pipeline test stage].
- Signal + Pass/Fail: 10-device pilot login test report; Pass = median logon <= 90s and failed logon rate < 2%, Fail = either threshold breached.
- Fail action: block production assignment change and return release to remediation queue.

2. Time-window-safe rollout scheduling
- Owner/Timing/Type: change manager | before deployment | manual (automation path: change-window policy check) [REQUIRES: ITSM change-window validation].
- Signal + Pass/Fail: change record planned start time and approval fields; Pass = rollout starts outside first business hour or has emergency approval + pilot-only scope, Fail = neither condition met.
- Fail action: reject or reschedule change and prevent assignment save to broad cohort.

3. Login-window contention alerting
- Owner/Timing/Type: DWP engineer | during deployment | automated [REQUIRES: Entra + Intune alert rule with ticket integration].
- Signal + Pass/Fail: 30-minute window threshold where failed sign-ins >= 5 and IME install retry count >= 20 in target cohort; Pass = below both thresholds, Fail = threshold breach.
- Fail action: create Sev2 ticket, notify on-call, and execute containment runbook step to narrow assignment.

4. Mandatory assignment snapshot before change
- Owner/Timing/Type: service desk lead | before deployment | manual (automation path: mandatory attachment check in change form) [REQUIRES: ITSM form rule].
- Signal + Pass/Fail: ticket artifact check for assignment export/screenshot timestamped before save; Pass = artifact present, Fail = artifact missing.
- Fail action: hold approval and return change to engineer until evidence is attached.

5. Post-change control cohort comparison
- Owner/Timing/Type: image owner | after deployment | manual (automation path: scheduled comparison report) [REQUIRES: cohort baseline report job].
- Signal + Pass/Fail: affected vs control metrics at +30 min: median logon delta and failed-logon delta; Pass = median delta <= 30s and failed-logon delta <= 2%, Fail = any breach.
- Fail action: pause rollout expansion and escalate to change manager for rollback decision.

6. Rollback trigger threshold control
- Owner/Timing/Type: change manager | during deployment and after deployment | automated + manual [REQUIRES: agreed rollback threshold policy].
- Signal + Pass/Fail: trigger if failed sign-ins >= 10 in 15 minutes or median logon > 180s for 2 consecutive samples; Pass = below threshold, Fail = threshold reached.
- Fail action: declare Rollback in Progress and restore pilot-first assignment within 10 minutes.

7. Knowledge update from incident learnings
- Owner/Timing/Type: service desk lead | after deployment | manual (automation path: PIR task template) [REQUIRES: post-incident review workflow].
- Signal + Pass/Fail: runbook, L1, and L2 article updated and linked in closure ticket within 2 business days; Pass = all 3 linked, Fail = any missing.
- Fail action: keep problem record open and assign update actions to DWP engineer and image owner.

## related: other incidents or KB article this connects to
- issue1-login-slow-or-failure-rca.md
- issue1-login-slow-or-failure-runbook.md
- issue1-login-slow-or-failure-l1-self-service.md
- issue1-login-performance-analysis.md
- issue1-login-slow-or-failure-triage.md
