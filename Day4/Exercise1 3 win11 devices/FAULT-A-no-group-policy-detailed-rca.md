# FAULT-A Detailed RCA - Win11 No Group Policy (Floor 3 Finance OU)

## Document Control
- Incident ID: FAULT-A
- Service Impact: Group Policy processing failure at startup on Floor 3 Finance OU endpoints
- Incident Date: 2024-03-15
- RCA Authoring Date: 2026-08-07
- Status: Resolved and validated

## Executive Summary
Three Win11 machines in Finance OU on Floor 3 failed to process Group Policy during startup because DHCP on the Floor 3 subnet continued assigning a decommissioned DNS server. This prevented domain controller discovery and SYSVOL access, resulting in Netlogon and GroupPolicy failures. A same-OU comparison endpoint remained healthy because it had been manually preconfigured with the correct DNS server before the migration wave. After DHCP Option 006 correction and client lease/DNS refresh, issue was resolved.

## Impact Statement
- Affected population: 3 of 4 endpoints in OU=Finance on Floor 3
- User-facing symptoms:
  - Domain-related startup policy failures
  - GPO not applying at startup/logon
  - Intermittent or failed domain service reachability
- Business impact:
  - Security/compliance and configuration drift risk due to missed policy application
  - Potential login and application baseline inconsistency

## Scope and Comparison Evidence
- Affected pattern:
  - Floor 3 devices FB055-057 received DNS 172.16.5.5 (decommissioned)
- Unaffected control in same OU:
  - DESKTOP-FB029 (FB058 reference): DNS 10.10.0.10 (correct), manually reconfigured pre-migration
- Key inference:
  - OU targeting was not causal; DNS assignment path differentiated affected vs unaffected outcomes.

## Supporting Evidence (Event and Log Artifacts)

### Affected Host Event Evidence
- 07:40:02, Service Control Manager, Event 7036
  - Network Location Awareness entered running state.
- 07:40:08, Netlogon, Event 5719, Error
  - Secure channel setup failed; no domain controller available.
  - DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09, GroupPolicy, Event 1058, Error
  - Failed to access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini
  - Error 0x3 (path not found).
- 07:40:10, GroupPolicy, Event 1030, Warning
  - Could not query list of Group Policy objects (0x546).
- 07:40:11, GroupPolicy, Event 1058, Error
  - Repeated SYSVOL/GPO retrieval failure.
- 07:40:12, GroupPolicy, Event 1129, Error
  - No network connectivity to a domain controller.
- 07:41:05, DNS Client Events, Event 1014, Warning
  - Name resolution for FINBRIDGE-DC01.finbridge.local timed out.
  - None of configured DNS servers responded.
- 07:42:18, DHCP Client, Event 50036, Information
  - IP 10.10.3.144 leased from 10.10.0.1.
  - DNS assigned: 10.10.3.250 (old/decommissioned in migration notes).
- 07:44:01, GroupPolicy, Event 1129, Error
  - Group Policy failed again due to no DC connectivity.

### Unaffected Peer Evidence (Same OU)
- DESKTOP-FB029
  - 07:40:05, DHCP Client, Event 50036
    - IP 10.10.3.141
    - DNS assigned: 10.10.0.10 (correct new DNS)
  - 07:40:11, GroupPolicy, Event 1500, Information
    - Group Policy processed successfully.
  - Context: Manually reconfigured before migration wave.

### DHCP Server Comparison Evidence
- FB055-057 DNS assigned: 172.16.5.5 (Floor 3 local DNS, decommissioned overnight 2024-03-14)
- FB058 DNS assigned: 10.10.0.10 (central DNS, correct)
- Direct causality statement from logs:
  - Floor 3 DHCP scope still referenced old DNS server.

