# FAULT-A Hypothesis Analysis (Do Not Finalize Root Cause Yet)

## Scope Snapshot
- Incident: "No Group Policy" on Win11 clients
- Affected: 3 of 4 machines in OU=Finance
- Location pattern: Floor 3
- Time pattern: Startup window 2024-03-15 07:40-07:55
- Sample host log reference: DESKTOP-FB031

## Most Probable Causes (Ranked)

### 1) Floor 3 network path issue to AD services at startup (DC/DNS/SYSVOL ports unreachable or delayed)
Why this fits scope facts:
- Strong location correlation (Floor 3) points to a shared dependency (switch stack, uplink, VLAN ACL, NAC, or DHCP scope behavior), not random endpoint failure.
- 3 of 4 affected in same OU suggests policy scope itself is likely fine; transport to domain services is the likely common failure.
- Startup-time clustering (07:40-07:55) is consistent with boot/logon race conditions where domain services are not reachable in time.

Single fastest confirm/eliminate check:
- From one affected machine during/near startup issue window, run:
  - `nltest /dsgetdc:<yourdomain>`
- If DC discovery fails or is slow/intermittent while the machine has basic network, this cause remains highly likely; if DC discovery is immediate and stable, deprioritize.

### 2) DNS resolution fault on affected clients/subnet (wrong DNS servers, stale DHCP option, or split-DNS issue)
Why this fits scope facts:
- Group Policy processing depends on AD DNS for SRV records and DC discovery; bad DNS commonly appears as "no Group Policy."
- Partial impact (3 of 4) can occur if one device has static/correct DNS while others use bad DHCP-provided DNS.
- Floor-based clustering matches a subnet/scope-specific DNS misconfiguration.

Single fastest confirm/eliminate check:
- On an affected host, run:
  - `nslookup -type=SRV _ldap._tcp.dc._msdcs.<yourdomain>`
- If SRV lookup fails or returns unexpected targets, DNS is likely causal; if it returns valid DCs quickly, deprioritize DNS as primary.

### 3) Transient domain controller/SYSVOL availability issue (or DFSR/replication lag) hitting only some clients
Why this fits scope facts:
- Time-bounded startup window suggests a transient backend condition can explain simultaneous misses.
- "3 of 4" is consistent with clients landing on one problematic DC while another machine contacts a healthy DC.
- OU targeting is not contradicted; retrieval failure can occur even when targeting is correct.

Single fastest confirm/eliminate check:
- On an affected machine, run:
  - `gpresult /r /scope computer`
- Then verify the "Last time Group Policy was applied" and any reported processing/DC errors. If errors indicate domain/SYSVOL access failures, keep this as likely; if policy applies successfully with no backend errors, deprioritize.

## Notes
- Do not lock to a single root cause yet.
- Next step should be to run the three checks above on one affected and one unaffected peer from the same OU for contrast.

## Incident Window Evidence Mapping (Per Ranked Hypothesis)

### Hypothesis 1: Floor 3 network path issue to AD services at startup (DC/DNS/SYSVOL ports unreachable or delayed)
Judgment: Support

Determining evidence:
- Netlogon Event 5719 at 07:40:08: no domain controller available and DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- GroupPolicy Event 1129 at 07:40:12: no network connectivity to a domain controller.
- GroupPolicy Event 1129 at 07:44:01: repeated no DC connectivity.

Why this judgment:
- The events directly show startup-time inability to reach domain services required for GPO processing.

### Hypothesis 2: DNS resolution fault on affected clients/subnet (wrong DNS servers, stale DHCP option, or split-DNS issue)
Judgment: Support

Determining evidence:
- DNS Client Event 1014 at 07:41:05: name resolution for FINBRIDGE-DC01.finbridge.local timed out; none of the configured DNS servers responded.
- DHCP Client Event 50036 at 07:42:18: DNS server assigned was 10.10.3.250 (old/decommissioned), not 10.10.0.10 (current).
- Netlogon Event 5719 at 07:40:08: DC name query returned no response.

Why this judgment:
- The DHCP-assigned stale DNS endpoint and name-resolution timeout directly explain DC discovery failure and downstream GPO failures.

