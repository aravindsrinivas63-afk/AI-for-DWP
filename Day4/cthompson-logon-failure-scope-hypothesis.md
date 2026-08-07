# User Logon Incident Analysis - Scope-Only Hypothesis

## Scope facts used
- Symptom: user cthompson not able to login
- Who: cthompson only one user
- Since: ~08:40 this morning
- Change: Nil

## Ranked likely causes (most probable first)

1. User account lockout or bad credential state
Why this fits the scope facts: The impact is isolated to one user, which matches a user-specific identity issue rather than a platform or shared service failure. A sudden start time this morning is consistent with repeated failed sign-in attempts leading to lockout.
Single fastest check: Check Entra ID/AD sign-in and lockout status for cthompson at and after ~08:40.

2. MFA challenge failure or expired authentication method for this user
Why this fits the scope facts: A single-user login failure with no wider impact commonly points to a broken second-factor path tied to one identity. No environment change is needed for this to occur because user factors can expire or fail independently.
Single fastest check: Review cthompson sign-in logs for MFA failure result codes and challenge details around the first failure time.

3. Account disabled, expired, or missing required entitlement assignment
Why this fits the scope facts: Single-user-only impact strongly fits an account state or entitlement issue scoped to that identity. This can appear suddenly without infrastructure change if account lifecycle rules or assignment drift occurred.
Single fastest check: Verify account enabled state, expiry, and required app/resource assignment membership for cthompson.

4. Conditional Access or policy evaluation mismatch affecting this user context
Why this fits the scope facts: One user can fail login if their device, location, risk, or group context no longer satisfies policy, even when everyone else remains unaffected. No new platform change is required if the user context changed.
Single fastest check: Inspect the failed sign-in Conditional Access evaluation for cthompson and identify the blocking policy/result.

5. Corrupt or stale local profile/token/session cache on the user endpoint
Why this fits the scope facts: A single affected user with normal service for others can indicate endpoint-local token or profile corruption rather than central service outage. Onset this morning also aligns with a local session state issue after reboot or reconnect.
Single fastest check: Test cthompson login from a different known-good device/session path; if successful, isolate to endpoint cache/profile state.

## Current position
Do not commit to a single root cause yet. Prioritise identity and sign-in telemetry checks in order above to quickly confirm or eliminate each hypothesis.

## Event details (incident window evidence)

Security Event Log - DESKTOP-FB022, 2024-03-15 08:44-09:12:
- 08:44:01 Event 4776 Audit Failure: FINBRIDGE\cthompson wrong password (0xC000006A) from DESKTOP-FB022.
- 08:44:03 Event 4625 Audit Failure: bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:28 Event 4625 Audit Failure: bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:55 Event 4625 Audit Failure: bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:56 Event 4740 Audit Failure: account FINBRIDGE\cthompson locked out; caller computer DESKTOP-FB022.
- 08:45:10 Event 4625 Audit Failure: account locked out, logon type 7 (unlock attempt), source DESKTOP-FB022.
- 08:45:44 Event 4771 Audit Failure: Kerberos pre-auth failed (0x18 wrong password), source IP 10.10.8.112.
- 08:46:01 Event 4771 Audit Failure: Kerberos pre-auth failed (0x18 wrong password), source IP 10.10.8.112.
- 08:46:33 Event 4771 Audit Failure: Kerberos pre-auth failed (0x18 wrong password), source IP 10.10.8.112.

## Hypothesis elimination against evidence

1. User account lockout or bad credential state
Judgement: Supports.
Determining events: 4776 at 08:44:01 (wrong password), 4625 at 08:44:03/08:44:28/08:44:55 (bad password), 4740 at 08:44:56 (account locked out), and 4625 at 08:45:10 (failure reason: account locked out).

2. MFA challenge failure or expired authentication method
Judgement: Contradicts.
Determining events: 4776 at 08:44:01 and 4625 at 08:44:03/08:44:28/08:44:55 show password failures before MFA stage, then 4740 at 08:44:56 confirms lockout.

3. Account disabled, expired, or missing required entitlement assignment
Judgement: Contradicts for disabled/expired; neutral for entitlement.
Determining events: 4776 at 08:44:01 and repeated 4625 bad-password events, followed by 4740 at 08:44:56, match wrong-password and lockout behavior rather than disabled/expired status; no entitlement-specific event appears in this set.

4. Conditional Access or policy evaluation mismatch
Judgement: Contradicts.
Determining events: 4776 at 08:44:01, 4625 at 08:44:03/08:44:28/08:44:55, and 4740 at 08:44:56 indicate credential failure and lockout, with no CA decision event in the provided log set.

5. Corrupt or stale local profile/token/session cache on endpoint
Judgement: Neutral.
Determining events: repeated 4771 at 08:45:44/08:46:01/08:46:33 from IP 10.10.8.112 show ongoing bad credentials from another source, which does not by itself prove local cache/profile corruption on DESKTOP-FB022.

## Survived hypothesis

User account lockout caused by repeated bad password attempts, with continued bad attempts also seen from a second source (10.10.8.112), resulting in locked account state.

## Resolution steps

1. Confirm lockout timeline in security logs for cthompson (4776 wrong password, repeated 4625 bad password, 4740 lockout, 4625 account locked out).
2. Contain ongoing bad attempts from 10.10.8.112 before unlock to avoid immediate relock.
3. Reset cthompson password to a temporary strong password per policy.
4. Unlock FINBRIDGE\cthompson only after containment and reset are complete.
5. Clear saved/stale credentials on DESKTOP-FB022 and any other user-associated endpoints or services.
6. Retest interactive login on DESKTOP-FB022 with the new password.
7. Monitor for 10-15 minutes to confirm no new 4625/4771 failures and no new 4740 lockout.
8. Record the offending source and stale credential location to prevent recurrence.
