# Ranked Differential — Floor 6 Login/Performance Incident

**Date:** 2026-08-14  
**Context:** New Document Management app deployed Friday afternoon to Floor 6; login failures/slowness reported Monday morning.

## Ranked Likely Causes (Most Probable First)

### 1) Post-logon startup regression caused by the new app or its startup components
**Why ranked #1:** Tight timing correlation (Friday deploy -> Monday onset), and symptom mix includes very slow desktop readiness, which is classic startup contention behavior.  
**Fastest check:** On one affected endpoint, compare startup timeline and top CPU/disk consumers for first 10 minutes after sign-in; verify whether new app process/service/task is active and heavy during delay window.

### 2) App deployment context/timing issue (SYSTEM vs USER, first-logon sequencing, retry loop)
**Why ranked #2:** Intune/IME deployments can stall user readiness if installs, detection retries, or script dependencies execute at first interactive session.  
**Fastest check:** Review Intune Management Extension logs and deployment status for the affected device and timestamp-correlate install attempts, detection failures, and retries with the slow logon period.

### 3) Compliance/Conditional Access gating side effect triggered by deployment-dependent state
**Why ranked #3:** Mixed reports of "cannot log in" plus "logs in but very slow" often indicate different failure points across users (auth accepted vs post-auth access gating).  
**Fastest check:** Check Entra sign-in logs and Intune compliance transitions for affected users around incident time; look for conditional-access blocks or prolonged compliance evaluation.

### 4) Account lockout/authentication noise amplified Monday morning
**Why ranked #4:** Monday surge can expose stale creds, repeated bad-auth background attempts, or unlock loops; this explains hard failures but usually not broad post-login slowness.  
**Fastest check:** Query Security events (4625/4740) and Entra failure reasons for affected users; confirm whether failure pattern is identity-led rather than endpoint startup-led.

### 5) Profile load/redirection side effect (including desktop/shell timing) triggered by recent policy/app changes
**Why ranked #5:** Related symptom of missing shortcuts suggests profile/shell initialization instability could coexist with perceived logon slowness.  
**Fastest check:** Review User Profile Service and Group Policy operational logs plus shell/desktop path state on affected vs unaffected endpoints.

## Evidence That Would Confirm Friday Deployment as Primary Cause

1. **Cohort alignment:** Most impacted users/devices are in the exact Friday deployment target group, while non-target peers are mostly unaffected.  
2. **Time boundary:** Incident begins after deployment window with no similar pattern before Friday.  
3. **Local technical signal:** Affected endpoints show new app install/detection/retry or startup-component activity in the same period as slow/failing sign-ins.  
4. **Control comparison:** Unaffected comparison endpoints (same floor/build baseline, not impacted) do not show the same app/startup signal pattern.  
5. **Change reversal effect:** Pausing/rolling back deployment improves sign-in success and startup time for newly impacted users.

## Evidence That Would Rule Out Friday Deployment as Primary Cause

1. **No assignment correlation:** Impacted users are not concentrated in the deployment cohort.  
2. **No timing correlation:** Similar failures existed before Friday or appeared equally in groups with no rollout.  
3. **Identity-led root evidence:** Entra/auth lockout/CA blocks fully explain failures independent of app state.  
4. **No local deployment artifacts:** Affected endpoints show no relevant install/retry/startup traces tied to the new app.  
5. **Rollback non-effect:** Rollback/pause produces no measurable improvement in login success or time-to-usable-desktop.

## Practical Next Step

Run Issue 1 evidence script on one affected and one unaffected Floor 6 endpoint, then compare startup/process, IME deployment traces, sign-in events, and policy refresh timing before making rollback decision.
