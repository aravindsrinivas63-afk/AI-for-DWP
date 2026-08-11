# Autopilot Enrollment Failure Detailed RCA

## Document control
- Incident title: Autopilot enrollment failure due to existing legacy MDM enrollment
- Affected device: DESKTOP-FB099
- Affected user: FINBRIDGE\\rthomas
- Incident date: 2024-03-15
- Analysis date: 2026-08-11
- Analyst: DWP Endpoint Management
- Severity: Medium (single-device enrollment failure with repeat-risk for similarly prepared devices)

## Executive summary
Autopilot enrollment failed because the device already had an active legacy manual MDM enrollment footprint from 2023-11-04. The failure surfaced as error 0x80180014 with explicit message text indicating pre-existing MDM enrollment. Because enrollment did not complete, downstream policy processing also failed (0 of 4 profiles applied) with last error 0x80070005 (Access denied). Network and licensing checks were healthy, reducing likelihood of connectivity or entitlement as primary causes.

## Scope and impact
- Scope in this case: Single confirmed device (DESKTOP-FB099).
- Immediate impact: Device could not complete Autopilot-managed enrollment and did not receive required security baseline profiles.
- Security/operations risk: Device remained outside intended compliant managed state until remediation.
- Recurrence risk: High for any redeployed/reused endpoints with leftover manual enrollment state.

## Supporting evidence

### Evidence source
MDM diagnostic export captured on 2024-03-15 from affected endpoint.

### Structured evidence table

| Evidence area | Observed value | Interpretation |
| --- | --- | --- |
| EnrollmentType | Autopilot | Device was expected to complete modern Autopilot flow. |
| EnrollmentState | Failed | Enrollment process did not complete. |
| ErrorCode | 0x80180014 | Enrollment blocked; export text ties this directly to existing MDM enrollment. |
| ErrorDescription | The device is already enrolled in MDM. | Direct indicator of conflicting enrollment record/state. |
| AzureADJoined | Yes | Entra join state is present; not a join-missing scenario. |
| MDMEnrolled | Yes (previous enrollment) | Confirms pre-existing management relationship before current attempt. |
| EnrollmentSource | Legacy manual MDM enrollment (2023-11-04) | Conflicting historical management method remains in scope. |
| ProfilesAttempted | 4 | Policy engine attempted baseline delivery. |
| ProfilesApplied | 0 | No policy payload applied successfully. |
| LastError | 0x80070005 (Access denied) | Secondary policy-stage failure after incomplete enrollment context. |
| ComplianceEngine | Could not evaluate (Enrollment not complete) | Compliance failure is downstream of enrollment failure. |
| Network endpoints | login.microsoftonline.com OK; enrollment.manage.microsoft.com OK; enterpriseregistration.windows.net OK | Connectivity to required Microsoft endpoints healthy. |
| ProxyDetected | No | No proxy obstruction indicated. |
| Licensing | M365: Yes, Intune P1: Yes, Autopilot: Yes | Licensing prerequisites available. |

### Evidence quality notes
- Error description is explicit and aligns with enrollment-state metadata.
- Multiple independent signals corroborate same root condition (MDMEnrolled, EnrollmentSource, error text).
- No contradictory evidence found in network or licensing sections.

## Timeline (UTC/local as captured)

| Time | Event | Evidence |
| --- | --- | --- |
| 2023-11-04 | Legacy manual MDM enrollment created on this device | DeviceInfo -> EnrollmentSource references legacy manual enrollment date. |
| 2024-03-15 09:18:44 | Autopilot enrollment attempt fails | EnrollmentStatus -> Failed, 0x80180014, device already enrolled in MDM. |
| 2024-03-15 09:19:01 | Policy Manager attempts 4 profiles and applies none | PolicyManager -> ProfilesAttempted 4, ProfilesApplied 0, LastError 0x80070005. |
| 2024-03-15 09:19:45 | Compliance evaluation cannot complete | ComplianceEngine -> Could not evaluate, reason: Enrollment not complete. |
| 2024-03-15 09:22 | Export generated and case evidence frozen | Header metadata timestamp in diagnostic export. |

## Root cause statement
A stale/active legacy manual MDM enrollment state already existed on the device prior to the Autopilot run. This pre-existing enrollment conflicted with Autopilot enrollment, causing failure 0x80180014 and preventing completion of the new enrollment transaction.

