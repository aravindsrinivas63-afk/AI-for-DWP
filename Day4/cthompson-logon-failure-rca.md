# Root Cause Analysis - cthompson Logon Failure Incident

## Incident
- Incident: User logon failure for FINBRIDGE\cthompson
- Affected user scope: Single user (cthompson only)
- Start time: ~08:40 on 2024-03-15
- Resolution time: 09:09 AM on 2024-03-15
- Status: Resolved and verified

## Summary
FINBRIDGE\cthompson was unable to log in starting around 08:40. Security events show repeated wrong-password attempts followed by account lockout, with additional Kerberos wrong-password attempts from a second source IP.

The applied account recovery action restored service. Resolution was verified by successful interactive logon at 09:09:01, and no further issues were reported.

## Supporting Evidence

### Failure evidence
- 08:44:01 Security Event 4776 Audit Failure: domain credential validation failed for FINBRIDGE\cthompson with error 0xC000006A (wrong password), source workstation DESKTOP-FB022.
- 08:44:03 Security Event 4625 Audit Failure: unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:28 Security Event 4625 Audit Failure: unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:55 Security Event 4625 Audit Failure: unknown user name or bad password, logon type 2, source DESKTOP-FB022.
- 08:44:56 Security Event 4740 Audit Failure: user account FINBRIDGE\cthompson locked out, caller computer DESKTOP-FB022.
- 08:45:10 Security Event 4625 Audit Failure: failure reason account locked out, logon type 7, source DESKTOP-FB022.
- 08:45:44 Security Event 4771 Audit Failure: Kerberos pre-authentication failed for FINBRIDGE\cthompson, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:01 Security Event 4771 Audit Failure: Kerberos pre-authentication failed, code 0x18, source IP 10.10.8.112.
- 08:46:33 Security Event 4771 Audit Failure: Kerberos pre-authentication failed, code 0x18, source IP 10.10.8.112.

### Recovery and verification evidence
- 09:08:14 Security Event 4722 Audit Success: user account FINBRIDGE\cthompson was enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 Security Event 4624 Audit Success: FINBRIDGE\cthompson successfully logged on (logon type 2 interactive) from DESKTOP-FB022.
- Operational confirmation: User was verified logging in to host and no issues were reported after recovery.

## Timeline
- ~08:40: User-reported inability to log in begins.
- 08:44:01: First captured wrong-password validation failure (Event 4776).
- 08:44:03-08:44:55: Repeated interactive logon failures (Event 4625).
- 08:44:56: Account lockout occurs (Event 4740).
- 08:45:10: Unlock attempt blocked because account is locked (Event 4625, logon type 7).
- 08:45:44-08:46:33: Additional Kerberos wrong-password pre-auth failures continue from source IP 10.10.8.112 (Event 4771).
- 09:08:14: Helpdesk recovery action includes account enablement (Event 4722).
- 09:09:01: Successful interactive logon confirmed (Event 4624).
- 09:09:00 onward: Incident treated as resolved; user confirmed working with no further issue reported.

## Root Cause
The incident was caused by repeated wrong-password authentication attempts against FINBRIDGE\cthompson, which triggered account lockout. Post-lockout, additional wrong-password Kerberos attempts from source IP 10.10.8.112 continued during the incident window.

## 5 Whys Analysis
1. Why could cthompson not log in?
Because authentication attempts were failing and the account became locked.

2. Why did authentication attempts fail?
Because wrong-password attempts were recorded (Event 4776 and Event 4625 bad password failures).

3. Why was login blocked even after further attempts?
Because the account entered locked state (Event 4740), and later attempts returned account locked out (Event 4625).

4. Why did failures continue after lockout?
Because Kerberos pre-auth wrong-password attempts persisted from source IP 10.10.8.112 (Event 4771).

5. Why was service restored?
Because account recovery action was applied (Event 4722), followed by verified successful interactive sign-in (Event 4624 at 09:09:01).

## Resolution Actions Applied
1. Performed helpdesk account recovery action (captured by Event 4722 account enabled).
2. Validated successful user interactive logon on DESKTOP-FB022 (Event 4624 at 09:09:01).
3. Confirmed user access restored and no further issue reported.

## Preventive Actions
1. Add a lockout triage check to identify and isolate any secondary bad-password source (for this incident, source IP 10.10.8.112) before or during unlock/reset.
2. Require post-recovery verification steps: confirm account state change event and a successful interactive logon event.
3. Document this incident pattern in the knowledge base: repeated 4776/4625 followed by 4740 and continued 4771 indicates lockout with ongoing bad-credential attempts.
4. Ask user to update stored credentials on all devices/services they use if repeated wrong-password events are detected after recovery.

## Closure Statement
Resolved. The logon failure was due to repeated wrong-password attempts causing account lockout for FINBRIDGE\cthompson. Account recovery was applied and successful interactive logon was verified at 09:09:01 on 2024-03-15; user confirmed working with no further reported issues.
