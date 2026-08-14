# RCA — Issue 3: Desktop Shortcuts Vanished

## Incident Summary
Multiple Floor 6 users reported missing desktop shortcuts after recent Win11 migration and a Friday application deployment.

## Business Impact
- Users lost quick access to core business tools.
- Productivity reduced due to manual app discovery and recreation of shortcuts.
- Increased service desk contacts and repeat tickets.

## Scope
- Affected: subset of Floor 6 migrated Win11 endpoints (exact count to confirm).
- Likely boundary: users/devices in the same rollout cohort as Friday deployment.

## Evidence Summary
- Temporal correlation: shortcut loss observed Monday after Friday deployment.
- Cohort pattern: multi-user reports suggest shared system/config condition, not isolated user error.
- Prior analysis ranking: deployment script/package side effect and logon-time policy/script sequencing are top causes.

## Timeline (Observed)
- Friday: deployment changes introduced for target endpoints.
- Monday morning: users report vanished shortcuts.
- Investigation period: evidence favored rollout-linked change over random deletion.

## Root Cause
Most likely root cause is a deployment-related shortcut management side effect (package/script/policy action) that removed, replaced, or failed to recreate expected desktop shortcuts during logon initialization.

## Contributing Factors
- Post-migration profile/policy sequencing sensitivity.
- Incomplete guardrails for preserving baseline shortcut set across app deployments.
- Limited pre-release validation for desktop-state continuity.

## Resolution Implemented
- Restored required shortcuts for affected users.
- Corrected or disabled offending shortcut-management behavior in rollout path.
- Confirmed shortcut baseline on affected cohort after corrective change.

## Verification
- Compare shortcut inventory before and after fix on affected devices.
- Confirm expected shortcuts persist across reboot and next-day sign-in.
- Confirm no new shortcut-loss incidents after corrected deployment action.

## Preventive Actions
1. Add pre/post deployment desktop-baseline validation (shortcut inventory check).
2. Require pilot testing that includes sign-in persistence verification.
3. Add guardrail in scripts: never remove corporate shortcuts unless explicitly approved list is provided.
4. Add automated alert for mass shortcut deletion/modification events in rollout window.
5. Include desktop-state rollback step in endpoint deployment runbook.

## Owner and Follow-up
- Owner: Endpoint Engineering and EUC Configuration Team.
- Follow-up: publish standard "desktop baseline protection" checklist for future migrations.
