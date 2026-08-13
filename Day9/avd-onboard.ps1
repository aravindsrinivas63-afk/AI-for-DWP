$work = "C:\Windows\Temp\avd"
New-Item -Path $work -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile "$work\RDAgentBootLoader.msi"
Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile "$work\RDAgent.msi"
Start-Process -FilePath msiexec.exe -ArgumentList "/i $work\RDAgentBootLoader.msi /quiet /qn /norestart /l*v $work\bootloader.log" -Wait
Start-Process -FilePath msiexec.exe -ArgumentList "/i $work\RDAgent.msi /quiet /qn /norestart REGISTRATIONTOKEN=$env:HP_TOKEN /l*v $work\agent.log" -Wait
Get-Service -Name RdAgent,RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize | Out-String
Get-Content "$work\agent.log" -Tail 30 | Out-String
