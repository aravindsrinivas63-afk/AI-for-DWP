param([string]$HP_TOKEN)
$work = "C:\Windows\Temp\avd"
if (-not (Test-Path $work)) { New-Item -Path $work -ItemType Directory -Force | Out-Null }
$boot = Join-Path $work 'RDAgentBootLoader.msi'
$agent = Join-Path $work 'RDAgent.msi'
if (-not (Test-Path $boot)) { Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile $boot }
if (-not (Test-Path $agent)) { Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile $agent }
Start-Process -FilePath msiexec.exe -ArgumentList "/i $boot /quiet /qn /norestart /l*v $work\bootloader-register.log" -Wait
Start-Process -FilePath msiexec.exe -ArgumentList "/i $agent /quiet /qn /norestart REGISTRATIONTOKEN=$HP_TOKEN /l*v $work\agent-register.log" -Wait
Restart-Service -Name RDAgentBootLoader -ErrorAction SilentlyContinue
Restart-Service -Name RdAgent -ErrorAction SilentlyContinue
Get-Service -Name RdAgent,RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize | Out-String
Get-Content "$work\agent-register.log" -Tail 20 | Out-String
