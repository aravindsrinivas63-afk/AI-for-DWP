# RCA — Issue 2: Copilot Surfaced a Client Matter User States She Never Had Access To

## Incident Summary
A legal user reported that Copilot surfaced and summarized a client matter she believed she was never authorized to access.

## Incident Classification
Potential information security and data-governance incident signal. This is not a standard endpoint issue.

## Business Impact
- Potential unauthorized exposure of sensitive client matter information.
- Legal and compliance risk pending entitlement validation.
- Elevated trust and reputational risk for AI-assisted workflows.

## Scope
- Reported by one legal user initially.
- Scope expansion required through audit to determine whether broader entitlement drift exists.

## Evidence Summary
- User report indicates unexpected matter retrieval by Copilot.
- Most probable path from prior analysis: permission oversharing, inherited access, shared-link path, or group-membership drift.
- Copilot defect remains lower probability until entitlement and policy controls are fully ruled out.

## Timeline (Observed)
- User interaction: Copilot summary included unexpected client matter.
- Immediate interpretation: potential boundary breach; security triage required.
- Investigation focus: entitlement path and M365 audit reconstruction.

## Root Cause
Most likely root cause is an access-boundary governance issue (direct, inherited, or shared-link permission path) that made the content technically accessible to the user account, allowing Copilot retrieval within existing permissions.

Note: If audit ultimately proves no valid entitlement path existed, root cause must be reclassified as service defect and escalated to vendor with preserved evidence.

## Contributing Factors
- Legacy or complex inherited permissions in collaboration repositories.
- User awareness gap about indirect access paths (group/share inheritance).
- Insufficient periodic oversharing/entitlement recertification for high-sensitivity legal content.

## Resolution Implemented
- Opened security-priority incident workflow.
- Preserved evidence (prompt context, timestamp, content path, tenant audit traces).
- Initiated entitlement review and immediate containment on suspected overshared paths.

## Verification
- Confirm effective access path for reported user at incident timestamp.
- Confirm whether retrieval source aligns with permitted path in audit logs.
- Confirm containment removed unintended exposure without breaking valid legal workflows.

## Preventive Actions
1. Enforce scheduled entitlement recertification for Legal matter repositories.
2. Reduce inheritance sprawl by moving sensitive matter stores to explicitly scoped groups.
3. Add oversharing detection checks before Copilot enablement on sensitive sites.
4. Add security runbook for AI-retrieval incidents with evidence checklist and SLA.
5. Add user-facing awareness note: Copilot uses existing permissions, not separate access rights.

## Owner and Follow-up
- Owner: Security Operations with M365 Governance and Legal IT.
- Follow-up: produce known-error/security-pattern record for "unexpected AI retrieval from inherited access."
