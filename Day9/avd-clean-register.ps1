param([string]$HP_TOKEN)
$work = "C:\Windows\Temp\avd"
New-Item -Path $work -ItemType Directory -Force | Out-Null
$boot = Join-Path $work 'RDAgentBootLoader.msi'
$agent = Join-Path $work 'RDAgent.msi'
if (-not (Test-Path $boot)) { Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile $boot }
if (-not (Test-Path $agent)) { Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile $agent }
Stop-Service -Name RdAgent -ErrorAction SilentlyContinue
Stop-Service -Name RDAgentBootLoader -ErrorAction SilentlyContinue
Start-Process -FilePath msiexec.exe -ArgumentList "/x {9E517C03-7990-4800-A050-ED26F41A2091} /qn /norestart /l*v $work\agent-uninstall.log" -Wait
Start-Process -FilePath msiexec.exe -ArgumentList "/i $boot /qn /norestart /l*v $work\bootloader-install.log" -Wait
Start-Process -FilePath msiexec.exe -ArgumentList "/i $agent /qn /norestart REGISTRATIONTOKEN=$HP_TOKEN /l*v $work\agent-install.log" -Wait
Start-Service -Name RDAgentBootLoader -ErrorAction SilentlyContinue
Start-Service -Name RdAgent -ErrorAction SilentlyContinue
Get-Service -Name RDAgentBootLoader,RdAgent -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize | Out-String
"--- INSTALL LOG TAIL ---"
Get-Content "$work\agent-install.log" -Tail 40 | Out-String
