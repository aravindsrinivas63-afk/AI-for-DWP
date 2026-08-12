# Finance-Win11 Startup Performance Drop – Cause Analysis

**Device Group:** Finance-Win11 (215 devices)  
**Signal:** Median startup time doubled from ~18s to ~43s overnight 2026-08-03 → 2026-08-04  
**Trigger:** Security baseline configuration profile deployed 2026-08-04 02:00  
**Comparison group:** IT-Win11 (40 devices) — no config change, no degradation  
**Analysis Date:** 2026-08-12  

---

## Ranked Causes

> Ranking weights heavily on the change log and the clean comparison group. Both are strong evidence that the config change is the direct cause. The question is which element of that change — or which combination — accounts for the ~23 second increase.

---

### Cause 1 — Startup Compliance Logging Script Running Synchronously at Login

**Probability: Highest**

**Why it fits the evidence:**

The config change explicitly added a startup script for compliance logging. Windows startup scripts that run in the foreground (synchronously) block the user session from progressing to a usable desktop until the script completes. A 20–25 second script execution is consistent with a script that contacts a compliance endpoint, writes logs, or waits for a network response before releasing control. The timing is exact — degradation begins on 2026-08-04, the same day the script was deployed. IT-Win11 did not receive the script and shows zero change, which eliminates hardware, network, or Windows Update as causes.

**Fastest check to confirm or eliminate:**

On one Finance-Win11 device, open **Event Viewer → Applications and Services Logs → Microsoft → Windows → GroupPolicy → Operational**. Filter for events on 2026-08-04 onwards and look for script execution duration entries at logon. A duration of 20+ seconds confirms this cause. Alternatively, temporarily move one test device out of the Finance-Win11 group (removing the script) and measure startup time.

---

### Cause 2 — Additional Defender Scan Policy Triggering a Resource-Intensive Scan at Login

**Probability: Moderate**

**Why it fits the evidence:**

The config change also deployed an additional Defender scan policy. If this policy is configured to run a scheduled quick or full scan at system startup or user login, it competes heavily for CPU and disk I/O during the exact window measured by the DEX metric (login to usable desktop). Defender scans at startup are a well-documented cause of login slowness on Windows 11, particularly on devices with large local profiles or spinning disks. The timing again matches exactly — no degradation before the policy was applied, sustained degradation afterwards. IT-Win11, which did not receive the policy, is unaffected.

**Fastest check to confirm or eliminate:**

On an affected device, open **Task Manager** immediately after login and observe CPU and disk usage. If disk is at 90–100% for 20–30 seconds post-login and drops once the startup period ends, Defender is likely the cause. Alternatively, check **Windows Security → Virus & Threat Protection → Protection History** for scan timestamps that align with login events. You can also review **Event Viewer → Microsoft → Windows → Windows Defender → Operational** for scan start/end times on login dates.

---

### Cause 3 — Compound Effect of Both Policies Running Concurrently at Login

**Probability: Moderate (as a secondary amplifier)**

**Why it fits the evidence:**

The config change deployed two policies simultaneously — the compliance script and the Defender scan policy. If both execute concurrently at login, their combined CPU and disk I/O demand may be greater than either alone. The ~23 second increase is large; it is plausible that neither policy alone accounts for the full magnitude, and that resource contention between the two creates a compounding delay. This explains why the drop is sustained and consistent across three days (2026-08-04–06) rather than recovering — both policies run on every login. IT-Win11's clean baseline rules out any external factor; the compound effect lives entirely within the deployed config.

**Fastest check to confirm or eliminate:**

After identifying which policy is primary (Causes 1 and 2 above), disable one policy at a time on a test device and measure startup time after each change. If disabling one policy alone reduces startup from ~43s back to ~18s, that is the dominant cause. If it drops only partially (e.g., to ~30s), both are contributing and must both be addressed.

---

## Recommended Investigation Order

1. Check Event Viewer for startup script execution duration (Cause 1) — takes under 5 minutes on one device.
2. Check Task Manager disk/CPU at login and Defender scan logs (Cause 2) — takes under 5 minutes alongside step 1.
3. If both show activity, test device removal from each policy in sequence (Cause 3).

Do not roll back the configuration until the dominant cause is confirmed — a targeted fix (e.g., making the script asynchronous, or rescheduling the Defender scan to outside login windows) is preferable to removing the security baseline entirely.

---

## What the Evidence Rules Out

| Candidate | Ruled Out Because |
|-----------|-------------------|
| Windows Update | IT-Win11 unaffected; both groups on same update ring |
| Network degradation | IT-Win11 on same network, no change in startup time |
| Hardware failure | 215 devices affected simultaneously overnight; not a hardware pattern |
| User behaviour change | Onset is overnight, before users arrive; rules out user-driven cause |
