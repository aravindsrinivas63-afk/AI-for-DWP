# Analysis — Issue 1: Login Failures and Slow Logons

## Scope Facts
- At least a dozen users on Floor 6 report either inability to log in or very slow logon.
- Floor 6 was recently migrated to Windows 11 and enrolled in Intune.
- A new Document Management application was deployed Friday afternoon.
- Symptoms surfaced Monday morning.

## Ranked Differential (Most Probable First)

1. Deployment-linked startup contention from new app components
- Why likely: Exact timing boundary and mixed "slow but eventually in" pattern strongly match startup overhead.
- Fastest check: Compare first 10-minute CPU/disk/process timeline on one affected device; confirm if new app process/service/task dominates.

2. Deployment sequencing or detection retry loop at logon
- Why likely: First business-day post-deploy issues commonly come from install/detection loops.
- Fastest check: Inspect Intune Management Extension logs and app status timestamps during logon window.

3. Compliance/Conditional Access delay triggered by deployment state
- Why likely: Explains split outcome (hard failure for some, long wait for others).
- Fastest check: Correlate Entra sign-in records with compliance state transitions.

4. Identity lockout/bad credential burst
- Why likely: Can cause inability to log in but less likely to explain broad slowness by itself.
- Fastest check: Review 4625/4740 and Entra failure reasons for affected users.

5. Profile load degradation after recent policy/app change
- Why likely: Can elongate sign-in and cause desktop-state anomalies.
- Fastest check: Review User Profile Service and Group Policy operational events around incident period.

## Deployment Causality Decision Evidence

### Confirms deployment as primary cause
- Impact cohort aligns with Friday assignment group.
- Delay/failure starts only after Friday change.
- App install/retry/startup signals overlap with logon delay period.
- Unaffected comparison devices do not show same signal.
- Rollback/pause measurably improves logon success/time.

### Rules out deployment as primary cause
- No assignment overlap with impacted users.
- Similar failures appear in non-target groups.
- Identity/compliance evidence fully explains failures independent of app state.
- No app deployment traces on affected endpoints during symptom window.
- Rollback/pause has no measurable effect.

## Immediate Investigation Action
Run endpoint evidence collection on one affected and one unaffected Floor 6 device and compare startup load, IME traces, sign-in events, and policy timing.

## Updated Hypothesis

### Current Working Hypothesis
The Friday Document Management deployment is the most likely primary fault boundary for Issue 1, with startup contention or install/detection sequencing causing delayed desktop readiness and contributing to failed logons for part of the cohort.

### What Would Validate This Hypothesis
- Affected users/devices align tightly to the Friday assignment group.
- IME/deployment timestamps overlap with Monday login delay/failure windows.
- Affected devices show repeatable startup pressure from deployment-related processes/services/tasks.

### What Would Falsify This Hypothesis
- Impact is evenly present in non-targeted users/devices.
- Identity/compliance telemetry fully explains login failures independent of deployment state.
- Rollback/pause of deployment has no measurable improvement.