$start=(Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$start} -ErrorAction SilentlyContinue |
  Select-Object -First 20 TimeCreated,
    @{N='TargetUserName';E={$_.Properties[5].Value}},
    @{N='TargetDomainName';E={$_.Properties[6].Value}},
    @{N='Status';E={$_.Properties[7].Value}},
    @{N='SubStatus';E={$_.Properties[9].Value}},
    @{N='LogonType';E={$_.Properties[10].Value}},
    @{N='ProcessName';E={$_.Properties[17].Value}},
    @{N='IpAddress';E={$_.Properties[19].Value}} |
  Format-Table -AutoSize | Out-String
