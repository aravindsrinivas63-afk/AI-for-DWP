# Windows 11 Intune Compliance Policy Translation

## Scope
This document translates the stated Windows 11 security baseline into Microsoft Intune compliance policy settings for the **Windows 10 and later** platform.

## Current UI path
Based on the tenant UI you provided, use this path in the Intune admin center:

- **Open compliance policies**: Devices > Compliance
- **Create policy**: Devices > Compliance > Policies > Create policy
- **Platform**: Windows 10 and later
- **Profile type**: Windows 10/11 compliance policy
- **Wizard steps**: Basics > Compliance settings > Actions for noncompliance > Assignments > Review + create
- **Compliance settings sections shown in the wizard**: Custom Compliance, Device Health, Device Properties, Configuration Manager Compliance, System Security, Microsoft Defender for Endpoint, Windows Subsystem for Linux (WSL)
- **Actions for noncompliance while creating a new policy**: wizard step 3, **Actions for noncompliance**
- **Actions for noncompliance for an existing policy**: Devices > Compliance > Policies > select policy > Properties > Actions for noncompliance
- **Final step before save**: Review + create

## UI path drift flag
Microsoft Learn still shows some compliance-related flows under **Endpoint security > Device compliance**, especially for notifications and some cross-linked articles. In your tenant, the working path for policy creation and policy editing is clearly:

- Devices > Compliance

Treat the setting names below as authoritative, and use **Devices > Compliance** as the primary navigation path for this environment.

## Wizard-aligned build notes

- In your tenant, the creation blade explicitly uses **Platform** and **Profile type** before the policy wizard opens.
- The compliance controls in this document are entered on the **Compliance settings** step, inside the exact section names shown in your screenshots.
- The 7-day grace period is configured on the separate **Actions for noncompliance** step, not inside **Compliance settings**.

## Policy settings translation

| Requirement | Settings name | Value | Effect | False-positive risk | Recommendation | UI path note |
| --- | --- | --- | --- | --- | --- | --- |
| Requirement 1: BitLocker must be enabled on the OS drive | **Require BitLocker** | **Require** | Marks the device noncompliant unless BitLocker is enabled on the Windows OS volume. | Commonly flags after BitLocker is enabled but before the next reboot, because Device Health Attestation evaluates this state at boot. Can also flag when BitLocker is suspended during BIOS or firmware work. | Require a reboot after enabling BitLocker or resuming protection, and avoid targeting unsupported or exception hardware with this policy. Do not replace this with generic encryption unless you accept weaker validation. | Compliance settings > Device Health |
| Requirement 2: Secure Boot must be enabled | **Require Secure Boot to be enabled on the device** | **Require** | Marks the device noncompliant unless Secure Boot is enabled in UEFI firmware. | Legacy BIOS devices, Compatibility Support Module configurations, and some older TPM-attested hardware can report noncompliant even if otherwise healthy for their age. | Scope the policy to supported Windows 11 hardware only. Validate firmware is set to UEFI-native boot and remove legacy boot exceptions before enforcement. | Compliance settings > Device Health |
| Requirement 3: Minimum OS build 22621.2861 | **Minimum OS version** | **10.0.22621.2861** | Marks the device noncompliant when its Windows version is lower than the specified minimum build. | Devices can briefly report the old build until the cumulative update completes and the final restart occurs. Confusion also happens because Windows 11 still commonly reports versions with the **10.0** prefix. | Use **10.0.22621.2861** exactly for this floor. If you need to support multiple approved Windows 11 branches at once, consider **Valid operating system builds** instead of a single minimum version. | Compliance settings > Device Properties |
| Requirement 4: Windows Defender real-time protection must be on | **Real-time protection** | **Require** | Marks the device noncompliant unless Microsoft Defender real-time monitoring is enabled. | Devices using third-party antivirus or Microsoft Defender in passive mode can appear noncompliant even when endpoint protection is healthy by design. | If the security standard requires Microsoft Defender specifically, standardize on Defender as the active AV. If the real requirement is any healthy AV, use **Antivirus** = **Require** instead, but that is a weaker mapping to this baseline statement. | Compliance settings > System Security > Defender |
| Requirement 5: Firewall must be enabled for all profiles | **Firewall** | **Require** | Marks the device noncompliant unless Windows Firewall is enabled and users cannot turn it off. | Microsoft documents that devices syncing immediately after reboot or wake can show **Error** transiently. Conflicting Group Policy can also make healthy devices appear noncompliant. | Use Intune firewall configuration profiles to enforce Domain, Private, and Public profile settings, and use compliance only as the health gate. Remove conflicting GPO-based firewall management where possible. | Compliance settings > System Security > Device security |
| Requirement 6: A PIN or password must be configured | **Require a password to unlock mobile devices** | **Require** | Requires the device to have a PIN or password before the user can unlock it. On Windows, this is the built-in compliance control closest to the baseline requirement. | Shared kiosks, meeting room devices, or special-purpose Windows devices can be flagged even when intentionally configured without standard user unlock patterns. There can also be short delays during initial Windows Hello for Business setup. | Exclude kiosk and shared-room device profiles from this compliance policy. If you need stronger assurance, pair this with Windows Hello for Business or device restriction policies rather than relying on compliance alone. | Compliance settings > System Security > Password |
| Requirement 7: Device must not be jailbroken or rooted | **No native Windows 10 and later compliance setting** | **Not available in built-in Windows compliance policy** | There is no native Intune Windows compliance setting that evaluates "jailbroken" or "rooted" state because that concept is primarily used on mobile platforms. | If you try to force an equivalent with an unrelated setting, you create policy noise rather than a valid control. | Do not fake this requirement with another setting. For compromise assurance on Windows, use **Require the device to be at or under the machine risk score** with Microsoft Defender for Endpoint, or use custom compliance for a defined Windows integrity signal. | No matching Windows compliance page item exists in Devices > Compliance for this requirement. |