## Contributing factors
- Device lifecycle process did not fully de-register and sanitize prior management artifacts before Autopilot reuse.
- No enforced preflight gate to detect legacy enrollment remnants before assigning/reusing Autopilot profile.
- Object hygiene gaps (potential stale cloud/device records) increased risk of enrollment collision scenarios.

## 5 Whys analysis

1. Why did Autopilot enrollment fail?
- Because the enrollment transaction returned failed with 0x80180014.

2. Why did it return 0x80180014?
- Because the device already had an existing MDM enrollment state, confirmed in export text and MDMEnrolled metadata.

3. Why was an existing MDM enrollment still present?
- Because the device had a legacy manual MDM enrollment from 2023-11-04 that was not fully removed before Autopilot enrollment.

4. Why was that legacy state not removed before reuse?
- Because redeployment/offboarding procedure did not consistently enforce cloud object cleanup and local enrollment artifact cleanup prior to Autopilot flow.

5. Why was procedure not consistently enforced?
- Because there was no mandatory pre-Autopilot readiness control/checklist with hard validation gates for legacy enrollment remnants.

### 5 Whys conclusion
The process root cause is a lifecycle control gap: absence of a mandatory preflight validation and cleanup standard for previously managed devices entering Autopilot provisioning.

## Corrective actions completed/planned

### Immediate corrective action for affected device
1. Remove stale Intune managed device object(s) and duplicate stale Entra device object(s) for the endpoint.
2. Remove legacy work/school enrollment connection and any orphaned enterprise enrollment artifacts on the device.
3. Reboot/reset device into clean Autopilot OOBE path.
4. Re-run Autopilot enrollment and force initial sync.
5. Validate enrollment success and baseline profile application.

### Validation criteria after fix
- Enrollment state shows Successful.
- 0x80180014 no longer appears for current enrollment attempt.
- Device has exactly one active intended MDM enrollment record.
- Policy application count increases from 0 to expected assigned profile count.
- Compliance engine can evaluate status normally.

## Preventive action plan

### Preventive objective
Prevent enrollment collisions caused by legacy/manual MDM remnants on reused or redeployed devices.

### Controls
1. Pre-Autopilot readiness gate (mandatory)
- Check for existing Intune managed records by serial/hardware hash.
- Check for duplicate/stale Entra device objects.
- Block Autopilot assignment until cleanup evidence is attached.

2. Standardized deprovisioning SOP
- During offboarding/redeployment, require both cloud cleanup and device-side enrollment disconnect.
- Record completion in ticket workflow before device can be reassigned.

3. Automation and reporting
- Run scheduled report for devices with signs of legacy/manual enrollment plus new Autopilot assignment intent.
- Alert endpoint ops queue when conflict indicators are found.

4. Change governance
- Add quality gate in endpoint release checklist requiring sign-off on enrollment-state hygiene.

### Ownership and target dates
- Endpoint Engineering: define/update SOP and checklist.
- Intune Operations: implement preflight validation runbook and dashboard/report.
- Service Desk L2: execute device-side cleanup playbook on reuse events.
- Target: implement controls in next operations cycle (30 days).

### Preventive success metrics
- Metric 1: Count of Autopilot failures with existing-enrollment conflict per month.
- Metric 2: Percentage of reused devices passing preflight on first attempt.
- Metric 3: Mean time to enroll reused devices after handoff.
- Acceptance target: zero repeat incidents for this failure mode across two consecutive reporting cycles.

## Residual risk
If manual or legacy management methods are reintroduced without cleanup governance, the same conflict can recur. Residual risk remains moderate until preflight controls are operational and audited.

## Lessons learned
- Enrollment-state hygiene is as critical as licensing and network readiness.
- Compliance and policy failures can be downstream symptoms; enrollment root state must be resolved first.
- Reuse workflows require explicit technical gates, not only procedural guidance.

## Appendix A: Key raw evidence excerpt
- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM
- MDMEnrolled: Yes (previous enrollment from 2023-11-04)
- EnrollmentSource: Legacy manual MDM enrollment
- ProfilesApplied: 0 of 4
- LastError: 0x80070005 (Access denied)
- AzureADJoined: Yes
- IntuneP1License: Yes
- AutopilotLicense: Yes
- Network: All endpoints reachable, no proxy
