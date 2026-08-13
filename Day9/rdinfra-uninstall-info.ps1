$paths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
Get-ItemProperty $paths -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match 'Remote Desktop Services Infrastructure|RDInfra|RDAgent' } |
  Select-Object DisplayName,DisplayVersion,PSChildName,UninstallString |
  Format-Table -AutoSize | Out-String
