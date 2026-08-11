# Autopilot Enrollment Failure Knowledge Base (L2/L3)
Version Header: v 1.0, 11/08/2026, status : Draft
Version: v 1.0
Date: 11/08/2026
Status : Draft

## Background: what the system does and why it matters
Windows Autopilot is used to provision corporate Windows devices into a managed state with Microsoft Entra join and Intune MDM enrollment. For reused or redeployed hardware, the Autopilot path depends on the device entering setup with a clean management state. If a previous manual or legacy MDM enrollment still exists, the new Autopilot enrollment can fail before policy application, leaving the device unmanaged or only partially configured.

In this incident pattern, cloud licensing and network reachability are healthy, but device lifecycle hygiene is not. The primary control boundary is whether old MDM enrollment state was fully removed before the Autopilot attempt.

## Symptom: what the engineer observes and what the user reports
### What users report
- "The device will not finish setup."
- "Autopilot enrollment failed."
- "I keep getting an enrollment error during setup."

### What engineers observe
- Enrollment attempt type is Autopilot.
- Enrollment state is Failed.
- Error code is 0x80180014.
- Error text states the device is already enrolled in MDM.
- Policy stage may show 0 of expected profiles applied.
- Compliance engine cannot evaluate because enrollment did not complete.
- Azure AD joined may already show Yes.
- Network and licensing checks are often healthy, which helps narrow the fault to enrollment-state conflict.

## Root cause: the specific technical cause with the evidence that confirms it
The root cause is a pre-existing legacy manual MDM enrollment that was not fully removed before the device entered Autopilot provisioning. That stale enrollment state conflicts with the new Autopilot MDM transaction and causes enrollment failure 0x80180014.

### Confirming evidence
- EnrollmentState = Failed.
- ErrorCode = 0x80180014.
- ErrorDescription = The device is already enrolled in MDM.
- MDMEnrolled = Yes (previous enrollment).
- EnrollmentSource = Legacy manual MDM enrollment.
- ComplianceEngine result = Could not evaluate because enrollment not complete.
- ProfilesApplied = 0 of 4.
- Network endpoints reachable and licensing present, ruling out two common alternatives.

### Secondary evidence
- 0x80070005 (Access denied) at policy stage is secondary in this incident pattern.
- It is consistent with incomplete or conflicted enrollment context rather than the primary initiating fault.

## Detection: exactly how to confirm this is the issue before acting
Target outcome: confirm or reject this incident signature in under 5 minutes.

1. Check the exact enrollment failure signature
- Required evidence fields:
  - EnrollmentState
  - ErrorCode
  - ErrorDescription
  - MDMEnrolled
  - EnrollmentSource
- Positive match:
  - EnrollmentState = Failed
  - ErrorCode = 0x80180014
  - ErrorDescription contains device already enrolled in MDM
  - MDMEnrolled = Yes
  - EnrollmentSource indicates legacy or manual MDM enrollment

2. Confirm common prerequisites are not the blocker
- Check fields:
  - AzureADJoined
  - IntuneP1License
  - AutopilotLicense
  - Network endpoint reachability
  - ProxyDetected
- Positive baseline:
  - AzureADJoined = Yes is acceptable
  - IntuneP1License = Yes
  - AutopilotLicense = Yes
  - Microsoft enrollment endpoints reachable
  - ProxyDetected = No

3. Confirm downstream symptoms are consistent with incomplete enrollment
- Check fields:
  - ProfilesAttempted
  - ProfilesApplied
  - ComplianceEngine evaluation result
- Supporting pattern:
  - ProfilesApplied = 0 of expected set
  - ComplianceEngine cannot evaluate because enrollment not complete

4. Device-side confirmation if the device is accessible
- Open Settings > Accounts > Access work or school.
- Look for an existing organization connection that predates current Autopilot attempt.
- Run:

```cmd
 dsregcmd /status
```

- Record join state and account state for case notes.

5. Portal-side confirmation if admin access is available
- Intune admin center path: Devices > All devices.
- Search by device name and serial number.
- Look for stale, duplicate, or older managed device records.
- Entra admin center path: Devices > All devices.
- Look for duplicate device objects for the same hardware identity.

## Resolution: step-by-step fix with expected result after each step
Goal: remove the stale enrollment footprint completely, then rerun Autopilot from a clean state.

### Phase 1: Intune cleanup
1. Open Intune admin center > Devices > All devices.
- Search for the affected device by device name and serial number.
- Expected result: all matching managed device records are visible.

2. Review each matching Intune record.
- Check enrollment date, management type, last check-in, and ownership context.
- Expected result: stale legacy-managed record is distinguishable from intended current target state.

3. Delete stale or duplicate managed device record(s).
- Use Delete on the stale enrollment record.
- Expected result: only the intended device record remains, or all stale conflicting records are removed before reenrollment.

