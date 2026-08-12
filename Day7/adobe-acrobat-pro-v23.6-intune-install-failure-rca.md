# Root Cause Analysis (RCA): Adobe Acrobat Pro v23.6 Intune Deployment Failure

RCA date: 2026-08-12  
Incident date/time: 2024-03-15 10:01 to 11:02 (observed window)  
Service: Endpoint Application Deployment (Intune Win32)  
Application: Adobe Acrobat Pro v23.6  
Package: AdobeAcrobatPro.intunewin

## 1. Incident Summary
Adobe Acrobat Pro v23.6 failed to install on targeted endpoint(s) via Intune Win32 deployment. Initial deployment and first retry both failed with MSI return code 1603. Detection subsequently reported Not detected using a registry rule referencing an Acrobat Reader path.

## 2. Business Impact
- Affected users/devices did not receive Adobe Acrobat Pro v23.6 as scheduled.
- Repeated retry attempts increased endpoint noise and support overhead.
- Deployment reporting confidence was reduced due to detection-rule mismatch risk.

## 3. What Happened (Timeline)
- 10:01:00: Intune AgentExecutor started install for Adobe Acrobat Pro v23.6.
- 10:01:03: Install command executed: msiexec /i AcrobatPro.msi /quiet.
- 10:01:44: Installer returned 1603; install marked failed.
- 10:01:45: Detection rule checked HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0; value not found.
- 10:01:47: Overall result set to Failed; retry scheduled in 60 minutes.
- 11:01:47: Retry attempt 1 started.
- 11:02:31: Retry attempt again returned 1603.
- 11:02:32: Retry 1 failed; next retry scheduled.

## 4. Root Cause
Primary root cause:
- Deployment configuration used a detection rule path aligned to Acrobat Reader (HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0) for an Acrobat Pro package, creating a product-detection mismatch.

Technical failure cause (co-existing):
- MSI installation failed with return code 1603 on repeated attempts, indicating a fatal install condition at endpoint/package level. Due to missing verbose MSI logging in the configured command, the exact failing MSI action was not captured in the provided evidence.

RCA conclusion:
- The incident is a combined configuration defect:
1. Product detection misconfiguration (confirmed from log evidence).
2. Installer failure condition not diagnosable to exact MSI action due to insufficient logging instrumentation (confirmed process gap).

## 5. Contributing Factors
- Install command did not include /L*v verbose MSI logging.
- No explicit pre-deployment validation checklist to confirm detection rule maps to product edition (Pro vs Reader).
- Pilot gate did not enforce a mandatory known-good endpoint validation of detection output before broader retry behavior.

## 6. Why Existing Controls Did Not Prevent It
- Intune retry logic handled re-attempting install but does not correct command or detection misconfiguration.
- Standard monitoring identified failures but lacked granular MSI evidence to isolate the exact 1603 sub-cause quickly.
- Change quality checks were focused on package upload and assignment, not full command/detection integrity validation.

## 7. Corrective Actions (Immediate)
1. Correct detection rule to Acrobat Pro-accurate criteria.
- Owner: Endpoint Engineering
- Due: Immediate
- Status: Open

2. Update install command to include verbose MSI logging and controlled restart behavior.
- Proposed command:
msiexec /i "AcrobatPro.msi" /qn /norestart /L*v "%ProgramData%\Microsoft\IntuneManagementExtension\Logs\AdobeAcrobatPro_v23.6_install.log"
- Owner: Packaging Team
- Due: Immediate
- Status: Open

3. Isolate failing devices in temporary hold group to stop noisy retries while remediation is tested.
- Owner: Intune Operations
- Due: Same day
- Status: Open

4. Run controlled pilot re-test (minimum 20 endpoints) after command and detection fixes.
- Owner: Endpoint Engineering
- Due: Next business day after remediation
- Status: Open

## 8. Preventive Actions (Systemic)
1. Add mandatory deployment quality gate:
- Validate detection rule against a known-good install for the exact product edition/version.
- Owner: Endpoint Governance
- Target date: +7 days

2. Require MSI verbose logging in all Win32 MSI deployment commands for pilot rings.
- Owner: Packaging Standards Owner
- Target date: +7 days

3. Add preflight checklist item for Pro vs Reader registry/path verification in Adobe package workflows.
- Owner: Packaging Team Lead
- Target date: +5 days

4. Add rollback-ready assignment template (current version and prior stable version) to all critical app rollouts.
- Owner: Intune Operations
- Target date: +10 days

## 9. Validation Criteria for Incident Closure
Incident can be closed when all criteria are met:
- Pilot install success >= 95% across at least 20 representative endpoints.
- 1603 recurrence <= 2 devices in pilot and each with reviewed MSI log.
- Detection accuracy = 100% on successfully installed pilot endpoints.
- No Sev1/Sev2 user-impacting incidents linked to Acrobat Pro v23.6 during 48-hour observation.

## 10. Lessons Learned
- Detection configuration errors can invalidate otherwise healthy deployments and distort health metrics.
- MSI 1603 without verbose logs delays RCA precision and remediation speed.
- Product-edition-specific validation (Acrobat Pro vs Reader) must be enforced before production assignments.

## 11. Final RCA Statement
Adobe Acrobat Pro v23.6 deployment failure was caused by a configuration defect in detection mapping (Reader registry path used for Pro package), combined with unresolved MSI 1603 installation failures that lacked diagnostic depth due to missing verbose logging in the deployment command. Corrective action requires detection realignment, installer logging enforcement, controlled pilot revalidation, and strengthened pre-deployment quality gates.
