# Ticket Triage and RCA - RDP Connection Failure and Account Lockout

**Ticket:** To confirm  
**Subject:** RDP authentication failures leading to account lockout, followed by recovery  
**Analyst role:** Senior Digital Workplace Analyst and Windows Application Support Engineer  
**Date:** 2026-08-06

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real device names, usernames, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary

The logs show repeated RDP authentication failures from client `10.10.5.44` for account `FINBRIDGE\\bwalker`, resulting in account lockout (`4740`). A later connection from the same client succeeds (`4624`), indicating the service path recovered after credential correction and/or account unlock.

The initial TermDD protocol stream error (`56`) aligns with failed security negotiation during invalid credential attempts and is secondary to the dominant authentication failure pattern.

---

## Impact

| Field | Detail |
|---|---|
| User impact | User unable to establish RDP session during incident window |
| Security impact | Repeated failed remote interactive logons; lockout policy triggered |
| Scope observed | Single user and single source IP in provided logs |
| Severity | Medium to high (availability + identity lockout) |

---

## Evidence Extracted from Logs

1. **System / TermDD / Event ID 56 - 14:01:02**
   - Terminal Server security layer detected protocol stream error and disconnected client `10.10.5.44`.

2. **System / RdpCoreTS / Event ID 140 - 14:01:02**
   - Connection from `10.10.5.44` failed due to incorrect username or password.

3. **Security / Event ID 4625 - 14:01:04**
   - Account `FINBRIDGE\\bwalker` failed logon.
   - Failure reason: unknown username or bad password.
   - Logon type: `10` (`RemoteInteractive`).
   - Source IP: `10.10.5.44`.

4. **Security / Event ID 4625 - 14:03:18**
   - Second failed remote interactive authentication from same source.

5. **Security / Event ID 4625 - 14:05:33**
   - Third failed remote interactive authentication from same source.

6. **Security / Event ID 4740 - 14:05:34**
   - Account `FINBRIDGE\\bwalker` locked out.
   - Caller/source computer: `10.10.5.44`.

7. **System / RdpCoreTS / Event ID 131 - 14:22:07**
   - Server accepted new TCP connection from `10.10.5.44:52341`.

8. **Security / Event ID 4624 - 14:22:09**
   - Successful `RemoteInteractive` logon for `FINBRIDGE\\bwalker` from `10.10.5.44`.

---

## Correlated Timeline

1. 14:01:02: RDP handshake/session setup shows security-layer/protocol disconnect (TermDD 56) and explicit bad credential warning (RdpCoreTS 140).
2. 14:01:04 to 14:05:33: Three `4625` remote interactive failures for same account and source IP.
3. 14:05:34: Lockout threshold reached; `4740` account lockout triggered.
4. 14:22:07 to 14:22:09: New TCP connection accepted and successful `4624` remote interactive sign-in from same source.

Interpretation: incident is consistent with repeated invalid credential submissions from one client, causing policy lockout; later successful login confirms eventual credential/account-state correction.

---

## Technical Interpretation

- `4625` with logon type `10` is definitive evidence of failed RDP credential authentication.
- `4740` immediately following repeated failures confirms lockout policy enforcement.
- `RdpCoreTS 140` directly states username/password incorrect and aligns with `4625` entries.
- `TermDD 56` often appears when secure channel/protocol stream handling fails; in this context it is likely a side-effect of failed auth/session negotiation rather than a standalone transport outage.
- Later `4624` success from same source IP materially lowers probability of persistent network path or RDP service outage.

---

## Most Likely Root Cause (Ranked)

1. **Repeated bad credentials entered or submitted from RDP client (highest probability)**
   - Strongly supported by multiple `4625` and `RdpCoreTS 140`.

2. **Stale cached credentials in RDP client or credential manager**
   - Common source of repeated failures from a single endpoint.

3. **Keyboard layout/domain format mismatch at sign-in prompt**
   - Can produce rapid repeated bad password events despite user intent.

4. **Automated reconnection/task using outdated credentials**
   - Possible when RDP files/scripts retain old secrets.

5. **Primary RDP protocol/security stack issue (lower probability)**
   - Less likely given eventual success from same client and account.

---

## Confidence Assessment

- **High confidence** in credential-driven lockout sequence.
- **Medium confidence** on exact origin (manual entry vs cached credential replay).
- **Low confidence** that network transport or RDP service failure is primary root cause.

---

## Recommended Triage and Remediation Sequence

1. Restore access safely.
   - Confirm account unlock per standard IAM process.
   - Verify user can sign in once with known-good credentials.

2. Eliminate stale credential sources on client `10.10.5.44`.
   - Remove saved RDP credentials from Credential Manager.
   - Review stored `.rdp` files and scripts for embedded/old username hints.

3. Validate account sign-in format and context.
   - Confirm `FINBRIDGE\\bwalker` UPN/SAM format expected by target host.
   - Confirm keyboard layout and Caps/Num lock state during sign-in.

4. Check lockout policy and failed-attempt threshold.
   - Confirm observed failure count matches domain policy.
   - Verify no unintended strict policy recently applied.

5. Hunt for non-interactive credential replay.
   - Review scheduled tasks, mapped resources, or background apps using same account.

6. Confirm no broader RDP security posture regression.
   - Review NLA and RDP hardening settings for recent changes.
   - Correlate TermDD 56 frequency across other users/hosts.

---

## What to Collect for Escalation

1. Security log export including `4625`, `4740`, `4624` around incident window.
2. RDP operational logs from client and target host.
3. Credential Manager state and recent RDP file usage on source endpoint.
4. Domain lockout policy snapshot and effective policy results.
5. Any recent changes to account password, MFA/conditional access, or sign-in restrictions.

---

## Risk Notes

- Repeated failed RDP attempts can mimic brute-force patterns and may trigger SOC alerts.
- Unlocking without removing stale credential sources leads to immediate re-lockout loops.
- If reused password patterns exist, lateral lockouts across services are possible.

---

## Conclusion

This incident is best explained by repeated invalid RDP credential attempts from `10.10.5.44` for `FINBRIDGE\\bwalker`, culminating in account lockout as designed by policy. The later successful remote interactive logon from the same source confirms recovery after credential/account-state correction. Prioritize stale credential cleanup and lockout-policy-aligned user guidance to prevent recurrence.
