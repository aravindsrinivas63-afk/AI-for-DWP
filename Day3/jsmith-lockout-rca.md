# Root Cause Analysis — jsmith Lockout Incident

**Incident:** User lockout during a 30 minute window  
**Account:** jsmith  
**Source workstation:** DESKTOP-FB001  
**Date:** 2026-08-06

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Event ID Meanings

**4625 - An account failed to log on**

This records a failed sign-in attempt. In this incident the failure reason is reported as unknown username or bad password, which means the system rejected the credentials presented for jsmith.

**4740 - A user account was locked out**

This records that the account has been locked after too many failed authentication attempts. The event also shows the computer name that triggered the lockout.

**4722 - A user account was enabled**

This records that an account was re-enabled by an administrative user. It does not by itself unlock the account; it shows that helpdesk-admin performed an account state change.

**4624 - An account successfully logged on**

This records a successful authentication. In this incident it confirms that jsmith was eventually able to log on after the account was restored.

---

## Reconstructed Sequence

1. At 08:02:14, jsmith attempted an interactive logon from DESKTOP-FB001 and the credentials were rejected.
2. At 08:04:22, a second interactive logon attempt failed again from the same workstation.
3. At 08:06:01, the account was locked out, and the lockout was attributed to DESKTOP-FB001.
4. At 08:07:45, an unlock attempt was made, but it failed because the account was still locked out.
5. At 08:22:10, helpdesk-admin enabled the account.
6. At 08:23:44, jsmith successfully logged on with an interactive logon.

---

## Most Likely Cause

The most likely cause of the lockout is repeated bad password attempts for jsmith from DESKTOP-FB001, leading to an account lockout policy being triggered.

### Evidence

- Two 4625 failures occurred before the lockout.
- Both failures show the same account and the same source workstation.
- The 4740 event confirms the account lockout and attributes it to DESKTOP-FB001.
- The later 4625 event explicitly says the account is locked out.
- A successful logon only occurred after helpdesk-admin enabled the account.

### What is not yet proven

- The logs do not prove whether the bad password came from the user typing it manually, a cached credential, a mapped resource, a script, or another stored sign-in.
- The 4722 event shows the account was enabled, but it does not show why the account had been enabled or whether a separate account state issue existed before the lockout.

---

## 5 Whys Analysis

**Why was the user locked out?**  
Because the account hit the lockout threshold after repeated failed logon attempts.

**Why were there repeated failed logon attempts?**  
Because jsmith credentials were rejected more than once from DESKTOP-FB001.

**Why were the credentials rejected?**  
The log reports unknown username or bad password, but it does not prove which one was wrong.

**Why did the issue continue until helpdesk intervention?**  
Because the account remained locked and an unlock attempt failed until helpdesk-admin re-enabled the account.

**Why did the source of the bad attempts need further investigation?**  
Because the event data identifies the workstation but not the exact process or saved credential that produced the failures.

---

## Supporting Notes

- Logon type 2 means an interactive sign-in at the machine.
- Logon type 7 means an unlock attempt.
- The lockout was localised to one workstation in the event data, which makes DESKTOP-FB001 the primary place to investigate stored credentials, reconnect prompts, or user sign-in errors.

---

## Recommended Follow-Up Checks

1. Confirm whether the user had any saved credentials, mapped drives, remote sessions, or scheduled tasks on DESKTOP-FB001.
2. Check whether the user typed the password incorrectly during the sign-in attempts.
3. Review whether any service, app, or Outlook/OneDrive prompt on DESKTOP-FB001 was repeatedly submitting old credentials.
4. Confirm whether the account was intentionally enabled by helpdesk-admin as part of the resolution.
5. Verify whether the domain lockout policy threshold matches the observed number of failed attempts.

---

## Conclusion

This incident is best explained by repeated failed interactive logon attempts from DESKTOP-FB001 causing jsmith to hit the account lockout threshold. The account was later enabled by helpdesk-admin, and the user then successfully logged on. The exact trigger for the bad credentials is not proven by the event log alone and should be verified on the workstation.