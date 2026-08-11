# Step-by-Step Guide: Add a Windows Application to the Intune App Catalog (Pre-Phased Rollout)

Purpose: This guide shows a DWP engineer how to add a Windows application to Intune before any phased rollout starts.
Worked example used throughout: FinBridge Connect v3.1, packaged as a .intunewin file.

Example package details:
- Package file: FinBridgeConnect_v3.1.intunewin
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Detection method: Registry key
- Registry path: HKLM\SOFTWARE\FinBridge\Connect
- Value name: Version
- Expected value: 3.1

Important note about UI labels: Exact menu names and blade labels can vary between tenant versions, Intune UI refresh waves, and role-based views. For every step below, verify the live label in your own tenant instead of relying only on the wording shown here.

## 1. Sign in to Intune Admin Center
1. Open https://intune.microsoft.com and sign in with an account that has app-management permissions.
2. If your tenant opens through Microsoft Endpoint Manager branding or a slightly different home page, continue using the equivalent Apps area in your live portal.

## 2. Navigate to the App Catalog Area
1. In the left navigation, go to Apps.
2. Select All apps.
3. Select Create (or Add in some tenants).
4. In the create pane, confirm Platform is set to Windows.
5. Verify the blade title and labels in your tenant. Common labels include Create, Add app, Select app type, or Create app.

## 3. Choose the Correct App Type
1. In App type, select Windows app (Win32), then select Select to continue.
2. For .intunewin packages, Windows app (Win32) is the correct choice in current Intune UI.
3. Note on terminology: some teams loosely call this a Windows LOB deployment workflow, but the selectable Intune app type label for .intunewin is Windows app (Win32).
4. For comparison, choose these alternatives only when appropriate:
5. Microsoft Store app path: choose Microsoft Store app (new) when deploying from the Microsoft Store catalog.
6. Web link path: choose Web link when you only need a URL shortcut and not a local software install.
7. UI labels can vary by tenant version. Verify the live label before proceeding.

## 4. Complete App Information (Includes Package Selection)
1. On App information, select file and upload FinBridgeConnect_v3.1.intunewin.
2. Wait for Intune to process package metadata.
3. Enter Name: FinBridge Connect v3.1.
4. Enter Description: FinBridge Connect desktop client for secure access to FinBridge services.
5. Enter Publisher: FinBridge.
6. Enter Version: 3.1.
7. Add optional metadata like category, logo, and owner if your DWP standard requires it.
8. Do not continue until package upload and validation complete.
9. Verify live labels in your tenant because this page can vary (for example, Select file may appear within App information).

## 5. Configure Program Settings
1. Go to Program.
2. Set Install command to FinBridgeConnect_Setup.exe /silent.
3. Set Uninstall command to FinBridgeConnect_Setup.exe /uninstall /silent.
4. Set Install behavior to System for device-level installation.
5. Use User context only if the app requires per-user profile installation and your packaging standard supports that mode.
6. Keep restart behavior aligned with your packaging and support model.
7. Configure Return codes in this stage if shown in your tenant, or in the equivalent advanced section.
8. Confirm success and reboot mappings include at least:
9. 0 as Success.
10. 3010 as Soft reboot required.
11. 1641 as Hard reboot initiated or equivalent reboot state.
12. Classify non-success codes as failures unless your packaging standard defines otherwise.
13. Verify labels such as Install behavior, Device context, User context, and Return codes in your tenant.

## 6. Configure Requirements
1. Go to Requirements.
2. Set Operating system architecture to match your package support, usually 64-bit.
3. Set Minimum operating system to your supported baseline, for example Windows 10 22H2 or Windows 11 baseline used by your organization.
4. If your tenant shows requirement presets differently, verify and choose the equivalent architecture and minimum OS controls.

## 7. Configure Detection Rules
1. Go to Detection rules.
2. Select Rule type: Registry.
3. Set Key path: HKLM\SOFTWARE\FinBridge\Connect.
4. Set Value name: Version.
5. Set Detection method: String comparison.
6. Set Operator: Equals.
7. Set Value: 3.1.
8. Set Associated with a 32-bit app on 64-bit clients: No.
9. Save the rule.
10. Understand why this matters: Intune marks installation as successful only when this rule is true on the device.
11. Alternative detection options you may use for other apps include MSI product code or file/folder path checks.
12. Verify control names in your tenant because detection-rule UI wording commonly varies.

