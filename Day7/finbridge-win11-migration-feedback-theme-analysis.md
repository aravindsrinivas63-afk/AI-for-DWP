# FinBridge Win 11 Migration – End-User Feedback Theme Analysis

**Source:** 50 post-migration comments from FinBridge staff  
**Analyst:** DWP Analyst  
**Date:** 2026-08-12  

---

## All Identified Themes

| # | Theme | Count | Severity |
|---|-------|-------|----------|
| 1 | Account Lockouts & AVD Authentication Failures | 7 | Blocker |
| 2 | Floor 3 Printer Not Mapping on Login | 6 | Blocker |
| 3 | OneDrive Files Missing or Sync Error | 4 | Blocker |
| 4 | Shared Drive (S:) Permission Denied | 3 | Blocker |
| 5 | VPN Dropping During Calls | 4 | Friction |
| 6 | Slow Login / Logon Performance | 3 | Friction |
| 7 | Missing Desktop Shortcuts and Files | 3 | Friction |
| 8 | UI and Cosmetic Changes | 11 | Minor |
| 9 | Positive Migration Experience | 9 | Positive |

**Total comments:** 50

---

## Top 3 Themes to Act On Today

> Ranking applies a severity-first weighting. A single Blocker outranks any number of Minor comments. Within the same severity tier, volume is the tiebreaker.

---

### Rank 1 — Account Lockouts & AVD Authentication Failures

**Count:** 7 | **Severity:** Blocker

**Why it ranks first:**  
Highest volume among all Blocker themes. Seven users — across multiple days and multiple attempts — are completely locked out of their working environment. Several comments reference repeat lockouts (2nd and 3rd occurrences in the same week), and at least two incidents occurred immediately before client calls. Users cannot work at all until this is resolved; no workaround exists for an account lockout. The persistence (repeated lockouts, not one-offs) suggests a policy or configuration defect, not isolated user error.

**One sentence for your manager:**  
Seven FinBridge staff are experiencing repeat account lockouts and AVD sign-in failures since the Win 11 migration — some for the third time this week — and cannot work at all until this is investigated and the root cause fixed today.

---

### Rank 2 — Floor 3 Printer Not Mapping on Login

**Count:** 6 | **Severity:** Blocker

**Why it ranks second:**  
Six comments spanning at least three consecutive days confirm this is unresolved and deteriorating — the final comment states the team has abandoned the floor 3 printer entirely and walks to floor 2. The impact is team-wide (not individual), it blocks printing of client documents, and at least one user raised it against a 2 pm client meeting deadline. Volume is strong and the duration (day 1 through day 3+) makes this an escalation risk if not resolved today.

**One sentence for your manager:**  
The floor 3 printer has failed to map on login for the entire team since migration day, it has not been resolved despite prior IT acknowledgement, and staff are now physically walking to another floor to print for client meetings.

---

### Rank 3 — OneDrive Files Missing or Sync Error

**Count:** 4 | **Severity:** Blocker

**Why it ranks third:**  
Four users report files as missing or unconfirmed from OneDrive, with two explicitly citing business deadlines (a Q1 report due end of day, a meeting requiring files). This carries a data-integrity risk — if files were not migrated or sync was broken, recovery windows may be time-limited. It ranks below the printer issue solely on volume (4 vs 6) and because OneDrive may have a shorter recovery path via admin restore; however, a single case of genuine data loss would make this a Rank 1 incident.

**One sentence for your manager:**  
Four users cannot locate their OneDrive files post-migration — two with same-day business deadlines — and this needs urgent admin verification today to rule out data loss before recovery options close.

---

## Themes Not in the Top 3 — Rationale

| Theme | Why excluded from top 3 |
|-------|------------------------|
| Shared Drive (S:) Permission Denied (3, Blocker) | Also a Blocker but lower volume than OneDrive (3 vs 4); monitor closely as a potential Rank 3 promotion if OneDrive is cleared. |
| VPN Dropping During Calls (4, Friction) | High frustration and real business impact, but users can still work between drops; address same day if Blocker queue clears. |
| Slow Login Performance (3, Friction) | Friction only; users are working, just slowly. Schedule investigation for tomorrow. |
| Missing Desktop Shortcuts (3, Friction) | Low effort fix but Friction only; self-service KB may resolve most cases. |
| UI and Cosmetic Changes (11, Minor) | Highest comment volume of any theme but zero work-blocking impact; no action required today. |
| Positive Feedback (9, Positive) | No action required; share with migration team for morale. |
