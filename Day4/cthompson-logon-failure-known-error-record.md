# Known-Error Record - cthompson Logon Failure

Symptom : FINBRIDGE\cthompson is unable to log in. During the incident window, logon attempts failed and later returned account locked out.

Cause : Repeated wrong-password authentication attempts against FINBRIDGE\cthompson triggered account lockout. Additional wrong-password Kerberos pre-authentication attempts from source IP 10.10.8.112 continued after lockout.

Scope : The incident affected a single user only: FINBRIDGE\cthompson. The observed endpoint/system context was DESKTOP-FB022 for interactive failures, with additional Kerberos failures from source IP 10.10.8.112.

Workaround : Apply account recovery to restore access by re-enabling the locked account. Then validate interactive sign-in from DESKTOP-FB022 to confirm service restoration.

Permanent fix: Use the lockout triage and prevention steps from the RCA: identify and isolate secondary bad-password sources before or during unlock/reset, and require post-recovery verification of account-state change plus successful interactive logon. Ensure the user updates stored credentials on all devices/services if repeated bad-password attempts are detected after recovery.

How to spot it: Look for this sequence: Event 4776 wrong password (0xC000006A), repeated Event 4625 bad password, then Event 4740 account lockout, and continued Event 4771 Kerberos pre-auth failures (0x18 wrong password) from a secondary source. Recovery is confirmed by Event 4722 account enabled followed by Event 4624 successful interactive logon.
