Write-Host '
	_______________  _____________.____    ________   ________   ____  __.
	\_   _____/\   \/  /\______   \    |   \_____  \  \_____  \ |    |/ _|
	 |    __)_  \     /  |     ___/    |    /   |   \  /   |   \|      <  
	 |        \ /     \  |    |   |    |___/    |    \/    |    \    |  \ 
	/_______  //___/\  \ |____|   |_______ \_______  /\_______  /____|__ \
      	  \/       \_/                  \/       \/         \/        \/
'
Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook" | Out-Null
$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNameSpace("MAPI")
$Folder = $namespace.Folders("im@fruw.org").Folders("foldername")
$Path = "$(pwd)\exp-look.csv"
$i = $max = $Folder.Items.Count
$Writed = 0
if (!(Test-Path -Path $Path)) {
   'Тест1;Тест2' | Out-File $Path -Encoding UTF8
}
for(;$i -gt 0;$i--){
    if ($Folder.Items[$i].Unread){
    $Writed++
    $Folder.Items[$i].Unread = $False
    $Percent = 100-($i/$max*100)
    Write-Progress -Activity "Работаем!" -Status "Осталось прочитать $i у.е." -PercentComplete $Percent
    $MailInfo = $Folder.Items[$i] | Select-Object -Property Body, Subject, ReceivedTime, SenderName, SenderEmailAddress
    $MailInfo | Out-File $Path -Append -Encoding UTF8
}}
Read-Host -Prompt "	Выполнено! Внесено в таблицу $Writed у.е.
	Нажмите Enter для того, чтобы выйти"