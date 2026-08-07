# FAULT-B Hypothesis Analysis (Scope-Only, No Final Root Cause Yet)

## Scope Facts Used
- Symptom: Finance team cannot access shared drives
- Scale: 45 users affected
- Data sources: Intune Management Extension Log + System Log
- Affected population: All Finance users on DESKTOP-FB* devices, OU=Finance

## Ranked Most Likely Causes (Most Probable First)

### 1) OU-targeted Group Policy drive mapping failure (or policy not applying)
Why this fits scope facts:
- Impact is universal within OU=Finance, which strongly matches an OU-scoped mapping/control mechanism.
- Shared drive access for a department is commonly delivered through GPO user/computer policies.
- System and Intune-adjacent log sources are consistent with endpoint policy-processing failure visibility.

Single fastest confirm/eliminate check:
- On one affected Finance endpoint, run `gpresult /r` and confirm whether expected Finance drive-mapping policies were applied or failed.

### 2) Authentication/authorization path failure to file services (Kerberos/secure channel/domain reachability)
Why this fits scope facts:
- "Cannot access shared drives" across all Finance users can occur when clients cannot authenticate properly to SMB/file servers.
- A domain-auth path issue can present simultaneously across many users on a common device cohort.
- System logs are a primary place to surface auth/channel failures.

Single fastest confirm/eliminate check:
- From one affected endpoint, test direct UNC access to a known share (for example `\\<fileserver>\<share>`) and check for immediate access-denied vs name/path/auth errors.

### 3) DNS/name-resolution issue for file server namespace used by Finance
Why this fits scope facts:
- Widespread access failure to shared drives can result from inability to resolve file server/DFS namespace names.
- Cohort-wide impact on DESKTOP-FB* can map to common network/DNS client configuration state.
- System logs typically capture resolver failures relevant to UNC access failures.

Single fastest confirm/eliminate check:
- On one affected endpoint, run `nslookup <fileserver-or-namespace-fqdn>` used by mapped drives and validate it resolves quickly to expected records.

### 4) Drive mapping shifted to Intune script/remediation and deployment failed or was withdrawn for Finance scope
Why this fits scope facts:
- Intune Management Extension log is explicitly called out, suggesting an endpoint script/remediation dependency is in play.
- If mapping logic is delivered by Intune to OU-aligned device/user groups, a deployment failure can affect all 45 users.
- Symptom pattern fits a centralized assignment failure rather than random endpoint defects.

Single fastest confirm/eliminate check:
- In Intune Management Extension log on one affected device, verify the latest Finance drive-mapping script/remediation execution status (success/failure/assignment missing).

### 5) File service side outage or share/DFS target unavailable for Finance path
Why this fits scope facts:
- A backend share outage can instantly affect all users of that department path.
- Universal Finance impact is compatible with a single dependency (server, cluster, DFS target, or share permission rollback).
- System logs on clients can show path unavailable/network path not found while other local functions remain normal.

Single fastest confirm/eliminate check:
- From an affected endpoint, ping and then test `Test-Path \\<fileserver>\<share>` for the known Finance share path to quickly separate endpoint policy issues from backend availability.

## Positioning
- This is a ranked hypothesis list built only from current scope facts.
- No single cause is selected at this stage.

## Addendum - Event Details, Survived Hypothesis, and Resolution

### Event Details (Affected User, Incident Window)
- 08:00:01 ScriptRunner Info: Executing Map-FinBridgeDrives.ps1
- 08:00:02 ScriptRunner Info: Script context is SYSTEM account
- 08:00:03 ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time
- 08:00:03 ScriptRunner Error: Script Map-FinBridgeDrives.ps1 failed with exit code 1; error: Network name cannot be found
- 08:00:04 ScriptRunner Info: No retry configured

### Survived Hypothesis
DNS/name-resolution failure for the Finance file share namespace (\\finbridge-fs01\Finance) during drive-mapping execution.

Why this survived:
- The decisive failure text at 08:00:03 is Network name cannot be found, which aligns directly with namespace resolution/reachability failure.
- The script executed but failed at UNC access time, indicating execution path exists while name/path lookup failed.
- No retry was configured, so transient resolution failure was not auto-recovered.

### Detailed Resolution Steps

1) Confirm and isolate DNS fault
- On an affected endpoint run:
	- nslookup finbridge-fs01
	- Resolve-DnsName finbridge-fs01
- Validate the returned target matches the active Finance file service endpoint.

2) Correct namespace resolution source
- Fix DNS record/alias for finbridge-fs01 to the active target.
- Remove stale record paths and confirm propagation/consistency on serving DNS infrastructure.

3) Refresh client resolver state
- On affected endpoints:
	- ipconfig /flushdns
	- re-test name resolution and UNC reachability:
		- nslookup finbridge-fs01
		- Test-Path \\finbridge-fs01\Finance

4) Re-run mapping workflow
- Trigger Intune sync and re-run Map-FinBridgeDrives.ps1 on pilot affected devices.
- Confirm the script completes without Network name cannot be found and that Finance drive mapping is present.

5) Verify service recovery
- Validate successful shared-drive access across a representative Finance user sample.
- Confirm no recurring script failures for the same error signature.

6) Prevent recurrence
- Add retry/backoff to mapping script execution (current state: No retry configured).
- Add pre-mapping guard that checks DNS resolution and UNC reachability before mapping.
- Add monitoring for repeated Map-FinBridgeDrives.ps1 failures with Network name cannot be found.
