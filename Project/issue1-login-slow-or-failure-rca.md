# RCA — Issue 1: People Cannot Log In or Logon Is Extremely Slow

## Incident Summary
On Monday morning after a Friday application rollout, multiple Floor 6 users reported either failed logons or very slow logons on recently migrated Windows 11 devices.

## Business Impact
- Multiple users on Floor 6 were unable to start work on time.
- Users who could log in experienced major delay before desktop readiness.
- Service desk volume and escalations increased during business-start window.

## Scope
- Affected: Floor 6 migrated Windows 11 and Intune-managed endpoints (cohort to confirm by assignment export).
- Not confirmed affected: non-migrated floors and non-targeted assignment groups.

## Evidence Summary
- Timing boundary: symptoms started Monday; new Document Management app deployed Friday.
- Pattern boundary: mixed symptom profile (some hard failures, others prolonged logon) consistent with startup pressure or sequencing.
- Analysis baseline: deployment-linked startup contention and/or install-detection retry behavior ranked highest.

## Timeline (Observed)
- Friday afternoon: Document Management deployment issued to target cohort.
- Monday morning (first business logons): users report login failures and severe slowness.
- Monday investigation window: hypothesis converges on deployment boundary due to timing and symptom shape.

## Root Cause
Primary cause is most consistent with deployment-linked startup contention and sequencing during logon after Friday rollout, where startup-time install/detection activity increased endpoint load and delayed or disrupted desktop readiness for part of the target cohort.

## Contributing Factors
- First business-day convergence of device check-in, startup tasks, and user sign-in.
- Recently migrated Win11/Intune posture where policy/app timing sensitivity is higher.
- Lack of phased performance gate before broad startup-time deployment impact.

## Resolution Implemented
- Paused/controlled further deployment pressure on affected cohort.
- Prioritized triage of affected devices during logon window.
- Validated that login success/time improved once rollout pressure was reduced (to verify via final metrics).

## Verification
- Compare pre- and post-mitigation median logon time for affected users.
- Confirm reduction of concurrent startup install/detection events during sign-in window.
- Confirm incident ticket rate dropped after containment.

## Preventive Actions
1. Add pre-deployment startup-performance gate for Win11 endpoint app rollouts.
2. Stagger deployment waves to avoid first-business-hour startup spikes.
3. Add automatic alert if login-time install/detection retries exceed threshold.
4. Add rollback hold condition tied to logon latency and failed-login rate.
5. Maintain unaffected control cohort comparison during all major endpoint releases.

## Owner and Follow-up
- Owner: Endpoint Engineering and Intune App Deployment Team.
- Follow-up: publish a short deployment runbook addendum for startup-sensitive apps.
