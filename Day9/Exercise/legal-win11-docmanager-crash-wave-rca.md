# Legal-Win11 App Crash Wave: Root Cause Analysis (RCA)

## Problem Statement
A significant rise in application crashes and user experience degradation occurred in the Legal-Win11 fleet shortly after a full deployment of Legal Document Manager v2.1.

## Root Cause
The incident was caused by post-install auto-save indexing behavior introduced in Document Manager v2.1, which drove high disk I/O and intermittent application crashes during the initial hours after installation, with higher susceptibility on devices below 8GB RAM.

## Evidence Supporting the Root Cause
1. Temporal evidence:
   - Deployment completed at 09:44, and degradation began in the 10:00 telemetry interval.
2. Scope evidence:
   - Both change rollout and impact telemetry are scoped to Legal-Win11 (45 devices).
3. Process evidence:
   - DocManager.exe accounted for 74% of crashes during the 10:00-11:00 window.
4. Symptom-pattern evidence:
   - Disk I/O changed from Normal to High while crash rates sharply increased.
5. Vendor evidence:
   - v2.1 release notes explicitly describe high disk I/O and intermittent crashes during early post-install indexing on less-than-8GB devices.
6. Fleet risk evidence:
   - 40% of Legal-Win11 devices are 4GB RAM, matching the under-8GB risk condition.

## Contributing Factors
- Broad same-window rollout to all 45 devices increased simultaneous exposure.
- No phased/ring deployment to detect early runtime regression before full rollout.
- Mixed hardware profile included a large low-memory segment.

## What Was Not the Primary Failure Mode
- SCCM installation failure was not indicated (45/45 success, 0 failures).
- The event is consistent with post-install runtime instability rather than deployment execution failure.

## RCA Confidence
- Confidence level: High.
- Reason: Multi-source evidence aligns on timing, scope, crashing process, telemetry signature, and vendor-known limitation behavior.
