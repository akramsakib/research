#!/usr/bin/env sh
# Re-create the local Strix Python environment when it is not already present.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
python3 -m venv "$ROOT/.venv"
"$ROOT/.venv/bin/python" -m pip install --upgrade pip
"$ROOT/.venv/bin/pip" install -e "$ROOT"
printf '\nStrix is installed at %s\n' "$ROOT/.venv/bin/strix"
