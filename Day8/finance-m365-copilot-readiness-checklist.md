# Microsoft 365 Copilot Readiness Checklist (Finance Department)

**Department:** Finance (~200 users)  
**Organisation:** Financial services  
**Date:** 2026-08-12  
**Current state:** Microsoft 365 E5 in place; Copilot add-on not yet assigned; SharePoint permissions inherited from 2019 migration and not fully audited.  
**Data sensitivity:** Payroll, board packs, M&A documents, client financial data.

## How to use this checklist
- This is a **tickable, go/no-go checklist**.
- Complete sections in priority order.
- **Do not assign Copilot licenses broadly until Priority 1 (Permissions & Oversharing Controls) is completed and signed off.**

---

## Priority 1 (Highest): Permissions & Oversharing Controls (Mandatory Gate)

> This is the single most important readiness area for this Finance deployment. Because permissions were inherited from a 2019 migration and never fully audited, this section is a hard prerequisite before broad rollout.

### 1.1 Governance and ownership
- [ ] Appoint named owners for each critical data area (Payroll, Board, M&A, Client Financials).
- [ ] Define a Copilot data governance lead (business) and technical owner (IT/security).
- [ ] Agree risk thresholds for oversharing (for example: any open access to payroll or M&A content is a blocker).

### 1.2 SharePoint and OneDrive permission audit (deep audit)
- [ ] Inventory all Finance SharePoint sites, libraries, and key folders.
- [ ] Export and review current permissions at site, library, and folder/item levels.
- [ ] Identify and document broken inheritance locations.
- [ ] Identify broad access groups (for example: Everyone except external users, large department-wide groups, legacy project groups).
- [ ] Review OneDrive sharing links and direct permissions for Finance leadership and high-risk users.
- [ ] Confirm external sharing status and historical external links for Finance content.

### 1.3 Oversharing remediation (must be completed before broad Copilot assignment)
- [ ] Remove excessive access from legacy/unused groups created during or after the 2019 migration.
- [ ] Re-baseline permissions using least privilege by role (Payroll, FP&A, Treasury, Controllership, Exec support, etc.).
- [ ] Replace broad links with restricted links where required.
- [ ] Remove or expire anonymous/anyone links (if any exist).
- [ ] Restrict or remove stale direct user permissions on sensitive folders/files.
- [ ] Validate that board packs, payroll, M&A, and client financial files are only accessible by authorised groups.

### 1.4 Validation and sign-off
- [ ] Run access validation tests for representative users in each Finance role.
- [ ] Perform spot checks: "What can this user discover?" across SharePoint/OneDrive.
- [ ] Security and Finance data owners sign off that oversharing risks are reduced to acceptable levels.
- [ ] Record exceptions with mitigation actions and due dates.

---

## Priority 2: Licensing Prerequisites

### 2.1 Base licensing
- [ ] Confirm all ~200 target users have eligible base licenses (M365 E5 already confirmed).
- [ ] Confirm target users are in scope for Copilot deployment wave(s).

### 2.2 Copilot add-on readiness
- [ ] Purchase/allocate Microsoft 365 Copilot add-on licenses for pilot cohort first.
- [ ] Map licenses to a pilot group (for example: 20-40 users across Finance functions).
- [ ] Confirm process for phased assignment after Priority 1 sign-off.

### 2.3 Service plan and account hygiene
- [ ] Verify user accounts are active and not blocked from required M365 workloads.
- [ ] Ensure disabled/stale accounts are excluded from license assignment groups.

---

## Priority 3: Microsoft 365 Apps Client Readiness

### 3.1 Supported client channel/version posture
- [ ] Ensure Windows/Mac devices for target users run supported Microsoft 365 Apps builds.
- [ ] Standardise update channel for Finance endpoints (Current Channel or approved enterprise channel per policy).
- [ ] Confirm automatic Office updates are enabled and working.

### 3.2 App-specific readiness
- [ ] Validate Outlook, Word, Excel, PowerPoint, and Teams are updated on pilot devices.
- [ ] Confirm users can sign in with corporate identity in desktop and web apps.
- [ ] Confirm modern authentication is in use; no legacy auth dependencies for pilot users.

### 3.3 Endpoint readiness checks
- [ ] Confirm device compliance posture for pilot users (as required by Conditional Access).
- [ ] Confirm network/proxy settings do not block M365 endpoints.

---

## Priority 4: Identity and MFA Readiness

### 4.1 Identity health
- [ ] Verify target users have healthy Entra ID accounts (no sync or sign-in anomalies).
- [ ] Confirm UPNs and primary SMTP addresses are correct and consistent.

### 4.2 MFA and Conditional Access
- [ ] Enforce MFA for all Finance users in scope.
- [ ] Confirm Conditional Access policies are aligned to Finance risk profile.
- [ ] Validate that break-glass/emergency access procedures are documented and tested.

### 4.3 Privileged role controls
- [ ] Review privileged/admin role assignments impacting Finance data access.
- [ ] Confirm role elevation uses approved controls (for example, just-in-time where available).

---

## Priority 5: Sensitivity Labelling and Protection

### 5.1 Label taxonomy and policy
- [ ] Confirm a clear sensitivity label taxonomy is published (for example: Public, Internal, Confidential, Highly Confidential - Finance Restricted).
- [ ] Ensure labels and protection policies specifically cover payroll, M&A, board, and client financial data.

### 5.2 Defaulting and enforcement
- [ ] Configure mandatory/default labels for key Finance document libraries where appropriate.
- [ ] Enable protection settings (encryption, access restrictions, watermarking) for high-risk categories.
- [ ] Validate label behavior across Office desktop, web, and mobile clients.

### 5.3 Monitoring and exceptions
- [ ] Monitor unlabeled or mis-labeled sensitive files in Finance repositories.
- [ ] Define exception approval path for temporary business-critical access changes.

---

## Priority 6: End-User Communications and Enablement

### 6.1 Communications plan
- [ ] Send pre-launch communication explaining what Copilot can and cannot access (it respects user permissions).
- [ ] Clearly explain Finance-specific data handling expectations and prohibited use cases.
- [ ] Publish support path for suspected oversharing or data exposure concerns.

### 6.2 Training and guidance
- [ ] Deliver role-based Copilot training for Finance (analysts, managers, leadership, exec support).
- [ ] Provide safe prompting guidance using synthetic/sanitised examples for sensitive scenarios.
- [ ] Share "before you share" checklist for files/links referenced in prompts.

### 6.3 Pilot and adoption controls
- [ ] Run a controlled pilot and capture feedback on utility, risk, and accuracy.
- [ ] Track helpdesk/security tickets related to permissions, oversharing, and sensitive content.
- [ ] Approve scale-out only after pilot risk review and remediation actions are completed.

---

## Go/No-Go Decision

- [ ] **GO** only if all Priority 1 items are complete and signed off.
- [ ] Confirm Priority 2-6 minimum controls are complete for pilot scope.
- [ ] Document executive sponsor approval for rollout phase.

## Suggested rollout approach (practical)
- [ ] Wave 1 pilot: 20-40 users, mixed Finance roles, 2-4 weeks.
- [ ] Wave 2 expansion: 60-80 users after pilot controls pass.
- [ ] Wave 3 full department rollout after final risk and operations review.

## Sign-off
- [ ] Finance Data Owner: ____________________ Date: __________
- [ ] Security Lead: _________________________ Date: __________
- [ ] M365 Service Owner: ____________________ Date: __________
