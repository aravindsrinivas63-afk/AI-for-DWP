# FinBridge AVD Black Screen Hypothesis

**Incident scope:** POOL-FIN-01 black screen after login, POOL-FIN-02 unaffected  
**Key timing clue:** POOL-FIN-01 received an overnight image update at 02:00; POOL-FIN-02 did not  
**Status:** Hypothesis only, not yet confirmed

---

## Most consistent explanation

The fact that POOL-FIN-02 was not updated and is completely unaffected makes the strongest hypothesis an issue introduced by the updated POOL-FIN-01 image itself. Within that set of image-bound causes, a graphics/display driver regression is the best fit for a black screen after login.

---

## Ranked causes, most likely first

1. **Graphics/display driver regression in the updated pool image**
   - Why it fits: The issue is isolated to the updated pool, began immediately after the overnight change, and the symptom is a black screen after login with partial recovery for some users.
   - Fastest check: Compare the image version and display/graphics driver set on an affected POOL-FIN-01 host with a healthy POOL-FIN-02 host.

2. **Session host logon shell initialization delay or failure in the updated image**
   - Why it fits: A black screen that clears after about 30 seconds suggests the desktop is eventually starting, which is consistent with a delayed shell or session initialization path.
   - Fastest check: Review event logs on an affected host for delayed shell, explorer, or userinit startup around the login window.

3. **Profile load regression tied to the new image**
   - Why it fits: A pool-specific image change can affect profile loading, and profile-load failures can present as a blank screen before the desktop appears.
   - Fastest check: Check whether affected sessions are slow or failing at profile load versus shell start by comparing logon timestamps and profile-related events.

4. **Host resource or service contention on POOL-FIN-01 after the image update**
   - Why it fits: A new image can introduce startup services or agents that delay desktop presentation on some hosts, which could explain why only part of the pool is affected.
   - Fastest check: Check CPU, RAM, disk, and service startup delays on an affected host during a fresh login.

5. **Bad logon script, GPO, or startup app introduced with the updated image**
   - Why it fits: A new startup or policy component can stall the session after sign-in, but this is a broader and less direct explanation than a graphics/display issue.
   - Fastest check: Compare applied GPOs, startup apps, and logon scripts between POOL-FIN-01 and POOL-FIN-02.

---

## Why the timing clue matters

POOL-FIN-02 being completely unaffected is the key discriminator. It strongly reduces the chance of a platform-wide AVD, network, or tenant issue and pushes the analysis toward a change introduced only in POOL-FIN-01 at 02:00. That makes image-bound causes the right bucket, and graphics/display regression the best first hypothesis inside that bucket.

---

## Current conclusion

Do not commit to a single root cause yet. Treat the updated POOL-FIN-01 image as the most likely fault boundary, then test graphics/display first because it best matches the black-screen symptom and the pool-only impact pattern.
