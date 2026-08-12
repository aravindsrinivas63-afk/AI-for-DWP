# Analysis: Adobe Acrobat Pro v23.6 Intune Install Failure

Date analyzed: 2026-08-12  
Log window analyzed: 2024-03-15 10:01 to 11:02

## 1. Executive Summary
The deployment of Adobe Acrobat Pro v23.6 failed on the endpoint during initial install and first retry. The installer returned MSI code 1603 both times, and post-install detection did not find the expected registry value, so Intune marked the app as Failed and scheduled retries.

Primary conclusion:
- Immediate technical failure is MSI error 1603 (fatal install error).
- Current detection rule appears misaligned with the target product (Acrobat Pro vs Acrobat Reader), which can cause false negatives even if installation later succeeds.

## 2. Observed Timeline (From Provided Logs)
- 10:01:00: Install started for Adobe Acrobat Pro v23.6.
- 10:01:01: Install context is SYSTEM.
- 10:01:03: Install command executed: msiexec /i AcrobatPro.msi /quiet.
- 10:01:44: Installer returned 1603; install marked failed.
- 10:01:45 to 10:01:46: Detection ran against HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0; value not found; result Not detected.
- 10:01:47: Overall app result Failed; retry scheduled in 60 minutes.
- 11:01:47: Retry attempt 1 started.
- 11:02:31: Retry returned 1603 again.
- 11:02:32: Retry 1 failed; next retry scheduled.

## 3. Evidence-Based Findings
Finding A: Installation failure is persistent.
- Two consecutive attempts returned 1603 in nearly identical runtime.
- This suggests a repeatable condition (package issue, prerequisite conflict, device state, or app conflict), not a transient network event.

Finding B: Detection rule likely targets the wrong product family path.
- Detection checks Acrobat Reader key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0.
- The deployed app is Adobe Acrobat Pro v23.6, which often registers under Adobe Acrobat paths, not Reader-only paths.
- Even with successful install, this detection rule may continue to report Not detected.

Finding C: Installer command lacks diagnostic logging.
- Command has /quiet but no MSI verbose log path.
- Without /L*v logging, root-cause isolation for 1603 is limited.

## 4. Working Hypothesis
Primary hypothesis:
- The deployment failure is caused by a combined configuration and endpoint install issue: MSI install fails with return code 1603 under SYSTEM context, and detection is mapped to an Acrobat Reader registry path that does not reliably represent Acrobat Pro v23.6.

Supporting sub-hypotheses:
1. A repeatable device/package condition is triggering 1603 (for example pending reboot, Adobe product conflict, or MSI custom action failure).
2. Detection would still report Not detected in some success scenarios because the current key path targets Reader-specific locationing.
3. Missing MSI verbose logging delayed precise isolation of the failing installer action, extending time to recovery.

Why this hypothesis fits current evidence:
- Two consecutive attempts failed with the same return code and similar execution duration.
- Detection checks HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 while deploying Acrobat Pro.
- Retry behavior repeats unchanged command/detection configuration, reproducing the same failure pattern.

## 5. Most Likely Root Causes (Ranked)
1. Detection rule mismatch (High confidence for detection failure; medium for overall app failure reporting).
2. MSI 1603 due to prerequisite/conflict condition (High confidence for install failure).
- Common 1603 triggers: pending reboot, older Acrobat components locked, conflicting installed product code, insufficient free space/profile state, custom action failure.
3. Packaging content or install syntax issue (Medium confidence).
- Example: required MST/transform or setup bootstrapper missing from package, wrong command for this Adobe media type.

## 6. Impact Assessment
- User/device impact: App unavailable on affected endpoints.
- Operational impact: Ongoing retry loop increases endpoint churn and support ticket risk.
- Reporting impact: Detection mismatch can inflate failure metrics and mask real install state.

## 7. Immediate Containment Actions
1. Pause broad targeting for this app assignment ring.
2. Keep deployment limited to test/pilot group until fixed.
3. Exclude repeatedly failing devices into a temporary hold group to reduce repeated failed attempts.

## 8. Corrective Actions

### 7.1 Fix install command instrumentation
Use verbose MSI logging and explicit no-restart behavior during testing.

Recommended test command:
msiexec /i "AcrobatPro.msi" /qn /norestart /L*v "%ProgramData%\Microsoft\IntuneManagementExtension\Logs\AdobeAcrobatPro_v23.6_install.log"

Purpose:
- Produces forensic installer log for exact failing action.
- Prevents unmanaged reboot behavior during pilot validation.

### 7.2 Correct detection rule
Replace Reader-based registry detection with a Pro-valid indicator.

Recommended approach order:
1. Prefer MSI product code detection (most stable for MSI deployments).
2. If registry must be used, validate exact key/value from a known-good Acrobat Pro v23.6 install and use that key.
3. Avoid Reader-only paths for Pro app detection unless confirmed by vendor install behavior.

### 7.3 Validate endpoint preconditions for 1603
On failing pilot devices, check and remediate:
- Pending reboot state.
- Existing Acrobat/Reader product conflicts.
- Windows Installer service health and event logs.
- Local disk availability and write access under SYSTEM context.

### 7.4 Repackage if media requires bootstrapper/transform
If Adobe package expects setup.exe, prerequisites, or MST:
- Rebuild intunewin with complete source structure.
- Use vendor-supported silent command line for that media type.

## 9. Verification Plan (Before Re-Expanding Assignment)
Success criteria for controlled re-test (minimum 20 pilot endpoints):
- Install success >= 95% on first attempt.
- No repeated 1603 on more than 2 devices.
- Detection result = Detected on all successfully installed endpoints.
- Verbose log review completed for any residual failure.

Required checks:
1. Intune Device install status by device.
2. IME logs for command execution and retries.
3. MSI verbose log root-cause signatures.
4. Registry/MSI detection confirmation on a known-good device.

## 10. Recommended Incident Record Statement
Adobe Acrobat Pro v23.6 deployment failed due to repeat MSI 1603 during SYSTEM-context installation, with additional evidence of a likely detection-rule mismatch (Reader key used for Pro package). Rollout should remain ring-limited until installer logging is enabled, detection is corrected to product-accurate criteria, and a successful pilot revalidation is completed.
