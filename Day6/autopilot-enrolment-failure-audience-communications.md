# Autopilot Enrollment Failure - Audience Communications

## Audience 1 - Non-technical executive

Provisioning has been restored for the affected device and no broader service issue was identified. On 15 March, one device, DESKTOP-FB099, failed Windows Autopilot enrollment because it still had an older device-management enrollment record from a previous setup. The stale enrollment was removed, the device was reprocessed through Autopilot, and enrollment could then complete normally. This was an isolated device-preparation issue rather than a platform outage. No action needed.

## Audience 2 - Affected end-user team (non-technical)

Hi team, the device enrollment issue has been identified and resolved. What happened: DESKTOP-FB099 could not complete setup through Windows Autopilot because it still had an older management connection from a previous enrollment. What we did: removed the old management record, reset the device into a clean setup state, and reran enrollment. Result: the device can now complete its managed setup normally. If you see a similar setup failure on another reused device, contact the Service Desk and mention a possible legacy MDM enrollment conflict.

## Audience 3 - Engineer-to-engineer internal note

Scope/config detail:
- Affected device: DESKTOP-FB099.
- Affected user: FINBRIDGE\rthomas.
- Incident date: 2024-03-15.
- Enrollment type: Autopilot.

Root cause:
- Pre-existing legacy manual MDM enrollment from 2023-11-04 conflicted with the new Autopilot enrollment.
- Enrollment failed with 0x80180014 and explicit export text: device already enrolled in MDM.
- Downstream policy stage also failed: 0 of 4 profiles applied, last error 0x80070005.

Evidence that ruled out common alternatives:
- Azure AD joined = Yes.
- Licensing present: M365, Intune P1, Autopilot.
- Network healthy: required Microsoft endpoints reachable, no proxy.

Exact action taken:
- Removed stale managed device/enrollment records from Intune.
- Removed stale duplicate device object(s) as needed from Entra.
- Removed legacy work or school enrollment from the device.
- Rebooted/reset device into clean Autopilot OOBE path.
- Re-ran Autopilot enrollment and initial sync.

Verification step:
- Confirm no recurrence of 0x80180014.
- Confirm a single active MDM enrollment record.
- Confirm successful Autopilot enrollment completion.
- Confirm profile application progresses beyond prior 0 of 4 state.

Preventive action needed:
- Add mandatory pre-Autopilot check for legacy/manual MDM enrollment artifacts on reused devices.
- Require Intune and Entra stale-object cleanup before Autopilot reassignment.
- Add redeployment SOP step to remove local work/school enrollment before device reuse.
- Track repeat incidents of existing-enrollment conflicts as a lifecycle hygiene metric.
