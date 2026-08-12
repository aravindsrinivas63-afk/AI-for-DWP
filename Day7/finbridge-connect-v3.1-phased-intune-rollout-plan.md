# FinBridge Connect v3.1 Phased Intune Rollout Plan

Scope: Deploy FinBridge Connect v3.1 to 10,000 Win11 endpoints within 3 weeks.
Start date assumption: 2026-08-12.
Deadline: 2026-09-02.

## 1. RING STRUCTURE

Ring design aligns to risk reduction, finance priority delivery by end of week 1, and completion by week 3.

Ring 1 (Pilot)
- Size: 500 endpoints total.
- Duration: Day 1 to Day 4 (4 calendar days minimum).
- Who to include:
- 200 IT + Service Desk devices (high observability, rapid feedback).
- 200 cross-business standard users (HR, Ops, Sales, non-finance).
- 100 known 4GB RAM endpoints (explicit at-risk sample).
- Purpose: Validate install behavior, detection accuracy, startup stability, and low-spec performance before wider exposure.
- Intune assignment group type:
- Entra ID security groups (recommended static for strict control):
- SG-APP-FinBridge-v3_1-Ring1-Pilot
- SG-APP-FinBridge-v3_1-Ring1-4GB
- Assignment type: Required.

Ring 2 (Early)
- Size: 2,500 endpoints total, including the 500-user Finance population by end of week 1.
- Duration: Day 5 to Day 10 (6 calendar days minimum).
- Who to include:
- All 500 Finance users/devices (priority).
- Additional 2,000 devices across business units and geographies.
- Include at least 125 additional 4GB RAM endpoints (5% sample of ring).
- Purpose: Prove scale behavior, finance workflow readiness, and support load tolerance under moderate volume.
- Intune assignment group type:
- Entra ID security group (can be dynamic by department and managed device filters):
- SG-APP-FinBridge-v3_1-Ring2-Early
- Assignment type: Required.

Ring 3 (Broad)
- Size: Remaining 7,000 endpoints.
- Duration: Day 11 to Day 21 (up to deadline).
- Who to include:
- All remaining eligible Win11 endpoints excluding devices in temporary hold/isolation groups.
- Keep 4GB RAM devices segmented for staged micro-batches (for example 10% per day).
- Purpose: Complete enterprise rollout while preserving rollback control and minimizing blast radius.
- Intune assignment group type:
- Entra ID dynamic device group + exclusion groups:
- DG-APP-FinBridge-v3_1-Ring3-Broad
- EXC-APP-FinBridge-v3_1-Hold
- EXC-APP-FinBridge-v3_1-4GB-Isolation
- Assignment type: Required.

## 2. ADVANCE CRITERIA

Use the same KPI definitions in every ring review:
- Install success rate = Installed / (Installed + Failed) from Intune Device install status.
- Error rate = Failed / total targeted devices in ring.
- Ticket rate = FinBridge-related incidents opened in ITSM per 100 targeted users.

Ring 1 to Ring 2 gate (evaluate no earlier than Day 4, 18:00 local)
- Install success rate: >= 97.0%.
- Error rate: <= 2.0%.
- User-reported issue rate: <= 1.5 tickets per 100 users over preceding 48 hours.
- Monitoring period: Minimum 72 hours after first assignment + at least 2 device check-in cycles.
- Required data sources: Intune Device install status, Endpoint Analytics app reliability where available, ITSM incident queue tag FinBridge-v3.1.

Ring 2 to Ring 3 gate (evaluate no earlier than Day 10, 18:00 local)
- Install success rate: >= 98.0%.
- Error rate: <= 1.5%.
- User-reported issue rate: <= 1.0 tickets per 100 users over preceding 72 hours.
- Monitoring period: Minimum 96 hours after Ring 2 start, including Finance cohort stability for at least 72 hours.
- Required data sources: Intune reporting, ITSM incidents, finance-app functional smoke checks.

Hold condition (pause without full rollback)
- Trigger: Ring-level install success drops below threshold by <= 1.0 percentage point, OR 4GB subgroup failure rate rises above 4.0% but below rollback trigger.
- Action: Pause next-ring assignment for 24 hours, keep current ring active, isolate high-failure subgroup, remediate packaging/detection or prerequisites, then re-evaluate.
- Specific example: Ring 2 shows 97.3% success (below 98.0%) and 4GB devices at 4.8% failures. Pause Ring 3, move 4GB devices to isolation exclusion, continue non-4GB stabilization.

