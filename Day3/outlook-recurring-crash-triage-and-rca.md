# Ticket Triage and RCA - Recurring Outlook Crash

**Ticket:** To confirm  
**Subject:** Outlook recurring crash with APPCRASH / AccessViolation  
**Analyst role:** Senior Digital Workplace Analyst and Windows Application Support Engineer  
**Date:** 2026-08-06

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary

Outlook (Office 16 build 16.0.17126.20132) is crashing repeatedly within minutes of launch. The crash signature is consistent across events: `OUTLOOK.EXE` faulting in `KERNELBASE.dll` with exception `0xc0000005` (access violation), followed by WER APPCRASH telemetry and a .NET Runtime unhandled `System.AccessViolationException`.

This is a recurring and likely deterministic failure path rather than an isolated transient crash.

---

## Impact

| Field | Detail |
|---|---|
| User impact | User cannot keep Outlook running reliably; likely mail/calendar workflow disruption |
| Frequency observed | 2 crashes in ~3 minutes in the supplied logs |
| Severity | High for affected user/device if reproducible every launch |
| Business risk | Loss of productivity and potential incident spread if caused by shared add-in/profile baseline |

---

## Evidence Extracted from Logs

1. **Application Error (Event ID 1000) - 09:14:22**
   - Faulting application: `OUTLOOK.EXE` `16.0.17126.20132`
   - Faulting module: `KERNELBASE.dll` `10.0.22621.3155`
   - Exception code: `0xc0000005`
   - Fault offset: `0x000000000003a4b2`
   - Report ID: `a3c2f1d4-89bb-4e21-91d7-f2c3a1b09e44`

2. **Application Error (Event ID 1000) - 09:17:45**
   - Same crash signature: Outlook + KERNELBASE + `0xc0000005` + same offset

3. **Windows Error Reporting (Event ID 1001) - 09:18:01**
   - APPCRASH fault bucket generated (`Fault bucket 1847362910`)

4. **.NET Runtime (Event ID 1026) - 09:18:05**
   - Process terminated due to unhandled exception
   - Exception type: `System.AccessViolationException`

---

## Correlated Timeline

1. Outlook starts at 09:13:44.
2. First APP crash recorded at 09:14:22.
3. Second crash recorded at 09:17:45 with identical signature.
4. WER APPCRASH telemetry records fault bucket at 09:18:01.
5. .NET runtime logs unhandled access violation at 09:18:05.

Interpretation: repeated launches or immediate relaunch attempts hit the same failure path.

---

## Technical Interpretation

- `0xc0000005` indicates invalid memory access (read/write/execute violation).
- `KERNELBASE.dll` as faulting module is often where the exception is surfaced, not always the true business-logic origin.
- The repeated identical fault offset strongly suggests a stable trigger (for example an add-in code path, profile corruption, damaged Office component, or injected third-party module).
- The .NET `AccessViolationException` supports the possibility of managed/unmanaged boundary failure (COM add-in, VSTO add-in, security hook, or native dependency issue).

---

## Most Likely Root Cause (Ranked)

1. **Outlook add-in or extension conflict (highest probability)**
   - Deterministic, repeated crash pattern shortly after startup is typical of add-in initialization failure.

2. **Corrupted Outlook profile / OST interaction path**
   - Startup-stage crashes can be profile-store-triggered, especially when loading folders, search index hooks, or MAPI providers.

3. **Office build issue or partially corrupted Office binaries**
   - Same build and repeatable signature can indicate damaged Office installation or known regression in that channel build.

4. **Third-party endpoint/security DLL injection conflict**
   - Security/AV/DLP plugins that hook Outlook APIs can cause access violations under certain update combinations.

5. **OS-level corruption (lower probability with current evidence)**
   - Possible, but current data is more app-path specific than broad OS instability.

---

## Confidence Assessment

- **High confidence** that this is a recurring application-level crash pattern.
- **Medium confidence** that add-in or Outlook startup integration is the primary trigger.
- **Lower confidence** in OS kernel component defect as primary cause without wider system crash evidence.

---

## Recommended Triage and Remediation Sequence

1. Launch Outlook in safe mode (`outlook.exe /safe`).
   - If stable in safe mode, treat add-ins/integrations as primary suspect.

2. Disable COM add-ins in staged batches.
   - Re-enable one-by-one to isolate offending add-in.

3. Create a new Outlook profile and test with cached mode.
   - If resolved, old profile/OST path is likely corrupt.

4. Run Office Quick Repair, then Online Repair if needed.
   - Validate Office files and registration.

5. Update Office to latest approved enterprise channel build.
   - If already current, compare against known bad build advisories.

6. Check endpoint protection/DLP plugins and recent agent updates.
   - Temporarily isolate policy/module (as per security governance) to test conflict hypothesis.

7. Run system integrity checks if still unresolved.
   - `sfc /scannow`
   - `DISM /Online /Cleanup-Image /RestoreHealth`

8. Collect crash dumps for escalation.
   - Capture user-mode dumps for `OUTLOOK.EXE` and map stack frames to add-in or module owner.

---

## What to Collect for Escalation

1. Full Event Viewer export around crash window (Application + System).
2. Outlook add-in inventory (enabled/disabled state, versions, publishers).
3. Office channel/build history and recent update timestamps.
4. EDR/AV/DLP client version and policy change timeline.
5. ProcDump or WER crash dump with symbolized call stack.

---

## Conclusion

The supplied logs show a repeatable Outlook APPCRASH pattern with identical access violation characteristics, indicating a persistent startup/runtime trigger rather than random instability. The highest-probability root-cause class is add-in or integration conflict, followed by profile corruption and Office component integrity issues. Prioritize safe-mode validation, add-in isolation, and profile/Office repair, then escalate with crash dumps if unresolved.
