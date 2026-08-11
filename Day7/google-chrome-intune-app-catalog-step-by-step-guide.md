# Step-by-Step Guide: Add Google Chrome to the Intune App Catalog (Before Phased Rollout)

Purpose: This guide shows a DWP engineer how to add a Windows application to the Intune app catalog before any phased rollout begins.
Worked example used throughout: Google Chrome Enterprise, packaged as a `.intunewin` file.

## Worked example details
- Package type: Windows app packaged as `.intunewin`
- Example source MSI: `GoogleChromeStandaloneEnterprise64.msi`
- Example `.intunewin` package: `GoogleChromeStandaloneEnterprise64.intunewin`
- Install command: `msiexec /i "GoogleChromeStandaloneEnterprise64.msi" /qn /norestart`
- Uninstall command: `msiexec /x "{VERIFY-ACTUAL-CHROME-PRODUCT-CODE}" /qn /norestart`
- Detection method used in this guide: Registry key
- Example registry path: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{VERIFY-ACTUAL-CHROME-PRODUCT-CODE}`
- Example value name: `DisplayVersion`
- Example expected value: verify against the Chrome MSI version you are packaging
- Alternative detection option: MSI product code

Important note about version-specific values: Google Chrome MSI product codes and display versions can change between releases. Before you create the app, verify the exact product code and version from the MSI you are packaging. Do not copy the placeholder product code from this guide into production.

Important note about UI labels: Exact menu names, wizard names, and blade labels can vary between tenant versions, Intune UI refresh waves, and role-based views. At every step below, verify the live label in your own tenant rather than trusting the wording shown here.

## 1. Sign in to Intune admin center
1. Open `https://intune.microsoft.com`.
2. Sign in with an account that has permission to create and assign apps.
3. If your tenant opens with slightly different branding or landing pages, continue to the equivalent Apps area in the live portal.

## 2. Go to the app catalog area
1. In the left navigation, select Apps.
2. Select All apps.
3. Select Create, Add, or Create app, depending on your tenant.
4. In the create pane, confirm the platform is Windows.
5. Verify the live labels before continuing. Common label variations include:
   - Create
   - Add app
   - Select app type
   - Create app

## 3. Choose the correct app type
1. For a `.intunewin` package, select Windows app (Win32).
2. Select Select or the equivalent continue action.
3. Use Windows app (Win32) for packaged Windows line-of-business deployments that use `.intunewin`.
4. Use Microsoft Store app (new) only when deploying an app directly from the Microsoft Store catalog.
5. Use Web link only when you want to publish a URL shortcut rather than install local software.
6. Verify the live app-type labels in your tenant because wording can vary.

## 4. Prepare the Chrome package before uploading
1. Confirm you have the Google Chrome Enterprise MSI file.
2. Package the MSI into `.intunewin` format using the Microsoft Win32 content prep tool if the package is not already prepared.
3. Record these values before you start the wizard:
   - MSI filename
   - install command
   - uninstall command
   - Chrome version
   - MSI product code
   - detection method
4. Verify the MSI product code from the actual package. You will need it if you choose MSI-based detection or MSI uninstall by product code.
5. Verify the Chrome version from the MSI or a test install. You will use it for version-aware detection if your DWP standard requires exact version matching.

## 5. Complete App information
1. In the wizard, open App information.
2. Select the file-upload control and upload `GoogleChromeStandaloneEnterprise64.intunewin`.
3. Wait for Intune to finish package processing.
4. Enter Name: `Google Chrome Enterprise`.
5. Enter Description: `Google Chrome Enterprise browser for managed corporate Windows devices.`
6. Enter Publisher: `Google`.
7. Enter Version: use the exact version from the packaged Chrome MSI.
8. Add optional metadata such as category, logo, information URL, privacy URL, owner, or notes if your DWP standard requires them.
9. Do not continue until upload and validation complete.
10. Verify the live page labels because some tenants place file upload inside App information with slightly different wording.

## 6. Configure Program settings
1. Open Program.
2. Set Install command to:

```text
msiexec /i "GoogleChromeStandaloneEnterprise64.msi" /qn /norestart
```

3. Set Uninstall command to:

```text
msiexec /x "{VERIFY-ACTUAL-CHROME-PRODUCT-CODE}" /qn /norestart
```

4. Set Install behavior to System for normal device-level Chrome deployment.
5. Use User context only if you have a specific packaging reason to deploy per user and your support standard explicitly allows it.
6. Keep Device restart behavior aligned with your packaging standard. For silent MSI deployment, do not force unexpected restarts unless there is a tested requirement.
7. Configure return codes in this stage if they are shown here, or in the equivalent advanced section if your tenant places them elsewhere.
8. At minimum, confirm these standard mappings unless your packaging standard says otherwise:
   - `0` = Success
   - `3010` = Soft reboot required
   - `1641` = Hard reboot initiated
9. Treat unknown non-success exit codes as failures unless the package owner has approved a specific mapping.
10. Verify labels such as Install behavior, Device context, User context, Restart behavior, and Return codes in your tenant.

## 7. Configure Requirements
1. Open Requirements.
2. Set Operating system architecture to the architecture supported by your Chrome package. For the worked example, use `64-bit`.
3. Set Minimum operating system to the lowest Windows version your organization supports for this app, for example your approved Windows 10 or Windows 11 baseline.
4. If your tenant shows these controls with different names or presets, verify the equivalent architecture and minimum-OS options before saving.

## 8. Configure Detection rules
1. Open Detection rules.
2. Decide how Intune will confirm installation succeeded. Common options are:
   - Registry key
   - MSI product code
   - File or folder path
