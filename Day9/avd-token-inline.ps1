$k = 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent'
$tok = ''
Set-ItemProperty -Path $k -Name RegistrationToken -Value $tok
Restart-Service -Name RDAgentBootLoader -Force
Start-Sleep -Seconds 30
$p = Get-ItemProperty $k
Write-Output ('TokenLength=' + $p.RegistrationToken.Length)
Write-Output ('TokenPrefix=' + $p.RegistrationToken.Substring(0,20))
Get-Service -Name RDAgentBootLoader | Select-Object Name,Status,StartType | ConvertTo-Json
