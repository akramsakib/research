#!/usr/bin/env sh
# Interactive, one-time OAuth sign-in for the ChatGPT subscription provider.
# This does not use or store an API key. It stores the OAuth token in ~/.strix/.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -x "$ROOT/.venv/bin/strix" ]; then
  printf '%s\n' "Strix dependencies are not installed. Run: $ROOT/bootstrap-strix.sh" >&2
  exit 1
fi
exec "$ROOT/.venv/bin/strix" auth login chatgpt --manual
