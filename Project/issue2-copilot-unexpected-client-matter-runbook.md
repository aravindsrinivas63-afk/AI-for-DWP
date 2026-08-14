# Title: Runbook — Issue 2: Unexpected Copilot Retrieval of Client Matter
# Version: 1.0
# Date: 14/08/2026
# Author: Aravind
# Reviewed: self
# Status: draft
# Change: initial version from RCA

# Runbook — Issue 2: Unexpected Copilot Retrieval of Client Matter

## 1) Prerequisites

Use this checklist before starting. Do not begin procedure steps until all items are confirmed.

- [ ] Ticket exists with incident priority set to Security High.
- [ ] Incident timestamp is known (local time and UTC).
- [ ] Reporting user UPN is known.
- [ ] Exact Copilot prompt text is captured from user report.
- [ ] Suspected document URL or library path is captured.
- [ ] Tenant ID and affected M365 workload are identified (SharePoint/OneDrive/Teams).
- [ ] You have Security Reader or Security Administrator access in Microsoft Purview and Unified Audit Log. [ELEVATED]
- [ ] You have SharePoint Administrator access for site and permission review. [ELEVATED]
- [ ] You have Entra ID role allowing group membership review (Directory Reader minimum). [ELEVATED]
- [ ] You have permission to apply temporary access containment on site/library/link scope. [ELEVATED]
- [ ] Tools available: M365 Admin Center, Purview Audit, SharePoint Admin Center, Entra Admin Center, ticketing system.
- [ ] Communications contact is assigned (Security Operations or Legal IT lead).

## 2) Procedure

Follow steps in order. Each step is one action with one expected result.

1. Open the incident ticket and set status to "Investigating - Security".  
   Expected result: Incident is tracked under security workflow with an owner.

2. Record the user-reported incident time, user UPN, prompt text, and suspected content path in the ticket.  
   Expected result: Core evidence fields are complete and timestamped.

3. In Purview Audit, run a query scoped to the reporting user for the 30-minute window around incident time. [ELEVATED]  
   Expected result: Relevant audit events are returned for review.

4. Filter audit results to file access/share events on the suspected site or library. [ELEVATED]  
   Expected result: Candidate entitlement/access events are isolated.

5. Export the filtered audit result set to the incident evidence folder. [ELEVATED]  
   Expected result: Immutable evidence artifact is saved for chain-of-custody.

6. In SharePoint Admin Center, open the suspected site and view site permissions. [ELEVATED]  
   Expected result: Current site-level access groups and principals are visible.

7. Open the reported document or library and review item-level permissions. [ELEVATED]  
   Expected result: Item-level inheritance state and direct grants are visible.

8. In Entra Admin Center, review current group memberships for the reporting user tied to the site permissions. [ELEVATED]  
   Expected result: Any group-based access path is identified or ruled out.

9. Check for active sharing links on the reported file/library and list who can use each link. [ELEVATED]  
   Expected result: Shared-link access path is identified or ruled out.

10. If an unintended access path is found, remove only the minimum offending permission path (direct grant, group membership, or link). [ELEVATED]  
    Expected result: The unintended path is removed while intended paths remain unchanged.

11. Add a ticket note that states exactly which permission path was removed and by whom.  
    Expected result: Change traceability is complete.

12. Request the reporting user to retry the same Copilot query against the same content reference.  
    Expected result: User confirms the previously surfaced unauthorized content is no longer retrievable.

13. Query audit logs again for the post-fix window and validate no new access events from the reporting user to that content. [ELEVATED]  
    Expected result: No post-fix unauthorized access events are present.

14. If no entitlement path is found and retrieval persists, escalate to Microsoft support with evidence bundle and classify as potential service defect. [ELEVATED]  
    Expected result: Vendor escalation case ID is logged in ticket.

15. Set ticket status to "Contained" when access is blocked, or "Escalated" when service defect path is active.  
    Expected result: Incident state accurately reflects current control posture.

## 3) Verification

Complete all checks before closure. Perform steps exactly in order.

1. Open Microsoft Purview portal at `https://purview.microsoft.com` and go to `Solutions` -> `Audit` -> `Search`. [ELEVATED]  
   Expected result: Audit search page opens with workload/user/date filters visible.

