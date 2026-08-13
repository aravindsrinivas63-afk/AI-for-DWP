$txt = dsregcmd /status | Out-String
$txt -split "`r?`n" | Where-Object { $_ -match 'AzureAdJoined|DomainJoined|EnterpriseJoined|DeviceAuthStatus|TenantId' } | Out-String
