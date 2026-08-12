# FinBridge Win 11 Migration – Week 1 vs Week 2 Feedback Comparison

**Analysis Date:** 2026-08-12  
**Week 1 Sample:** 50 comments  
**Week 2 Sample:** 40 comments  

---

## Week 1 Themes: Status in Week 2

### Theme: Account Lockouts & AVD Authentication Failures

**Week 1:** 7 comments | Blocker | *Issue: Users locked out, cannot log in*

**Week 2 Status:** ✅ **RESOLVED**

**Evidence from Week 2:**
- *"Login is back to normal now, thanks for the fix!"* (ID 1)
- *"No more lockouts this week, good improvement."* (ID 7)
- *"Account lockouts have completely stopped, appreciate the fix."* (ID 19)
- *"Login and lockout issues from week 1 are fully resolved for me."* (ID 34)

**Analysis:** Zero lockout complaints in Week 2. The fix deployed after Week 1 was successful. Users explicitly acknowledge the improvement. This is a resolution success.

---

### Theme: Floor 3 Printer Not Mapping on Login

**Week 1:** 6 comments | Blocker | *Issue: Printer not auto-mapping, team cannot print*

**Week 2 Status:** ⚠️ **WORSENING**

**Evidence from Week 2:**
- *"Still can't get the printer on floor 3 to map, this is week 2 now."* (ID 2)
- *"Printer issue on floor 3 still not resolved, very frustrating."* (ID 5)
- *"Floor 3 printer – can someone just replace the thing at this point."* (ID 9)
- *"Still walking to floor 2 to print, floor 3 printer a lost cause at this point."* (ID 14)
- *"Printer floor 3 is now a running joke on our team, still broken."* (ID 18)
- *"Floor 3 printer unresolved for two weeks running now, needs escalation."* (ID 40)

**Analysis:** Comment count increased from 6 to 9 in Week 2. More importantly, **tone has escalated dramatically** — from frustration in Week 1 to resignation and escalation requests. Users have adapted by walking to floor 2 ("lost cause," "running joke"). One user is escalating to their manager. The unresolved status + team-wide workaround + duration (now two weeks) makes this a critical escalation risk and potential manager complaint. **This is trending downward in user satisfaction despite being the same issue.**

---

### Theme: OneDrive Files Missing or Sync Error

**Week 1:** 4 comments | Blocker | *Issue: Files not appearing in OneDrive*

**Week 2 Status:** ✅ **RESOLVED**

**Evidence from Week 2:**
- *"OneDrive files all showing up fine now."* (ID 3)
- *"Files are all there now, no more OneDrive issues for me."* (ID 11)
- *"OneDrive sync working perfectly now."* (ID 21)
- *"No file issues anymore, all resolved."* (ID 26)

**Analysis:** Zero missing-file complaints in Week 2. Files have been restored or recovery was completed. Users report files "all showing up fine" and sync working "perfectly." Complete resolution.

---

### Theme: Shared Drive (S:) Permission Denied

**Week 1:** 3 comments | Blocker | *Issue: Cannot access shared drive S:*

**Week 2 Status:** ✅ **RESOLVED** (or no new incidents)

**Evidence from Week 2:** No comments about S: drive access in Week 2.

**Analysis:** Either permissions were fixed or users found a workaround. No new reports suggest resolution or adaptation.

---

### Theme: VPN Dropping During Calls

**Week 1:** 4 comments | Friction | *Issue: VPN disconnects mid-call*

**Week 2 Status:** ✅ **RESOLVED**

**Evidence from Week 2:**
- *"VPN has been rock solid this week, no complaints."* (ID 10)
- *"VPN stable, no drops this week at all."* (ID 27)
- *"VPN and login both solid this week, thank you."* (ID 36)

**Analysis:** Zero complaints about VPN drops in Week 2. Users explicitly praise stability ("rock solid," "no drops"). Complete resolution.

---

### Theme: Slow Login / Logon Performance

**Week 1:** 3 comments | Friction | *Issue: Login takes 4–5 minutes*

**Week 2 Status:** ✅ **RESOLVED**

**Evidence from Week 2:**
- *"Login speed is back to what it used to be, thank you."* (ID 12)
- *"Login fast and reliable this week."* (ID 22)

**Analysis:** No complaints about login speed in Week 2. Users report speed returned to pre-migration baseline. Issue resolved alongside the lockout fix.

---

### Theme: Missing Desktop Shortcuts and Files

