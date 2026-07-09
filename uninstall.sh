#!/usr/bin/env bash
set -e

DEST="/usr/local/bin/dvi"

if [ -f "$DEST" ]; then
    sudo rm "$DEST"
    echo "dvi удалён"
else
    echo "dvi не найден в /usr/local/bin" >&2
fi
