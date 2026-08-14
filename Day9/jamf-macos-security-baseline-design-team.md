# JAMF Pro Translation: macOS Security Baseline (Design Team Fleet)

## Scope
This document translates the stated macOS security baseline into JAMF Pro configuration profile settings for a 25-device Design team fleet.

## Current UI path
JAMF Pro interface layouts vary by major version and role permissions, but the common path is:

- Open configuration profiles: Computers > Configuration Profiles
- Create profile: Computers > Configuration Profiles > New
- Platform: macOS
- Scope and deployment: General tab plus Scope tab
- Payload editing: Select each payload in the left navigation and configure values
- Save and deploy: Save profile, then monitor profile status and inventory updates

## UI path drift flag
JAMF has changed payload names and section placement over time, and Apple has also shifted some management keys across macOS releases. Treat the mapped controls in this document as implementation intent and verify the exact label and payload location in your own JAMF Pro instance before enforcing production scope.

Controls with higher naming drift risk are marked below as Verify UI label in your JAMF instance: Yes.

## Baseline mapping table

| Requirement | Payload type | Value | Effect | False-positive risk | Recommendation | Verify UI label in your JAMF instance |
| --- | --- | --- | --- | --- | --- | --- |
| FileVault disk encryption must be enabled | Security and Privacy (Disk Encryption / FileVault area) | Enable FileVault; allow enablement for current or next user as per rollout model; escrow personal recovery key to JAMF Pro | Encrypts startup volume data at rest so disk theft or offline access cannot read user data without unlock credentials. | Freshly encrypted devices can report not compliant before encryption completion, escrow confirmation, and inventory reconverge. | Enforce escrow verification before considering rollout complete. Use a smart group for FileVault enabled plus escrowed key present. | Yes |
| Gatekeeper must be enabled (identified developers only) | Restrictions (Security or Functionality section, depending on JAMF version) | Allow app execution from App Store and identified developers only; do not allow Anywhere. | Prevents execution of unsigned or untrusted apps by default, reducing malware and tampering risk. | Temporary drift can appear if local admin changes Gatekeeper via command line before MDM profile reasserts control. | Pair configuration with software install governance and self service packaging process for approved unsigned internal tools. | Yes |
| Minimum macOS version: current stable minus one point release | Restricted Software and/or Software Updates strategy plus Smart Group compliance logic | Define minimum approved major and minor floor at current stable minus one point release; flag below-floor devices for remediation. | Keeps devices on a security-supported level while preserving operational runway for design tooling validation. | Apple release timing, deferred update windows, and delayed check-in can mark healthy devices as below floor transiently. | Use staged rings and track both version and install deadline state. Rebaseline floor promptly after new stable release validation. | Yes |
| Firewall must be enabled | Security and Privacy (Firewall payload) | Enable Application Firewall; optionally lock user ability to disable if policy requires strict posture. | Blocks unsolicited inbound connection attempts and reduces lateral movement risk. | Local troubleshooting changes, temporary exception profiles, or delayed profile reapplication can produce short-lived mismatch. | Standardize firewall exceptions centrally and avoid ad hoc local overrides for design tools and creative plugins. | Yes |
| Login password required after sleep or screen saver | Security and Privacy and/or Login Window related controls | Require password immediately after sleep or screen saver starts; set grace period to immediate equivalent. | Prevents unauthorized use when an unlocked Mac is left unattended. | User context caching or delayed profile processing after enrollment can briefly show non-enforced state despite correct policy. | Validate with both profile status and local setting readouts on test devices before broad scope. | Yes |
| Automatic security updates enabled | Software Update payload and related restrictions controls | Enable automatic security updates, including security responses and system data updates where supported by OS version. | Ensures critical security fixes are applied without waiting for user action. | Offline devices, battery and power state constraints, or maintenance deferrals can delay installation and appear non-compliant. | Set user communications for restart expectations and track update age in smart groups. | Yes |

## Wizard-aligned build notes for JAMF Pro
Unlike Intune, JAMF does not use the same multi-step compliance wizard terminology. Equivalent build flow for this baseline is:

- Create one baseline profile for always-on hardening controls.
- Add payloads for FileVault, Firewall, Restrictions, Login behavior, and Software Update settings.
- Scope to Design team device group only.
- Save and deploy to pilot ring first.
- Confirm inventory and profile status before moving to full ring.

## Profile construction guidance

### General tab
- Name: macOS Security Baseline - Design Team - Core
- Level: Computer level profile
- Distribution method: Install automatically
- User removable: No

### Scope tab
- Include: Design team smart group or static group with 25 managed Macs
- Exclude: Lab devices, kiosk/shared demo devices, break-glass admin test machines

### Payload coverage in one profile vs multiple profiles
- One profile approach: easier to audit baseline in one object but can increase blast radius if edited incorrectly.
- Multi-profile approach: isolate high-risk controls (for example FileVault and Software Update) for safer staged changes.
- For this 25-device fleet, either model is acceptable. Prefer multi-profile if design workflows are sensitive to rapid update changes.

## Requirement-by-requirement implementation notes

### 1) FileVault must be enabled
- Payload type: Security and Privacy (FileVault or Disk Encryption area)
- Value: Enable FileVault and escrow recovery key to JAMF Pro
- Effect: Device storage is encrypted and recoverable through managed escrow process
- False-positive risk: Encryption in progress, token issues, or delayed escrow posting can look non-compliant

