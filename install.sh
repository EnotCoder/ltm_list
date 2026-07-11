#!/usr/bin/env bash
set -e

SCRIPTS=("dvi" "dins" "calc" "imgsh" "gh" "vfx" "ved")
DIR="$(dirname "$(readlink -f "$0")")"

for name in "${SCRIPTS[@]}"; do
    src="$DIR/$name"
    dest="/usr/local/bin/$name"

    if [ ! -f "$src" ]; then
        echo "Файл $name не найден в текущей папке, пропускаю" >&2
        continue
    fi

    sudo cp "$src" "$dest"
    sudo chmod 755 "$dest"
    echo "$name установлен"
done

echo "Готово! Установлены: dvi, dins, calc, imgsh, gh, vfx, ved"
