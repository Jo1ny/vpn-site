#!/usr/bin/env bash
set -euo pipefail
USERNAME="${1:-}"
CONFIG_FILE="$HOME/vpn-site/xray-conf/config.json"
DOMAIN="cns-devnotes.space"
WS_PATH="/VLSpdG9k"

if [[ -z "$USERNAME" ]]; then
	echo "Usage: ./add-user.sh <username>"
	exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
	echo "Ошибка: Файл конфигурации не найден по пути $CONFIG_FILE"
	exit 1
fi

if jq -r '.inbounds[0].settings.clients[].email' "$CONFIG_FILE" | grep -qx "$USERNAME"; then
	echo "Пользователь '$USERNAME' уже есть!"
	exit 1
fi

NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
echo "Создаем пользователя: $USERNAME с UUID: $NEW_UUID"
echo "Путь к конфигу: $CONFIG_FILE"

cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
jq --arg email "$USERNAME" --arg uuid "$NEW_UUID" \
	'.inbounds[0].settings.clients += [{"id": $uuid, "email": $email}]' \
	"$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

docker compose -f "$HOME/vpn-site/docker-compose.yml" restart xray

VLESS_LINK="vless://${NEW_UUID}@${DOMAIN}:443?type=ws&security=tls&path=${WS_PATH}&sni=${DOMAIN}#${USERNAME}"
echo -e "\n Пользователь $USERNAME успешно добавлен!"
echo -e "Ссылка для клиента:\n$VLESS_LINK\n"
echo "QR-код для сканирования"
qrencode -t ANSIUTF8 "$VLESS_LINK"
