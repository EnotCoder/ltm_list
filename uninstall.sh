#!/usr/bin/env bash
set -e

SCRIPTS=("dvi" "dins" "calc" "imgsh" "gh" "vfx" "vol" "snk" "tls" "cld")

for name in "${SCRIPTS[@]}"; do
    dest="/usr/local/bin/$name"

    if [ -f "$dest" ]; then
        sudo rm "$dest"
        echo "$name removed"
    else
        echo "$name not found in /usr/local/bin" >&2
    fi
done
