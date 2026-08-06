# Ticket Triage and Resolution — Missing Mapped Drives After Win11 Migration

**Subject:** Finance user mapped drives S: and P: missing every morning after Windows 11 migration  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-05

> **AI usage note:** This note was drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real usernames, device names, share paths, domain details, or internal identifiers were used. Treat as a draft record and verify before reuse operationally.

---

## Summary
A Finance user reported that after Windows 11 migration, mapped network drives S: and P: were missing each morning and had to be remapped manually. A logon script existed but appeared not to run reliably post-upgrade.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single Finance user reported |
| How many | 1 confirmed; to confirm whether other migrated users were affected |
| Business urgency | Medium to high — repeated start-of-day disruption to access finance file locations |
| Wider risk | To confirm — may affect other Windows 11 migrated users if tied to policy/logon timing |

---

## Known Facts

- Issue began after Windows 11 migration
- Affected user is in Finance
- Mapped drives affected were S: and P:
- Drives were missing each morning
- User could restore access by remapping manually
- A logon script existed
- Script appeared unreliable after the upgrade, to confirm from logs

---

## Missing Information to Gather

1. Exact user account, device name, and migration date/time
2. Whether issue affected only this user or multiple Finance users/devices
3. Whether user was on office network or VPN at sign-in each morning
4. Sign-in pattern involved: cold boot, restart, lock/unlock, or reconnected session
5. Actual mapping method in use: logon script, Group Policy Preferences, Intune, or hybrid, to confirm
6. Whether the script executed at logon according to logs/events, to confirm
7. Whether any credential prompts, password changes, or access denied errors were seen
8. Whether manual remap lasted for the rest of the day/session
9. Relevant Group Policy, logon, SMB, and network event evidence, to confirm
10. Whether policies related to waiting for network at startup/logon were applied, to confirm

---

## Likely Category

**Windows 11 post-migration drive mapping issue — logon script or policy timing/network readiness problem**

---

## First Diagnostic Step
Confirm whether the logon script actually executes at user sign-in on the affected Windows 11 device by collecting a fresh morning reproduction and checking sign-in-time logs/events. This distinguishes script execution failure from network timing or drive-mapping policy application failure.

---

## Ranked Likely Fixes

### 1. Ensure drive mapping runs after network is ready at sign-in

**Why it is likely**  
Post-Win11 migration and the pattern of missing drives every morning strongly suggested a sign-in timing issue where mapping attempts occurred before domain/network/VPN connectivity was fully available. The existing logon script appearing unreliable also pointed to this.

**Specific check to confirm**
- Check whether S: and P: were absent immediately after sign-in but could be remapped manually without permission errors
- Review sign-in-time policy/script processing evidence showing delayed or failed drive map application because network was not ready, to confirm
- Confirm whether the issue was worse when offsite or when VPN connected after sign-in, to confirm

**Action if confirmed**
- Apply policy/configuration so mapping occurs only after network is established at logon
- Align the mapping mechanism with Windows 11 sign-in sequencing, for example by using synchronous policy processing where appropriate, to confirm
- Re-test across at least 2 morning sign-ins

### 2. Move from legacy logon script mapping to centrally managed drive mapping policy, or repair the existing GPO mapping item

**Why it is likely**  
If the script was unreliable after migration, the mapping method itself may have been too fragile for the upgraded sign-in flow.

**Specific check to confirm**
- Verify the current source of mappings: script-only, Group Policy Preferences, or another management channel, to confirm
- Check whether logs showed script execution inconsistencies or incorrect GPO drive mapping scope/targeting, to confirm
- Confirm the Finance user was in scope for the expected mapping policy, to confirm

**Action if confirmed**
- Standardise mappings through the approved central policy method
- Correct scope, targeting, drive letters, and target paths
- Force policy refresh and validate at next morning sign-in

### 3. Fix user/group targeting or OU/security-filter mismatch introduced post-migration

**Why it is likely**  
Migration can alter device or user placement, causing expected scripts or GPO items not to apply.

**Specific check to confirm**
- Compare applied policies/groups for the affected user/device with a working Finance peer, to confirm
- Validate OU placement, security filtering, WMI filters, and item-level targeting for S: and P:, to confirm
- Confirm whether only migrated users/devices were affected, to confirm

**Action if confirmed**
- Correct OU placement, group membership, or policy filters
- Refresh policy and confirm mapping persistence across multiple sign-ins

### 4. Correct credential or access-token context issues for the network shares

**Why it is likely**  
If authentication context changed during migration, mappings could fail at logon but succeed when remapped manually later.

**Specific check to confirm**
- Review sign-in-time authentication or access-denied events, to confirm
- Check whether manual remap prompted for credentials or used a different context, to confirm
- Validate user permission to the underlying shares remained correct

**Action if confirmed**
- Remove stale credentials or correct the sign-in/authentication context, to confirm
- Correct share or NTFS permissions if needed
- Re-test unattended mapping at next sign-in

### 5. Address Fast Startup or hybrid boot behavior interfering with logon processing

**Why it is likely**  
The every-morning pattern could align with boot-time behavior rather than general session behavior, to confirm.

**Specific check to confirm**
- Compare full restart behaviour with normal morning power-on, to confirm
- Check whether mappings were reliable after restart but not after standard startup

**Action if confirmed**
- Adjust startup/sign-in configuration in line with endpoint standards, to confirm
- Validate across several morning boots

### 6. Resolve drive-letter conflict or competing mapping source

**Why it is likely**  
Multiple mapping mechanisms can create intermittent results, especially after migration.

**Specific check to confirm**
- Verify whether S: or P: were being assigned to unexpected targets or left disconnected
- Confirm whether more than one mapping mechanism was active, to confirm

**Action if confirmed**
- Remove the conflicting mapping source
- Keep one authoritative mapping method and retest

### 7. Repair or redeploy client-side policy/script processing state on the affected endpoint

**Why it is likely**  
If only one migrated device was affected, the local policy processing state may have been inconsistent.

**Specific check to confirm**
- Determine whether other Windows 11 Finance users were unaffected, to confirm
- Compare client-side policy/script processing state with a known-good peer, to confirm

**Action if confirmed**
- Perform endpoint policy/client remediation per standard support process, to confirm
- Validate sign-in mapping behaviour over multiple days

---

## Resolution Outcome

Issue resolved through fix 1.

### Closure Note
Resolved. Cause: Drive mappings for S: and P: were not being applied reliably after the Windows 11 migration because sign-in processing was occurring before network availability was fully established. Action: Modified policy behavior so the device waits for network and related sign-in processing before applying drive mapping actions, then re-tested the mapping behavior. Preventive: Keep the drive-mapping process aligned with Windows 11 sign-in/network readiness behavior for affected users and similar migrated devices to reduce recurrence. User confirmed working.
