$start=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$start} -ErrorAction SilentlyContinue |
  Select-Object -First 12 | ForEach-Object {
    $x=[xml]$_.ToXml(); $d=@{}; foreach($n in $x.Event.EventData.Data){$d[$n.Name]=$n.'#text'}
    [pscustomobject]@{
      Time=$_.TimeCreated
      User=$d['TargetUserName']
      Domain=$d['TargetDomainName']
      AuthPkg=$d['AuthenticationPackageName']
      LogonProcess=$d['LogonProcessName']
      LogonType=$d['LogonType']
      Status=$d['Status']
      SubStatus=$d['SubStatus']
    }
  } | Format-Table -AutoSize | Out-String