## 8. Configure Dependencies (If Required)
1. Go to Dependencies.
2. Add dependencies only if FinBridge Connect requires another app to be installed first (for example, a runtime, agent, or prerequisite package).
3. If no prerequisite app is required, leave Dependencies empty.

## 9. Configure Supersedence (If Required)
1. Go to Supersedence.
2. Add supersedence only if FinBridge Connect v3.1 must replace or uninstall an older managed app version.
3. If this is a first deployment or there is no managed predecessor app, leave Supersedence empty.
4. For initial pilot rollout, it is normal to leave Supersedence unconfigured unless there is a proven technical requirement.
5. Verify section labels in your tenant because these blades can appear in different positions depending on UI version.

## 10. Understand Assignment Types Before Targeting Devices
1. Required means Intune pushes install automatically to targeted devices or users.
2. Available means app appears in Company Portal for self-service install.
3. Uninstall means Intune removes the app from targeted devices or users.
4. Verify assignment label text in your tenant because wording can vary slightly by UX version.

## 11. Configure Assignments (Pilot First)
1. In the wizard, go to Assignments.
2. Add a small pilot group, not the entire production fleet.
3. Recommended pilot size is a controlled set of representative devices and users.
4. Do not assign directly to all 10,000 devices.
5. Reason: pilot assignment limits blast radius, validates packaging and detection behavior, and reduces service impact if rollback is needed.
6. Use Required for managed silent rollout testing, or Available if your pilot requires user-triggered install through Company Portal.
7. Use Uninstall only when testing managed removal behavior.

## 12. Review + Create the App
1. Open the Review + create page.
2. Check all entered values, commands, requirements, detection rules, dependency/supersedence choices, and assignments.
3. Select Create.
4. Wait until the app object appears in All apps.

## 13. Verify the App Appears in the Catalog
1. Return to Apps > All apps.
2. Search for FinBridge Connect v3.1.
3. Open the app and confirm:
4. App type is the expected .intunewin-compatible type.
5. Version is 3.1.
6. Program commands match the defined install and uninstall values.
7. Detection rule shows Registry, Key path HKLM\SOFTWARE\FinBridge\Connect, Value name Version, Detection method String comparison, Operator Equals, Value 3.1, and 32-bit on 64-bit set to No.
8. Return codes include your approved success/reboot mappings (for example, 0, 3010, 1641).

## 14. Verify Install Status on a Pilot Device
1. Ensure at least one pilot device has synced with Intune.
2. In Intune, open the app and go to Device install status.
3. Locate the pilot device entry.
4. Confirm status transitions after policy sync and install window.
5. If needed, trigger manual sync from the device via Settings > Accounts > Access work or school > connected account > Info > Sync.
6. Re-check Intune status after sync and install attempt.

## 15. Interpret Common Status Values
1. Installed means Intune detected the app successfully using your detection rule.
2. Failed means installer or detection did not complete successfully. Review return code, command syntax, and detection rule accuracy.
3. Not applicable means the device does not meet requirements or target conditions, such as unsupported OS version, architecture mismatch, or assignment filter exclusion.

## 16. Gate to Phased Rollout
1. Proceed to phased rollout only after pilot success criteria are met.
2. Minimum criteria should include stable install success rate, low failure rate, validated uninstall behavior, and no critical user-impact incidents.
3. Record findings and adjust commands, requirements, or detection rules before broad assignment.

## 17. Quick Execution Checklist
1. Correct app type selected for .intunewin package.
2. App information completed, including package file upload.
3. Install and uninstall commands validated.
4. Install behavior set correctly to System or User context.
5. Return codes mapped correctly.
6. Requirements aligned to supported OS and architecture.
7. Detection rule validated on a real pilot endpoint.
8. Dependencies configured only when a prerequisite is genuinely required.
9. Supersedence configured only when replacing a managed predecessor app.
10. Assignment set to pilot group first.
11. Review + create completed after assignment review.
12. Status reviewed until pilot outcomes are clear.
13. Only then move to phased production rollout.
