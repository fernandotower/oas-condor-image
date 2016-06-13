#!/bin/bash

set -eu

config="/etc/telegram-notify-conf.json"

message="${1:-no message}"
bot_key="${TELEGRAM_BOT_KEY:-}"
notify_chats="${TELEGRAM_NOTIFY_CHATS:-}"

if [ -z "${bot_key}" -a -e "${config}" ]
then
  bot_key="$(jq -r .botKey < "${config}" || true)"
fi

if [ -z "${notify_chats}" -a -e "${config}" ]
then
  notify_chats="$(jq -r '.notifyChats' < "${config}" || true)"
fi

if [ -z "${bot_key}" ]
then
  echo "No puedo continuar sin una llave de bot, defina la llave del bot como 'botKey' en '${config}' o en la variable de entorno TELEGRAM_BOT_KEY"
  exit 1
fi

if [ -z "${notify_chats}" ]
then
  echo "No puedo continuar sin un chat al cual notificar, defina los chats a notificar como 'notifyChats' una lista separada por comas en '${config}' o en la variable de entorno TELEGRAM_NOTIFY_CHATS"
  exit 1
fi

api_base="https://api.telegram.org/bot${bot_key}"

ok="true"
IFS=,
for chat_id in $notify_chats
do
  body="$(jq --arg chat_id "${chat_id}" --arg text "${message}" '{
    "chat_id": $chat_id,
    "parse_mode": "Markdown",
    "text": $text
  }' <<< "{}" )"
  telegram_response="$(curl -s -d@- -H "Content-Type: application/json" "${api_base}/sendMessage" <<< "${body}")"
  ok_response="$(jq -r .ok <<< "${telegram_response}")"
  if [ "${ok_response}" != "true" ]
  then
    ok="false"
    last_error="${telegram_message}"
  fi
done

if [ "${ok}" != "true" ]
then
  echo "${last_error}"
  exit 1
fi
