# Finance Copilot Readiness Tiered Prioritisation

**Department context:** ~200 Finance users in a financial services company with highly sensitive data (payroll, board packs, M&A, client financial data). SharePoint permissions were inherited from a 2019 migration and have not been fully audited since.

This document ranks the checklist items into three implementation tiers.

---

## Tier 1: MUST Complete Before Rollout (Blocking)

These are hard go/no-go gates. Copilot assignment beyond a tightly controlled admin test group should not proceed until these are complete.

### A. Permissions and oversharing controls (highest priority)
- [ ] Appoint data owners and technical accountability for sensitive Finance repositories.
- [ ] Complete deep SharePoint/OneDrive permissions audit (site, library, folder/item, direct sharing, legacy links, broad groups, broken inheritance).
- [ ] Remediate oversharing (remove excessive/stale access, fix inheritance problems, replace broad links, eliminate anonymous links).
- [ ] Validate least-privilege access with role-based user tests.
- [ ] Obtain Security + Finance data owner sign-off.

### B. Identity and access protection baseline
- [ ] Enforce MFA for all in-scope Finance users.
- [ ] Confirm Conditional Access is aligned to Finance risk profile.
- [ ] Verify no critical identity hygiene issues for pilot/rollout users.

### C. Sensitive data protection minimums
- [ ] Confirm sensitivity labels and protection policies exist for payroll, board, M&A, and client financial data.
- [ ] Ensure high-risk repositories/documents have required label/protection behavior.

### D. Licensing gate for users being enabled
- [ ] Confirm eligible base licenses (M365 E5) for target users.
- [ ] Assign Copilot add-on only to approved pilot/rollout cohorts after A-C are complete.

---

## Tier 2: SHOULD Complete Before Rollout (High Risk if Skipped)

Skipping these does not always create an immediate stop condition, but materially increases operational or security risk.

### A. Microsoft 365 Apps readiness and version consistency
- [ ] Ensure target users are on supported Microsoft 365 Apps builds/channels.
- [ ] Confirm Office app updates are functioning across pilot devices.
- [ ] Validate modern auth and app sign-in consistency.

### B. Endpoint and operational readiness
- [ ] Confirm device compliance posture where required by policy.
- [ ] Verify network/proxy readiness for M365 service endpoints.

### C. Monitoring and exception workflow
- [ ] Establish monitoring for unlabeled/mislabeled sensitive files.
- [ ] Define and document exception approval for temporary access changes.

### D. Pilot governance and risk review mechanics
- [ ] Define pilot success/risk criteria and required evidence for go-forward.
- [ ] Ensure helpdesk/security triage paths are ready for oversharing incidents.

---

## Tier 3: CAN Complete During/After Rollout (Lower Risk)

These are important for adoption quality and long-term maturity, but can proceed in parallel with controlled rollout once Tier 1 is complete.

### A. End-user comms depth and adoption enhancement
- [ ] Expand role-specific training content and advanced prompting workshops.
- [ ] Add iterative FAQ updates from pilot learnings.
- [ ] Refine comms cadence and manager toolkits.

### B. Rollout optimisation
- [ ] Tune wave sizing/timing from pilot telemetry.
- [ ] Improve operational dashboards and executive reporting pack.

### C. Continuous improvement controls
- [ ] Schedule recurring (for example, quarterly) permissions recertification.
- [ ] Add periodic tabletop exercises for data exposure response.

---

## Why Permissions/Oversharing Is MUST (Finance-Specific Justification)

Even though licensing assignment and client version checks are technically faster and simpler, they are not the primary risk driver in this environment.

### 1) Copilot obeys existing permissions; it does not fix bad permissions
If legacy access is over-broad, Copilot can make that overexposure easier to discover and use. In other words, Copilot can amplify pre-existing access design flaws.

### 2) Your highest-risk data categories are exactly the ones harmed by oversharing
Payroll, board papers, M&A content, and client financial data can cause severe regulatory, legal, market, and reputational impact if exposed to unintended internal audiences.

### 3) 2019 inherited permissions with no full audit is a known red flag
Unreviewed migration-era inheritance and stale group memberships commonly produce hidden access paths (broken inheritance, legacy links, direct grants) that users and owners no longer understand.

### 4) Simpler checks do not reduce data exposure risk on their own
Having the right license and current Office builds only proves technical eligibility. It does not prove safe data access boundaries.

### 5) In regulated financial contexts, data governance evidence is part of readiness
Before scale rollout, Security and Finance owners need demonstrable evidence that least-privilege is restored and validated, not assumed.

---

## Practical Decision Rule

- [ ] **Do not progress to broad Finance rollout until Tier 1-A (Permissions/Oversharing) is complete and signed off.**
- [ ] If Tier 2 items are partially open, proceed only with controlled pilot scope and explicit risk acceptance.
- [ ] Complete Tier 3 items as part of post-pilot scale and continuous improvement.
