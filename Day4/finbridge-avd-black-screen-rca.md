# Root Cause Analysis — FinBridge AVD Black Screen Incident

**Incident:** AVD black screen after login in Finance host pool  
**Reported by:** Maria Lopez, Finance (ext 4421)  
**Scope:** POOL-FIN-01  
**Date logged:** 2024-03-15  
**Analyst role:** DWP Service Desk

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real hostnames, tenant details, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary

Users in Finance host pool POOL-FIN-01 experienced a black screen immediately after AVD sign-in. In the reported case the screen recovered after about 30 seconds, but other users in the same pool reported that the screen never returned and they had to call for support. The issue began this morning and did not affect POOL-FIN-02.

The most likely cause is a regression introduced by the overnight image update applied to POOL-FIN-01 at 02:00, with symptoms consistent with a graphics driver or host image issue affecting that pool only.

---

## Incident Impact

| Field | Detail |
|---|---|
| Who affected | Multiple Finance users on POOL-FIN-01 |
| How many | About 40% of POOL-FIN-01, based on the incident notes |
| Business impact | Login disruption, delayed access to desktop sessions, helpdesk calls |
| Wider risk | Limited to the updated pool; POOL-FIN-02 was not included in the update wave and was unaffected |

---

## Known Facts

- The symptom is a black screen after AVD login
- The first report was around 07:00
- The problem started this morning and was not present yesterday
- One user saw recovery after about 30 seconds
- Other users in the same pool reported that the black screen did not recover
- The affected pool is POOL-FIN-01
- POOL-FIN-02, including the IT team, was not included in the overnight update wave and was fine
- A recent image update was applied to POOL-FIN-01 at 02:00
- The issue appears to affect multiple users in the same pool rather than a single user profile

---

## Most Likely Cause

The most likely cause is the overnight image update to POOL-FIN-01 introducing a graphics/display regression in the session host image.

This aligns with the pattern in the incident notes: the issue began immediately after the update window, it is limited to one host pool, and another pool on the same platform was unaffected because it was not updated.

### Evidence

- Symptom began the same morning as the overnight image update
- Only POOL-FIN-01 is affected
- POOL-FIN-02 was not part of the update wave and remained healthy
- Multiple users are affected, which points away from a single-user profile issue
- Black screen after AVD login is consistent with a host image, session host, or graphics driver problem

### What is not yet proven

- The notes do not include host logs, event IDs, or a formal image version comparison
- The specific failing component is not confirmed; graphics driver regression is the most likely explanation, but not proven from the incident notes alone
- The exact percentage affected is an estimate from the incident notes, not a measured total

---

## Event / Incident Sequence

1. An overnight image update was applied to POOL-FIN-01 at 02:00.
2. By around 07:00, users in POOL-FIN-01 began reporting a black screen after AVD login.
3. One user recovered after about 30 seconds, suggesting the session could eventually initialize on some hosts.
4. Other users reported that the black screen never returned and they had to contact support.
5. POOL-FIN-02 remained unaffected because it was not included in the update wave.

---

## 5 Whys Analysis

**Why did users see a black screen after login?**  
Because the AVD session was not completing normal desktop display initialization.

**Why was display initialization not completing normally?**  
Because the updated session host image in POOL-FIN-01 likely introduced a graphics or display-related regression.

**Why is the image update the leading suspect?**  
Because the issue started immediately after the overnight update and only the updated pool was affected.

**Why were some sessions delayed rather than permanently black?**  
Because the fault may have been intermittent or host-dependent, with some sessions eventually recovering after startup delays while others did not.

**Why did the problem not affect POOL-FIN-02?**  
Because POOL-FIN-02 was not included in the update wave, so it did not receive the likely faulty image change.

---

## Contributing Factors

- Overnight image change on the affected pool
- Pool-specific exposure rather than platform-wide exposure
- Symptoms appearing immediately after the update window
- No evidence in the notes of a user-specific profile issue

