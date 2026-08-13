# Azure Virtual Desktop Provisioning and Validation (Day9)

## Scope
This document captures the exact Azure Virtual Desktop (AVD) provisioning flow executed for the DWP Windows 11 migration lab, including validation and troubleshooting done during implementation.

## Environment
- Subscription: `779b5333-794a-4b85-81ae-cf5a7d5d1f4a`
- Resource Group: `dwpai-lab-rg`
- Region: `eastus`
- Tenant: `zippyops.in`
- Target user: `p31@zippyops.in`

## Pre-checks Performed
1. Verified active Azure CLI context and subscription.
2. Verified operator RBAC permissions:
	- Signed-in operator had `Owner` at subscription scope.
	- Confirmed ability to create role assignments before proceeding.
3. Registered and validated `Microsoft.DesktopVirtualization` provider.

## AVD Build Steps Executed
1. Created pooled host pool `POOL-FIN-01`:
	- Host pool type: `Pooled`
	- Load balancer: `BreadthFirst`
	- Max sessions per host: `5`
	- Preferred app group type: `Desktop`
2. Created workspace `FinBridge-Workspace`.
3. Created desktop app group `DAG-POOL-FIN-01` linked to host pool.
4. Registered desktop app group to workspace.
5. Created networking resources for session host:
	- VNet/subnet
	- NSG
	- Public IP
	- NIC
6. Created session host VM `vm-fin-sh-01`:
	- Size: `Standard_B2ms`
	- Image: `MicrosoftWindowsDesktop:office-365:win11-23h2-avd-m365:latest`
	- Security type: `TrustedLaunch`
	- `Secure Boot`: enabled
	- `vTPM`: enabled
7. Enabled Entra login extension (`AADLoginForWindows`) on the VM.
8. Generated host pool registration token and installed AVD agents in-guest.

## Access and RBAC Assignment
Assigned `p31@zippyops.in`:
1. `Virtual Machine User Login` on VM scope (`vm-fin-sh-01`) for direct RDP auth authorization.
2. `Desktop Virtualization User` on app group scope (`DAG-POOL-FIN-01`) for AVD desktop access.

## Troubleshooting Performed
Issue observed:
- User sign-in failures despite correct password.

Root cause identified:
1. VM and AVD side Entra integration became healthy.
2. Client-side login attempts were routed through legacy `NTLM` (`NtLmSsp`) path.
3. NTLM path returned `0xc000006d` / `0xc0000064` for attempted usernames.

Additional blocker:
- Installing modern Microsoft Remote Desktop client on this machine failed with MSI policy error `1625` (non-admin install forbidden by policy), including per-user install attempt.

Outcome:
1. Host-side Entra integration validated as healthy.
2. Session host reached `Available` status in host pool.
3. Client auth failure persisted only due to local client/auth path constraints.

## Final Validation Snapshot
1. VM extension:
	- `AADLoginForWindows` provisioning state: `Succeeded`
2. In-guest dsreg state:
	- `AzureAdJoined : YES`
	- `DomainJoined : NO`
	- `DeviceAuthStatus : SUCCESS`
3. AVD host status:
	- Session host: `POOL-FIN-01/vm-fin-sh-01`
	- Status: `Available`
	- `AADJoinedHealthCheck`: `HealthCheckSucceeded`

## Scripts Created During Provisioning
All generated scripts were moved from Day3 to Day9.

### Provisioning and Registration Scripts
- `avd-onboard.ps1`
- `avd-register.ps1`
- `avd-reregister.ps1`
- `avd-clean-register.ps1`
- `avd-set-token.ps1`
- `avd-token-inline.ps1`

### Entra / Join Validation Scripts
- `aad-validate-dsreg.ps1`
- `aad-joined-flag.ps1`
- `aad-prereq-check.ps1`
- `aad-regstate.ps1`
- `aad-marker-find.ps1`
- `aadlogin-log-tail.ps1`

### Auth Failure and Security Event Diagnostics
- `latest-authproof.ps1`
- `latest-4625-detail.ps1`
- `latest-4625-now.ps1`
- `rdp-fail-audit.ps1`
- `rdp-fail-hex.ps1`
- `rdp-success-audit.ps1`

### RDInfra / AVD Service and Health Diagnostics
- `avd-service-check.ps1`
- `avd-rdagent-event.ps1`
- `avd-events.ps1`
- `avd-network-check.ps1`
- `avd-diag.ps1`
- `rdinfra-lognames.ps1`
- `rdinfra-search.ps1`
- `rdinfra-uninstall-info.ps1`

### Client Connection Profile
- `vm-fin-sh-01-aad.rdp`

## Notes
- The infrastructure and host integration are healthy.
- Remaining login failures from this workstation are tied to client auth mode and endpoint policy constraints, not AVD host provisioning.
