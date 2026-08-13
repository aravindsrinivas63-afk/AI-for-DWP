$start=(Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$start} -ErrorAction SilentlyContinue |
  Where-Object { $_.Properties[5].Value -eq 'p31@zippyops.in' } |
  Select-Object -First 5 TimeCreated,
    @{N='User';E={$_.Properties[5].Value}},
    @{N='StatusHex';E={('{0:X8}' -f ([uint32]$_.Properties[7].Value))}},
    @{N='SubStatusHex';E={('{0:X8}' -f ([uint32]$_.Properties[9].Value))}},
    @{N='LogonType';E={$_.Properties[10].Value}} |
  Format-Table -AutoSize | Out-String
