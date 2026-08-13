$urls = @(
  "https://rdbroker.wvd.microsoft.com/",
  "https://rdbroker-g-us-r1.wvd.microsoft.com/",
  "https://rddiagnostics-g-us-r1.wvd.microsoft.com/",
  "https://enterpriseregistration.windows.net/"
)
foreach($u in $urls){
  try {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing -Method Get -TimeoutSec 20
    "$u => $($r.StatusCode)"
  } catch {
    "$u => ERROR: $($_.Exception.Message)"
  }
}
