#!/usr/bin/env bash

set -e
if ! whiptail -v >>/dev/null 2>&1; then
  if [ "$EUID" -ne 0 ]; then
    echo "Запустите скрипт от имени суперпользователя."
    exit 0
  fi
  apt-get -qq update
  apt-get -y install whiptail >>/dev/null 2>&1
fi

function error_msg () {
  whiptail --backtitle "EASY-TLS" --title "ОШИБКА" --msgbox "$1" 8 50
}

if [ "$EUID" -ne 0 ]; then
  error_msg "Запустите скрипт от имени суперпользователя."
  exit 0
fi
set +e

function certificate_services {
  set -e
  if [ -e "certs/$1.cert.pem" ]; then
    return 0
  fi
  SERVICE_DNS_NAME=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте адрес сертификата $1:" 9 50 "$1.$CA_DNS_NAME" 3>&1 1>&2 2>&3)
  openssl req -new \
    -newkey rsa:2048 -nodes \
    -keyout "certs/$1.key.pem" -out "certs/$1.csr" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$COMPANY/OU=$DEPARTMENT/CN=$SERVICE_DNS_NAME" 1>/dev/null 2>>easy-tls.log
  openssl x509 -req \
    -sha256 -days 365 \
    -CAkey "certs/root.key.pem" -CA "certs/root.cert.pem" -CAcreateserial \
    -in "certs/$1.csr" -out "certs/$1.cert.pem" 1>/dev/null 2>>easy-tls.log
}

function certificate_ca {
  set -e
  COUNTRY=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте страну:" 9 50 "RU" 3>&1 1>&2 2>&3)
  STATE=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте область:" 9 50 "MO" 3>&1 1>&2 2>&3)
  CITY=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте город:" 9 50 "MOSCOW" 3>&1 1>&2 2>&3)
  COMPANY=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте компанию:" 9 50 "IWTM" 3>&1 1>&2 2>&3)
  DEPARTMENT=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте отдел:" 9 50 "IT" 3>&1 1>&2 2>&3)
  CA_DNS_NAME=$(whiptail --backtitle "EASY-TLS" --title "CERTIFICATES" \
    --inputbox "\nЗадайте адрес:" 9 50 "demo.lab" 3>&1 1>&2 2>&3)
  if ! [ -e "certs" ]; then
    mkdir certs
  fi
  if ! [ -e "certs/root.key.pem" ]; then
    openssl req -x509 \
      -newkey rsa:2048 -sha256 -days 365 -nodes \
      -keyout "certs/root.key.pem" -out "certs/root.cert.pem" \
      -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$COMPANY/OU=$DEPARTMENT/CN=$CA_DNS_NAME" 1>/dev/null 2>>easy-tls.log
  fi
  certificate_services "iwtm"
  set +e
}

certificate_ca