3. For this worked example, use Registry.
4. Set Rule type to Registry.
5. Set Key path to:

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{VERIFY-ACTUAL-CHROME-PRODUCT-CODE}
```

6. Set Value name to `DisplayVersion`.
7. Set Detection method to String comparison.
8. Set Operator to Equals if your DWP standard requires exact version match. If your packaging standard allows minor-version tolerance, use the operator approved by your team.
9. Set Value to the exact Chrome version from the MSI you are deploying.
10. Set Associated with a 32-bit app on 64-bit clients to No for the 64-bit Chrome example.
11. Save the rule.
12. Understand why this matters: Intune marks the app as installed only when the detection rule is true on the device.
13. Alternative detection options you may choose for Chrome in another design are:
   - MSI product code detection using the verified Chrome MSI product code
   - File detection, for example checking `chrome.exe` in the installed program path
14. Verify the control names in your tenant because detection-rule wording commonly varies.

## 9. Configure Return codes carefully
1. If Return codes are displayed in a separate stage or expandable section, review them before creating the app.
2. Confirm success and reboot behavior for the installer.
3. Use standard MSI mappings unless your packaging standard overrides them:
   - `0` = Success
   - `3010` = Soft reboot required
   - `1641` = Hard reboot initiated
4. Mark unexpected or unapproved codes as Failure.
5. Reason: wrong return-code mapping can make a successful install look failed, or hide a real deployment problem.

## 10. Configure Dependencies if needed
1. Open Dependencies.
2. Add dependencies only if your Chrome deployment genuinely requires another managed package first.
3. If there is no prerequisite, leave Dependencies empty.
4. Do not add unnecessary dependencies because they complicate troubleshooting and delay install flow.

## 11. Configure Supersedence if needed
1. Open Supersedence.
2. Add supersedence only if this Chrome package is replacing an older managed Chrome package already controlled in Intune.
3. If this is the first managed Chrome deployment or there is no predecessor app object, leave Supersedence empty.
4. Verify the section label in your tenant because the wizard order can vary.

## 12. Understand assignment types before targeting devices
1. Required means Intune installs the app automatically for targeted users or devices.
2. Available means the app appears in Company Portal for self-service installation.
3. Uninstall means Intune removes the app from targeted users or devices.
4. Verify the exact assignment label text in your tenant because wording can vary slightly by UI version.

## 13. Assign to a pilot group first
1. Open Assignments.
2. Add a small test or pilot group rather than the full production fleet.
3. For a new app, do not assign directly to all 10,000 devices.
4. Use Required when you want Chrome to install silently and automatically on pilot devices.
5. Use Available when you want pilot users to install Chrome manually from Company Portal.
6. Use Uninstall only when you are testing managed removal or rollback behavior.
7. Reason for pilot-first assignment:
   - limits blast radius if packaging or detection is wrong
   - validates install and uninstall behavior on real devices
   - confirms detection rules work correctly
   - reduces service impact if rollback is needed
8. Use a representative pilot group that includes the device types and OS versions you expect in production.
9. Verify the live assignment labels in your tenant before saving.

## 14. Review and create the app
1. Open Review + create.
2. Review all values carefully:
   - app name
   - publisher
   - version
   - install command
   - uninstall command
   - install behavior
   - requirements
   - detection rules
   - return codes
   - assignments
3. Confirm that all placeholder values such as `{VERIFY-ACTUAL-CHROME-PRODUCT-CODE}` have been replaced with verified package values.
4. Select Create.
5. Wait until the app object appears in All apps.

## 15. Verify the app appears correctly in the catalog
1. Return to Apps > All apps.
2. Search for `Google Chrome Enterprise`.
3. Open the app record.
4. Confirm these values are correct:
   - app type is Windows app (Win32)
   - name is correct
   - publisher is Google
   - version matches the packaged MSI
   - install command is correct
   - uninstall command is correct
   - install behavior is correct
   - detection rule is correct
   - return codes are correct
5. If any value is wrong, correct it before broad assignment.

## 16. Verify install status on a pilot device
1. Ensure at least one assigned pilot device has synced with Intune.
2. In Intune, open the Google Chrome app.
3. Go to Device install status or the equivalent status page shown in your tenant.
4. Locate the pilot device.
5. Review the install result after sync and the expected install window.
6. If needed, trigger a manual sync from the pilot device:
   - Settings > Accounts > Access work or school > connected work account > Info > Sync
7. Recheck the Intune app status after the sync and install attempt.
8. If the status still does not update, review command syntax, detection rule accuracy, assignment scope, and requirement settings.

## 17. Interpret common install status values
1. Installed means Intune successfully detected the app on the device using your detection rule.
2. Failed means the installer failed, the command line was wrong, the return code mapping was wrong, or the detection rule did not match the actual installed state.
3. Not applicable means the device did not meet one or more targeting or requirement conditions, such as:
   - unsupported OS version
   - architecture mismatch
   - assignment filter exclusion
   - user or device not actually in the target scope

## 18. Gate to phased rollout
1. Do not begin phased rollout until pilot success criteria are met.
2. Minimum pilot success criteria should include:
   - stable installation success rate
   - low failure rate
   - correct detection on pilot devices
   - validated uninstall behavior if rollback is part of the plan
   - no critical end-user impact incidents
3. If pilot results show failures, correct the app configuration before expanding assignment.

## 19. Quick execution checklist
1. Correct app type selected for `.intunewin` package.
2. App information completed.
3. Package file uploaded successfully.
4. Install command validated.
5. Uninstall command validated.
6. Actual Chrome MSI product code verified.
7. Requirements aligned to supported OS and architecture.
8. Detection rule tested against the real package.
9. Return codes confirmed.
10. Assignment limited to pilot group first.
11. Review + create completed after validation.
12. Pilot install status reviewed until outcome is clear.
13. Only after successful pilot results should phased production rollout begin.
