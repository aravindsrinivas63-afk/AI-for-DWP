# cthompson Logon Incident - Audience Communications

## Audience 1 - Non-technical executive

Your access is restored and your data is safe. On 15 March, only cthompson was affected when repeated wrong-password attempts from device DESKTOP-FB022 caused account lockout around 08:40, and another device continued wrong-password attempts during the same period. Helpdesk re-enabled the account at 09:08:14, and successful sign-in was verified at 09:09:01 from DESKTOP-FB022, with no further issues reported. No action needed.

## Audience 2 - Affected end-user team (10 people, non-technical)

Hi team, access is restored and data is safe. What happened: on 15 March around 08:40, only cthompson was blocked from signing in after repeated wrong-password attempts from device DESKTOP-FB022 locked the account, while another device continued wrong-password attempts during the same period. Helpdesk re-enabled the account at 09:08:14, and sign-in succeeded at 09:09:01 from DESKTOP-FB022 with no further issues reported. If you see this, contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Scope/config detail:
- User: FINBRIDGE\cthompson only.
- Primary endpoint: DESKTOP-FB022.
- Incident start: ~08:40 on 2024-03-15.

Root cause:
- Repeated bad-password attempts for FINBRIDGE\cthompson caused account lockout.
- Additional bad-password attempts continued from a secondary source during the same incident window.

Exact action taken:
- Helpdesk performed account recovery by enabling the account at 09:08:14 (Event 4722).
- Service validation performed via interactive logon test from DESKTOP-FB022.

Verification step:
- Successful interactive logon recorded at 09:09:01 from DESKTOP-FB022 (Event 4624).
- User confirmed working and no further issues were reported.

Preventive action needed:
- Add lockout triage to identify and isolate any secondary bad-password source before unlock/reset.
- Require post-recovery verification of account state change and successful interactive logon.
- Document and monitor the lockout pattern: repeated 4776/4625, then 4740, with continued 4771 attempts.
- Require user credential updates on all devices/services when repeated post-recovery bad-password attempts are detected.