---

## Recommended Follow-Up Checks

1. Compare the image version and driver set on POOL-FIN-01 against POOL-FIN-02.
2. Review AVD session host logs for graphics, display, or shell initialization errors on the affected pool.
3. Confirm whether the issue resolves after rolling back or replacing the updated image.
4. Check whether the affected hosts show a consistent driver or image build pattern.
5. Verify whether Microsoft or the image pipeline documented any known issue with the update applied at 02:00.

---

## 5-Point RCA Conclusion

1. The incident affected multiple users in POOL-FIN-01 after login.
2. The issue started the same morning as an overnight image update.
3. POOL-FIN-02 was unaffected because it was not included in the update wave.
4. The symptom pattern is most consistent with a host image or graphics regression.
5. The most likely root cause is the updated POOL-FIN-01 image, pending confirmation from host logs and image comparison.

---

## Appended Event Details

- `07:02:10` Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: session logon succeeded for `FINBRIDGE\mlopez` on SHFIN-01-A.
- `07:02:14` Microsoft-Windows-Kernel-General Event 1: system boot time recorded as `2024-03-15 02:03:11`, matching the overnight image update window.
- `07:02:16` Application Error Event 1000: `dwm.exe` faulted in `igdumd64.dll` with exception code `0xc0000005`.
- `07:02:17` Microsoft-Windows-TerminalServices-LocalSessionManager Event 40: the session disconnected immediately after the DWM fault.
- `07:02:18` Desktop Window Manager Event 9009: DWM exited with code `0x40010004`.
- `07:02:44` Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: reconnect succeeded for the same session.
- `07:02:46` Application Error Event 1000: the same `dwm.exe` / `igdumd64.dll` crash repeated.
- `07:02:47` Microsoft-Windows-TerminalServices-LocalSessionManager Event 40: the session disconnected again.
- `07:03:01` Desktop Window Manager Event 9009: DWM exited again.
- `07:03:10` Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: second reconnect succeeded.
- `07:08:22` Microsoft-Windows-TerminalServices-LocalSessionManager Event 21: another Finance user logged on successfully to the same host pool.
- `07:08:24` Application Error Event 1000: `dwm.exe` faulted again in `igdumd64.dll` for the second user.
- Comparison host SHFIN-02-A on POOL-FIN-02 showed `07:01:46` Event 21 and `07:01:46` Event 9011, with Desktop Window Manager starting successfully and no application errors.

---

## Reviewed Hypothesis

The surviving hypothesis is now more specific: a graphics/display driver regression in the updated POOL-FIN-01 image, with `igdumd64.dll` causing Desktop Window Manager to crash during session startup.

### Why this survives the evidence

- The failure repeats on the same host pool after logon and is tied to `dwm.exe`, not a general shell or profile error.
- The same module fault appears across multiple sessions and multiple users.
- The unaffected pool remained on the pre-update image and did not show the crash pattern.
- The timing aligns with the overnight image change, which makes the updated image the fault boundary.

### Why other hypotheses were lowered

- Session shell delay is weakened because logon already succeeds before the crash.
- Profile load regression is not directly evidenced by any profile-specific event.
- Generic host contention is weaker than a named module fault in `igdumd64.dll`.
- Logon script or GPO issues are not reflected in the event set and do not explain the DWM crash pattern.

---

## Resolution Notes

1. Stop or drain new logons to POOL-FIN-01 while the faulty image remains in use.
2. Roll back POOL-FIN-01 to the last known good image or rebuild it from the pre-update baseline.
3. If the image included a graphics driver change, restore the known-good driver version.
4. Reboot the affected hosts so the graphics stack and DWM restart cleanly.
5. Retest with at least two user logons and confirm that `Event 1000` and `Event 9009` no longer recur.
6. Validate that POOL-FIN-01 now behaves like POOL-FIN-02 before returning the pool to service.

