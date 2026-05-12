#!/bin/sh
set -eu

sed -e "s|__TELEGRAM_BOT_TOKEN__|${TELEGRAM_BOT_TOKEN:-}|g" \
    -e "s|__TELEGRAM_CHAT_ID__|${TELEGRAM_CHAT_ID:-}|g" \
  /etc/alertmanager/alertmanager.yml > /tmp/alertmanager.rendered.yml

exec /bin/alertmanager \
  --config.file=/tmp/alertmanager.rendered.yml \
  --storage.path=/alertmanager \
  --log.level=info