## Timeline (UTC-local sequence from incident window)
- 07:40:02: NLA service started (network stack entering ready state)
- 07:40:08: Netlogon 5719 (cannot find DC)
- 07:40:09: GP 1058 (cannot access SYSVOL gpt.ini)
- 07:40:10: GP 1030 (cannot enumerate GPO list)
- 07:40:11: GP 1058 repeats
- 07:40:12: GP 1129 (no DC connectivity)
- 07:41:05: DNS 1014 (name resolution timeout; DNS servers non-responsive)
- 07:42:18: DHCP 50036 confirms stale DNS assignment to affected host
- 07:44:01: GP 1129 repeats (persistent failure until config corrected)

## Root Cause Statement
Primary root cause: DHCP scope configuration for Floor 3 subnet retained decommissioned DNS server entries in Option 006 after DNS migration, causing affected clients to receive invalid DNS and fail domain controller discovery at startup.

Contributing factors:
- Change-control gap between DNS server decommission and DHCP scope option validation.
- Inconsistent client state due to manual pre-configuration on one endpoint, masking blast radius if only random sampling is used.

## 5 Whys Analysis
1. Why did Group Policy fail on startup?
- Clients could not contact a domain controller or SYSVOL path.

2. Why could clients not contact a domain controller?
- DC name resolution failed or timed out.

3. Why did DC name resolution fail?
- Clients were using a decommissioned DNS server address.

4. Why were clients using a decommissioned DNS server?
- DHCP Option 006 on Floor 3 scope still referenced old DNS after migration.

5. Why was DHCP scope not corrected before decommission?
- Migration process lacked a hard gate/checklist enforcing DHCP option audit and sign-off before DNS retirement.

Systemic cause:
- Process control deficiency in infrastructure migration sequencing and validation.

## Resolution Implemented
1. Corrected DHCP Option 006 for Floor 3 subnet to current DNS server set (including 10.10.0.10 primary as designed).
2. Removed old DNS server references from applicable scope/policy configuration.
3. Refreshed affected clients:
- lease renew
- DNS cache flush
- DNS registration
4. Re-ran Group Policy processing and validated successful application.

## Resolution Verification
- Same OU unaffected peer remained healthy with correct DNS and successful GP (Event 1500).
- Affected clients recovered after DHCP/DNS correction.
- Login and policy processing verified as successful post-fix.
- Comparative evidence confirms configuration-based, not OU-targeting, failure mode.

## Preventive and Corrective Actions

### Immediate Corrective Actions (Completed)
- DHCP scope Option 006 corrected for Floor 3 subnet.
- Legacy DNS entries removed from active assignment path.
- Incident communications and closure validation completed.

### Preventive Actions (Required)
1. Migration Guardrail
- Add mandatory pre-decommission checkpoint: verify all DHCP scopes/options and policy overrides contain only target DNS servers.

2. Dual-Control Sign-off
- Require joint sign-off from DNS owner and DHCP owner before DNS decommission execution.

3. Automated Compliance Audit
- Schedule daily audit script for DHCP Option 006 across all scopes to detect non-approved DNS IPs.

4. Telemetry and Alerting
- Alert on subnet spikes of:
  - Netlogon 5719
  - DNS Client 1014
  - GroupPolicy 1129/1058/1030

5. Standardized Endpoint Validation Set
- During migrations, validate at least one random endpoint and one control endpoint per OU/subnet with:
  - DHCP-assigned DNS capture
  - DC SRV lookup
  - gpresult outcome

6. Runbook Update
- Update Win11 GPO incident runbook with this failure pattern and fast triage decision tree:
  - If 5719 + 1014 + DHCP stale DNS observed, prioritize DHCP scope correction.

## Closure Criteria and Evidence Package
- Closure criteria met:
  - Service restored for affected endpoints
  - Successful login/policy verification completed
  - Root cause identified and corrected
  - Preventive actions defined and assigned
- Recommended artifacts to retain with incident record:
  - Event log exports (affected and unaffected)
  - DHCP scope option snapshots before/after
  - Change record linking DNS decommission and DHCP updates
  - Post-fix gpresult validation outputs
