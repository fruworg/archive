# Разрешаем запуск скрипта и запускаем его
# Set-ExecutionPolicy Unrestricted -force ; cd ~\Desktop\ ; .\ad-users.ps1

Import-Module ActiveDirectory

# Указываем директорию
$dir = "$(pwd)\Users"
new-item -path "$dir" -ItemType Directory -force >$null

# Переменные DC
$dc_first = "demo"
$dc_second = "lab"

# Переменные OU
$ou_main = "DemoOffice"
$ou_users = "Users"
$ou_computers = "Computers"

# Переменные для настройки сети
$mask = "255.255.255.0"
$gw = '192.168.10.1'
$dns = '192.168.10.100'
$eth = 'Ethernet0'

# Переменные PATH
$dc_path = "DC=$dc_first,DC=$dc_second"
$main_path = "OU=$ou_main,DC=$dc_first,DC=$dc_second"
$users_path = "OU=$ou_users,OU=$ou_main,DC=$dc_first,DC=$dc_second"
$computers_path = "OU=$ou_computers,OU=$ou_main,DC=$dc_first,DC=$dc_second"

# Проверка OU
try
{
Get-ADOrganizationalUnit -SearchBase "$main_path" -Filter * >$null
Get-ADOrganizationalUnit -SearchBase "$users_path" -Filter * >$null
Get-ADOrganizationalUnit -SearchBase "$computers_path" -Filter * >$null
}
catch
{
New-ADOrganizationalUnit -Name "$ou_main" -Path $dc_path
New-ADOrganizationalUnit -Name "$ou_users" -Path $main_path
New-ADOrganizationalUnit -Name "$ou_computers" -Path $main_path
}

# Вводим переменные
if ("$args[0]" -eq "[0]"){
$numb = "1"
} else {
$numb = $args[0]
}
$count=1..$numb
$users = @()

Foreach ($i in $count)
{
$Row = "" | Select Username,Admin,IP,PC
$Row.Username = Read-Host "Введите имя пользователя номер $i"
$Row.Admin = Read-Host "Должен ли пользователь $i иметь права администратора? (Y - да, N - нет)"
if ($Row.Admin -eq "y")
{$Row.Admin = "Yes"}
else {$Row.Admin = "No"}
$Row.PC = Read-Host "Введите имя компьютера номер $i"
$Row.IP = Read-Host "Введите IP адрес для пользователя номер $i"
$Users += $Row
}
$pass = Read-Host 'Enter the password'

# Цикл с пользователями
foreach ($user in $users) {
$name = $user.Username
$ip = $user.ip
$pc = $user.pc
$Username = @{
Name = "$name"
GivenName = "$name"
UserPrincipalName = "$name@$dc_first.$dc_second"
Path = $users_path
ChangePasswordAtLogon = $true
AccountPassword = "$pass" | ConvertTo-SecureString -AsPlainText -Force
Enabled = $true
}

# Создание пользователей
New-ADUser @Username
Set-ADUser $name -PasswordNeverExpires:$True
if ($user.Admin -eq "Yes")
{Add-ADGroupMember "Domain admins" $name}

# Создание скрпитов для компьютеров "локально"
$securepassword = '$pass' + " | ConvertTo-SecureString -AsPlainText -Force"
$credential = "New-Object System.Management.Automation.PSCredential -ArgumentList" + ' $name, $securepassword'

$out = '# Разрешаем запуск скрипта и запускаем его
# Set-ExecutionPolicy Unrestricted -force ; cd ~\Desktop\ ;' + " .\$name.ps1" + '
$name = "' + "$name" + '"
' + '$pass = "' + "$pass" + '"
' + '$securepassword = ' + "$securepassword
" + '$credential = ' + "$credential
Disable-NetAdapterBinding -Name '*' -ComponentID ms_tcpip6
netsh interface ip set address name=$eth static $ip $mask $gw
netsh interface ip set dns $eth static $dns " + '>$null' + "
Timeout /T 5
Add-Computer -DomainName $dc_first.$dc_second -NewName $pc -OUPath " + '"' + "$computers_path" + '"' + " -Credential" + ' $credential
$ans = Read-Host "Перезагрузить ПК?"
if ($ans -eq "y")
{Restart-Computer -Force}'

$con="Проводное соединение 1"

$outl = '#!/usr/bin/env bash
if [[ $(whoami) == "root" ]]; then
' + '
ip=' + '"' + $ip + '"' + '
mask=' + '"' + 24 + '"' + '
gw=' + '"' + $gw + '"' + '
dns=' + '"' + $dns + '"' + '
pc=' + '"' + $pc + '"' + '
dc_first=' + '"' + $dc_first + '"' + '
dc_second=' + '"' + $dc_second + '"' + '
con=' + '"' + $con + '"' + '
name=' + '"' + $name + '"' + '
#Установка пакетов
apt install astra-ad-sssd-client -y
#Вводим краткое доменное имя
hostnamectl set-hostname "$pc"
# Задаем адрес шлюза
nmcli con mod "$con" ip4 $ip/$mask gw4 $gw
# Задаем адреса DNS
nmcli con mod "$con" ipv4.dns "$dns"
# Отключаем DHCP, переводим в "ручной" режим настройки
nmcli con mod "$con" ipv4.method manual
nmcli con mod "$con" ipv6.method ignore
nmcli -p con show "$con" | grep ipv4
# Перезапускаем соединение для применения новых настроек
nmcli con down "$con" ; nmcli con up "$con"
#Вход в домен Active Directory
astra-ad-sssd-client -d demo.lab -u Administrator -p ' + "$pass" + ' -y
# sudo
echo "$name ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo
#Перезагрузка
read -p "Перезагрузить ПК? " in
if [[ "$in" == "y" ]]; then
sudo reboot
fi
#Выполнено не от рута
else
echo "Запусти скрипт через sudo!"
fi'

# Указываем директорию и записываем данные пользователя
write-output $out | out-file -append -encoding utf8 "$dir\$name.ps1"

# Указываем директорию и записываем данные пользователя
write-output $outl | out-file -append -encoding utf8 "$dir\$name.sh"
((Get-Content "$dir\$name.sh") -join "`n") + "`n" | Set-Content -NoNewline -encoding utf8 "$dir\$name.sh"
}