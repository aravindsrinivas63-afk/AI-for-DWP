$start=(Get-Date).AddHours(-1)
$events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$start} -ErrorAction SilentlyContinue | Select-Object -First 6
foreach($e in $events){
  "=== Event Time: $($e.TimeCreated) ==="
  $xml = [xml]$e.ToXml()
  $data = @{}
  foreach($d in $xml.Event.EventData.Data){ $data[$d.Name]=$d.'#text' }
  "TargetUserName: $($data['TargetUserName'])"
  "TargetDomainName: $($data['TargetDomainName'])"
  "Status: $($data['Status'])"
  "SubStatus: $($data['SubStatus'])"
  "LogonType: $($data['LogonType'])"
  "AuthenticationPackageName: $($data['AuthenticationPackageName'])"
  "IpAddress: $($data['IpAddress'])"
  "WorkstationName: $($data['WorkstationName'])"
  "ProcessName: $($data['ProcessName'])"
}
