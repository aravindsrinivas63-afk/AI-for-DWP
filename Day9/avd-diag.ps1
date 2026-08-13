$p = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent'
Write-Output ('AzureResourceId=' + $p.AzureResourceId)
Write-Output ('HostPoolType=' + $p.HostPoolType)
if ($p.RegistrationToken) {
  Write-Output ('TokenLength=' + $p.RegistrationToken.Length)
  Write-Output ('TokenPrefix=' + $p.RegistrationToken.Substring(0,20))
} else {
  Write-Output 'TokenMissing'
}
Get-ChildItem 'C:\ProgramData\Microsoft\RDInfra' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 40 FullName,Length,LastWriteTime | Format-Table -AutoSize | Out-String
