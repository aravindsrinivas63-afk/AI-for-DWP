# Autopilot Enrollment Failure: L1 Support KB
Version: v 1.0
Date: 11/08/2026
Status: Draft

This article helps L1 support handle a Windows Autopilot enrollment failure where the device may already have an older MDM enrollment. Use this when a device fails during setup and does not complete managed enrollment.

## When to Use This KB

Use this KB if the user or field engineer reports:
- The device fails during Autopilot setup.
- The setup process does not complete device enrollment.
- The error shown or collected in diagnostics includes 0x80180014.
- The device appears to have been used before or was recently redeployed.

## What L1 Should Check First

1. Confirm the device is connected to the internet.
Expected result: The device has a working wired or wireless connection.

2. Confirm the user can reach the Microsoft sign-in screen during setup.
Expected result: The user can enter work credentials and continue in the enrollment flow.

3. Ask whether the device is new, reused, or recently rebuilt.
Expected result: You know whether this may be a redeployment scenario.

4. Capture the exact error message and code shown during enrollment.
Expected result: You have the exact wording and code for the ticket.

5. If diagnostics are available, check whether the following are present:
- EnrollmentState: Failed
- ErrorCode: 0x80180014
- ErrorDescription: The device is already enrolled in MDM
Expected result: You confirm this known error pattern.

## What This Usually Means

If 0x80180014 is present with a message that the device is already enrolled in MDM, the most likely cause is a legacy or stale enrollment record from an earlier setup. Autopilot cannot complete while that conflicting enrollment state still exists.

## What L1 Can Do

1. Confirm basic connectivity only.
Expected result: Required setup traffic is not obviously blocked.

2. Confirm the user has the correct assigned device and is using the correct work account.
Expected result: Wrong-user or wrong-device confusion is ruled out.

3. Record whether the device was previously in use.
Expected result: Ticket includes reuse/redeployment context.

4. Collect the following details for escalation:
- Device name
- Serial number, if available
- User name
- Date and time of failure
- Screenshot/photo of the error
- Whether the device is reused or newly issued
- Any diagnostic export or enrollment log available
Expected result: L2/L3 receives enough detail to act without re-contacting the user.

## What L1 Should Not Do

1. Do not repeatedly retry Autopilot enrollment multiple times.
Expected result: Avoids delay and duplicate failed enrollment attempts.

2. Do not advise the user to keep signing in again and again.
Expected result: Prevents unnecessary repeat failures.

3. Do not remove device records from Intune or Entra unless your process explicitly allows L1 to do this.
Expected result: Avoids accidental deletion of active management objects.

4. Do not tell the user the issue is a licensing or network fault if diagnostics show licensing is present and endpoints are reachable.
Expected result: Escalation stays focused on the likely enrollment conflict.

## Escalation Path

Escalate to L2/L3 Endpoint Management if:
- Error 0x80180014 is present.
- The message says the device is already enrolled in MDM.
- The device is known to be reused or redeployed.
- Basic connectivity is working but enrollment still fails.

## Escalation Summary Template

Use this wording in the ticket:

"Autopilot enrollment failed on [device name] for [user] at [time/date]. Error observed: 0x80180014. Message indicates device already enrolled in MDM. Device is [new/reused/rebuilt]. Basic connectivity confirmed. Please check for stale Intune/Entra/legacy MDM enrollment artifacts and advise cleanup/re-enrollment steps."

## Resolution Expected from L2/L3

L2/L3 will typically:
- Remove stale Intune or Entra device/enrollment records.
- Remove legacy work or school enrollment state from the device.
- Reboot or reset the device into a clean Autopilot state.
- Re-run enrollment and verify successful completion.

## How to Confirm Resolution

After L2/L3 completes remediation, confirm:
1. The device completes Autopilot setup.
Expected result: Enrollment finishes successfully.

2. The previous error does not return.
Expected result: 0x80180014 is no longer seen.

3. The user reaches the managed desktop normally.
Expected result: Device provisioning completes and the user can work.

## Quick Reference

- Primary known error: 0x80180014
- Known pattern: device already has existing MDM enrollment
- L1 action: confirm basics, collect evidence, escalate
- L1 stop point: do not attempt portal cleanup unless explicitly authorized
