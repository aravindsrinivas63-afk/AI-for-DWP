# Autopilot Enrolment Failure RCA and Remediation (Legacy MDM Conflict)

## Incident summary
- Device: DESKTOP-FB099
- User: FINBRIDGE\rthomas
- Date of failure: 2024-03-15 09:22
- Enrollment type: Autopilot
- Enrollment state: Failed
- Primary error: 0x80180014
- Secondary policy error: 0x80070005 (Access denied)
- Azure AD joined: Yes
- Existing MDM enrollment: Yes (legacy manual enrollment from 2023-11-04)
- Network reachability: Healthy (required endpoints reachable, no proxy)
- Licensing: Present (M365, Intune P1, Autopilot)

## Confirmed root cause
Autopilot enrollment failed because the device already had an existing legacy manual MDM enrollment record. The failure code 0x80180014 and export message explicitly indicate an existing MDM enrollment conflict that blocks new Autopilot enrollment.

## Why the secondary error is not the primary root cause
`0x80070005 (Access denied)` occurred during policy processing after enrollment attempt and is consistent with the enrollment state not being cleanly established. With the confirmed duplicate/stale enrollment condition present, the first corrective action is to remove the legacy enrollment conflict before reassessing policy-stage errors.

## Remediation plan (exact order of operations)

### Phase 1: Admin center cleanup (admin center only)
1. In Intune admin center, go to Devices > All devices.
2. Search for the affected device by name and serial number to identify duplicate or stale records.
3. Open each matching device record and review:
	- Enrollment type
	- Last check-in
	- Management name
	- Primary user
4. Retain the intended Autopilot target record and remove stale managed device record(s):
	- Select stale device object.
	- Use Delete.
5. Go to Devices > Windows > Windows enrollment > Devices (Autopilot devices).
6. Verify the hardware hash record exists only once for the device.
7. If duplicate Autopilot registration entries exist for the same hardware, remove stale duplicate entries and keep the correct active one.
8. Go to Entra admin center > Devices > All devices.
9. Locate duplicate Entra device objects tied to the same physical endpoint and remove stale/unneeded duplicate object(s), preserving the intended active identity.

### Phase 2: Device cleanup (requires device access: physical or remote)
1. Sign in to the affected Windows device with local admin or authorized support account.
2. Open Settings > Accounts > Access work or school.
3. Identify old organizational connection(s) tied to legacy manual MDM enrollment.
4. Disconnect/remove the old work or school connection.
5. Open elevated Command Prompt and run:

```cmd
dsregcmd /status
```

6. Confirm current join state and capture output for case notes.
7. Open Task Scheduler > Microsoft > Windows > EnterpriseMgmt.
8. Remove orphaned legacy MDM enrollment task folders if still present for the old enrollment context.
9. Reboot the device.

### Phase 3: Re-initiate Autopilot enrollment (requires device access: physical or remote)
1. Trigger a fresh Autopilot OOBE/enrollment cycle:
	- For repurposed device: perform required reset/wipe path per support standard.
	- Ensure device reaches OOBE and internet connectivity is available.
2. Sign in with intended user and allow Autopilot profile to apply.
3. Wait for MDM enrollment and initial policy processing to complete.

### Phase 4: Post-enrollment sync (split responsibilities)
1. Admin center only: Confirm new managed device record appears with current enrollment timestamp.
2. Device access (physical or remote): From Settings > Accounts > Access work or school > connected org account > Info, run Sync.
3. Admin center only: Recheck device status and policy application counts.

## Verification checks (success criteria)

### Enrollment success confirmation
- Enrollment state is Successful (not Failed).
- No recurrence of 0x80180014 on the latest enrollment attempt.
- Device shows one active current MDM enrollment record.

### Autopilot completion confirmation
- Autopilot profile assignment is visible for the device.
- Device completes provisioning flow without enrollment conflict interruption.

### Policy application confirmation
- ProfilesApplied increases from 0 of 4 to expected baseline application count.
- Failed profile no longer reports immediate access-denied condition tied to incomplete enrollment context.

### Identity and management consistency
- Azure AD join state remains expected.
- Intune managed state is healthy.
- No duplicate stale objects remain in Intune/Entra for this hardware.

## Preventive action for fleet (to avoid recurrence)

### Preventive control
Implement a pre-Autopilot readiness gate that checks for legacy/manual MDM enrollment artifacts before device import or reassignment.

### Recommended implementation
1. Admin center only: Define a standard pre-provision checklist requiring validation that no old Intune managed device object and no duplicate Entra object exists for the hardware/serial.
2. Device access (physical or remote): Add a pre-reset device-side check to remove legacy work/school enrollment connections before initiating Autopilot reuse.
3. Admin center only: Add cleanup SOP for stale objects during offboarding/redeployment events.
4. Admin center only: Track exceptions with recurring pattern (legacy enrollment collisions) and enforce mandatory cleanup before assigning Autopilot profile.

## Operations quick runbook

### Required sequence
1. Remove stale Intune/Entra records.
2. Remove legacy enrollment from device.
3. Reboot.
4. Re-run Autopilot enrollment from clean OOBE state.
5. Sync and verify enrollment/policy status.

### Access flags
- Admin center only:
  - Intune stale record cleanup
  - Autopilot device record validation
  - Entra duplicate object cleanup
  - Final monitoring and validation in portals
- Device access required (physical or remote):
  - Remove legacy work/school enrollment
  - Inspect/clean EnterpriseMgmt artifacts if present
  - Reboot/reset and run Autopilot flow
  - Local sync trigger and local status validation

## Final resolution statement
The failure is resolved by removing the conflicting legacy enrollment footprint (cloud objects and local enrollment artifacts), then re-running Autopilot enrollment on a clean management state.
