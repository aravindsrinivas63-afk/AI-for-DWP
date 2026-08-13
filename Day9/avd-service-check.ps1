Get-Service -Name RdAgent,RDAgentBootLoader,TermService -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize
Get-Process -Name RDAgentBootLoader,RDAgent -ErrorAction SilentlyContinue | Select-Object Name,Id,CPU,StartTime | Format-Table -AutoSize
