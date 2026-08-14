# Version Header
v 1.0, 14/08/2026, status : Draft

# L2/L3 Knowledge Base — Issue2: Copilot Surfaced Unauthorized Client Matter

## Background: what the system does and why it matter
Microsoft 365 Copilot answers user prompts by grounding responses in content the signed-in user can access across SharePoint, OneDrive, Teams, and other connected M365 workloads. For Legal workloads, any unintended access path can lead to sensitive matter exposure, creating compliance, confidentiality, and reputational risk. This incident must be handled as a security-governance incident first, not as an endpoint fault.

## Symptom: what the engineer observers and what the user report
Engineer observes:
- Incident ticket shows one or more users receiving Copilot output that references a client matter outside expected authorization scope.
- M365 content access events exist near incident time for sensitive site, library, or file paths.
- Permission model may include inherited ACLs, stale sharing links, or group membership drift.

User reports:
- Copilot returned or summarized a matter they believe they never had access to.
- User can provide approximate timestamp, prompt text, and sometimes a fragment of surfaced content.

## Root Cause: the specific technical cause with the evidence that confirms it
Most likely root cause is an unintended entitlement path that made the sensitive content technically accessible at query time. Typical paths:
- Direct permission granted on file or library.
- Inherited permission from site or parent library.
- Sharing link (people in org, specific people, or existing access) that remained active.
- Group membership change granting indirect access.

Evidence that confirms root cause:
- Purview Unified Audit shows reporting user access events for the flagged content around incident time.
- SharePoint Manage Access shows direct grant, inherited path, or active share link that includes the user.
- Entra group membership timeline aligns with access window.

## Detection: exactly how to confirm this is the issue before acting- include specific event ids, log locations and what to look for
Target detection time: under 3 minutes. Stop after step 4 with a Yes/No decision.

1. 60-second Purview access hit check
- Log location: https://purview.microsoft.com -> Solutions -> Audit -> Search.
- Event IDs to filter: RecordType 6 (SharePointFileOperation).
- Additional operation filter: FileAccessed, FileDownloaded, FilePreviewed.
- Time filter: incident timestamp +/- 15 minutes.
- Field filters: UserId = reporting user UPN; ObjectId contains flagged file name or URL fragment.
- Fields to inspect in results: CreationTime, UserId, Operation, ObjectId, SiteUrl, ResultStatus.
- Confirming signal: at least one event where UserId matches reporting user, ObjectId/SiteUrl matches flagged matter path, and ResultStatus is success.

2. 45-second Purview share/permission-path check
- Log location: https://purview.microsoft.com -> Solutions -> Audit -> Search.
- Event IDs to filter: RecordType 14 (SharePointSharingOperation) and RecordType 8 (AzureActiveDirectory).
- Additional operation filter: SharingSet, SharingInvitationCreated, Added member to group, Add member to group.
- Time filter: 24 hours before first reported Copilot retrieval.
- Fields to inspect: CreationTime, Operation, UserId (actor), TargetUserOrGroupName, ModifiedProperties, ObjectId.
- Confirming signal: a share or group-change event introduces an access path tied to reporting user or their group before incident time.

3. 45-second SharePoint effective-access check
- Log location: https://admin.microsoft.com -> Admin centers -> SharePoint -> Sites -> affected site -> Documents -> flagged file -> Manage access.
- Event ID reference: none in this console view.
- Fields to inspect: Direct access principals, Active links, Link scope, Inheritance state, Permission level.
- Confirming signal: reporting user (or group from step 2) appears in direct access, active links, or inherited permission chain.

4. 30-second Entra membership correlation check
- Log location: https://entra.microsoft.com -> Identity -> Users -> reporting user -> Groups, then Audit logs.
- Event IDs to filter in audit: Category = GroupManagement; Activity Display Name = Add member to group or Remove member from group.
- Fields to inspect: Target (user), Group, Initiated by, Activity date/time.
- Confirming signal: reporting user membership aligns with SharePoint permission group and incident timestamp.

Detection decision rule (under 3 minutes):
- Confirm Issue2 if all are true: step 1 successful access hit, and at least one entitlement path from step 2 or step 3, with step 4 correlation when group-based.
- Do not confirm Issue2 yet if step 1 has no matching event; extend audit window to +/- 60 minutes before any permission change.

## Resolution: step-by-step fix with expected result after each step - include specific portal/console paths
Target completion: 5 to 10 minutes. Follow the clocked sequence.

1. T+0:00 to T+1:00 | Open the two consoles you need
- Azure portal path 1: https://portal.azure.com -> search Microsoft 365 admin center -> Open -> Admin centers -> SharePoint.
- Azure portal path 2: https://portal.azure.com -> search Microsoft Purview -> Open -> Solutions -> Audit -> Search.
- Action: keep both tabs open side by side.
- Expected result: SharePoint Manage access and Purview Audit are ready without more navigation.

