# Analysis and Remediation Plan - FinBridge Citrix Session Launch Failure

## Incident
- Incident: Citrix VDI session launch failure in FinBridge
- Affected pool: FinBridge-VDI-Pool-02
- Affected user scope: 22 of 30 users
- Unaffected comparison pool: FinBridge-VDI-Pool-01
- Status: Analysis complete; leading hypothesis selected from collected evidence

> AI usage note: Drafted with AI assistance in line with the DWP Personal AI Usage Charter. Treat as a draft and verify in the live environment before action.

---

## Confirmed Scope Facts

- The affected pool is `FinBridge-VDI-Pool-02`, with `22 of 30` users impacted.
- The unaffected pool is `FinBridge-VDI-Pool-01` in the same site.
- The broker log shows `Timeout waiting for machine registration response (30000ms exceeded)`.
- The exact broker failure string is `error 1030 'No machines available in the desktop group'`.
- `Pool-02` catalog state: `25 provisioned`, `3 registered`, `22 unregistered`, `0 maintenance mode`.
- `Pool-01` catalog state: `20 provisioned`, `19 registered`, `1 unregistered`.
- Sample affected machines in `Pool-02` failed registration with `Unable to contact Delivery Controller` and `dc-vdi-02.finbridge.local:80 - connection refused`.
- `dc-vdi-02` health shows `Citrix Broker Service` `STOPPED`, last known running `yesterday 23:40`, with a `reboot required` flag after Windows Update at `00:15`.
- `dc-vdi-01` health shows `Citrix Broker Service` `RUNNING` with `14 days` uptime.

---

## Ranked Likely Causes

### 1. Citrix Broker Service outage on `dc-vdi-02` left `Pool-02` machines unable to register

**Why it fits the evidence**

- The affected pool boundary aligns with the controller showing a failed health state.
- `22` machines in `Pool-02` are unregistered, which closely matches the `22 of 30` affected users.
- Sample `Pool-02` machines report `Unable to contact Delivery Controller` and `connection refused` specifically to `dc-vdi-02.finbridge.local:80`.
- The broker log shows registration timeout followed by `error 1030 'No machines available in the desktop group'`.
- The comparison pool remains healthy while its serving controller, `dc-vdi-01`, also remains healthy.

**Fastest check to confirm or eliminate it**

- On `dc-vdi-02`, confirm the `Citrix Broker Service` state and attempt to start it.
- Immediately after that, refresh `Pool-02` registration counts and confirm whether unregistered machines begin moving back to `Registered`.

**Specific remediation if confirmed**

- Restore the `Citrix Broker Service` on `dc-vdi-02`.
- If service recovery is unstable or blocked by the pending update state, perform a controlled reboot of `dc-vdi-02` and recheck the service.
- Once the controller is healthy, trigger or allow `Pool-02` machines to re-register and validate successful launches.

### 2. `Pool-02` VDAs are dependent on `dc-vdi-02` and not successfully failing over to a healthy controller

**Why it fits the evidence**

- The sample registration failures point to one specific controller endpoint: `dc-vdi-02.finbridge.local:80`.
- `Pool-01` remains healthy while `dc-vdi-01` is healthy, which suggests a controller-path or pool-to-controller dependency boundary.
- The available data does not show `Pool-02` machines successfully registering against `dc-vdi-01`.

**Fastest check to confirm or eliminate it**

- Inspect VDA controller configuration for affected `Pool-02` machines and compare it with `Pool-01`.
- Confirm whether `Pool-02` VDAs are configured with only `dc-vdi-02`, have stale controller lists, or are otherwise not attempting a healthy controller.

**Specific remediation if confirmed**

- Correct the VDA controller list or registration policy so affected machines can register to a healthy controller.
- Republish the corrected controller configuration and restart the registration-related VDA services or the affected VDAs if required.

### 3. Pending Windows Update state on `dc-vdi-02` left controller services down after overnight servicing

