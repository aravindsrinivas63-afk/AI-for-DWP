$logs = Get-WinEvent -ListLog * | Where-Object { $_.LogName -like '*RemoteDesktop*' -or $_.LogName -like '*TerminalServices*' -or $_.LogName -like '*WVD*' -or $_.LogName -like '*RDAgent*' }
$logs | Select-Object LogName,RecordCount,IsEnabled | Sort-Object LogName | Format-Table -AutoSize
foreach($l in $logs){
  Write-Output ("=== " + $l.LogName + " ===")
  try {
    Get-WinEvent -LogName $l.LogName -MaxEvents 5 | Select-Object TimeCreated,Id,LevelDisplayName,ProviderName,Message | Format-List
  } catch {
    Write-Output $_.Exception.Message
  }
}
