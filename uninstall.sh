#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "Uninstallation failed at line $LINENO." >&2' ERR

SCRIPTS=(
    "dvi" "dins" "calc" "imgsh" "gh" "vfx"
    "vol" "snk" "tls" "cld" "keyfix"
)

LUA_SCRIPTS=(
    "ltm_welc"
)

APP_DIR="$HOME/.local/share/my-python-tools"
VENV="$APP_DIR/venv"
BIN_DIR="/usr/local/bin"
EXPECTED_SHEBANG="#!$VENV/bin/python"

# A file is managed by this installation when its shebang is either the
# virtual environment interpreter (Python) or any Lua interpreter. Lua may be
# installed at different paths, so its shebang is matched with a pattern.
is_managed() {
    case "$1" in
        "$EXPECTED_SHEBANG"|'#!'*lua*) return 0 ;;
        *) return 1 ;;
    esac
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

if [ "$EUID" -eq 0 ]; then
    fail "Run this script without sudo:
  bash uninstall.sh

The uninstaller will request sudo when needed."
fi

TO_REMOVE=()

# Only select scripts installed with this environment's interpreter.
for name in "${SCRIPTS[@]}" "${LUA_SCRIPTS[@]}"; do
    dest="$BIN_DIR/$name"

    if [ -L "$dest" ]; then
        echo "Skipping $name: symbolic links are not managed."
        continue
    fi

    if [ ! -f "$dest" ]; then
        echo "Skipping $name: not installed."
        continue
    fi

    if [ ! -r "$dest" ]; then
        echo "Skipping $name: file is not readable." >&2
        continue
    fi

    first_line="$(head -n 1 "$dest")"

    if ! is_managed "$first_line"; then
        echo "Skipping $name: not managed by this installation."
        continue
    fi

    TO_REMOVE+=("$name")
done

REMOVE_ENV=false

if [ -e "$APP_DIR" ] || [ -L "$APP_DIR" ]; then
    echo
    echo "Application directory:"
    echo "  $APP_DIR"
    echo "Removing it will delete the virtual environment and its packages."

    answer=""
    read -r -p "Remove this directory too? [y/N] " answer || true

    case "$answer" in
        y|Y|yes|YES)
            REMOVE_ENV=true
            ;;
    esac
fi

if [ "${#TO_REMOVE[@]}" -eq 0 ] && [ "$REMOVE_ENV" = false ]; then
    echo "Nothing to uninstall."
    exit 0
fi

echo
echo "Uninstallation plan:"

for name in "${TO_REMOVE[@]}"; do
    echo "  Remove $BIN_DIR/$name"
done

if [ "$REMOVE_ENV" = true ]; then
    echo "  Remove $APP_DIR"
else
    echo "  Keep the virtual environment."
fi

echo
answer=""
read -r -p "Continue? [y/N] " answer || true

case "$answer" in
    y|Y|yes|YES)
        ;;
    *)
        echo "Cancelled."
        exit 0
        ;;
esac

if [ "${#TO_REMOVE[@]}" -gt 0 ]; then
    command -v sudo >/dev/null 2>&1 ||
        fail "The sudo command is required."

    sudo -v

    for name in "${TO_REMOVE[@]}"; do
        dest="$BIN_DIR/$name"

        # Check installation markers again before removing the file.
        if [ -L "$dest" ] || [ ! -f "$dest" ]; then
            echo "Skipping $name: file changed."
            continue
        fi

        if [ ! -r "$dest" ]; then
            echo "Skipping $name: file is not readable." >&2
            continue
        fi

        first_line="$(head -n 1 "$dest")"

        if ! is_managed "$first_line"; then
            echo "Skipping $name: interpreter changed."
            continue
        fi

        sudo rm -- "$dest"
        echo "Removed: $name"
    done
fi

if [ "$REMOVE_ENV" = true ]; then
    # Guard against an unexpected deletion target.
    if [ "$APP_DIR" != "$HOME/.local/share/my-python-tools" ]; then
        fail "Unexpected application directory."
    fi

    # Remove a symlink itself, never its target.
    if [ -L "$APP_DIR" ]; then
        rm -- "$APP_DIR"
    elif [ -d "$APP_DIR" ]; then
        rm -rf -- "$APP_DIR"
    elif [ -e "$APP_DIR" ]; then
        fail "Application path exists but is not a directory."
    fi

    echo "Removed application directory: $APP_DIR"
fi

echo "Uninstallation complete."