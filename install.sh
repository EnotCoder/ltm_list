#!/usr/bin/env bash
set -e

SCRIPTS=("dvi" "dins" "calc" "imgsh" "gh" "vfx" "vol" "snk" "tls" "cld" "keyfix")
DIR="$(dirname "$(readlink -f "$0")")"

for name in "${SCRIPTS[@]}"; do
    src="$DIR/$name"
    dest="/usr/local/bin/$name"

    if [ ! -f "$src" ]; then
        echo "File $name not found in current folder, skipping" >&2
        continue
    fi

    sudo cp "$src" "$dest"
    sudo chmod 755 "$dest"
    echo "$name installed"
done

echo "Done! Installed: dvi, dins, calc, imgsh, gh, vfx, vol, snk, tls, cld"