Operational checks:
- Verify FileVault status is enabled in inventory
- Verify recovery key escrow exists
- Confirm no pending user enablement prompt remains unresolved

### 2) Gatekeeper set to identified developers only
- Payload type: Restrictions
- Value: App execution allowed only for App Store and identified developers
- Effect: Untrusted executables are blocked by policy default
- False-positive risk: Local override commands or stale inventory snapshots

Operational checks:
- Validate Gatekeeper assessment state on pilot devices
- Confirm no conflicting local hardening script is flipping the value

### 3) Minimum macOS version floor
- Payload type: Software Update and compliance smart group logic
- Value: Current stable minus one point release minimum
- Effect: Devices below approved version floor are rapidly identified and remediated
- False-positive risk: Recently updated devices not yet rebooted or not yet inventoried

Operational checks:
- Build a smart group for below-minimum version
- Track devices pending restart separately from truly out-of-date devices

### 4) Firewall enabled
- Payload type: Security and Privacy (Firewall)
- Value: Enable firewall and lock setting where policy demands
- Effect: Inbound exposure is reduced unless explicitly allowed
- False-positive risk: Temporary exception state for troubleshooting or profile conflict

Operational checks:
- Confirm firewall status in inventory
- Review exception list for design tooling to avoid shadow IT bypasses

### 5) Require password after sleep or screen saver
- Payload type: Security and Privacy or Login Window related payload
- Value: Immediate password requirement after sleep or screensaver
- Effect: Reduces risk of walk-up access to unattended unlocked sessions
- False-positive risk: User session timing and delayed policy reconciliation

Operational checks:
- Validate on a pilot Mac by sleep and wake test
- Confirm setting persistence after reboot and re-login

### 6) Automatic security updates enabled
- Payload type: Software Update
- Value: Enable automatic security update channels supported by installed macOS
- Effect: Security fixes are applied with less user dependency
- False-positive risk: Device unavailable for update cycle due to power/network or long deferral window

Operational checks:
- Track last update install timestamp and pending reboot
- Correlate update failures with available disk space and uptime

## Assignment and rollout design for 25 devices

### Recommended rings
- Ring 0 (IT pilot): 3 devices
- Ring 1 (Design pilot): 5 devices
- Ring 2 (Production): remaining 17 devices

### Rollout gate criteria
- No critical design app regression
- FileVault escrow success rate at 100 percent in the ring
- No persistent false non-compliance pattern for firewall or password-after-sleep controls
- Update install success rate aligned with expected maintenance window behavior

## Compliance and monitoring model in JAMF context
JAMF configuration profiles enforce settings, while compliance reporting often depends on inventory freshness, smart group logic, and any connected conditional access tooling. Use all three signals together:

- Profile installed status
- Inventory-reported configuration state
- Smart group membership for exception and non-compliance targeting

## Suggested smart groups for evidence and operations
- SG - Design - Baseline - FileVault Missing or Not Escrowed
- SG - Design - Baseline - Gatekeeper Drift
- SG - Design - Baseline - Below Minimum macOS
- SG - Design - Baseline - Firewall Off
- SG - Design - Baseline - Password After Sleep Drift
- SG - Design - Baseline - Security Updates Overdue

## Validation and monitoring playbook

### Where to validate after deployment
- Computers > Configuration Profiles > select baseline profile > scope and status
- Computers > Smart Computer Groups > review baseline exception groups
- Individual computer record > Inventory and Security sections for control evidence

### State interpretation guidance
- Healthy: profile installed, inventory confirms expected value, device absent from exception smart groups
- Transitional: profile installed but inventory lag or pending restart still present
- Action required: profile missing, hard control off, or repeated smart group exception membership

## False-positive triage checklists

### FileVault appears non-compliant but should be enabled
- Check if encryption is still in progress
- Check if recovery key escrow has posted
- Check if user has completed enablement prompt if deferred enablement model is used
- Force inventory update and re-evaluate before raising incident

### Minimum macOS version appears below baseline after update
- Confirm update actually completed and not staged pending reboot
- Confirm device checked in after reboot
- Confirm smart group comparator value matches current baseline floor definition

### Firewall drift reported unexpectedly
- Check for local admin troubleshooting changes
- Check for overlapping profile with conflicting firewall settings
- Reconfirm inventory timestamp before escalation

## First 24 hours monitoring guidance
- Watch exception smart group counts every few hours during each ring rollout
- Separate transitional states from persistent failures before incident declaration
- Track app compatibility tickets from Design users alongside security posture metrics
- If exception counts rise after a specific macOS patch, pause next ring and validate tooling compatibility

## Communications recommendations
- Pre-change notice: explain restart expectations, update behavior, and FileVault prompts
- Day-of-change notice: include self-check steps for users and support contact route
- Post-change closure note: summarize compliance posture and any approved exceptions

## Recommended exact baseline summary
- FileVault: Enabled and escrowed
- Gatekeeper: App Store and identified developers only
- Minimum macOS: Current stable minus one point release
- Firewall: Enabled
- Password after sleep or screensaver: Required immediately
- Automatic security updates: Enabled

## Final verification reminder
Do not assume exact JAMF payload labels from this document are immutable. Validate every control label, payload path, and option wording against your JAMF Pro version before production enforcement.
