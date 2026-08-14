# Analysis — Issue 2: Copilot Surfaced Matter User Says She Never Had Access To

## Scope Facts
- A paralegal reported Copilot surfaced a client matter she believes she was never authorized to access.
- Incident is in Legal context with sensitive client information.
- Timing overlaps broader Monday disruption window.

## Incident Classification
This is a potential information security and data-governance incident signal, not a standard endpoint support ticket.

## Ranked Differential (Most Probable First)

1. Permission oversharing or inherited access drift
- Why likely: Most common cause of unexpected Copilot retrieval in M365-boundaries.
- Fastest check: Validate effective permissions for the user on the exact matter path at incident timestamp.

2. Shared-link or group-membership path user was unaware of
- Why likely: Users often have indirect access through links/groups without awareness.
- Fastest check: Review sharing links, inheritance chain, and recent membership changes.

3. Connector/index retrieval from permitted but unexpected content location
- Why likely: Copilot may retrieve from sources user technically can access but does not expect.
- Fastest check: Audit Copilot interaction source workload/item reference in M365 logs.

4. Sensitivity label/DLP boundary gap
- Why likely: Policy mis-scope can permit retrieval where business intent expected restriction.
- Fastest check: Verify label and DLP decisions for surfaced item at event time.

5. Genuine Copilot defect
- Why likely: Possible but should be last hypothesis after entitlement and audit path checks.
- Fastest check: Escalate with preserved evidence only after non-bug causes are excluded.

## What Not To Do
- Do not close as "AI weirdness".
- Do not ask user to repeatedly repro without security oversight.
- Do not treat as endpoint troubleshooting.
- Do not change permissions broadly before evidence preservation.

## Required Escalation (Two Sentences)
Potential security incident: a Legal user reported Copilot surfaced and summarized a client matter they state they were never authorized to access, indicating possible unauthorized exposure or permission oversharing.  
Please open a Priority 1 Security Incident, preserve cloud audit evidence for the exact timestamp/content path, validate effective permissions immediately, and apply temporary containment until unauthorized access is ruled out.

## Updated Hypothesis

### Current Working Hypothesis
Issue 2 is most likely a permissions-boundary or oversharing condition (direct, inherited, shared-link, or group-based access path) rather than a device problem, and must be treated as a security incident signal until disproved.

### What Would Validate This Hypothesis
- Effective permissions show an unexpected but real access path for the reporting user.
- M365 audit traces confirm Copilot retrieved the matter from an accessible source path.
- Recent ACL/group/share changes correlate with incident timing.

### What Would Falsify This Hypothesis
- No entitlement path exists and audit evidence shows retrieval beyond authorized boundaries.
- Evidence isolates a service-side Copilot defect after permission and policy paths are ruled out.