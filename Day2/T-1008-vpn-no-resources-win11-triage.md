# Ticket Triage — T-1008

**Ticket:** T-1008  
**Subject:** VPN connects but no internal resources reachable after Win11 upgrade  
**Analyst role:** DWP Service Desk  
**Date:** 2026-08-04

> **AI usage note:** Drafted with AI assistance in line with the DWP Personal AI Usage Charter. No real VPN server names, IP ranges, hostnames, usernames, or internal network details used. Treat as a draft; verify before action.

---

## Summary
Following a Windows 11 upgrade, the user's VPN client connects successfully but internal resources (file shares, intranet, internal applications) are unreachable despite the tunnel being established.

---

## Impact

| Field | Detail |
|---|---|
| Who affected | Single remote user (role/team not specified) |
| How many | 1 confirmed; to-verify whether others in the same Win11 upgrade batch are affected |
| Business urgency | High — user is fully blocked from internal resources; effectively unable to work remotely |
| Wider risk | To-verify — if this is a driver or routing issue introduced by the Win11 upgrade, others in the same batch may be affected |

---

## Known Facts

- User has recently been upgraded to Windows 11
- VPN client reports a successful connection
- Internal resources are not reachable despite the connected state
- Issue began after the Win11 upgrade, not before

---

## Missing Information to Gather

1. Which VPN client is in use, and has it been updated or reinstalled as part of the Win11 upgrade? *(to-verify — some VPN clients require reinstallation post OS upgrade)*
2. Can the user reach any internal resource, or is everything blocked (DNS resolution, IP, web proxy)?
3. Does `ipconfig /all` show the VPN adapter with an assigned internal IP address when connected?
4. Is DNS resolution working for internal hostnames — does `nslookup <internal-hostname>` resolve correctly? *(use a generic placeholder, not a real hostname)*
5. Was the VPN client or its network adapter drivers flagged during the Win11 upgrade compatibility check? *(to-verify)*
6. Has the device received all post-upgrade Windows Updates, including driver updates?
7. Is the Windows Firewall profile showing the VPN adapter as **Public** rather than **Domain**? *(to-verify — common post-upgrade issue)*

---

## Likely Category

**VPN / Network — Post-Win11 upgrade routing or DNS split-tunnel failure, or VPN adapter/driver incompatibility**

Secondary possibility: Windows Firewall network profile changed to Public on VPN adapter, blocking internal traffic; VPN client split-tunnel routes not re-applied. *(to-verify)*

---

## First Diagnostic Step

> **Do not enter real VPN server addresses, internal IP ranges, hostnames, or network configurations from DWP into this or any AI tool.**

1. With the VPN connected, ask the user to run the following in an elevated command prompt and report back:

```
ipconfig /all
```

Confirm that:
- A VPN network adapter is listed
- It has an assigned IP address (not APIPA 169.254.x.x)
- DNS servers listed include internal DNS addresses

2. Then test basic name resolution:

```
nslookup <use a known internal generic hostname placeholder>
```

If the VPN adapter has no IP or DNS is pointing only to external resolvers, the tunnel is not routing correctly — escalate to the network/VPN team with the `ipconfig` output (redacted of any sensitive values before sharing).
