# Ticket Triage — T-1005

**Ticket:** T-1005  
**Subject:** Teams audio dead on three machines in the same meeting room  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, room names, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary
Three machines in the same physical meeting room have no audio in Microsoft Teams; the issue is isolated to that room, suggesting a shared environmental or infrastructure cause.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | All users attempting to use Teams in the affected meeting room |
| How many | 3 devices confirmed affected; room capacity may mean more users impacted during calls |
| Business urgency | High — meeting room unusable for Teams calls; impacts collaboration and external meetings |
| Wider risk | Low for wider estate — issue appears room-scoped; to-verify whether shared audio hardware or network segment is the cause |

---

## Known Facts

- Three machines in the same meeting room all have no Teams audio
- Issue is consistent across multiple devices, not a single-device fault
- Physical co-location strongly suggests a shared cause (shared audio device, network policy, or room AV hardware)

---

## Missing Information to Gather

1. Is there a shared meeting room audio device (speakerphone, AV bar, Bluetooth speaker) — and is it powered on and connected?
2. Do the three machines have audio in other applications (e.g., system sounds, browser video), or is it Teams-specific?
3. Does Teams show a microphone/speaker device selected, or does it show no device available?
4. Has any recent change occurred in the room — new hardware, Teams update, or device replacement?
5. Do the affected users have working Teams audio when they move to a different room or use headsets? *(isolates room vs. account/policy)*
6. Is the meeting room on a separate network VLAN or behind different switching? *(to-verify with network team)*

---

## Likely Category

**Microsoft Teams / Endpoint Audio — Shared room audio device failure or Teams audio device selection issue**

Secondary possibility: Teams media policy applied to room network segment blocking audio ports; shared Bluetooth audio device in failed pairing state. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real room names, device hostnames, or network segment details into this or any AI tool.**

1. Test whether audio works **outside Teams** on one of the affected machines (play a system sound or browser video) — this immediately splits a Teams-specific issue from a system audio failure.

2. In Teams, go to **Settings > Devices** and check:
   - Which speaker and microphone are selected
   - Whether the correct room device appears and produces sound via the test function

3. If all three machines show no device or the same failed device, physically inspect and reseat/power-cycle the shared room audio hardware (AV bar, speakerphone, or dock audio).
