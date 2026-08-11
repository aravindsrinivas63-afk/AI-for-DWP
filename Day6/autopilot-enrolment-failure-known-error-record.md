# Known-Error Record - Autopilot Enrollment Failure

Symptom : A Windows device fails during Autopilot enrollment. The enrollment attempt returns failed with 0x80180014, and the device does not complete managed setup. Policy processing may also show 0 of expected profiles applied, with secondary error 0x80070005.

Cause : The device already has an existing legacy manual MDM enrollment state, which conflicts with the new Autopilot enrollment attempt. In the confirmed case, the prior enrollment dated from 2023-11-04.

Scope : This error pattern applies to reused or redeployed Windows devices that were previously manually enrolled in MDM and were not fully cleaned up before Autopilot reprovisioning. The confirmed incident affected DESKTOP-FB099 for FINBRIDGE\rthomas.

Workaround : Remove the stale enrollment footprint, then rerun Autopilot. In Intune and Entra, delete stale device/enrollment records for the endpoint. On the device, remove the old work or school connection, reboot or reset into a clean OOBE state, and start Autopilot enrollment again.

Permanent fix: Add a mandatory pre-Autopilot readiness check for reused devices to detect and remove legacy/manual MDM enrollment artifacts in both cloud records and local device enrollment state before profile assignment or redeployment.

How to spot it: Look for this combination: EnrollmentState = Failed, ErrorCode = 0x80180014, ErrorDescription = The device is already enrolled in MDM, MDMEnrolled = Yes (previous enrollment), and EnrollmentSource showing legacy or manual MDM enrollment. Supporting indicators often include AzureADJoined = Yes, licensing present, network endpoints reachable, and ComplianceEngine unable to evaluate because enrollment did not complete.