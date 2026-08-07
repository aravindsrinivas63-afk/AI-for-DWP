Symptom: On affected Windows 11 devices, Group Policy did not process at startup and domain-related sign-in settings failed to load. Users experienced startup/logon policy failures until connectivity to domain services was restored.

Cause: The verified root cause was a Floor 3 DHCP scope Option 006 misconfiguration that still assigned a decommissioned DNS server after the migration. This caused failed domain controller discovery and subsequent Group Policy/SYSVOL access failures.

Scope: Impact was limited to Floor 3 Finance OU endpoints in this incident, with 3 of 4 machines affected during the startup window. A same-OU comparison machine was unaffected because it had been manually preconfigured with the correct DNS server before the migration wave.

Workaround: Restore service immediately by correcting DHCP Option 006 for the affected subnet to the active DNS server set and removing old DNS entries. On affected clients, renew lease and refresh DNS state, then force Group Policy processing to recover.

Permanent fix: Implemented permanent resolution was DHCP scope correction to assign current DNS (including 10.10.0.10) and removal of stale DNS assignment paths. Post-change login and policy processing were verified as successful.

How to spot it: Look for Netlogon Event 5719 (no domain controller available), GroupPolicy Events 1058/1030/1129, DNS Client Event 1014 (name resolution timed out), and DHCP Client Event 50036 showing stale DNS assignment. In this incident, the failure chain included DNS query failure for FINBRIDGE-DC01.finbridge.local and SYSVOL path access failure to \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini.
