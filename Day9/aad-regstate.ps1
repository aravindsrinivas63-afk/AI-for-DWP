$paths = @(
  "HKLM:\SOFTWARE\Microsoft\AADLoginForWindowsExtension",
  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AAD",
  "HKLM:\SOFTWARE\Microsoft\Enrollments"
)
foreach($path in $paths){
  "=== $path ==="
  if(Test-Path $path){ Get-ItemProperty -Path $path | Format-List * | Out-String } else { "NotFound" }
}
