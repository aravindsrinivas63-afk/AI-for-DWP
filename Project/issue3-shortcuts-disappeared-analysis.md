# Analysis — Issue 3: Desktop Shortcuts Disappeared

## Scope Facts
- Several Floor 6 users report missing desktop shortcuts.
- Floor 6 devices are recently migrated to Windows 11 and Intune-managed.
- New Document Management app was deployed Friday; symptoms reported Monday.

## Ranked Differential (Most Probable First)

1. App package/script side effect removed or replaced shortcuts
- Why likely: Strong timing correlation and likely shared configuration boundary.
- Fastest check: Compare shortcut inventory/timestamps on affected vs unaffected endpoints and correlate with deployment window.

2. Logon-time script/policy failed to recreate corporate shortcuts
- Why likely: Post-migration policy/script sequencing issues can leave desktops partially initialized.
- Fastest check: Check Group Policy and IME script execution results for shortcut actions/failures.

3. Desktop path redirection/KFM state mismatch
- Why likely: Shortcuts can appear missing if desktop path shifted unexpectedly.
- Fastest check: Validate User Shell Folders desktop path and OneDrive desktop redirection status.

4. Profile load/shell initialization issue
- Why likely: Partial profile load can suppress expected desktop objects.
- Fastest check: Review User Profile Service events and explorer-related application events.

5. Isolated user-level manual deletion or one-off profile corruption
- Why likely: Possible but less consistent with multi-user report.
- Fastest check: Determine if missing set is consistent across affected users.

## Deployment Causality Decision Evidence

### Confirms deployment as primary cause
- Missing shortcuts mainly in rollout cohort.
- Shortcut modifications cluster around Friday/Monday boundary.
- IME/policy logs show shortcut-change actions or errors tied to deployment.
- Non-rollout control endpoints retain expected shortcut baseline.

### Rules out deployment as primary cause
- No cohort alignment between affected users and rollout assignment.
- Missing shortcuts are random with no timestamp correlation.
- No deployment or script traces tied to shortcut paths.
- Root cause is isolated to specific user profile corruption.

## Immediate Investigation Action
Capture shortcut inventories and modified timestamps from affected and unaffected endpoints, then correlate with rollout logs and profile/policy events.

## Updated Hypothesis

### Current Working Hypothesis
The Friday deployment likely introduced a shortcut-management side effect (package/script/policy timing) that removed, replaced, or failed to recreate expected desktop shortcuts for a subset of Floor 6 users.

### What Would Validate This Hypothesis
- Missing or modified shortcuts cluster around Friday-to-Monday timestamps.
- Impact maps to the deployment cohort.
- IME/policy logs show shortcut-related actions or errors during the same window.

### What Would Falsify This Hypothesis
- No time or cohort correlation with deployment.
- Shortcut state differs randomly per user with no common deployment trace.
- Evidence points to isolated profile corruption unrelated to rollout.