2. T+1:00 to T+3:00 | Remove the smallest offending access path
- Azure portal path: https://portal.azure.com -> Microsoft 365 admin center -> Admin centers -> SharePoint -> Sites -> affected site -> Documents -> flagged file -> Manage access.
- Action: remove only one offending path identified in Detection:
	- direct user permission, or
	- active sharing link, or
	- group-derived access (if group-derived, continue to step 3).
- Expected result: reporting user no longer appears in direct access or offending link path for flagged file.

3. T+3:00 to T+4:00 | If group-based, remove group path
- Azure portal path: https://portal.azure.com -> search Microsoft Entra ID -> Open -> Identity -> Groups -> affected group -> Members.
- Action: remove reporting user from the single offending group only.
- Expected result: group membership route to flagged matter is removed.

4. T+4:00 to T+5:00 | Capture rollback-safe evidence
- Azure portal path: https://portal.azure.com -> search Microsoft Purview -> Open.
- Action: write change note in incident ticket with principal removed, scope (file/link/group), old permission level, actor, and UTC timestamp.
- Expected result: exact rollback input is documented before retest.

5. T+5:00 to T+7:00 | Validate no new post-fix access
- Azure portal path: https://portal.azure.com -> Microsoft Purview -> Solutions -> Audit -> Search.
- Query settings: RecordType 6 and 14, UserId = reporting user, time = Last 15 minutes, ObjectId contains flagged file name/path.
- Action: run search and inspect CreationTime, UserId, Operation, ObjectId, ResultStatus.
- Expected result: no successful new access event for reporting user to flagged file after change time.

6. T+7:00 to T+10:00 | Run controlled retest
- Azure portal path: https://portal.azure.com -> search Microsoft 365 admin center -> Open.
- Action: ask reporting user to rerun same Copilot prompt in same app context; ask approved legal user to open the file directly.
- Expected result: reporting user cannot retrieve/summarize flagged matter, while approved legal user retains valid access.

## Verification: how to confirm the fix worked
Complete in under 3 minutes after resolution steps.

1. Purview zero-access confirmation
- Log location: https://purview.microsoft.com -> Solutions -> Audit -> Search.
- Event IDs: RecordType 6 and RecordType 14.
- Filters: Last 15 minutes, UserId = reporting user, ObjectId contains flagged file/path.
- Fields to confirm: CreationTime, UserId, Operation, ObjectId, ResultStatus.
- Pass condition: no successful post-fix access to flagged matter by reporting user.

2. SharePoint entitlement confirmation
- Log location: https://admin.microsoft.com -> Admin centers -> SharePoint -> Sites -> affected site -> Documents -> flagged file -> Manage access.
- Fields to confirm: reporting user absent from Direct access; offending Active link removed; inheritance no longer gives user path.
- Pass condition: no active file-level entitlement path remains for reporting user.

3. Entra group confirmation (only if group change was made)
- Log location: https://entra.microsoft.com -> Identity -> Users -> reporting user -> Groups.
- Fields to confirm: reporting user absent from offending group.
- Pass condition: no group-based route to flagged content remains.

4. Service continuity confirmation
- Log location: affected SharePoint file URL.
- Fields to confirm: approved legal user can still open file.
- Pass condition: intended access works while unintended access is blocked.

## Rollback: what to do if the fix makes thing worse- be specific
Use only if valid business access was removed.

Target first restore action: under 3 minutes.

1. T+0:00 to T+0:45 | Open exact restore context
- Portal path: incident ticket -> resolution change note.
- Action: set status Rollback in Progress and copy pre-change principal, scope, and permission level.
- Expected result: exact restore values are ready (no guesswork).

2. T+0:45 to T+2:00 | Restore file-level entitlement only
- Azure portal path: https://portal.azure.com -> Microsoft 365 admin center -> Admin centers -> SharePoint -> Sites -> affected site -> Documents -> flagged file -> Manage access.
- Action: re-add same principal with prior permission level or recreate people-specific link with expiry and intended recipients only.
- Expected result: valid business access is restored precisely.

3. T+2:00 to T+3:00 | Restore group membership only if that was removed
- Azure portal path: https://portal.azure.com -> Microsoft Entra ID -> Identity -> Groups -> affected group -> Members -> Add members.
- Action: re-add removed user.
- Expected result: group-based business access path is restored.

4. T+3:00 to T+4:30 | Confirm rollback in audit
- Azure portal path: https://portal.azure.com -> Microsoft Purview -> Solutions -> Audit -> Search.
- Query settings: Last 15 minutes; restored principal; ObjectId/path for flagged file.
- Expected result: restoration actions are logged and no unintended broad grants appear.

5. T+4:30 to T+5:00 | Stabilize ownership
- Azure portal path: https://portal.azure.com -> Microsoft Purview.
- Action: if root cause still uncertain, set ticket Escalated - Governance Review and attach updated evidence pack.
- Expected result: service is restored and risk ownership is explicit.

