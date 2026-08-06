# Ticket Triage — T-1007

**Ticket:** T-1007  
**Subject:** OneDrive stuck "processing changes" since migration; files missing locally  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real usernames, OneDrive paths, tenant details, or file names used. Treat as a draft; verify before action.

---

## Summary
Following a migration, the user's OneDrive client has been stuck in a "processing changes" state and files that were previously available locally are no longer present.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single user (role/team not specified) |
| How many | 1 confirmed; to-verify whether others in the same migration batch are affected |
| Business urgency | High — files missing locally could mean the user cannot access work documents; data integrity concern |
| Wider risk | To-verify — migration-related OneDrive issues can affect whole cohorts; escalate to migration team if pattern found |

---

## Known Facts

- User's OneDrive has been in "processing changes" state since a migration event
- Files that were previously visible locally are no longer present
- Duration of the stuck state is not confirmed but appears persistent since migration
- "Processing changes" can indicate a large sync queue, an authentication issue, or a sync conflict

---

## Missing Information to Gather

1. What type of migration occurred — tenant-to-tenant, SharePoint migration, or OneDrive account move?
2. How long has OneDrive been showing "processing changes"? Is there any progress, or is it completely static?
3. Is the user signed in to OneDrive with the correct post-migration account? *(account may still reference old tenant)*
4. Are the files still accessible via **OneDrive on the web (browser)**? *(determines if data is lost or just not synced)*
5. Does OneDrive show any error icon or specific error message when clicked?
6. Has the device been restarted since the migration?
7. Is the OneDrive client up to date? *(to-verify)*

---

## Likely Category

**OneDrive / Microsoft 365 — Post-migration sync failure (account re-authentication required or sync state corruption)**

Secondary possibility: OneDrive still connected to old tenant; known-folder move (Desktop/Documents redirect) not re-established post-migration. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real OneDrive paths, tenant URLs, usernames, or file listings from DWP devices into this or any AI tool.**

1. **Check OneDrive on the web first** — ask the user to sign in via a browser to confirm whether their files exist in the cloud. This immediately determines if the issue is a sync problem (data safe, not syncing) or a potential data loss event (escalate immediately if files are absent online).

2. Check which account OneDrive is signed in to on the device — right-click the OneDrive tray icon > **Settings > Account** — confirm it matches the post-migration account.

3. If the account is correct and files exist online, attempt to **pause and resume sync** via the OneDrive tray icon. If the client remains stuck, a **sign-out and sign-back-in** of the OneDrive client is the next step. *(to-verify this is permitted and does not affect other sync clients on the device)*