### Hypothesis 3: Transient domain controller/SYSVOL availability issue (or DFSR/replication lag) hitting only some clients
Judgment: Contradicts

Determining evidence:
- DHCP Client Event 50036 at 07:42:18 identifies client-side DNS misassignment to a decommissioned server.
- DNS Client Event 1014 at 07:41:05 shows resolver path failure before DC/SYSVOL access could succeed.
- GroupPolicy Event 1058 at 07:40:09 and 07:40:11 plus Event 1030 at 07:40:10 are consistent with inability to locate/reach DC via DNS, not by themselves proof of DC backend outage.

Why this judgment:
- The strongest observed fault is on client DNS pathing, which provides a concrete alternative explanation; this weakens a primary hypothesis of transient DC/SYSVOL backend instability.

## Positioning
- All hypotheses have been evaluated against evidence.
- No single winner is declared in this document yet.

## Addendum - Event Details, Surviving Hypothesis, and Resolution

### Event Details (Affected User, Incident Window)
- 07:40:02 Service Control Manager Event 7036: Network Location Awareness service entered running state.
- 07:40:08 Netlogon Event 5719 (Error): unable to set up secure channel to FINBRIDGE; no domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 GroupPolicy Event 1058 (Error): cannot access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini (0x3 path not found).
- 07:40:10 GroupPolicy Event 1030 (Warning): cannot query list of Group Policy objects (0x546).
- 07:40:11 GroupPolicy Event 1058 (Error): repeated SYSVOL access failure.
- 07:40:12 GroupPolicy Event 1129 (Error): no network connectivity to a domain controller.
- 07:41:05 DNS Client Event 1014 (Warning): FINBRIDGE-DC01.finbridge.local resolution timed out; configured DNS servers did not respond.
- 07:42:18 DHCP Client Event 50036 (Information): lease 10.10.3.144 from 10.10.0.1; DNS assigned 10.10.3.250.
- Note: 10.10.3.250 was decommissioned at 02:00; correct DNS is 10.10.0.10; DHCP scope was not updated.
- 07:44:01 GroupPolicy Event 1129 (Error): Group Policy failed again with no DC connectivity.

### Surviving Hypothesis
DNS resolution fault on affected clients/subnet due to stale DHCP Option 006 DNS assignment (old DNS server 10.10.3.250).

Why this survives:
- Netlogon 5719 (07:40:08) shows failed DC discovery.
- DNS Client 1014 (07:41:05) confirms resolver timeout against configured DNS servers.
- DHCP Client 50036 (07:42:18) provides direct causal path: clients received decommissioned DNS server.

### Detailed Resolution Steps

1) Fix DHCP scope configuration
- Update DHCP Option 006 on Floor 3 scope to use current DNS servers, with 10.10.0.10 as primary.
- Remove 10.10.3.250 from scope options and any DHCP policy-level overrides.
- If DHCP failover is enabled, verify partner replication and identical options on both servers.

2) Force client network and DNS refresh
- Run on each affected client:
  - `ipconfig /release`
  - `ipconfig /renew`
  - `ipconfig /flushdns`
  - `ipconfig /registerdns`

3) Validate DC discovery and name resolution
- Run on affected client:
  - `nslookup FINBRIDGE-DC01.finbridge.local`
  - `nslookup -type=SRV _ldap._tcp.dc._msdcs.finbridge.local`
  - `nltest /dsgetdc:finbridge.local`
- Expected: successful and low-latency responses from active DNS/DC infrastructure.

4) Re-run Group Policy processing
- Execute:
  - `gpupdate /force`
  - `gpresult /r /scope computer`
- Confirm computer policy applies successfully and no unresolved GP processing errors remain.

5) Verify event-log recovery criteria
- Confirm no new instances during next startup cycle of:
  - Netlogon 5719
  - GroupPolicy 1058, 1030, 1129
  - DNS Client 1014
- Confirm positive/normal policy processing events after DNS correction.

6) Prevent recurrence
- Perform DHCP option audit across all migrated subnets for references to decommissioned DNS IPs.
- Add migration change-control gate: DHCP Option 006 validation before DNS decommission approvals.
- Add monitoring alert for spikes of Event 1014 and 5719 by subnet/floor.
