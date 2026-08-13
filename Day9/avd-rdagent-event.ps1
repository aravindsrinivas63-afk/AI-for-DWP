$log='RemoteDesktopServices'
Get-WinEvent -LogName $log -MaxEvents 120 | Where-Object { $_.Message -match 'RdAgent|RDAgent|host pool|broker|heartbeat|health|connection|not accepting logons|registration' } | Select-Object -First 30 TimeCreated,Id,LevelDisplayName,ProviderName,Message | Format-List | Out-String
