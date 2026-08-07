# Known-Error Record - FinBridge AVD Black Screen

Symptom : Users in POOL-FIN-01 see a black screen immediately after AVD login. Some sessions recover after a short delay, while others remain black and disconnect/reconnect repeatedly.

Cause : The verified root cause is a graphics/display driver regression in the updated POOL-FIN-01 image. The failure pattern is dwm.exe crashing in igdumd64.dll during or immediately after logon.

Scope : The issue is isolated to POOL-FIN-01, which received the 02:00 image update on 2024-03-15. Approximately 40% of users in POOL-FIN-01 were affected; POOL-FIN-02 was unaffected and not part of the update wave.

Workaround : Drain or stop new logons to POOL-FIN-01 while the faulty image is active. Keep service on unaffected hosts/pools until validation is complete.

Permanent fix: Roll back or repair POOL-FIN-01 to the last known-good pre-update image baseline and restore the known-good graphics driver version where changed. Reboot affected hosts, retest multiple logons, and return POOL-FIN-01 to service only after no recurring black-screen pattern is observed.

How to spot it: Look for repeated Application Error Event 1000 showing dwm.exe faulting in igdumd64.dll (exception 0xc0000005), Desktop Window Manager Event 9009 exits (code 0x40010004), and TerminalServices-LocalSessionManager Event 40 disconnects following Event 21 logon success. In comparison, unaffected hosts show DWM Event 9011 start success with no corresponding Application Error events in the same window.
