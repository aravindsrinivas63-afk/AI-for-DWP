# Ticket Triage — T-1003

**Ticket:** T-1003  
**Subject:** AVD session disconnects after ~10 min, then reconnects  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real hostnames, session host names, tenant details, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary
A user's Azure Virtual Desktop (AVD) session drops approximately every 10 minutes before automatically reconnecting, causing repeated disruption to their working session.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single user (role/team not specified) |
| How many | 1 confirmed; to-verify whether other AVD users on same host pool are affected |
| Business urgency | Medium-High — repeated disconnections disrupt productivity and may cause unsaved work loss |
| Wider risk | To-verify — a session host or network issue could affect all users on that host pool |

---

## Known Facts

- User is on an AVD session (not a physical device issue)
- Disconnections occur consistently at approximately 10 minutes
- Session reconnects automatically after disconnection
- Consistent interval suggests a timeout policy or session limit rather than random network drop

---

## Missing Information to Gather

1. Is the ~10 minute interval consistent on every occurrence, or approximate? *(consistent = policy-driven; variable = network/resource)*
2. What client is the user connecting from — Windows App, Remote Desktop client, or browser?
3. Is the user on a corporate network, VPN, or home broadband?
4. Are other users on the same host pool experiencing the same issue? *(to-verify with host pool admin)*
5. Does the session reconnect to the same session or start a fresh one? *(indicates disconnect vs. logoff)*
6. Has anything changed recently — new device, network change, or AVD policy update? *(to-verify)*

---

## Likely Category

**Azure Virtual Desktop — Session timeout / idle disconnect policy or network instability**

Secondary possibility: Host pool session limit policy set to 10 minutes idle; local network MTU/packet loss causing periodic drop. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real session host names, host pool names, or tenant identifiers into this or any AI tool.**

1. Ask the user to note **exactly what they are doing** in the 2 minutes before a disconnect — if they are idle, an idle timeout policy is the most likely cause.

2. Check the **AVD host pool RDP properties and session time limit policies** (via Azure Portal or Intune/GPO) for:
   - Idle session limit
   - Active session time limit
   - Disconnected session limit

3. If policies appear correct, ask the user to run a continuous ping to a known internal address during the session to determine whether the underlying network drops at the same interval. *(to-verify whether network diagnostics are permitted under DWP policy)*
