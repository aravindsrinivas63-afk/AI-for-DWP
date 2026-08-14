# Legal-Win11 App Crash Wave: Analysis

## Incident Scope
- Reported issue: Wave of app crashes in Legal (Floor 6) this morning.
- Affected group: Legal-Win11 (45 devices).
- Data sources used:
  - Nexthink DEX export.
  - SCCM deployment log.

## Source Facts
### Nexthink DEX Export (Legal-Win11)
| Date/Time | DEX Score | App Crash Rate | Disk I/O |
|---|---:|---:|---|
| 2024-03-25 08:00 | 91 | 0.1% | Normal |
| 2024-03-25 09:00 | 90 | 0.2% | Normal |
| 2024-03-25 10:00 | 58 | 6.2% | High |
| 2024-03-25 11:00 | 55 | 6.8% | High |

- Top crashing process (10:00-11:00): DocManager.exe (74% of all crashes).

### SCCM Deployment Log
- 09:38:20: Deployment started for Legal Document Manager v2.1 to Legal-Win11 (45 devices).
- 09:44:07: Install completed on 45/45 devices.
- 09:44:07: Install result: Success, 0 failures.

### Version and Fleet Context
- Previous version: Document Manager v2.0 (stable, deployed 6 weeks prior).
- New version: Document Manager v2.1.
- Vendor release-note limitation: On devices with less than 8GB RAM, auto-save indexing can cause high disk I/O and intermittent crashes during the first hours after installation while initial index builds.
- Legal-Win11 RAM distribution:
  - 60% with 8GB RAM.
  - 40% with 4GB RAM.

## Cross-Source Correlation
1. Scope alignment:
   - The SCCM deployment target and Nexthink impacted cohort are the same 45-device Legal-Win11 group.
2. Timing alignment:
   - SCCM rollout completed at 09:44.
   - Nexthink degradation appears at 10:00, about 16 minutes later.
3. Baseline-to-incident shift:
   - 08:00-09:00 baseline was stable (high DEX, low crashes, normal disk I/O).
   - 10:00-11:00 shows degraded DEX, elevated crashes, and high disk I/O.
4. Process alignment:
   - DocManager.exe is the dominant crash process in the incident window and matches the updated application family.
5. System-state contrast:
   - SCCM confirms installation success state.
   - Nexthink confirms runtime degradation state in the same cohort.
6. Content alignment with vendor note:
   - Observed incident pattern includes both high disk I/O and higher crash activity in the early post-install period.
7. Hardware overlap with known limitation condition:
   - 40% of the fleet is less than 8GB RAM (4GB devices).

## Analysis Confidence
- Confidence in this correlation analysis: High.
- Basis: Consistent linkage across timing, scope, process identity, telemetry pattern, and release-note behavior description.
