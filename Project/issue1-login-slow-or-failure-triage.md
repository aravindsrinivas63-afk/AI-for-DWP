# Triage — Issue 1: Users Cannot Log In or Sign-in Is Very Slow

**Date:** 2026-08-14  
**Context:** Floor 6 incident, post-Friday app rollout

## Summary
Multiple users on Floor 6 report either login failure or very slow sign-in experience.

## Impact
- **Who affected:** Floor 6 users (Legal team context), exact user list to confirm  
- **How many:** "At least a dozen" reported, exact count to confirm  
- **Business urgency:** High — users blocked or delayed from starting work  
- **Wider risk:** Possible if issue is tied to shared policy/app change

## Known Facts
- Reports include both "can’t log in" and "taking forever".
- Users were recently migrated to Win11 and enrolled in Intune.
- A new document management app was rolled out Friday afternoon to this floor.

## Missing Information to Gather
1. Exact split: hard login failure vs successful but slow login.
2. Exact error messages/codes shown on failed logins.
3. Whether affected users are all in the Friday rollout assignment group.
4. Whether unaffected users exist on same floor with similar device profile.
5. Whether lockout, conditional access, or compliance signals appear in sign-in logs.
6. Whether delay occurs before credentials accepted, after auth, or during desktop/profile load.

## Likely Category
**Identity/compliance and endpoint startup regression potentially correlated to Friday change** (to confirm).

## First Diagnostic Step
Start with rapid scope split and evidence pull:
1. Separate users into "cannot authenticate" and "auth succeeds but slow desktop load".
2. Check Entra sign-in and account lockout/compliance signals for 2-3 affected users.
3. Compare one affected vs one unaffected device for logon/profile load timing and policy/app assignment state.
