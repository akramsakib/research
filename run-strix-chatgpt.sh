#!/usr/bin/env sh
# Run the workspace copy of Strix using a ChatGPT subscription (no API key).
# First time only: ./bootstrap-strix.sh && ./setup-chatgpt-auth.sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -x "$ROOT/.venv/bin/strix" ]; then
  printf '%s\n' "Strix dependencies are not installed. Run: $ROOT/bootstrap-strix.sh" >&2
  exit 1
fi
exec "$ROOT/.venv/bin/strix" --config "$ROOT/strix-chatgpt-config.json" "$@"
