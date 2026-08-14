# Prevention Note

## Control Name
Mandatory Department Pilot Ring with First-Business-Day Validation Gate

## Process Change
Before any application deployment can be promoted to an entire department, it must first be deployed to a named Pilot Ring consisting of 5-10 representative users from that department and remain in pilot status through the next business morning.

A deployment cannot progress to full departmental rollout until the deployment owner completes and documents a First-Business-Day Validation Checklist, confirming:

- Successful user logins
- Acceptable logon performance
- Desktop shortcuts and user profile settings remain intact
- Application launches successfully
- No increase in help desk tickets
- No Intune or endpoint health alerts
- Pilot user sign-off obtained

## Why This Would Have Prevented the Incident
The document management application was deployed on Friday afternoon, but the widespread impact was not discovered until users returned on Monday morning.

Had a Department Pilot Ring with a First-Business-Day Validation Gate been in place:

- The deployment would have been limited to a small subset of Legal users.
- Login delays and missing shortcuts would have been detected Monday morning within the pilot group.
- The rollout would have been automatically blocked from reaching all 45 Floor 6 users.
- IT could have remediated the issue before department-wide impact occurred.

## Success Criteria
No application deployment may proceed from Pilot to Department-Wide status without documented completion of the validation gate and approval from the application owner and endpoint management team.

Expected Outcome: Issues affecting logon performance, user profiles, desktop shortcuts, or application compatibility are detected within a controlled pilot population before reaching the wider business.