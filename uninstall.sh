#!/usr/bin/env bash
set -e

SCRIPTS=("dvi" "dins" "calc" "imgsh" "gh")

for name in "${SCRIPTS[@]}"; do
    dest="/usr/local/bin/$name"

    if [ -f "$dest" ]; then
        sudo rm "$dest"
        echo "$name удалён"
    else
        echo "$name не найден в /usr/local/bin" >&2
    fi
done