**Why it fits the evidence**

- `dc-vdi-02` shows `Citrix Broker Service` stopped, `reboot required`, and an overnight Windows Update installed at `00:15`.
- The service was last known running at `23:40`, which creates a clear overnight change window on the affected controller.
- This explains why the controller can refuse connections while the peer controller remains stable.

**Fastest check to confirm or eliminate it**

- Review Service Control Manager and Windows Update events on `dc-vdi-02` around `23:40` to `00:15` to verify whether the Broker service stopped during or after servicing and did not recover.

**Specific remediation if confirmed**

- Perform a controlled reboot of `dc-vdi-02` to complete the update cycle.
- Verify that `Citrix Broker Service` returns in a healthy running state and that `Pool-02` machines re-register.

---

## Error Code Handling Note

The available data explicitly states `error 1030 'No machines available in the desktop group'` in the broker log. This analysis uses that quoted message from the log and does not rely on any additional interpretation beyond the provided evidence.

---

## Finalized Hypothesis

The leading hypothesis is that `dc-vdi-02` stopped serving broker functionality, leaving most of `FinBridge-VDI-Pool-02` machines unregistered and causing the broker to time out on registration queries before returning `error 1030 'No machines available in the desktop group'`.

This is the strongest hypothesis because it is the narrowest explanation that directly matches all observed boundaries: affected users, affected pool, unregistered machine count, per-machine controller contact failure, and the unhealthy state of the controller serving that path.

---

## Exact Remediation Steps

1. Place `FinBridge-VDI-Pool-02` under incident handling so no further assumptions are made from repeated failed launch attempts while remediation is in progress.
2. On `dc-vdi-02`, verify the current state of `Citrix Broker Service` and its startup type.
3. Start `Citrix Broker Service` on `dc-vdi-02`.
4. If the service does not start cleanly, stops again, or other controller health checks remain failed, perform a controlled reboot of `dc-vdi-02` to clear the pending Windows Update state.
5. After the service is running, refresh the machine catalog view for `FinBridge-VDI-Pool-02` and watch for the `Registered` count to increase from `3` and the `Unregistered` count to decrease from `22`.
6. For any `Pool-02` machines that remain unregistered after controller recovery, trigger re-registration by restarting the relevant VDA registration path on those machines or rebooting only the remaining non-registering machines.
7. Retest session launch for at least one affected user against `FinBridge-VDI-Pool-02`.
8. Confirm that the broker no longer returns the registration timeout and no longer reports `error 1030 'No machines available in the desktop group'` for new launches.

---

## Correct Order of Operations

1. Confirm and restore controller health on `dc-vdi-02` first.
2. Confirm `Pool-02` machine registration recovery second.
3. Repair any remaining non-registering VDAs third.
4. Perform user launch verification last.

This order matters because user launch retries will continue to fail until the controller path is healthy and the pool has registered machines available again.

---

## Verification Check After Remediation

- `dc-vdi-02` shows `Citrix Broker Service` `RUNNING`.
- `FinBridge-VDI-Pool-02` registration counts recover materially from `3 registered / 22 unregistered` toward expected healthy levels.
- A new launch test against `FinBridge-VDI-Pool-02` succeeds.
- The broker no longer logs `Timeout waiting for machine registration response (30000ms exceeded)` for new launch attempts.
- The broker no longer returns `error 1030 'No machines available in the desktop group'` for the affected pool.

---

## Preventive Action

1. Add a post-patching controller health validation step that explicitly checks `Citrix Broker Service` state on every Delivery Controller before business hours.
2. Alert on sudden increases in unregistered machines per catalog so controller-side registration failures are detected before users report launch issues.
3. Review VDA controller registration configuration to ensure affected machines can fail over cleanly when one controller is unavailable.
4. Require completion of reboot-pending maintenance on Delivery Controllers during the approved change window rather than leaving systems in a partially serviced state.