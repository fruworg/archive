#!/usr/bin/env bash

# проверка запуска от имени рута
if [ "$EUID" -ne 0 ]
  then echo "Use sudo, dummy."
  exit
fi

network_variables () {
  # переменные хоста
  read -p 'Введите имя этого ПК: ' -i $(hostname -s) -e PC_NAME
  read -p 'Введите имя домена: ' -i $(hostname -d) -e DOMAIN

  # меняем имя хоста
  hostnamectl set-hostname "$PC_NAME"

  # переменные сети
  read -p 'Введите имя интерфейса: ' -i eth0 -e INTERFACE
  read -p 'Введите адрес этого ПК: ' -i $(hostname -i) -e IP
  read -p 'Введите маску подсети: ' -i 24 -e SUBNET
  read -p 'Введите gateway: ' -i $(echo "$IP" | grep -Eo '([0-9]+\.)+') -e GATEWAY
  read -p 'Введите адрес DNS сервера: ' -i $(echo "$IP" | grep -Eo '([0-9]+\.)+') -e DNS

  # удаляем все соединения
  rm /etc/network/interfaces.d/* 2> /dev/null
  nmcli --terse connection show 2> /dev/null | cut -d : -f 1 | \
    while read name; do echo nmcli connection delete "$name" 2> /dev/null; done

  # поднимаем сеть
  echo "auto $INTERFACE" > "/etc/network/interfaces.d/$INTERFACE"
  echo "iface $INTERFACE inet static" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\taddress $IP" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\tnetmask $SUBNET" >> "/etc/network/interfaces.d/$INTERFACE"
  echo -e "\tgateway $GATEWAY" >> "/etc/network/interfaces.d/$INTERFACE"
  echo "nameserver $DNS" > '/etc/resolv.conf'
  systemctl restart networking

  # прописываем хостс
  echo "127.0.0.1 localhost" > /etc/hosts
  echo "$IP $PC_NAME.$DOMAIN $PC_NAME" >> /etc/hosts
}

admin_variables () {
  # переменные админа (для входа в домен)
  read -p 'Введите логин админимтратора: ' -i Administrator -e ADMIN_LOGIN
  read -p 'Введите пароль администратора: ' -i xxXX1234 -e ADMIN_PASSWORD
}

another_variables () {
  # переменные другого пк (домен/клиент)
  read -p 'Введите имя ПК: ' ANOTHER_PC_NAME
  read -p 'Введите адрес ПК: ' ANOTHER_IP

  # прописываем хостс
  echo "$ANOTHER_IP $ANOTHER_PC_NAME.$DOMAIN $ANOTHER_PC_NAME" >> /etc/hosts
}

check_variables () {
  if grep -L "0" <<< "$WHICH_FUNC"; then
    read -p "Сеть и хостс настроены? " -i n -e QUESTION
    if [[ "$QUESTION" == "n" ]]; then
      network_variables
    fi
  fi
}

admin_rules () {
  read -p "Дать пользователю права администратора? " -i y -e QUESTION
  if [[ "$QUESTION" == "y" ]]; then
    read -p 'Введите имя доменного пользователя: ' USERNAME
    pdpl-user -i 63 "$USERNAME"
    echo "$USERNAME ALL=(ALL:ALL) ALL" | EDITOR="tee -a" visudo
  fi
}

1.6_repos_update () {
  # подсказка по дискам
  echo "1. Smolensk-1.6.iso"
  echo "2. Devel-Smolensk-1.6.iso"
  echo "3. Repository-Update.iso"
  echo "4. Repository-Update-Devel.iso"
  read -p "Вы вставили все диски?"

  # CD/DVD-1 [Smolensk-1.6]
  while ! ls /dev/sr0 > /dev/null 2>&1; do
     read -p "Вставьте Smolensk-1.6.iso"
  done
  mkdir -p /srv/repo/smolensk/main
  mount /dev/sr0 /media/cdrom
  cp -a /media/cdrom/* /srv/repo/smolensk/main
  umount /media/cdrom

  # CD/DVD 2 [Devel-Smolensk-1.6]
  while ! ls /dev/sr1 > /dev/null 2>&1; do
     read -p "Вставьте Devel-Smolensk-1.6.iso"
  done
  mkdir -p /srv/repo/smolensk/devel
  mount /dev/sr1 /media/cdrom
  cp -a /media/cdrom/* /srv/repo/smolensk/devel
  umount /media/cdrom

  # CD/DVD 3 [20200722SE16]
  while ! ls /dev/sr2 > /dev/null 2>&1; do
     read -p "Вставьте Repository-Update.iso"
  done
  mkdir -p /srv/repo/smolensk/update
  mount /dev/sr2 /media/cdrom
  cp -a /media/cdrom/* /srv/repo/smolensk/update
  umount /media/cdrom

  # CD/DVD 4 [Repository-Update-Devel]
  while ! ls /dev/sr3 > /dev/null 2>&1; do
     read -p "Вставьте Repository-Update-Devel.iso"
  done
  mkdir -p /srv/repo/smolensk/update-dev
  mount /dev/sr3 /media/cdrom
  cp -a /media/cdrom/* /srv/repo/smolensk/update-dev
  umount /media/cdrom

  # дополняем источники
  echo "deb file:/srv/repo/smolensk/main smolensk main contrib non-free" > /etc/apt/sources.list
  echo "deb file:/srv/repo/smolensk/devel smolensk main contrib non-free" >> /etc/apt/sources.list
  echo "deb file:/srv/repo/smolensk/update smolensk main contrib non-free" >> /etc/apt/sources.list
  echo "deb file:/srv/repo/smolensk/update-dev smolensk main contrib non-free" >> /etc/apt/sources.list
}

1.7_repos_update () {
  # сертификаты
  apt install apt-transport-https ca-certificates

  # дополняем источники
  echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-main/ 1.7_x86-64 main contrib non-free" > /etc/apt/sources.list
  echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 main contrib non-free" >> /etc/apt/sources.list
  echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free" >> /etc/apt/sources.list
  echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free" >> /etc/apt/sources.list
}

repos_update () {
  # проверяем версию Астры
  ASTRA_VERISON=$(cat /etc/*-release)

  # версия 1.6
  if grep -q "1.6" <<< "$ASTRA_VERISON"; then
    1.6_repos_update
  fi

  # версия 1.7
  if grep -q "1.7" <<< "$ASTRA_VERISON"; then
    1.7_repos_update
  fi

  # обновление пакетов
  apt update -y
  apt dist-upgrade -y
  apt -f install -y
  apt autoremove -y
}

ssh_server () {
  # устанавливаем пакет
  apt install openssh-server -y

  # включаем SSH
  systemctl enable --now ssh
}

ssh_client () {
  # генерим ключи
  ssh-keygen

  # логин@пароль
  echo "Вводите данные сервера."
  admin_variables

  # передаюм ключи на удалённый сервер
  ssh-copy-id -i ~/.ssh/id_rsa.pub "$ADMIN_LOGIN"@"$ADMIN_PASSWORD"
}

ad_join () {
  # устанавливаем пакет
  apt install astra-ad-sssd-client -y

  # входим в домен
  check_variables
  admin_variables
  astra-ad-sssd-client -d "$(hostname -d)" -u "$ADMIN_LOGIN" -p "$ADMIN_PASSWORD" -y
  admin_rules
}

ald_init () {
  # устанавливаем пакеты
  apt install fly-admin-ald-server ald-server-common smolensk-security-ald -y

  # функции
  check_variables
  echo "Вводите данные клиента."
  another_variables

  # иницилизируем ald
  ald-init init
}

ald_join () {
  # устанавливаем пакеты
  apt install ald-client-common ald-admin -y

  # функции
  check_variables
  echo "Вводите данные домена."
  another_variables

  # входим в домен
  ald-client join
  admin_rules
}

dmcli_install () {
  # директория dmcli
  rm -rf dmcli/; mkdir dmcli/

  # наличие архива
  while ! ls *.tar.gz > /dev/null 2>&1; do
     read -p "Переместите архив клиента Device Monitor."
  done

  # распаковка архива
  tar -xvf *.tar.gz -C dmcli/

  # распаковка пакета
  PACKAGE=$(echo dmcli/*.deb)
  dpkg-deb -x "$PACKAGE" dmcli/dpkg/
  dpkg-deb -e "$PACKAGE" dmcli/dpkg/DEBIAN

  # замена файлов (вписывает текущее ядро)
  mv dmcli/dpkg/opt/iw/dmagent/lib/modules/*-$(uname -r | grep -P -o 'generic|hardened') \
	dmcli/dpkg/opt/iw/dmagent/lib/modules/$(uname -r)

  # сборка пакета
  rm "$PACKAGE" && dpkg -b dmcli/dpkg "$PACKAGE"

  # удаление старых ядер
  sudo apt-get remove `dpkg --list 'linux-image*' |grep ^ii | awk '{print $2}'\ | grep -v \`uname -r\``
  
  # установка девайс монитор клиента
  read -p 'Введите адрес и порт IWDM: ' -i 192.168.1.20:15101 -e IWDM
  dmcli/install.sh $IWDM
}

rutk_server () {
  # установка библиотек для сертификатов
  apt install libccid pcscd libpcsclite1 pcsc-tools opensc krb5-pkinit libpam-krb5 libengine-pkcs11-openssl1.1 -y
  wget https://es.ukrtb.ru/nextcloud/s/HX6fcj5mpBASTeG/download/librtpkcs11ecp_2.3.3.0-1_amd64.deb -O /tmp/librtpkcs11ecp.deb
  dpkg -i /tmp/librtpkcs11ecp.deb

  # создание сертификатов
  mkdir /etc/ssl/CA ; cd "$_"
  openssl genrsa -out cakey.pem 2048
  openssl req -key cakey.pem -new -x509 -days 3650 -out cacert.pem -subj "/C=RU/ST=RB/L=Ufa/O=UKRTB/OU=IB/CN=astra/emailAddress=astra@demo.lab"
  openssl genrsa -out kdckey.pem 2048
  openssl req -new -out kdc.req -key kdckey.pem -subj "/C=RU/ST=RB/L=Ufa/O=UKRTB/OU=IB/CN=astra/emailAddress=astra@demo.lab"
  wget https://es.ukrtb.ru/git/ukrtb/learn/raw/branch/master/pkinit_extensions
  sed -i "s/КЛИЕНТ/$(hostname -s)/" pkinit_extensions
  sed -i "s/РЕАЛМ/$(hostname -d)/" pkinit_extensions
  openssl x509 -req -in kdc.req -CAkey cakey.pem -CA cacert.pem -out kdc.pem -extfile pkinit_extensions -extensions kdc_cert -CAcreateserial -days 365
  cp kdc.pem kdckey.pem cacert.pem /var/lib/krb5kdc/

  # конфигурация керберос
  sed -i '/kdcdefaults/a \
    pkinit_identity = FILE:/var/lib/krb5kdc/kdc.pem,/var/lib/krb5kdc/kdckey.pem \
    pkinit_anchors = FILE:/var/lib/krb5kdc/cacert.pem '\
    /etc/ald/config-templates/kdc.conf
  ald-init commit-config

  # перезапуск керберос
  systemctl restart krb5-admin-server
  systemctl restart krb5-kdc

  # проверка наличия рутокена
  while ! pkcs11-tool --module /usr/lib/librtpkcs11ecp.so -T > /dev/null 2>&1; do
     read -p "Вставьте Рутокен."
  done

  # форматирование и инициализация токена
  pkcs15-init --erase-card -p rutoken_ecp
  pkcs15-init --create-pkcs15 --so-pin "87654321" --so-puk ""
  pkcs15-init --store-pin --label "User PIN" --auth-id 02 --pin "12345678" --puk "" --so-pin "87654321" --label "Rutoken" --finalize

  # генерация закрытых ключей на рутокене
  pkcs11-tool --slot 0 --login --pin 12345678 --keypairgen --key-type rsa:2048 --id 42 --label “ukrtb” --module /usr/lib/librtpkcs11ecp.so

  # генерация сертификатов
  openssl << EOT
engine dynamic -pre SO_PATH:/usr/lib/x86_64-linux-gnu/engines-1.1/pkcs11.so -pre ID:pkcs11 -pre LIST_ADD:1  -pre LOAD -pre MODULE_PATH:/usr/lib/librtpkcs11ecp.so
req -engine pkcs11 -new -key 0:42 -keyform engine -out client.req -subj "/C=RU/ST=RB/L=Ufa/O=UKRTB/OU=IB/CN=client/emailAddress=client@demo.lab"
x509 -CAkey cakey.pem -CA cacert.pem -req -in client.req -extensions client_cert -extfile pkinit_extensions -out client.pem -days 365
x509 -in client.pem -out client.cer -inform PEM -outform DER
q
EOT

  # перенос сертификатов на Рутокен
  pkcs15-init --store-certificate client.cer --auth-id 02 --id 42 --format der
  # pkcs15-init --store-certificate cacert.pem --auth-id 02 --id 11 --format pem
}

rutk_client () {
  # установка библиотек для сертификатов
  apt install libccid pcscd libpcsclite1 pcsc-tools opensc krb5-pkinit libpam-krb5 libengine-pkcs11-openssl1.1 -y
  wget https://es.ukrtb.ru/nextcloud/s/HX6fcj5mpBASTeG/download/librtpkcs11ecp_2.3.3.0-1_amd64.deb -O /tmp/librtpkcs11ecp.deb
  dpkg -i /tmp/librtpkcs11ecp.deb

  # создане директории для корневого сертификата
  mkdir /etc/krb5/

  # конфигурация керберос
  sed -i '/default_realm/a \
    pkinit_anchors = FILE:/etc/krb5/cacert.pem \
    pkinit_identities = PKCS11:/usr/lib/librtpkcs11ecp.so ' \
    /etc/krb5.conf
}

# определение необходимостей
echo "Сеть [0]"
echo "Репозитории [1]"
echo "Сервер SSH [2]"
echo "Беспарольный вход по SSH [3]"
echo "Вход в Active Directory [4]"
echo "Иницилизация Astra Linux Directory [5]"
echo "Вход в Astra Linux Directory [6]"
echo "Device Monitor клиент [7]"
echo "RUTK Сервер [8]"
echo "RUTK Клиент [9]"
read -p 'Выберите интересующие вас функции: [0124] ' WHICH_FUNC

if grep -q "0" <<< "$WHICH_FUNC"; then
  network_variables
fi

if grep -q "1" <<< "$WHICH_FUNC"; then
  repos_update
fi

if grep -q "2" <<< "$WHICH_FUNC"; then
  ssh_server
fi

if grep -q "3" <<< "$WHICH_FUNC"; then
  ssh_client
fi

if grep -q "4" <<< "$WHICH_FUNC"; then
  ad_join
fi

if grep -q "5" <<< "$WHICH_FUNC"; then
  ald_init
fi

if grep -q "6" <<< "$WHICH_FUNC"; then
  ald_join
fi

if grep -q "7" <<< "$WHICH_FUNC"; then
  dmcli_install
fi

if grep -q "8" <<< "$WHICH_FUNC"; then
  rutk_server
fi

if grep -q "9" <<< "$WHICH_FUNC"; then
  rutk_client
fi