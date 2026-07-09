#!/usr/bin/env bash
set -e

SRC="$(dirname "$(readlink -f "$0")")/dvi"
DEST="/usr/local/bin/dvi"

if [ ! -f "$SRC" ]; then
    echo "Файл dvi не найден в текущей папке" >&2
    exit 1
fi

sudo cp "$SRC" "$DEST"
sudo chmod 755 "$DEST"

echo "Установлено! Теперь можешь запускать: dvi <ссылка>"
