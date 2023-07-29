# Скачиваем софт по ссылкам ниже
# https://es.ukrtb.ru/nextcloud/s/xwBAsTqWqT8QyBT/download/OpenSSL.msi
# https://es.ukrtb.ru/nextcloud/s/PoxqfCWkXtrdgw7/download/putty.msi
# https://es.ukrtb.ru/nextcloud/s/ybKx8rpJX8fbZtS/download/WinSCP.exe

# Делаем ручное подключение (Астра)
# plink iwtm@192.168.1.10 -pw xxXX1234

# Запускаем скрипт
# Set-ExecutionPolicy Unrestricted -force; cd ~\Desktop\; .\tm-ssl.ps1

# Павершелл следует запускать от имени администратора
Write-Host "`nПроверка привелегий администратора:"
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Warning "Запустите павершелл от имени администратора.`n"
Break
}
else {
Write-Host "Скрипт запущен от имени администратора.`n" -ForegroundColor Green
}

# Остановка скрипта при ошибке
$ErrorActionPreference = "Stop"

# Указываем пути
$path = "C:\Program Files\OpenSSL-Win64\bin"
$hpath = "$(pwd)\tm-ssl"
$wpath = "C:\Program Files (x86)\WinSCP"
$lpath = "$hpath\linux"
$cpath = "$hpath\certs"
$dpath = "tmp"

# Названия сертификатов
$root = "root"
$intermediate = "intermediate"
$server = "iwtm"
$client = "arm"

# Данные для линупса
$cnf = "iw"
if (!($ip = Read-Host "Введите IP IWTM [192.168.1.10]")) { $ip = "192.168.1.10" }
if (!($luser = Read-Host "Введите пользователя IWTM [iwtm]")) { $luser = "iwtm" }
if (!($lpassword = Read-Host "Введите пароль IWTM [xxXX1234]")) { $lpassword = "xxXX1234" }

# Промежуточный = серверный
if (!($servint = Read-Host "`nСделать серверный сертификат промежуточным [y]")) { $servint = "y" }
if ($servint -eq "y"){
  $intermediate = $server
}

# Данные для сертификата
if (!($country = Read-Host "`nВведите страну [RU]")) { $country = "RU" }
if (!($state = Read-Host "Введите штат [RB]")) { $state = "RB" }
if (!($city = Read-Host "Введите город [Ufa]")) { $city = "Ufa" }
if (!($corp = Read-Host "Введите организацию [UKRTB]")) { $corp = "UKRTB" }
if (!($unit = Read-Host "Введите отдел [IT]")) { $unit = "IT" }
if (!($hostname = Read-Host "Введите хостнейм [iwtm]")) { $hostname = "iwtm" }
if (!($domain = Read-Host "Введите домен [demo.lab]")) { $domain = "demo.lab" }
if (!($password = Read-Host "Введите пароль .p12 [xxXX1234]")) { $password = "xxXX1234" }
$site = "$hostname.$domain"