## Grace period
In the current UI, set the policy action for noncompliance as follows:

- **Wizard step**: Actions for noncompliance
- **Default action shown**: Mark device noncompliant = Immediately
- **Required change**: change the built-in **Mark device noncompliant** schedule from **Immediately** to **7** days
- **Target value**: Mark device noncompliant = 7 days after noncompliance

### Effect
Users get a 7-day remediation window before Intune marks the device as noncompliant for Conditional Access purposes.

### Important note
The screenshot confirms the built-in default action is currently **Immediately**. In practice, that is the zero-day behavior. You must change that built-in action to **7** days if you want a real 7-day grace period.

## Assignments
The screenshot shows the next wizard step as **Assignments**. Use this step to target the policy to the correct scope.

### UI details shown in the screenshot

- **Included groups**
- **Add groups**
- **Add all users**
- **Add all devices**
- **Excluded groups**
- **No groups selected** until you add a target group

### Important assignment rule
When excluding groups, you cannot mix user groups and device groups across include and exclude. Keep the targeting model consistent for the policy.

### Recommendation
For this Windows compliance policy, prefer **device groups** when you want the policy to follow the device regardless of which user signs in. Use **all users** only if your compliance model is intentionally user-scoped.

## Review + create
The screenshot sequence ends on **Review + create**. Use this step to confirm the policy before publishing it.

### What to verify before creating

- **Policy name** is correct and clearly identifies the Windows 11 baseline
- **Platform** is **Windows 10 and later**
- **Profile type** is **Windows 10/11 compliance policy**
- **Compliance settings** include the intended device health, device properties, and system security controls
- **Actions for noncompliance** show **Mark device noncompliant = Immediately** changed to the intended **7-day** grace period
- **Assignments** contain the expected included and excluded groups

### Recommendation
Use the review screen as the last chance to catch accidental group targeting or an unchanged default grace period before you save the policy.

## Validation and monitoring
Use this section after the policy is assigned and the test device has synced.

### Where to check the compliance status for this policy

- Go to **Devices > Compliance > Policies**
- Open the specific **Windows 10/11 compliance policy**
- Use the policy's **Device status** or **Monitor** view to inspect the assigned device's result for that policy
- If you need a setting-level view, check the policy's per-setting results from the same policy page rather than from the tenant-wide compliance dashboard

### What the compliance states mean

- **Compliant**: The device currently meets the policy. Conditional Access should treat it as allowed if the CA policy requires a compliant device.
- **Not compliant**: The device fails one or more checked settings. Conditional Access should block access when the CA policy requires compliance.
- **In grace period**: The device is currently noncompliant, but the configured noncompliance action delay has not expired yet. Conditional Access behavior depends on your CA design, but the device is effectively in a remediation window rather than in a healthy state.

### BitLocker false-positive check list
If the device shows noncompliant on BitLocker even though BitLocker is enabled, check these first:

- **Boot-time attestation has not refreshed yet**: BitLocker is only measured at boot for this compliance signal. Fastest check: restart the device and then sync it again.
- **The compliance check is still catching up after enablement or suspension**: The drive may be encrypted, but the policy has not re-evaluated after BitLocker was turned on, resumed, or completed. Fastest check: confirm `manage-bde -status` shows protection on, then reboot and resync.
- **Conflicting firmware or trust-state conditions are blocking the attestation result**: BIOS/UEFI changes, TPM issues, or suspended protectors can keep the device out of the trusted state Intune expects. Fastest check: verify Secure Boot is on, confirm TPM is healthy, and ensure no BitLocker protectors are suspended.

### First 24 hours monitoring

- Watch the policy's device list for the count of BitLocker-related failures and whether they cluster on newly updated devices.
- Compare failures against restart state, because a large spike that disappears after reboot is usually timing, not real encryption loss.
- Confirm the number of **In grace period** devices stays within the expected migration ring.
- Check whether noncompliance is isolated to a build, a device model, or a specific update wave.
- If Conditional Access is in scope, verify that compliant devices are still authenticating and that only truly failing devices are blocked.

## Recommended implementation notes

- For Requirement 5, compliance can check firewall state, but it is not the right place to define profile-level firewall rules. Enforce profile behavior through Endpoint security firewall policy and let compliance act as the gate.
- For Requirement 7, the cleanest Windows-native compensating control is usually Microsoft Defender for Endpoint machine risk integrated into compliance.
- For Requirement 3, if your estate spans more than one supported Windows 11 release train, **Valid operating system builds** is easier to maintain than a single minimum OS version.

## Suggested exact baseline in Intune

- Require BitLocker = Require
- Require Secure Boot to be enabled on the device = Require
- Minimum OS version = 10.0.22621.2861
- Real-time protection = Require
- Firewall = Require
- Require a password to unlock mobile devices = Require
- Jailbroken or rooted = No native Windows compliance equivalent
- Mark device noncompliant = 7 days after noncompliance
