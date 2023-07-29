#Перед началом необходимо выполнить следующие команды:
#Install-module PSExcel
#Get-command -module psexcel
clear
Write-Host "
	       .__                           .__        
	___  __|  |   _________  ___         |__|_____  
	\  \/  /  |  /  ___/\  \/  /  ______ |  \____ \ 
	 >    <|  |__\___ \  >    <  /_____/ |  |  |_> >
	/__/\_ \____/____  >/__/\_ \         |__|   __/ 
	      \/         \/       \/            |__|    
"
if ($Args.count -ne 0){
	$Value = $Args
} else {
	$Value = Read-Host "	Введите имена файлов"
	Write-Host ""
	$Value = $Value -split " " 
} 

for ($i=0; $i -lt $Value.count; $i++){
$Path = "$(pwd)\" + [string]$Value[$i] + ".xlsx"
try{
$File = Import-XLSX -Path $Path
$Out = $File.IP -match "\d" -replace "ip address "
$Out = $Out -replace " 255\.0\.0\.0", "/8"
$Out = $Out -replace " 255\.128\.0\.0", "/9"
$Out = $Out -replace " 255\.192\.0\.0", "/10"
$Out = $Out -replace " 255\.224\.0\.0", "/11"
$Out = $Out -replace " 255\.240\.0\.0", "/12"
$Out = $Out -replace " 255\.248\.0\.0", "/13"
$Out = $Out -replace " 255\.252\.0\.0", "/14"
$Out = $Out -replace " 255\.254\.0\.0", "/15"
$Out = $Out -replace " 255\.255\.0\.0", "/16"
$Out = $Out -replace " 255\.255\.128", "/17"
$Out = $Out -replace " 255\.255\.192\.0", "/18"
$Out = $Out -replace " 255\.255\.224\.0", "/19"
$Out = $Out -replace " 255\.255\.240\.0", "/20"
$Out = $Out -replace " 255\.255\.252\.0", "/22"
$Out = $Out -replace " 255\.255\.254\.0", "/23"
$Out = $Out -replace " 255\.255\.255\.0", "/24"
$Out = $Out -replace " 255\.255\.255\.128", "/25"
$Out = $Out -replace " 255\.255\.255\.192", "/26"
$Out = $Out -replace " 255\.255\.255\.224", "/27"
$Out = $Out -replace " 255\.255\.255\.240", "/28"
$Out = $Out -replace " 255\.255\.255\.248", "/29"
$Out = $Out -replace " 255\.255\.255\.252", "/30"
$Out | Out-File .\except.txt -Append -Encoding UTF8
cat .\except.txt | select -Unique | sc .\except.txt
$nerr = $nerr + "	$Path
"
}
catch{
$err = $err + "	$Path
"}
}
if ($nerr -match "[A-z]"){
Write-Host -ForegroundColor Gree "	Файлы ниже обработаны:
$nerr"}
if ($err -match "[A-z]"){
Write-Host -ForegroundColor Red "	Файлы ниже не найдены:
$err"
}
Read-Host -Prompt "	Выполнено! Нажмите Enter"
