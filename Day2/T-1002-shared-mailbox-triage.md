# Ticket Triage — T-1002

**Ticket:** T-1002  
**Subject:** Finance user cannot open a shared mailbox after migration  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real usernames, mailbox addresses, tenant details, or internal identifiers used. Treat as a draft; verify before action.

---

## Summary
A Finance team user lost access to a shared mailbox following a migration event, and can no longer open or view it in Outlook.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single Finance user (business-critical team) |
| How many | 1 user confirmed; to-verify whether other Finance users are affected |
| Business urgency | High — Finance shared mailboxes typically carry time-sensitive correspondence |
| Wider risk | To-verify — if migration affected a group or batch, multiple users may be impacted silently |

---

## Known Facts

- User is in the Finance team
- Shared mailbox was accessible before migration
- Access has failed since migration completed
- Specific error message not yet captured

---

## Missing Information to Gather

1. What type of migration occurred — Exchange on-premises to Exchange Online, tenant-to-tenant, or mailbox move?
2. What error (if any) does the user see when attempting to open the mailbox in Outlook?
3. Can the user access the shared mailbox via Outlook Web Access (OWA)? *(narrows client vs. permissions issue)*
4. Has the user's own mailbox migrated successfully, or are there other mail issues?
5. Has the shared mailbox itself been migrated, or only the user's primary mailbox?
6. Is the Full Access permission still assigned to the user on the shared mailbox? *(to-verify in admin portal)*
7. Has the Outlook profile been recreated or auto-mapped since migration? *(to-verify)*

---

## Likely Category

**Exchange / Microsoft 365 — Shared mailbox permissions lost or not re-applied post-migration**

Secondary possibility: Automapping not re-established after mailbox move; Outlook profile stale. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real mailbox addresses, user UPNs, or tenant details into this or any AI tool.**

1. Check the shared mailbox permissions in the **Microsoft 365 Admin Centre** or Exchange Admin Centre:
   - Confirm Full Access is still assigned to the affected user
   - Check whether the permission shows as pending or recently removed

2. Ask the user to attempt access via **OWA (Outlook Web Access)** — if it works there but not in the desktop client, the issue is Outlook profile/automapping rather than permissions.

3. If permissions are missing, re-assign Full Access and allow up to 60 minutes for propagation before retesting. *(to-verify propagation time in current tenant config)*
