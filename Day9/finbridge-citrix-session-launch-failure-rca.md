# Root Cause Analysis - FinBridge Citrix Session Launch Failure

## Incident
- Incident: Citrix VDI session launch failure in FinBridge
- Affected pool: FinBridge-VDI-Pool-02
- Affected user scope: 22 of 30 users
- Unaffected comparison pool: FinBridge-VDI-Pool-01
- Status: Root cause analysis completed from collected evidence; resolution path finalized

> AI usage note: Drafted with AI assistance in line with the DWP Personal AI Usage Charter. Treat as a draft and verify in the live environment before action.

---

## Summary

Users launching sessions against `FinBridge-VDI-Pool-02` experienced widespread launch failure, while `FinBridge-VDI-Pool-01` in the same site remained healthy. The strongest supported explanation is controller-side broker outage on `dc-vdi-02`, which left most `Pool-02` machines unregistered and caused launch requests to time out during machine registration checks before failing with `error 1030 'No machines available in the desktop group'`.

The evidence boundary is consistent across every layer collected so far: affected users align to the affected pool, the affected pool aligns to high unregistered counts, sample VDAs in that pool show refused connections to `dc-vdi-02`, and that controller shows `Citrix Broker Service` stopped while the comparison controller remains healthy.

---

## Supporting Evidence

### Scope evidence

- Affected: `22 of 30` users on `FinBridge-VDI-Pool-02`
- Unaffected: `FinBridge-VDI-Pool-01` in the same site

### Broker evidence

- `08:58:03` Session launch requested for user `jsmith`, `Pool-02`
- `08:58:04` Broker queried available machines in `Pool-02`
- `08:58:34` Broker logged `Timeout waiting for machine registration response (30000ms exceeded)`
- `08:58:34` Session launch failed with `error 1030 'No machines available in the desktop group'`

### Machine catalog evidence

- `Pool-02` catalog: `25 machines provisioned`, `3 registered`, `22 unregistered`, `0 maintenance mode`
- `Pool-01` catalog: `20 machines provisioned`, `19 registered`, `1 unregistered`

### Affected machine registration evidence

- `VDI-P02-014`: last registration attempt `06:15:22`, failed
- Error: `Unable to contact Delivery Controller`
- Endpoint: `dc-vdi-02.finbridge.local:80 - connection refused`
- `VDI-P02-017`: last registration attempt `06:16:01`, failed
- Error: `Unable to contact Delivery Controller`
- Endpoint: `dc-vdi-02.finbridge.local:80 - connection refused`

### Delivery Controller health evidence

- `dc-vdi-02`: `Citrix Broker Service` `STOPPED`
- `dc-vdi-02`: last known running `yesterday 23:40`
- `dc-vdi-02`: Windows Update installed `today 00:15`
- `dc-vdi-02`: `reboot required` flag set and host not rebooted
- `dc-vdi-01`: `Citrix Broker Service` `RUNNING`
- `dc-vdi-01`: uptime `14 days`

---

## Timeline

| Time | Event |
|---|---|
| Yesterday 23:40 | `dc-vdi-02` `Citrix Broker Service` last known running |
| Today 00:15 | Windows Update installed on `dc-vdi-02`; reboot required flag set |
| 06:15:22 | `VDI-P02-014` last registration attempt failed against `dc-vdi-02.finbridge.local:80` |
| 06:16:01 | `VDI-P02-017` last registration attempt failed against `dc-vdi-02.finbridge.local:80` |
| 08:58:03 | Session launch requested for `jsmith` on `Pool-02` |
| 08:58:04 | Broker queried available machines in `Pool-02` |
| 08:58:34 | Broker timeout waiting for machine registration response after `30000ms` |
| 08:58:34 | Session launch failed with `error 1030 'No machines available in the desktop group'` |

---

## Ranked Hypotheses Considered

### 1. Controller-side broker outage on `dc-vdi-02`

This best fits the data because it directly explains the controller connection refusals, the large unregistered population in `Pool-02`, the launch-time registration timeout, and the clean health state of the comparison controller.

### 2. `Pool-02` VDA controller dependency or failover gap

This remains plausible because the affected machines are clearly attempting `dc-vdi-02`, and the present evidence does not yet show successful fallback to another controller.

### 3. Windows Update and pending reboot state on `dc-vdi-02` left broker services down

This is also plausible as a contributing trigger because the controller shows both an overnight update and a reboot-required state, but it is still subordinate to the more direct observable condition that the Broker service is stopped.