2. Set `Activities` to SharePoint/OneDrive file access activities and set `Users` to the reporting user UPN. [ELEVATED]  
   Expected result: Query is scoped only to the affected user and relevant content access events.

3. Set time range to `Last 1 hour` (or incident window plus 30 minutes) and click `Search`. [ELEVATED]  
   Expected result: Post-fix event list is returned.

4. Open each returned event and confirm `Site URL`, `SourceFileName`, and `UserId` do not show successful access to the flagged matter. [ELEVATED]  
   Expected result: No successful post-fix access by reporting user to the flagged content.

5. Open SharePoint Admin Center at `https://admin.microsoft.com` -> `Admin centers` -> `SharePoint` -> `Sites` -> affected site. [ELEVATED]  
   Expected result: Affected site admin panel is open.

6. Open the document library and select `Manage access` for the flagged file. [ELEVATED]  
   Expected result: Current direct permissions and links are visible for the exact file.

7. Confirm the reporting user is absent from direct permissions and from active sharing links for that file. [ELEVATED]  
   Expected result: No direct or link-based entitlement path remains for reporting user.

8. Open Entra admin center at `https://entra.microsoft.com` -> `Identity` -> `Users` -> reporting user -> `Groups`. [ELEVATED]  
   Expected result: Group memberships used by SharePoint access can be checked.

9. Confirm the reporting user is not a member of any group that grants access to the flagged site/library/file. [ELEVATED]  
   Expected result: No group-based entitlement path remains.

10. Ask one approved legal user to open the same file from SharePoint in browser.  
    Expected result: Authorized business access still works for intended user.

11. Ask the reporting user to retry the same Copilot prompt from the same M365 app context.  
    Expected result: Copilot no longer returns or summarizes the flagged matter.

12. Attach verification evidence to the ticket: Purview search export, Manage Access screenshot, group-membership check, and user retest note.  
    Expected result: Incident has complete closure evidence pack.

## 4) Rollback

Use only if containment removed valid business access or created wider disruption. Target completion time: under 3 minutes.

1. Open ticket and set status to `Rollback in Progress`, then copy the exact removed-permission note from Procedure Step 11.  
   Expected result: You have the exact principal, scope, and permission level to restore.

2. Open SharePoint Admin Center at `https://admin.microsoft.com` -> `Admin centers` -> `SharePoint` -> `Sites` -> affected site -> flagged file -> `Manage access`. [ELEVATED]  
   Expected result: You are on the exact file access panel ready to restore access.

3. Click `Grant access` and re-add the same principal with the same permission level captured in the ticket note. [ELEVATED]  
   Expected result: Business access is restored exactly to pre-change state.

4. If rollback item was group removal, open Entra at `https://entra.microsoft.com` -> `Identity` -> `Groups` -> affected group -> `Members` -> `Add members`, then re-add the removed user. [ELEVATED]  
   Expected result: Group-based access is restored.

5. If rollback item was link disablement, in `Manage access` recreate a people-specific sharing link with expiry and add only intended users. [ELEVATED]  
   Expected result: Time-bounded controlled link access is restored.

6. Ask one approved legal user to open the file immediately in browser and confirm access.  
   Expected result: Business service is restored for intended users.

7. Open Purview at `https://purview.microsoft.com` -> `Solutions` -> `Audit` -> `Search`, set `Last 15 minutes`, and search for the file path and restored principal. [ELEVATED]  
   Expected result: Audit log confirms intended restoration activity with no unintended principals.

8. Set ticket to `Escalated - Governance Review` if root cause is still unknown after rollback.  
   Expected result: Service is restored while risk ownership remains active.

## 5) Notes

- This incident type is security-first; do not treat as standard endpoint troubleshooting.
- Copilot respects existing permissions; unexpected retrieval usually indicates an access-governance path, not a random model action.
- Inherited permissions and stale sharing links are common edge cases in legacy repositories.
- If audits prove no entitlement path existed, preserve all artifacts and escalate as potential vendor defect.
- Related incidents/patterns:
  - Unexpected Copilot retrieval from inherited SharePoint access.
  - Shared-link oversharing in legal repositories.
  - Group-membership drift causing unintended content visibility.