# Конфиг опенссл
$config = "
[ ca ]
default_ca = CA_default
[ CA_default ]
certs = ./
serial = serial
database = index
new_certs_dir = ./
certificate = $root.crt
private_key = $root.key
default_days = 36500
default_md  = sha256
preserve = no
email_in_dn  = no
nameopt = default_ca
certopt = default_ca
policy = policy_match
[ policy_match ]
commonName = supplied
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
emailAddress = optional
[ req ]
input_password = $password
prompt = no
distinguished_name  = default
default_bits = 2048
default_keyfile = priv.pem
default_md = sha256
req_extensions = v3_req
encyrpt_key = no
x509_extensions = v3_ca
[ default ]
commonName = default
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true
[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectAltName = @alt_names
[ v3_req ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = $site
IP.1 = $ip"

# Удаляем файлы, которые могли остаться от прошлого запуска скрипта
cd $path
Remove-Item * -Include *.sh,*.cnf,*.key,*.csr,*.crt,*.p12,*.pem,seria*,inde* -Force

if (Test-Path "$hpath") {
  rm -r -fo "$hpath"
}

# Создаём файл с номером и индексом скрипта, конфиг опенссл и скрипт для линукса
out-file -append -encoding utf8 "index"
write-output "01" | out-file -append -encoding ASCII "serial"
write-output $config | out-file -append -encoding utf8 "$cnf.cnf"

# Продолжение скрипта при ошибке
$ErrorActionPreference = "Continue"

# Обработка ошибок
$TempFile = New-TemporaryFile
function Error-Break{
# Если в файлы нет Signature ok + MAC + он не пустой, то if выполняется
if ((!(Select-String -Path "$TempFile" -Pattern 'Signature ok') -and (!(Select-String -Path "$TempFile" -Pattern 'MAC'))) -xor ([String]::IsNullOrWhiteSpace((Get-content $TempFile)))){
  # Вывод ошибок
  $err = Get-Content -Path $TempFile 
  Write-Error "$err"
  # break
  break
  }
}

# Имя сертификата
$name = $root
# Создаём корневой ключ
.\openssl genrsa -out "$root.key" 2> $TempFile; Error-Break
# Создаём корневой самоподписанный сертификат
.\openssl req -x509 -new -nodes -key "$root.key" -sha256 -days 1024 -out "$root.crt" -config "$cnf.cnf" -subj "/C=$country/ST=$state/L=$city/O=$corp/OU=$unit/CN=$name/emailAddress=$name@$domain" *> $TempFile; Error-Break

Write-Host "`nКорневой сертификат создан." -ForegroundColor Green

# Имя сертификата
$name = $intermediate
# Создаёи промежуточный ключ
.\openssl genrsa -out "$intermediate.key" *> $TempFile; Error-Break
# Создаём запрос на подпись  
.\openssl req -new -sha256 -config "$cnf.cnf" -key "$intermediate.key" -out "$intermediate.csr" *> $TempFile; Error-Break
# Подписываем сертификат корневым 
.\openssl ca -config "$cnf.cnf" -extensions v3_intermediate_ca -days 2650 -batch -in "$intermediate.csr" -out "$intermediate.crt" -subj "/C=$country/ST=$state/L=$city/O=$corp/OU=$unit/CN=$name/emailAddress=$name@$domain" *> $TempFile; Error-Break

# Промежуточный =/= серверный + создание серверного сертификата
if ($servint -ne "y"){
  Write-Host "Промежуточный сертификат создан." -ForegroundColor Green
  # Имя сертификата
  $name = $server
  # Создаём ключ клиента
  .\openssl genrsa -out "$server.key" *> $TempFile; Error-Break
  # Создаём запрос на подпись
  .\openssl req -new -key "$server.key" -out "$server.csr" -config "$cnf.cnf" *> $TempFile; Error-Break
  # Подписываем сертификат промежуточным
  .\openssl x509 -req -in "$server.csr" -CA "$intermediate.crt" -CAkey "$intermediate.key" -CAcreateserial -sha256 -days 2650 -days 2650 -set_serial 01 -out "$server.crt" -extensions v3_req -extfile "$cnf.cnf" -subj "/C=$country/ST=$state/L=$city/O=$corp/OU=$unit/CN=$name/emailAddress=$name@$domain" *> $TempFile; Error-Break
} 

Write-Host "Серверный сертификат создан." -ForegroundColor Green

# Создание клиентского сертификата
# Имя сертификата
$name = $client
# Создаём ключ клиента
.\openssl genrsa -out "$client.key" *> $TempFile; Error-Break
# Создаём запрос на подпись
.\openssl req -new -key "$client.key" -out "$client.csr" -config "$cnf.cnf" *> $TempFile; Error-Break
# Подписываем сертификат промежуточный
(.\openssl x509 -req -in "$client.csr" -CA "$intermediate.crt" -CAkey "$intermediate.key" -CAcreateserial -sha256 -days 2650 -out "$client.crt" -extensions v3_req -extfile "$cnf.cnf" -subj "/C=$country/ST=$state/L=$city/O=$corp/OU=$unit/CN=$name/emailAddress=$name@$domain") *> $TempFile; Error-Break

Write-Host "Клиентский сертификат создан." -ForegroundColor Green

# Остановка скрипта при ошибке
$ErrorActionPreference = "Stop"

$thumbprint = $(Get-PfxCertificate -FilePath "$client.crt" | select -expand Thumbprint).ToLower()

# Экспортируем промежуточный сертификат и ключ
.\openssl pkcs12 -export -in "$server.crt" -inkey "$server.key" -out "$server.p12" -password pass:"$password"

# Экспортируем для бравузера
.\openssl pkcs12 -export -in "$client.crt" -inkey "$client.key" -out "$client.p12" -password pass:"$password"

# Экспортируем всё
.\openssl pkcs12 -export -in "$server.crt" -inkey "$server.key" -in "$client.crt" -inkey "$client.key" -in "$root.crt" -inkey "$root.key" -out out.p12 -password pass:"$password"

&{
  # Создаём директории для сертификатов и линупса
  New-Item -path "$cpath" -ItemType Directory -force
  New-Item -path "$lpath" -ItemType Directory -force
} >$null

Write-Host "`nДиректории созданы успешно." -ForegroundColor Green

$ssl_client_fingerprint = '$ssl_client_fingerprint'
# Скрипт для линукса
$linux = "#!/usr/bin/env bash
openssl pkcs12 -in /$dpath/$server.p12 -nokeys -out /opt/iw/tm5/etc/certification/$server.crt -password pass:$password
openssl pkcs12 -in /$dpath/$server.p12 -nocerts -nodes -out /opt/iw/tm5/etc/certification/$server.key -password pass:$password
rm /$dpath/$server.p12
cd /etc/nginx/conf.d
cp iwtm.conf -n iwtm.conf.bak || mv iwtm.conf.bak iwtm.conf
sed -i '9s/web-server.pem/$server.crt/' iwtm.conf
sed -i '10s/web-server.key/$server.key/' iwtm.conf
sed -i '12i ssl_verify_client optional_no_ca;' iwtm.conf
sed -i '21i if ( $ssl_client_fingerprint != $thumbprint ) { return 496; }' iwtm.conf
"

write-output $linux | out-file -append -encoding utf8 "$cnf.sh"

# Преобразуем скрипт для линукса в *nix формат
((Get-Content "$cnf.sh") -join "`n") + "`n" | Set-Content -NoNewline "$cnf.sh"

# Перемещаем скрипт для линукса и .p12
Move-Item -path ".\$cnf.sh" -destination "$lpath\$cnf.sh" -force
Move-Item -path ".\$server.p12" -destination "$lpath\$server.p12" -force

# Перемещаем остальное добро
Get-ChildItem -Path ".\*.pfx" -Recurse | Move-Item -Destination "$cpath" -force
Get-ChildItem -Path ".\*.p12" -Recurse | Move-Item -Destination "$cpath" -force
Get-ChildItem -Path ".\*.key" -Recurse | Move-Item -Destination "$cpath" -force
Get-ChildItem -Path ".\*.csr" -Recurse | Move-Item -Destination "$cpath" -force
Get-ChildItem -Path ".\*.crt" -Recurse | Move-Item -Destination "$cpath" -force

# Подчищаем за собой
Remove-Item * -Include *.cnf,*.pem,seria*,inde* -Force

# Устанавливаем сертификаты в шиндоус
&{
  Import-Certificate -FilePath "$cpath\$root.crt" -CertStoreLocation Cert:\LocalMachine\Root
  if ($servint -eq "y"){
  Import-Certificate -FilePath "$cpath\$server.crt" -CertStoreLocation Cert:\LocalMachine\CA
  }else{
    Import-Certificate -FilePath "$cpath\$intermediate.crt" -CertStoreLocation Cert:\LocalMachine\CA
    Import-Certificate -FilePath "$cpath\$server.crt" -CertStoreLocation Cert:\LocalMachine\My
  }
  Import-Certificate -FilePath "$cpath\$client.crt" -CertStoreLocation Cert:\LocalMachine\My
} >$null

Write-Host "Сертификаты установлены." -ForegroundColor Green

# Перемещаем скрипт и сертификаты в линупс
&{
  cd $wpath
  .\WinSCP.exe sftp://${luser}:${lpassword}@${ip}/$dpath/ /upload $lpath\$server.p12 $lpath\$cnf.sh /defaults
  Read-Host "`nКогда WinSCP успешно передаст файлы, нажмите [ENTER]"

  # Запускаем скрипт удалённо
  echo y | plink -batch $luser@$ip -pw $lpassword "exit" *> $null
  plink -batch $luser@$ip -pw $lpassword "sudo bash /$dpath/$cnf.sh"; Error-Break 

  # Чистим за собой
  plink -batch $luser@$ip -pw $lpassword "sudo rm /$dpath/$cnf.sh"; Error-Break
  plink -batch $luser@$ip -pw $lpassword "history -c"; Error-Break
} 2>$null

Write-Host "IWTM сконфигурирован." -ForegroundColor Green

# Записываем данные в DNS
&{Remove-DnsServerResourceRecord -ZoneName $domain -Name $hostname -RRType A -force} 2> $null
Add-DnsServerResourceRecordA -Name $hostname -IPv4Address $ip -ZoneName $domain -TimeToLive 01:00:00

Write-Host "DNS запись создана.`n" -ForegroundColor Green
Write-Warning "Перезагрузи NGINX и установи в бразуер сертификат.`n"