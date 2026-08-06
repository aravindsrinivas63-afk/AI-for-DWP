# Ticket Triage — T-1004

**Ticket:** T-1004  
**Subject:** Company app fails to install from Company Portal, error 0x87D1041C  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, usernames, app names, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary
A user is unable to install an application from the Intune Company Portal; the installation fails with error code 0x87D1041C.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single user (role/team not specified) |
| How many | 1 confirmed; to-verify whether the same app fails for other users |
| Business urgency | Medium — user blocked from required application; workaround availability unknown |
| Wider risk | To-verify — if the app deployment itself is broken in Intune, all targeted users will fail |

---

## Known Facts

- User is using Intune Company Portal to install an application
- Installation fails with error **0x87D1041C**
- This error code is publicly documented as a general Intune app installation failure relating to the Intune Management Extension (IME) or app detection rule mismatch *(to-verify against current Microsoft documentation)*
- No further detail on the specific application captured yet

---

## Missing Information to Gather

1. Which application is the user trying to install? *(needed to check Intune app deployment status)*
2. Has the user ever successfully installed this app on this device before?
3. Is the device fully Intune-enrolled and compliant? *(to-verify in Intune portal)*
4. Has the device been restarted recently? *(IME issues often resolve after restart)*
5. What OS version and build is the device running?
6. Is the Intune Management Extension (IME) service running on the device? *(to-verify)*
7. Are other apps from Company Portal installing successfully on the same device?

---

## Likely Category

**Intune / Company Portal — App deployment failure (IME error or app detection rule mismatch)**

Secondary possibility: Device compliance issue blocking app assignment; stale Intune policy sync. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real device names, Intune tenant details, or app deployment configurations into this or any AI tool.**

1. Ask the user to **restart the device** and retry the installation — IME-related failures frequently clear on reboot.

2. If the issue persists, check the **Intune portal** for the device:
   - Device compliance status
   - App installation status for the affected application
   - Any reported errors against the device or app assignment

3. On the device, check whether the **Intune Management Extension** service is running:

```
Get-Service -Name IntuneManagementExtension
```

If the service is stopped, attempt to start it and retry the installation.