4. Open Intune admin center > Devices > Windows > Windows enrollment > Devices.
- Validate the Autopilot device entry exists and is not duplicated.
- Expected result: one correct hardware-hash-backed Autopilot record.

5. If duplicate Autopilot entries exist for the same device, remove stale duplicate entry.
- Expected result: only one valid Autopilot registration remains.

### Phase 2: Entra device cleanup
1. Open Entra admin center > Devices > All devices.
- Search for matching device objects.
- Expected result: any duplicate or stale device identities are visible.

2. Delete stale duplicate device objects that are not the active intended identity.
- Expected result: one correct active device object remains.

### Phase 3: Device-side cleanup
1. Access the device locally or remotely with administrative support rights.
- Expected result: support can inspect and remove local enrollment artifacts.

2. Open Settings > Accounts > Access work or school.
- Remove the old work or school connection tied to the previous manual enrollment.
- Expected result: legacy connection no longer appears.

3. Inspect EnterpriseMgmt task artifacts.
- Path: Task Scheduler > Microsoft > Windows > EnterpriseMgmt.
- Remove orphaned enrollment task folders associated with the removed legacy enrollment if still present.
- Expected result: no stale scheduled enrollment tasks remain for the old enrollment context.

4. Capture device registration state.

```cmd
 dsregcmd /status
```

- Expected result: output saved to the ticket and used to confirm post-cleanup state.

5. Reboot the device.
- Expected result: local enrollment artifacts are fully unloaded and the device is ready for clean reprovisioning.

### Phase 4: Re-run Autopilot
1. Reset or reprovision the device into OOBE according to support standard.
- Expected result: device starts setup from a clean state.

2. Connect to network and proceed through Autopilot sign-in with the intended user account.
- Expected result: Autopilot profile applies and enrollment continues without immediate MDM conflict.

3. Allow initial enrollment and policy sync to complete.
- Expected result: device reaches managed desktop or completes assigned provisioning stage.

### Phase 5: Post-enrollment sync
1. On the device, open Settings > Accounts > Access work or school > connected org account > Info > Sync.
- Expected result: fresh device sync is triggered.

2. In Intune admin center, reopen the device record and review compliance/policy state.
- Expected result: current enrollment timestamp, healthy check-in, and policy application progress are visible.

## Verification: how to confirm the fix worked
Run all checks before closure.

1. Verify enrollment succeeded
- Required result:
  - Enrollment no longer fails.
  - 0x80180014 does not recur.
  - Current enrollment status is successful or healthy in the portal/device record.

2. Verify there is only one active management record
- Intune admin center path: Devices > All devices.
- Entra admin center path: Devices > All devices.
- Pass condition: no stale duplicates remain for the hardware.

3. Verify Autopilot completed
- Required result:
  - Device completes setup.
  - Assigned Autopilot profile is in effect.
  - User reaches the managed desktop successfully.

4. Verify policy application moved forward
- Required result:
  - Profiles applied progress beyond previous 0 of 4 state.
  - Compliance engine can evaluate normally after enrollment completion.

5. Verify device-side state
- Run:

```cmd
 dsregcmd /status
```

- Pass condition: join and workplace state align with intended post-enrollment design.

## Rollback: what to do if reenrollment still fails
Trigger deeper rollback or escalation if 0x80180014 persists after cleanup.

1. Recheck Intune, Autopilot, and Entra for hidden duplicates or delayed-deletion artifacts.
- Expected result: no remaining stale objects are missed.

2. Confirm device-side work or school enrollment was fully removed.
- Expected result: no prior organization connection remains.

3. Reboot and retry once only after confirmed cleanup.
- Expected result: one controlled reattempt after validated state reset.

4. If still failing, escalate with full evidence set.
- Include:
  - screenshots or export showing 0x80180014
  - Intune object inventory
  - Entra object inventory
  - dsregcmd output
  - timestamps of deletion and reattempt
- Expected result: escalation starts with complete evidence rather than repeating first-line steps.

## Preventive control: how to stop this recurring
1. Add a mandatory pre-Autopilot readiness check for reused devices.
- Check for stale Intune managed records.
- Check for duplicate Entra device objects.
- Check for local work or school enrollment remnants.

2. Update redeployment SOP.
- Require cloud-object cleanup plus local enrollment removal before device reassignment.

3. Add reporting/alerting.
- Flag reused devices with historical manual enrollment before Autopilot assignment.

4. Track this as a known error pattern.
- Use recurring incident metrics to validate preventive control adoption.

## Engineer quick reference
- Primary fault signature: 0x80180014 with explicit device already enrolled in MDM text.
- Primary root cause: stale legacy manual MDM enrollment.
- Immediate fix path: remove stale cloud records, remove device-side legacy enrollment, reboot/reset, rerun Autopilot.
- Do not over-focus on network or licensing when export already shows them healthy.
