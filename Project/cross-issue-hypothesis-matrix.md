# Floor 6 Incident: Cross-Issue Hypothesis Matrix

## Purpose
This matrix aligns the three active Floor 6 issues into one evidence-driven view so triage can quickly validate, falsify, and sequence work.

## Scope
- Issue 1: Login slow/failure and desktop readiness delay
- Issue 2: Copilot surfaced matter user claims was unauthorized
- Issue 3: Desktop shortcuts disappeared for part of the cohort

## Cross-Issue Hypothesis Matrix

| Issue | Current Working Hypothesis | Fastest Validation Check (First 30 Minutes) | Key Evidence to Collect | What Falsifies It | Priority / Track |
|---|---|---|---|---|---|
| Issue 1: Login + performance | Friday Document Management deployment introduced startup contention or sequencing side effects that delay readiness and contribute to failed logons for part of Floor 6 | Compare one affected and one unaffected device for deployment overlap with logon delay window and startup pressure | IME logs, Diagnostics-Performance events, Security sign-in events, startup task/process snapshots | Impact is equal in non-targeted users/devices; identity/compliance signals fully explain failures independent of deployment; no improvement after pause/rollback | High / Endpoint + Identity |
| Issue 2: Copilot security signal | Permissions-boundary or oversharing path (direct/inherited/group/shared link) exposed content path to user; treat as security incident until disproved | Validate effective permissions for the exact user/resource/time and preserve M365 audit trail immediately | Unified Audit Log, SharePoint/OneDrive permissions, Entra group membership and change history, Copilot retrieval context | No entitlement path exists and audit shows retrieval outside authorized boundary, indicating potential product-side defect after access paths are ruled out | Critical / Security Incident |
| Issue 3: Shortcut disappearance | Friday deployment created shortcut-management side effect (script/policy/package timing) that removed or failed to recreate expected links | Time-correlate shortcut modified/deleted timestamps with rollout and policy/script execution window | Desktop/Public Desktop inventories, IME/script logs, Group Policy/User Profile events, change timestamps | No cohort/time alignment to deployment; random per-user state with no shared traces; isolated profile corruption explains cases | Medium-High / Endpoint Config |

## Shared Signals to Correlate
- Cohort overlap: same users/devices affected across Issues 1 and 3 strongly increases confidence in a common deployment-side contributor.
- Time boundary: Friday rollout through Monday morning is the primary correlation window.
- Change control: assignment, detection, remediation scripts, and policy deltas in that window are highest-yield artifacts.

## Immediate Decision Rules
1. If Issue 2 has confirmed unauthorized exposure risk, keep it isolated on Security Incident track and preserve evidence before broad troubleshooting.
2. If Issues 1 and 3 both correlate to the same deployment scope/time, prioritize controlled pause/rollback test and compare impact delta.
3. If no correlation appears after first-pass evidence, split ownership: Identity for Issue 1, Security for Issue 2, Endpoint/Profile for Issue 3.

## Suggested Owner Split
- Issue 1: Endpoint Engineering + Identity Operations
- Issue 2: Security Operations + Compliance + M365 Admin
- Issue 3: Endpoint Engineering + EUC Packaging/Policy Team

## Notes
Use this matrix as the working coordination artifact during bridge calls and update each row as evidence confirms or falsifies the active hypothesis.