## 3. ROLLBACK TRIGGERS

Rollback means halt forward deployment and revert impacted scopes to FinBridge Connect v3.0.

Trigger 1: Install failure rate automatic halt
- Condition: Failed installs >= 5.0% within any rolling 6-hour window in the active ring.
- Decision maker: DWP Incident Commander + Endpoint Engineering Lead.
- Decision window: 30 minutes from threshold breach alert.
- Exact Intune action:
- Remove Required assignment for FinBridge v3.1 from active ring group.
- Add Required assignment for FinBridge v3.0 to same ring group.
- If needed, set FinBridge v3.1 assignment to Uninstall for affected ring after validating uninstall command behavior.

Trigger 2: Application crash rate rollback consideration
- Condition: App crash-impacted sessions >= 2.0% of active users over rolling 24 hours, or crash count trend increasing for 2 consecutive 4-hour checks.
- Decision maker: Endpoint Engineering Lead with App Owner sign-off.
- Decision window: 2 hours from confirmed telemetry pattern.
- Exact Intune action:
- Freeze all new v3.1 assignments.
- Reassign affected ring to FinBridge v3.0 Required.
- Keep unaffected validated ring on v3.1 only if crash rate there remains < 0.5% and no business impact.

Trigger 3: Business-critical failure immediate rollback
- Condition: Finance users cannot complete payment approval workflow in production due to v3.1 client defect for >= 15 consecutive minutes.
- Decision maker: Major Incident Manager (authority to declare Sev1) with Finance service owner confirmation.
- Decision window: Immediate (<= 15 minutes).
- Exact Intune action:
- Immediate halt of all v3.1 assignments (all rings).
- Assign v3.0 Required to Finance and currently active rollout groups.
- Create temporary exclusion group EXC-APP-FinBridge-v3_1-CriticalBlock and apply to v3.1 assignments.

Trigger 4: 4GB RAM device ring isolation
- Condition: 4GB RAM subgroup failure rate >= 8.0% in any 24-hour period, even if overall ring KPIs pass.
- Decision maker: Endpoint Engineering Lead.
- Decision window: 1 hour.
- Exact Intune action:
- Move all 4GB RAM devices to EXC-APP-FinBridge-v3_1-4GB-Isolation.
- Keep non-4GB rollout active if overall ring remains above advance criteria.
- Re-target isolated 4GB devices either to v3.0 Required or deferred v3.1 remediation ring.

## 4. FINANCE DEADLINE RESOLUTION

Option A: Compress pilot timeline so Finance enters Ring 2 by end of week 1
- Minimum safe pilot duration: 4 calendar days with 72-hour monitoring and at least 2 check-in cycles.
- Risk introduced: Reduced time to detect low-frequency defects (especially memory/performance issues on 4GB devices).
- Compensating control: Increase pilot observability (hourly KPI review during business hours), require explicit go/no-go review on Day 4, and pre-stage v3.0 rollback assignment.

Option B: Create Finance-specific Ring 0 before main pilot
- Ring 0 structure: 150 Finance power users + 50 IT support users (200 total), Day 1 to Day 3.
- Ring 0 advance conditions:
- Install success >= 98.0%.
- Error rate <= 1.0%.
- Finance workflow blocking incidents = 0 Sev1/Sev2.
- Ring 0 rollback plan:
- If failure >= 4.0% over 6 hours or any payment approval blocker occurs, revert Ring 0 to v3.0 immediately and stop main rollout.

Recommendation: Option A.
- Reason 1: Meets Finance deadline by end of week 1 without introducing a separate pre-pilot branch that can fragment governance and reporting.
- Reason 2: Preserves a representative pilot population including 4GB hardware risk, which Ring 0 would under-sample.
- Reason 3: Keeps one consistent ring model and simpler Intune assignment operations under a tight 3-week program.
- Decision: Run a 4-day Pilot (Ring 1), start Ring 2 on Day 5 including all 500 Finance users, and enforce the rollback triggers above with a pre-approved 30-minute decision SLA for threshold breaches.
