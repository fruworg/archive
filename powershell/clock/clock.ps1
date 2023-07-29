$wshell = New-Object -ComObject Wscript.Shell
if (Get-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSecondsInSystemClock 2>$null){
  Remove-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSecondsInSystemClock
  $wshell.Popup("The registry entry was deleted.")
}else{
  New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowSecondsInSystemClock -PropertyType DWord -Value 1 >$null
  $wshell.Popup("The registry entry was created.")
}
taskkill /f /im explorer.exe >$null; start explorer.exe