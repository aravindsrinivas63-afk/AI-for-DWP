# Root Cause Analysis — FinBridge AVD Black Screen Incident

**Incident:** Black screen after AVD logon in Finance host pool  
**Scope:** POOL-FIN-01  
**Unaffected control group:** POOL-FIN-02  
**Resolution time:** 2024-03-15 10:00 AM  
**Status:** Resolved and verified

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real hostnames, tenant details, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary

Users in POOL-FIN-01 experienced a black screen immediately after AVD login beginning shortly after 07:00 on 2024-03-15. Some sessions recovered after a short delay, while others remained black and disconnected/reconnected repeatedly. The issue was isolated to the pool that had received the overnight image update at 02:00, while POOL-FIN-02 remained healthy and was not part of the update wave.

The root cause was a graphics/display driver regression in the updated POOL-FIN-01 image, evidenced by repeated `dwm.exe` crashes in `igdumd64.dll`. The suggested rollback and driver restoration were applied, and at 10:00 AM the issue was confirmed resolved: users were logging in successfully to POOL-FIN-01 with no further black-screen reports.

---

## Supporting Evidence

### Scope and change boundary

- `POOL-FIN-01` received an overnight image update at `02:00`
- `POOL-FIN-02` was not included in the update wave
- The problem began the same morning the updated image was active
- The issue affected approximately `40%` of users in `POOL-FIN-01`

### Host event evidence

- `07:02:10` TerminalServices-LocalSessionManager Event `21`: session logon succeeded for `FINBRIDGE\mlopez`
- `07:02:14` Kernel-General Event `1`: boot time recorded as `2024-03-15 02:03:11`, which aligns with the overnight image update window
- `07:02:16` Application Error Event `1000`: `dwm.exe` faulted in `igdumd64.dll` with exception code `0xc0000005`
- `07:02:17` TerminalServices-LocalSessionManager Event `40`: session disconnected immediately after the DWM fault
- `07:02:18` Desktop Window Manager Event `9009`: DWM exited with code `0x40010004`
- `07:02:44` TerminalServices-LocalSessionManager Event `21`: reconnect succeeded for the same session
- `07:02:46` Application Error Event `1000`: the same `dwm.exe` / `igdumd64.dll` crash repeated
- `07:02:47` TerminalServices-LocalSessionManager Event `40`: session disconnected again
- `07:03:01` Desktop Window Manager Event `9009`: DWM exited again
- `07:03:10` TerminalServices-LocalSessionManager Event `21`: second reconnect succeeded
- `07:08:22` TerminalServices-LocalSessionManager Event `21`: another Finance user logged on successfully to the same host pool
- `07:08:24` Application Error Event `1000`: `dwm.exe` faulted again in `igdumd64.dll` for the second user

### Comparison host evidence

- `SHFIN-02-A` on `POOL-FIN-02` remained unaffected
- `07:01:46` TerminalServices-LocalSessionManager Event `21`: session logon succeeded on the unaffected host
- `07:01:46` Desktop Window Manager Event `9011`: DWM started successfully
- No Application Error events were present in the comparison window

### Resolution evidence

- The rollback / repair action was applied to the affected pool
- At `10:00 AM`, verified users were logging in to hosts in `POOL-FIN-01`
- No black-screen issues were reported after the fix
- The unaffected pool continued to behave normally, confirming the fault was isolated to the updated image path

---

## Timeline

| Time | Event |
|---|---|
| 02:00 | Overnight image update applied to POOL-FIN-01 |
| 02:03:11 | Host boot time recorded after the update |
| ~07:00 | First user reports black screen after login |
| 07:02:10 | Session logon succeeds for FINBRIDGE\mlopez on SHFIN-01-A |
| 07:02:16 | `dwm.exe` crashes in `igdumd64.dll` |
| 07:02:17 | Session disconnects |
| 07:02:18 | DWM exits |
| 07:02:44 | Reconnect succeeds |
| 07:02:46 | The same DWM crash repeats |
| 07:02:47 | Session disconnects again |
| 07:03:01 | DWM exits again |
| 07:03:10 | Second reconnect succeeds |
| 07:08:22 | Second Finance user logs on to the same pool |
| 07:08:24 | Same `dwm.exe` / `igdumd64.dll` crash appears again |
| 10:00 | Suggested resolution applied; verified users log in successfully to POOL-FIN-01 with no issues |

---

## Root Cause

The most likely root cause is a graphics/display driver regression introduced in the updated POOL-FIN-01 image, specifically associated with `igdumd64.dll` causing Desktop Window Manager to crash during or immediately after user logon.

### Why this is the root cause

- The fault recurred across multiple user sessions on the same host pool
- The fault module was consistent: `igdumd64.dll`
- The visible symptom was a black screen after login, which is consistent with DWM failure
- The comparison pool on the pre-update image did not show the fault
- The timing aligns with the overnight image update boundary rather than a tenant-wide or network-wide problem

---

## 5 Whys Analysis

**Why did users see a black screen after login?**  
Because the desktop session was not rendering normally and DWM was exiting.

**Why was DWM exiting?**  
Because `dwm.exe` was crashing in `igdumd64.dll`.

**Why was `igdumd64.dll` crashing?**  
Because the updated POOL-FIN-01 image likely introduced a graphics/display driver regression.

**Why is the updated image the fault boundary?**  
Because the issue started immediately after the overnight image update and only the updated pool was affected.

**Why did some sessions recover while others remained black?**  
Because the regression appears to have been intermittent or host-dependent within the updated pool, causing some logons to stabilize after reconnect while others continued to fail.

---

## Resolution

1. Drain or stop new logons to POOL-FIN-01 while the faulty image is active.
2. Roll back POOL-FIN-01 to the last known good image or rebuild it from the pre-update baseline.
3. Restore the known-good graphics driver version if the image update included a driver change.
4. Reboot the affected session hosts so the graphics stack and DWM start cleanly.
5. Retest with multiple user logons to confirm that the black screen no longer occurs.
6. Confirm that no new `Event 1000` or `Event 9009` entries appear after the fix.
7. Return POOL-FIN-01 to service only after successful validation.

---

## Preventive Action

### Short-term prevention

- Hold image changes in one pool only before rolling them into the wider host pool set
- Require a pre-production validation step for graphics driver and DWM behaviour after image updates
- Monitor the first hour after image deployment for black-screen or DWM-related event patterns

### Long-term prevention

- Add a host-pool comparison check for any future image rollout so updated and non-updated pools can be compared quickly
- Track `dwm.exe` / `igdumd64.dll` crash signatures as a release-blocking indicator for future image waves
- Keep a known-good rollback image for each production pool
- Document the minimum post-update verification steps: successful logon, DWM startup, and no repeating Event `1000` / `9009` faults

---

## Validation of Resolution

- Verified users were logging in to hosts in `POOL-FIN-01` at `10:00 AM`
- No black screen symptoms were reported after the fix
- The pool behaved normally after rollback / repair
- The unaffected comparison pool remained stable, confirming the issue was isolated to the updated image path

---

## Closure Statement

Resolved. The incident was caused by a graphics/display driver regression in the updated POOL-FIN-01 image. The image was rolled back / repaired, hosts were restarted, and service was verified at `10:00 AM` with successful user logons and no further black-screen reports.
