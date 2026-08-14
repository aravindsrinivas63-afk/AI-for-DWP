# Triage — Issue 3: Desktop Shortcuts Vanished

**Date:** 2026-08-14  
**Context:** Floor 6 incident, post-Win11 migration and Friday app rollout

## Summary
Users report missing desktop shortcuts after Monday sign-in.

## Impact
- **Who affected:** Floor 6 users reporting missing shortcuts, exact users to confirm  
- **How many:** At least 1 confirmed report, likely multiple to confirm  
- **Business urgency:** Medium — users can work but with disruption and delays  
- **Wider risk:** Could be broad if tied to profile/policy/script rollout behavior

## Known Facts
- A user reported desktop shortcuts disappeared.
- Floor 6 recently moved to Win11 and Intune management.
- New document management app was rolled out Friday afternoon.

## Missing Information to Gather
1. Whether shortcuts are actually deleted vs not rendered/loaded at sign-in.
2. Which shortcuts are missing: user-created, corporate, or app-installed.
3. Whether files under user Desktop/Public Desktop paths still exist.
4. Whether affected users align with Friday app/package assignment.
5. Whether OneDrive desktop redirection/sync errors are present.
6. Whether start menu/taskbar entries were also changed.

## Likely Category
**User profile/policy/script side effect, potentially linked to rollout or desktop redirection state** (to confirm).

## First Diagnostic Step
Run a quick affected-vs-unaffected comparison:
1. Check desktop file paths and OneDrive/KFM status for one affected user.
2. Validate Intune policy/script and app deployment actions that modify desktop/start shortcuts.
3. Determine if issue is reproducible after profile refresh/sign-out sign-in.
