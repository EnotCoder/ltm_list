#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "Installation failed at line $LINENO." >&2' ERR

SCRIPTS=(
    "dvi" "dins" "calc" "imgsh" "gh" "vfx"
    "vol" "snk" "tls" "cld" "keyfix"
)

# Lua programs. They are installed only if a Lua interpreter is available
# or the user agrees to install one.
LUA_SCRIPTS=(
    "ltm_welc"
    "notelp"
)

DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
REQUIREMENTS="$DIR/requirements.txt"

APP_DIR="$HOME/.local/share/my-python-tools"
VENV="$APP_DIR/venv"
BIN_DIR="/usr/local/bin"

# Select an interpreter with:
# PYTHON=python3.14 bash install.sh
PYTHON="${PYTHON:-python3}"

fail() {
    echo "Error: $*" >&2
    exit 1
}

# Print the name of an available Lua interpreter, or fail if none is found.
find_lua() {
    local candidate

    for candidate in lua luajit lua5.4 lua5.3 lua5.2 lua5.1; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s' "$candidate"
            return 0
        fi
    done

    return 1
}

# Try to install a Lua interpreter with the system package manager.
install_lua() {
    echo "Trying to install Lua with the system package manager..."

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y lua5.4
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y lua
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y lua
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm lua
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper --non-interactive install lua
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add lua5.4
    else
        echo "No supported package manager found." >&2
        return 1
    fi
}

if [ "$EUID" -eq 0 ]; then
    fail "Run this script without sudo:
  bash install.sh

The installer will request sudo when needed."
fi

command -v "$PYTHON" >/dev/null 2>&1 ||
    fail "Python interpreter not found: $PYTHON"

command -v sudo >/dev/null 2>&1 ||
    fail "The sudo command is required."

[ -f "$REQUIREMENTS" ] ||
    fail "Requirements file not found: $REQUIREMENTS"

[ -d "$DIR/python_code" ] ||
    fail "Source directory not found: $DIR/python_code"

# Accept Python 3.11 or newer, including Python 3.14.
"$PYTHON" -c '
import sys

if sys.version_info < (3, 11):
    print("Python 3.11 or newer is required.", file=sys.stderr)
    print("Current version:", sys.version.split()[0], file=sys.stderr)
    sys.exit(1)

print("Selected Python:", sys.version.split()[0])
' || fail "Please select a supported Python interpreter."

# Do not silently reuse an environment from another Python version.
if [ -e "$VENV" ] || [ -L "$VENV" ]; then
    [ -x "$VENV/bin/python" ] ||
        fail "The existing virtual environment is incomplete:
  $VENV

Move or remove it, then run the installer again."

    SELECTED_VERSION="$("$PYTHON" -c \
        'import sys; print(".".join(map(str, sys.version_info[:2])))')"

    EXISTING_VERSION="$("$VENV/bin/python" -c \
        'import sys; print(".".join(map(str, sys.version_info[:2])))')"

    if [ "$SELECTED_VERSION" != "$EXISTING_VERSION" ]; then
        fail "The existing environment uses Python $EXISTING_VERSION,
but the selected interpreter uses Python $SELECTED_VERSION.

Move or remove this environment before switching Python versions:
  $VENV"
    fi
fi

mkdir -p "$APP_DIR"

if [ ! -x "$VENV/bin/python" ]; then
    echo "Creating virtual environment: $VENV"

    if ! "$PYTHON" -m venv "$VENV"; then
        fail "Could not create the virtual environment.
Make sure venv support is installed for the selected Python."
    fi
else
    echo "Using existing virtual environment: $VENV"
fi

echo "Updating pip..."
"$VENV/bin/python" -m pip install --upgrade pip

echo "Installing dependencies..."
if ! "$VENV/bin/python" -m pip install -r "$REQUIREMENTS"; then
    fail "Dependency installation failed.
Check the pip output above."
fi

echo "Checking required imports..."
if ! "$VENV/bin/python" -c 'import PIL; import requests'; then
    fail "Dependency import check failed.
Check the error output above."
fi

# --- Lua programs (optional) ---
# Lua is not part of a standard system install, so ask the user before adding
# a new dependency. Declining simply skips the Lua programs.
LUA_BIN=""

if LUA_BIN="$(find_lua)"; then
    echo "Found Lua interpreter: $LUA_BIN"
else
    echo
    echo "Lua is not installed. It is required for the Lua programs:"
    printf '  %s\n' "${LUA_SCRIPTS[@]}"

    answer=""
    read -r -p "Install Lua now? [y/N] " answer || true

    case "$answer" in
        y|Y|yes|YES)
            if install_lua && LUA_BIN="$(find_lua)"; then
                echo "Lua installed: $LUA_BIN"
            else
                echo "Could not install Lua. Lua programs will be skipped." >&2
                LUA_BIN=""
            fi
            ;;
        *)
            echo "Skipping Lua programs."
            LUA_BIN=""
            ;;
    esac
fi

# Prepare scripts before modifying the installation directory.
STAGING="$(mktemp -d)"
trap 'rm -rf -- "$STAGING"' EXIT

INSTALLED=()

for name in "${SCRIPTS[@]}"; do
    src="$DIR/python_code/$name"

    if [ ! -f "$src" ]; then
        echo "Skipping $name: source file not found." >&2
        continue
    fi

    echo "Checking $name..."

    # Validate Python syntax without running the script.
    "$VENV/bin/python" - "$src" <<'PY'
import sys
import tokenize

path = sys.argv[1]

with tokenize.open(path) as source:
    compile(source.read(), path, "exec")
PY

    # Replace the shebang with the virtual environment interpreter.
    {
        printf '#!%s/bin/python\n' "$VENV"

        first_line="$(head -n 1 "$src")"

        if [[ "$first_line" == '#!'* ]]; then
            tail -n +2 "$src"
        else
            cat "$src"
        fi
    } > "$STAGING/$name"

    INSTALLED+=("$name")
done

if [ -n "$LUA_BIN" ]; then
    LUA_PATH="$(command -v "$LUA_BIN")"

    for name in "${LUA_SCRIPTS[@]}"; do
        src="$DIR/lua_code/$name.lua"

        if [ ! -f "$src" ]; then
            echo "Skipping $name: source file not found." >&2
            continue
        fi

        echo "Checking $name..."

        # Validate Lua syntax without running the script.
        if ! LUA_SRC="$src" "$LUA_BIN" -e \
            'local chunk, err = loadfile(os.getenv("LUA_SRC"))
             if not chunk then io.stderr:write(err, "\n"); os.exit(1) end'; then
            fail "Syntax check failed for $name."
        fi

        # Replace the shebang with the detected Lua interpreter.
        {
            printf '#!%s\n' "$LUA_PATH"

            first_line="$(head -n 1 "$src")"

            if [[ "$first_line" == '#!'* ]]; then
                tail -n +2 "$src"
            else
                cat "$src"
            fi
        } > "$STAGING/$name"

        INSTALLED+=("$name")
    done
fi

if [ "${#INSTALLED[@]}" -eq 0 ]; then
    fail "No scripts were found to install."
fi

echo
echo "Installing commands into $BIN_DIR..."
echo "Existing files with matching names will be replaced."

sudo -v
sudo install -d -m 755 "$BIN_DIR"

for name in "${INSTALLED[@]}"; do
    sudo install -m 755 "$STAGING/$name" "$BIN_DIR/$name"
    echo "Installed: $name"
done

echo
echo "Installation complete."
printf 'Installed commands: %s\n' "${INSTALLED[*]}"
echo "Virtual environment: $VENV"
echo "Manual environment activation is not required."