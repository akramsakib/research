#!/usr/bin/env sh
# Create a local-only handoff pack for review in this Arena conversation.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -x "$ROOT/.venv/bin/strix" ]; then
  printf '%s\n' "Strix dependencies are not installed. Run: $ROOT/bootstrap-strix.sh" >&2
  exit 1
fi
exec "$ROOT/.venv/bin/strix" arena-review "$@"
