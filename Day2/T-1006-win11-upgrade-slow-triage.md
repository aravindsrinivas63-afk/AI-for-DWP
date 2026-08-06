# Ticket Triage — T-1006

**Ticket:** T-1006  
**Subject:** "Everything is slow" — user upgraded to Win11 two days ago  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary
A user reports generalised system slowness across all activity following a Windows 11 upgrade completed two days ago.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single user (role/team not specified) |
| How many | 1 confirmed; to-verify whether other users in the same upgrade batch are affected |
| Business urgency | Medium — user is degraded but still able to work; escalates if unresolved |
| Wider risk | To-verify — if this is a batch upgrade issue, multiple users could be in the same state silently |

---

## Known Facts

- User was recently upgraded from a previous OS to Windows 11
- Upgrade completed approximately two days ago
- Slowness is described as general ("everything") — not application-specific
- Two days post-upgrade is a known period of background activity (indexing, policy re-application, profile migration, Windows Update)

---

## Missing Information to Gather

1. Is the device a physical laptop/desktop or a VDI/AVD session? *(VDI session performance is not a device issue)*
2. Has the device been restarted since the upgrade? *(pending restart can leave background tasks running)*
3. What does Task Manager show as the top CPU, RAM, and Disk consumers right now?
4. Has Windows Update completed all post-upgrade updates, or are updates still pending?
5. Is OneDrive or any backup/sync client running and actively syncing?
6. What was the device's performance like before the upgrade — was it already borderline on hardware spec for Win11?
7. Has any endpoint security product re-run a full scan post-upgrade? *(to-verify — common cause of post-upgrade slowness)*

---

## Likely Category

**Windows 11 Upgrade — Post-upgrade background processing (indexing, updates, profile migration, AV scan)**

Secondary possibility: Hardware marginally below Win11 recommended spec; driver incompatibility post-upgrade causing high CPU/disk usage. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real device names, usernames, or performance log output from DWP devices into this or any AI tool.**

1. Ask the user to open **Task Manager** (`Ctrl+Shift+Esc`) and go to the **Performance** tab — note CPU, RAM, Disk, and GPU utilisation percentages.

2. Switch to the **Processes** tab, sort by **Disk** and then **CPU** — identify the top offending process and report back.

3. Check whether **Windows Update** shows pending downloads or installs (`Settings > Windows Update`) — if updates are still running, advise the user to allow overnight processing and retest the following morning before further investigation.
