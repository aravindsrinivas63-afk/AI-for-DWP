# Combined End-User Communication — Issues 1, 2, and 3

## Update Summary
We are sharing one combined update on three active incidents that affected logon performance, unexpected AI content retrieval, and missing desktop shortcuts.

## Issue 1 — Login Failures and Slow Logons (Floor 6)
On Monday morning after a Friday application rollout, multiple Floor 6 users reported either failed logons or very slow logons on recently migrated Windows 11 devices.

Most likely cause: startup-time deployment activity increased endpoint load during sign-in, which delayed or disrupted desktop readiness for part of the target cohort.

Action taken: we paused or controlled further rollout pressure on the affected cohort and prioritized triage during the logon window.

Current status: login success and logon time improved after rollout pressure was reduced, with final validation continuing through metrics.

## Issue 2 — Unexpected Copilot Retrieval of Client Matter (Legal)
A legal user reported that Copilot surfaced and summarized a client matter she believed she was never authorized to access.

Most likely cause: an access-boundary governance path (direct, inherited, or shared-link permission path) made the content technically accessible to that account.

Action taken: we opened a security-priority workflow, preserved evidence, and initiated entitlement review with containment on suspected overshared paths.

Current status: entitlement-path and audit validation are in progress. If no valid entitlement path is confirmed, this will be reclassified as a service defect and escalated with preserved evidence.

## Issue 3 — Missing Desktop Shortcuts (Floor 6)
Multiple Floor 6 users reported missing desktop shortcuts after recent Windows 11 migration and a Friday application deployment.

Most likely cause: a deployment-related shortcut management side effect during logon initialization removed, replaced, or failed to recreate expected shortcuts.

Action taken: we restored required shortcuts for affected users and corrected or disabled the offending behavior in the rollout path.

Current status: baseline shortcut checks were completed on affected users, and persistence is being monitored across reboot and next sign-in.

## What You Should Do
- If you still see login failure or unusually slow sign-in, contact the service desk and report your device name, floor, and time of issue.
- If Copilot returns content that looks unexpected for your access level, stop and report the prompt time and content path to the service desk immediately.
- If desktop shortcuts are missing again, report which shortcuts are missing and when you last signed in.

## Closing Note
Thank you for your patience. We will continue to provide clear updates as verification completes, and we will not close any of these incidents until validation confirms stability and containment.
