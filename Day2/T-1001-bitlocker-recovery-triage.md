# Ticket Triage — T-1001

**Ticket:** T-1001  
**Subject:** New Win11 laptop — BitLocker prompting for recovery key every boot  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** This triage was drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, usernames, asset tags, or internal identifiers were used. All outputs are treated as a draft and must be verified before action.

---

## Summary
New Win11 device is triggering a BitLocker recovery prompt on every boot, blocking the user from accessing their laptop without manual key entry.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single named user (new starter or reissued device) |
| How many | 1 device currently reported |
| Business urgency | High — user is blocked from working at every boot; productivity fully impaired |
| Wider risk | To-verify — if this is an imaging/provisioning pattern, other new devices may be affected |

---

## Known Facts

- Device is a new Win11 laptop (recently provisioned or reissued)
- BitLocker is active on the device (expected for DWP endpoints)
- Recovery key prompt appears at every boot — not a one-off event
- User does not have frictionless access; recovery key is required each time

---

## Missing Information to Gather

1. Has the device ever booted successfully without the recovery prompt, or has this happened since first use?
2. Is the device Intune/Azure AD joined — and has enrolment completed fully? *(to-verify — incomplete join can break TPM trust)*
3. Was the device re-imaged, transferred from another user, or issued new from stock?
4. Has any hardware change occurred (RAM swap, dock, USB-C adapter at boot)? *(to-verify — some peripherals can alter measured boot state)*
5. Is the BitLocker recovery key escrowed in Azure AD / Intune — can it be retrieved from the portal? *(to-verify)*
6. What is the exact point in boot where the prompt appears — before or after the Windows login screen?

---

## Likely Category

**BitLocker / Endpoint Encryption — TPM PCR measurement mismatch (new device provisioning)**

Secondary possibility: Intune/Azure AD enrolment incomplete, preventing TPM-backed key protector from sealing correctly. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter the actual recovery key or any user credentials into this or any AI tool.**

1. From another device or the service desk portal, check whether a BitLocker recovery key is escrowed against this device in **Azure AD / Intune**.
2. If a key is present, use it to unlock the device for this session.
3. Once logged in, open an elevated command prompt and run:

```
manage-bde -status C:
```

Review the output for:
- Key protectors listed (TPM, TPM+PIN, Password, Recovery Password)
- Protection status (On / Off)
- Whether a TPM protector is present and active

This confirms whether the TPM protector is correctly registered or if re-sealing / re-enrolment is needed before escalating to the endpoint team.
