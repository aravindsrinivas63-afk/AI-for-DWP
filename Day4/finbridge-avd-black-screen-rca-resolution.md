# Root Cause Analysis and Resolution — FinBridge AVD Black Screen Incident

**Incident:** AVD black screen after login in Finance host pool  
**Scope:** POOL-FIN-01  
**Affected period:** 2024-03-15 around 07:00  
**Status:** Resolved hypothesis and remediation plan; confirm with rollback validation before closure

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real hostnames, tenant details, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary

The strongest surviving hypothesis is a graphics/display driver regression introduced by the overnight image update applied to POOL-FIN-01 at 02:00. The affected host showed repeated `dwm.exe` crashes in `igdumd64.dll`, while the unaffected comparison host on POOL-FIN-02 started Desktop Window Manager successfully and showed no application errors.

This explains the symptom pattern: black screen after sign-in, partial recovery for some users, persistent failure for others, and no impact to the untouched pool.

---

## Root Cause

The most likely root cause is a graphics/display driver fault in the updated POOL-FIN-01 image, specifically associated with `igdumd64.dll` causing Desktop Window Manager to crash during or immediately after user logon.

### Evidence

- `07:02:16` Event 1000 on SHFIN-01-A: `dwm.exe` faulting module `igdumd64.dll`
- `07:02:18` Event 9009 on SHFIN-01-A: Desktop Window Manager exited
- `07:02:46` Event 1000 on SHFIN-01-A: the same `dwm.exe` / `igdumd64.dll` fault repeated after reconnect
- `07:03:01` Event 9009 on SHFIN-01-A: Desktop Window Manager exited again
- `07:08:24` Event 1000 on SHFIN-01-A: the same fault appeared for another user session
- `07:01:46` Event 9011 on SHFIN-02-A: Desktop Window Manager started successfully, with no application errors

---

## Resolution

1. Drain or stop new logons to POOL-FIN-01 while the faulty image remains active.
2. Compare the updated image and graphics driver set on SHFIN-01-A with the known-good POOL-FIN-02 image baseline.
3. Roll back POOL-FIN-01 to the last known good image, or rebuild it from the pre-update baseline.
4. If the image update included a graphics driver change, pin the driver back to the known-good version.
5. Reboot affected hosts after rollback so the graphics stack and Desktop Window Manager start cleanly.
6. Retest with at least two user logons and confirm no new `Event 1000` or `Event 9009` entries occur.
7. Return POOL-FIN-01 to service only after logon stability is confirmed.

---

## 5 Whys

**Why did users see a black screen after login?**  
Because Desktop Window Manager was crashing during session startup.

**Why was Desktop Window Manager crashing?**  
Because `igdumd64.dll` faulted inside `dwm.exe`.

**Why did that happen on POOL-FIN-01?**  
Because the updated POOL-FIN-01 image likely introduced a graphics/display driver regression.

**Why is the updated image the leading fault boundary?**  
Because the issue began immediately after the overnight update and POOL-FIN-02, which was not updated, remained healthy.

**Why was the same issue seen for multiple users?**  
Because the fault was pool-level rather than user-level, affecting the shared session host image instead of a single profile.

---

## Validation Criteria

- No black screen after sign-in on POOL-FIN-01
- No repeat `Event 1000` entries for `dwm.exe` / `igdumd64.dll`
- No repeat `Event 9009` Desktop Window Manager exits
- Consistent successful logon behaviour on both POOL-FIN-01 and POOL-FIN-02

---

## Closure Note

Resolved by removing the faulty image/driver combination from POOL-FIN-01 and restoring the known-good baseline. The incident is consistent with a graphics/display driver regression introduced by the overnight image update. Final closure should follow successful post-rollback validation.
