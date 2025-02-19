#!/bin/bash
RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="36m"
SED=$(which sed)
CP=$(which cp)

usage="$(basename "$0") [-h] [-m -d -p]\n\n
      Please use the following options:\n\n
      -h help\n\n
      -m your email address eg: user@admin.com\n\n
      -d your dns eg: www.example.com\n\n
      -p (optional) caddy plugins eg: http-cache,tls.dns.cloudflare\n"

colorEcho(){
  COLOR=$1
  echo -e "\033[${COLOR}${@:2}\033[0m"
}

while getopts ":h:m:d:p:" opt; do
  case $opt in
    h)
      echo -e $usage
      exit
      ;;
    m)
      EMAIL=$OPTARG
      ;;
    d)
      V2RAY_DOMAIN=$OPTARG
      ;;
    p)
      PLUGINS=$OPTARG
      ;;
    \?)
      colorEcho ${RED}"Invalid option: -$opt"
      echo -e $usage
      exit 1
      ;;
  esac
done

if [[ -z $EMAIL ]]; then
  colorEcho ${YELLOW} "Please set your email address."
  echo -e ${usage}
  exit 1
fi

if [[ -z $V2RAY_DOMAIN ]]; then
  colorEcho ${YELLOW} "Please set your domain."
  echo -e ${usage}
  exit 1
fi

let PORT=$RANDOM+10000

if [[ "$OSTYPE" == *"darwin"*  ]]; then
  UUID=$(uuidgen | tr "[:upper:]" "[:lower:]")
  PATH=$(uuidgen | tr "[:upper:]" "[:lower:]")
else
  PATH=$(/bin/cat /proc/sys/kernel/random/uuid)
  UUID=$(/bin/cat /proc/sys/kernel/random/uuid)
fi

if [[ ! -d "config" ]]; then
  /bin/mkdir "config"
fi

$SED "s/{PORT}/$PORT/; s/{UUID}/$UUID/; s/{PATH}/$PATH/" files/v2ray-server.template > config/config.json
$SED "s/{URI}/$V2RAY_DOMAIN/; s/{PATH}/$PATH/; s/{UUID}/$UUID/" files/v2ray-client.template > config/client.json
$SED "s/{URI}/$V2RAY_DOMAIN/; s/{EMAIL}/$EMAIL/; s/{PATH}/$PATH/; s/{PORT}/$PORT/" files/caddyfile.template > config/Caddyfile
$CP config/config.json build/v2ray-tls/
$CP config/Caddyfile build/web-server/

if [[ -z $PLUGINS ]]; then
  $SED "s/{PLUGINS}//" files/getcaddy.template > build/web-server/getcaddy.sh
else
  $SED "s/{PLUGINS}/plugins=$PLUGINS/" files/getcaddy.template > build/web-server/getcaddy.sh
fi

colorEcho ${GREEN} "Please use $(pwd)/config/client.json to configure your client."