## Preventive: the specific change to process or tooling that stop this recurring
1. Weekly legal-repository entitlement recertification
- Owner/Timing/Type: change manager | after deployment (weekly) | manual (automation candidate: scheduled Entra/Purview access review workflow) [REQUIRES: tenant access-review workflow].
- Signal + Pass/Fail: Purview Audit Search (RecordType 14) and link inventory report; Pass = 100% legal sites reviewed and 0 stale links older than 30 days, Fail = any site unreviewed or stale link present.
- Fail action: block next related release approval and raise governance remediation task due in 4 business hours.

2. Automated oversharing detection control
- Owner/Timing/Type: release engineer | during deployment and after deployment (15-minute cadence) | automated [REQUIRES: Purview scheduled query + ticket integration].
- Signal + Pass/Fail: RecordType 14 risky events (SharingSet, SharingInvitationCreated) on tagged legal sites; Pass = alert created within 15 minutes and false-positive rate <10%, Fail = missed alert or late alert.
- Fail action: auto-open incident, notify service desk lead, and pause further rollout until triage completes.

3. Access-path change gate for sensitive libraries
- Owner/Timing/Type: change manager | before deployment | manual (automation candidate: policy-based approval gate in change system) [REQUIRES: enforced change template fields].
- Signal + Pass/Fail: change record must include inheritance impact, sharing scope, approver role, and rollback plan; Pass = all required fields + approval present, Fail = any field/approval missing.
- Fail action: reject change at CAB gate and return to engineer for correction before scheduling.

4. Copilot pre-enablement data-boundary check
- Owner/Timing/Type: DWP engineer | before deployment | manual (automation candidate: scripted permission graph scan) [REQUIRES: permission graph export process].
- Signal + Pass/Fail: pre-enable scan output for legal sites; Pass = 0 critical oversharing findings and 0 unknown external links, Fail = any critical finding remains open.
- Fail action: hold Copilot enablement for affected cohort and track remediation as release blocker.

5. Incident evidence standardization
- Owner/Timing/Type: service desk lead | after deployment (at incident closure) | manual (automation candidate: mandatory ticket fields + closure validator) [REQUIRES: ITSM field policy].
- Signal + Pass/Fail: closure checklist has 7/7 artifacts (prompt, UPN, UTC time, URL, audit export, access screenshot, membership snapshot); Pass = 7/7, Fail = <=6/7.
- Fail action: deny ticket closure and return to resolver queue within same shift.

6. Pre-deployment test gate (smoke test before release)
- Owner/Timing/Type: release engineer | before deployment | manual (automation candidate: scripted smoke test in release pipeline) [REQUIRES: test tenant + seeded legal test data].
- Signal + Pass/Fail: one approved and one non-approved test user run fixed Copilot prompt; Pass = approved user retrieves expected item and non-approved user gets no sensitive matter, Fail = any cross-boundary retrieval.
- Fail action: cancel release window and open defect ticket linked to change record.

7. In-flight monitoring (alert during rollout window)
- Owner/Timing/Type: DWP engineer | during deployment | automated [REQUIRES: near-real-time audit alert rule].
- Signal + Pass/Fail: threshold = >=1 unexpected RecordType 6 file access to tagged legal matter by non-approved cohort during rollout; Pass = 0 threshold breaches, Fail = threshold breach.
- Fail action: trigger incident, stop rollout, and execute rollback trigger control immediately.

8. Post-deployment validation (healthy state before closure)
- Owner/Timing/Type: DWP engineer | after deployment | manual (automation candidate: post-change validation script + report upload).
- Signal + Pass/Fail: 30-minute Purview check shows 0 unauthorized successful accesses and 100% sampled approved users retain access; Pass = both true, Fail = either false.
- Fail action: keep change open, invoke rollback, and escalate to change manager.

9. Rollback trigger (automatic or manual threshold)
- Owner/Timing/Type: change manager | during deployment and after deployment | automated + manual [REQUIRES: agreed rollback threshold policy].
- Signal + Pass/Fail: rollback trigger if >=1 confirmed unauthorized access event or >=3 related user tickets in 15 minutes; Pass = below threshold, Fail = threshold reached.
- Fail action: declare rollback state, restore prior permissions, and send service desk advisory within 10 minutes.

10. Knowledge update (runbook/checklist learning capture)
- Owner/Timing/Type: service desk lead | after deployment | manual (automation candidate: mandatory PIR task template) [REQUIRES: post-incident review workflow].
- Signal + Pass/Fail: runbook, L1, and L2/L3 docs updated with incident deltas within 2 business days; Pass = all three updated and linked in ticket, Fail = any missing update.
- Fail action: keep incident in Problem Review state and assign update actions to DWP engineer.

## Related: other incidents or KB article this connects to
- issue2-copilot-unexpected-client-matter-runbook.md
- issue2-copilot-unexpected-client-matter-rca.md
- issue2-copilot-unauthorized-matter-triage.md
- issue2-copilot-security-signal-analysis.md
- cross-issue-hypothesis-matrix.md
