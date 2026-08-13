$root = "C:\Program Files\Microsoft RDInfra"
Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.log','.txt','.config','.json','.xml','.ps1' } | ForEach-Object {
  try {
    Select-String -Path $_.FullName -Pattern 'RegistrationToken|hostpool|broker|rdbroker|wvd' -SimpleMatch -ErrorAction SilentlyContinue | Select-Object Path,LineNumber,Line
  } catch {}
} | Select-Object -First 80 | Format-Table -AutoSize | Out-String
