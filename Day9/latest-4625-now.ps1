$start=(Get-Date).AddMinutes(-20)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$start} -ErrorAction SilentlyContinue |
  Select-Object -First 8 | ForEach-Object {
    $xml=[xml]$_.ToXml(); $d=@{}; foreach($x in $xml.Event.EventData.Data){$d[$x.Name]=$x.'#text'}
    [pscustomobject]@{
      Time=$_.TimeCreated
      User=$d['TargetUserName']
      Domain=$d['TargetDomainName']
      Status=$d['Status']
      SubStatus=$d['SubStatus']
      LogonType=$d['LogonType']
      AuthPkg=$d['AuthenticationPackageName']
      LogonProcess=$d['LogonProcessName']
    }
  } | Format-Table -AutoSize | Out-String
