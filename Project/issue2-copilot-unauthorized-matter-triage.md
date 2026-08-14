# Triage — Issue 2: Copilot Surfaced Client Matter User Says They Never Had Access To

**Date:** 2026-08-14  
**Context:** Floor 6 incident, legal data sensitivity

## Summary
A user reports Copilot surfaced a client matter they believe they were never authorized to access.

## Impact
- **Who affected:** At least 1 confirmed user; potential wider impact to legal users to confirm  
- **How many:** 1 confirmed report initially  
- **Business urgency:** Critical — potential confidentiality and regulatory exposure  
- **Wider risk:** High until access boundary is verified and containment decision made

## Known Facts
- One paralegal reported Copilot returned a client matter she says she never had access to.
- Floor 6 includes Legal users with sensitive case data.
- A new document management app was deployed Friday afternoon.

## Missing Information to Gather
1. Exact timestamp, prompt text, and Copilot response snippet.
2. Exact client matter/document identifier surfaced.
3. User’s current and historical permissions to that matter/folder/site.
4. Whether result is reproducible under controlled observation.
5. Audit trail: direct permission, inherited group, shared link, connector/plugin data path.
6. Whether any permission sync/indexing changes occurred after Friday rollout.

## Likely Category
**Permissions/access boundary issue or oversharing exposure path** (to confirm).

## First Diagnostic Step
Prioritize evidence and entitlement verification:
1. Capture the exact reported Copilot interaction and matter reference.
2. Immediately validate user entitlement on the source content system.
3. If entitlement mismatch is seen or reproduction succeeds, trigger security containment workflow and preserve logs.