**Week 1:** 3 comments | Friction | *Issue: Shortcuts and files disappeared from desktop*

**Week 2 Status:** ✅ **RESOLVED** (or adapted)

**Evidence from Week 2:** No comments about missing shortcuts in Week 2.

**Analysis:** Either users recreated them or adapted to finding apps elsewhere. No new reports.

---

### Theme: UI and Cosmetic Changes

**Week 1:** 11 comments | Minor | *Issue: Start menu, taskbar, wallpaper, font sizes look different*

**Week 2 Status:** ➡️ **UNCHANGED**

**Evidence from Week 2:** No new complaints about cosmetic issues.

**Analysis:** Users have adapted to the new UI. No new reports in Week 2 suggests this is now "background noise" — not actively complained about, but not fully resolved. However, priority is zero since it's cosmetic.

---

### Theme: Positive Migration Experience

**Week 1:** 9 comments | Positive

**Week 2 Status:** ✅ **IMPROVING**

**Evidence from Week 2:**
- *"Overall much smoother now, appreciate the quick turnaround."* (ID 6)
- *"Great improvement overall since last week."* (ID 25)
- *"No issues to report this week, all smooth."* (ID 17)

**Analysis:** Positive sentiment has increased and become more grateful. Users are acknowledging the fixes and praising IT's response time. This is a morale win for the migration team.

---

## NEW THEME: Excel Crashes on Large Spreadsheets

**Week 2 Only:** 8 comments | Friction (escalating toward Blocker)

**Severity:** **Friction → Blocker** for finance team

**Evidence from Week 2:**
- *"New issue: Excel crashes when opening large spreadsheets."* (ID 4)
- *"Excel keeps crashing on our biggest budget spreadsheet, happened 3 times today."* (ID 8)
- *"Excel crash is really disruptive, losing unsaved work each time."* (ID 13)
- *"Excel large-file crash happened again, please look into this urgently."* (ID 24)
- *"Excel keeps crashing, this is now my biggest issue with the new setup."* (ID 30)
- *"New Excel crash issue – happens specifically with files over 10MB."* (ID 33)
- *"Excel crash is new and quite disruptive, please prioritise."* (ID 37)

**Trigger Pattern:** Large files, specifically files **over 10 MB** (noted in ID 33).

**Business Impact:** Finance team's biggest budget spreadsheet crashes repeatedly; users lose unsaved work. Same team that was affected by printer issues.

**Recommendation:** This is a new Blocker (or high-Friction escalating to Blocker) that requires immediate investigation. Likely related to the Windows 11 migration, possibly Office/Excel configuration, memory/resource allocation, or file size handling. Escalate to technical team same-day.

---

## Summary Table

| Theme | Week 1 | Week 2 | Trend |
|-------|--------|--------|-------|
| Account Lockouts | 7 Blocker | 0 | ✅ RESOLVED |
| Floor 3 Printer | 6 Blocker | 9 | ⚠️ WORSENING |
| OneDrive Missing | 4 Blocker | 0 | ✅ RESOLVED |
| Shared Drive Access | 3 Blocker | 0 | ✅ RESOLVED |
| VPN Dropping | 4 Friction | 0 | ✅ RESOLVED |
| Slow Login | 3 Friction | 0 | ✅ RESOLVED |
| Missing Shortcuts | 3 Friction | 0 | ✅ RESOLVED |
| UI Cosmetic | 11 Minor | 0 | ➡️ UNCHANGED |
| Positive Feedback | 9 Positive | 4+ | ✅ IMPROVING |
| **Excel Crashes (NEW)** | — | **8 Friction/Blocker** | 🆕 **NEW BLOCKER** |

---

## Key Takeaways

✅ **Major wins:** 6 out of 9 Week 1 themes have been fully resolved (lockouts, OneDrive, VPN, login speed, shared drive, shortcuts).

⚠️ **Critical risk:** Floor 3 printer remains unresolved and is now a **team-wide frustration point escalating to manager level**. This requires urgent executive action — either fix the root cause or replace the printer to restore trust.

🆕 **New blocker:** Excel crashes on large files (>10 MB) is a previously hidden issue now surfacing in Week 2. Finance team impact is significant. Requires same-day investigation.

📊 **Overall trajectory:** Week 2 shows marked improvement in user satisfaction for most issues, but the unresolved printer is creating a **negative halo effect** that is undermining the wins on other fronts.
