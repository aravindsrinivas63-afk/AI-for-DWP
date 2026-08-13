$start=(Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624; StartTime=$start} -ErrorAction SilentlyContinue |
  Select-Object -First 20 TimeCreated,
    @{N='TargetUserName';E={$_.Properties[5].Value}},
    @{N='TargetDomainName';E={$_.Properties[6].Value}},
    @{N='LogonType';E={$_.Properties[8].Value}},
    @{N='ProcessName';E={$_.Properties[17].Value}},
    @{N='IpAddress';E={$_.Properties[18].Value}} |
  Format-Table -AutoSize | Out-String
