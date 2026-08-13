$start=(Get-Date).AddMinutes(-15)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$start} -ErrorAction SilentlyContinue |
  Select-Object -First 5 | ForEach-Object {
    $xml=[xml]$_.ToXml(); $d=@{}; foreach($x in $xml.Event.EventData.Data){$d[$x.Name]=$x.'#text'}
    [pscustomobject]@{
      Time=$_.TimeCreated
      User=$d['TargetUserName']
      Domain=$d['TargetDomainName']
      AuthPackage=$d['AuthenticationPackageName']
      LogonProcess=$d['LogonProcessName']
      Status=$d['Status']
      SubStatus=$d['SubStatus']
    }
  } | Format-Table -AutoSize | Out-String
