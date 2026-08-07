# FinBridge AVD Black Screen - Audience Communications

## Audience 1 - Non-technical executive

Your access is restored and your files were not changed by this incident. On 15 March, from about 07:00, some users in one Finance desktop group saw a black screen after sign-in. A second group was unaffected because it did not receive the 02:00 update. We traced the issue to the updated image and rolled that group back to a known-good version, restarted hosts, and confirmed normal sign-in by 10:00. No action needed.

## Audience 2 - Affected end-user team (10 people, non-technical)

Your access is now back to normal, and this issue did not change your files. On 15 March, from around 07:00, some people in one Finance desktop group saw a black screen after sign-in because that group received a faulty 02:00 update, while a second group that did not get that update stayed normal. We rolled the affected group back to a known-good version, restarted hosts, and confirmed normal sign-in by 10:00. If you see this again, report it straight away with the time and desktop group name. Contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Incident facts (same as user comms):
- 2024-03-15, ~07:00 onset: subset of users in POOL-FIN-01 hit post-logon black screen.
- POOL-FIN-02 unaffected and excluded from the 02:00 image update wave.
- Service validated recovered at 10:00 after rollback/repair path.

Root cause:
- Graphics/display regression introduced by updated POOL-FIN-01 image.
- Crash signature: dwm.exe faulting in igdumd64.dll, followed by DWM exits and session disconnect/reconnect loops.

Exact action taken:
- Drained/stopped new logons on POOL-FIN-01.
- Rolled back/repaired POOL-FIN-01 to last known-good pre-update image baseline.
- Restored known-good graphics driver version where image introduced driver change.
- Rebooted affected session hosts to restart graphics stack/DWM cleanly.
- Retested with multiple user logons before returning pool to service.

Config detail:
- Fault boundary: POOL-FIN-01 (updated at 02:00).
- Control boundary: POOL-FIN-02 (not in update wave).
- Representative event pattern on affected hosts: App Error 1000 (dwm.exe/igdumd64.dll), DWM 9009 exits, TS LSM 40 disconnects after successful Event 21 logon.

Verification step:
- At 10:00, verified successful logons to POOL-FIN-01 with no recurring black-screen symptom.
- Post-fix checks: no new repeating Event 1000 (dwm.exe/igdumd64.dll) and Event 9009 in validation window; POOL-FIN-02 remained stable.

Preventive action needed:
- Keep staged rollout (single pool first) for image updates.
- Add mandatory pre-prod validation for graphics driver + DWM behavior.
- Monitor first-hour post-deploy for black-screen pattern and Event 1000/9009 signature.
- Maintain known-good rollback image per production pool.
