# FAULT-A Communications Pack (Three Audiences)

## Audience 1 - Non-Technical Executive (Under 80 Words)
Your access and data are safe. On 2024-03-15, three of four Floor 3 Finance Windows 11 computers did not load company sign-in settings at startup because those devices were given an old server address after an overnight server change. One peer device was unaffected because it had been manually updated earlier. We corrected the central settings and refreshed affected devices; login and settings now work normally. No action is required unless issues return; then contact IT Service Desk.

## Audience 2 - Affected End-User Team (Under 100 Words)
Hi team - your access and data are safe, and the issue is fixed. On 2024-03-15, three of four Floor 3 Finance Windows 11 PCs could not load company startup settings because they were given an old server address after an overnight server change; one similar PC was unaffected because it had been manually updated earlier. IT corrected the central network settings and refreshed the affected PCs, and logins/settings were verified as normal. If you see the same symptoms again, restart once and then contact IT Service Desk.

## Audience 3 - Engineer-to-Engineer Internal Note
Incident: FAULT-A, 2024-03-15 startup window, Floor 3 Finance OU (3/4 impacted).

Root cause:
- Floor 3 DHCP scope Option 006 still referenced decommissioned DNS server(s) after migration.
- Client subset received stale DNS (server-log comparison: FB055-057 got 172.16.5.5 decommissioned overnight 2024-03-14; unaffected control FB058 got 10.10.0.10 because manually preconfigured).
- Event chain on affected host aligns: Netlogon 5719, GP 1058/1030/1129, DNS 1014, DHCP 50036 with stale assignment.

Exact action taken:
- Updated Floor 3 DHCP scope Option 006 to current DNS set with 10.10.0.10 as correct active DNS.
- Removed old DNS entries from scope/policy assignment path.
- Refreshed affected clients (lease renew, DNS flush/register), then forced GP processing.

Config detail:
- Bad path: old/decommissioned DNS still assigned by Floor 3 DHCP scope.
- Good path: 10.10.0.10 assigned (same OU control endpoint succeeded with GP Event 1500).

Verification:
- Post-change login verification completed.
- Group Policy processing verified successful after fix.
- Same-OU unaffected control behavior remains consistent with corrected DNS assignment model.

Preventive action required:
- Add hard migration gate: DHCP Option 006 audit/sign-off before DNS decommission.
- Require DNS owner plus DHCP owner dual approval for decommission changes.
- Automate daily DHCP scope audit for non-approved DNS IPs.
- Add monitoring for spikes in Netlogon 5719, DNS 1014, GP 1129/1058/1030 by subnet/floor.
- Keep endpoint validation set per OU/subnet (DHCP-assigned DNS, SRV lookup, gpresult) during migrations.