---

## Root Cause

The most likely root cause is that `dc-vdi-02` stopped providing broker service, which prevented most `FinBridge-VDI-Pool-02` machines from registering and left the pool without sufficient available registered machines for session launch.

The analysis does not need to invent any additional interpretation of the broker error code. The platform log itself explicitly records `error 1030 'No machines available in the desktop group'`, and the surrounding evidence shows why that condition existed for `Pool-02` at the time of the incident.

---

## Why This Is the Root Cause

- The outage boundary matches the affected pool and does not extend to the comparison pool.
- The affected pool has `22` unregistered machines, which aligns with the number of affected users.
- Sample failed VDAs show direct connectivity refusal to `dc-vdi-02`.
- `dc-vdi-02` has the core broker service stopped.
- `dc-vdi-01`, which is associated with the unaffected path, remains healthy.
- The broker timeout during launch is consistent with waiting on machine availability and registration state rather than a user-specific authentication issue.

---

## 5 Whys Analysis

1. Why were users unable to launch sessions in `FinBridge-VDI-Pool-02`?
Because the broker could not provide an available machine and the launch failed with `error 1030 'No machines available in the desktop group'`.

2. Why could the broker not provide an available machine?
Because most machines in `Pool-02` were unregistered: `22` unregistered and only `3` registered.

3. Why were most `Pool-02` machines unregistered?
Because sample affected machines were unable to contact the Delivery Controller and received `connection refused` to `dc-vdi-02.finbridge.local:80`.

4. Why were machines unable to contact `dc-vdi-02` for registration?
Because `dc-vdi-02` showed `Citrix Broker Service` in the `STOPPED` state during the incident window.

5. Why did `dc-vdi-02` remain in that failed state?
Because the controller had an overnight servicing boundary with Windows Update installed and a reboot-required state still pending; this is the strongest contributing change window visible in the data, though the directly observed incident condition remains the stopped broker service.

---

## Exact Remediation Steps

1. Record the current `Pool-02` registration counts and controller health state before change.
2. On `dc-vdi-02`, verify `Citrix Broker Service` status and set the startup type to the expected automatic state if it has drifted.
3. Start `Citrix Broker Service` on `dc-vdi-02`.
4. If the service fails to stay running or controller health remains degraded, perform a controlled reboot of `dc-vdi-02` to clear the pending update state.
5. After controller recovery, refresh `Pool-02` catalog status and verify that machines begin re-registering.
6. For any remaining unregistered `Pool-02` machines, restart the registration path on those machines or reboot only the remaining non-registering VDAs.
7. Run a controlled user launch test against `FinBridge-VDI-Pool-02`.
8. Confirm the broker no longer logs the registration timeout and no longer returns `error 1030 'No machines available in the desktop group'`.

---

## Correct Order of Operations

1. Restore `dc-vdi-02` health first.
2. Confirm VDA re-registration second.
3. Repair only any residual non-registering machines third.
4. Validate user session launch last.

This sequence avoids spending time on individual VDAs before restoring the shared controller dependency that they are failing against.

---

## Verification of Resolution

- `dc-vdi-02` shows `Citrix Broker Service` `RUNNING`.
- `FinBridge-VDI-Pool-02` no longer shows the previous `3 registered / 22 unregistered` degraded state.
- Affected users can launch sessions successfully against `FinBridge-VDI-Pool-02`.
- New broker logs do not show `Timeout waiting for machine registration response (30000ms exceeded)` for launch attempts.
- New broker logs do not show `error 1030 'No machines available in the desktop group'` for the pool after recovery.

---

## Preventive Actions

1. Add Delivery Controller post-patching validation that confirms broker services are running on every controller before service hours.
2. Alert on abrupt increases in unregistered machines by catalog so pool-wide registration failure is detected early.
3. Review VDA controller lists and failover design so an unhealthy controller does not strand a pool on one endpoint.
4. Complete reboot-required maintenance on Delivery Controllers inside the approved change window rather than leaving controllers partially serviced overnight.
5. Add a standard incident triage step to compare affected and unaffected pools in the same site to isolate controller versus pool versus user boundaries quickly.

---

## Closure Statement

Based on the data collected so far, the incident is best explained by controller-side broker failure on `dc-vdi-02`, which left `FinBridge-VDI-Pool-02` largely unregistered and unable to supply launchable desktops. The finalized resolution path is to restore controller service health first, confirm machine re-registration second, and validate user launch recovery last.