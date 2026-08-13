$base = "C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.ActiveDirectory.AADLoginForWindows\2.2.0.0"
Get-ChildItem $base -Filter *.log | Sort-Object LastWriteTime -Descending | Select-Object -First 6 | ForEach-Object {
  "=== $($_.Name) ==="
  Get-Content $_.FullName -Tail 120
}
