#!/usr/bin/env bash
set -euo pipefail

# Copy a local source directory to the Kali host using tar over Tailscale SSH.
# Usage:
#   ./kali-sync-dir.sh ./local-project [remote-dir]
# Optional env vars:
#   KALI_HOST=kali
#   KALI_USER=kali
#   KALI_PORT=22
#   KALI_USE_TAILSCALE_SSH=1
#   KALI_REMOTE_ROOT=~/strix-arena-workspaces

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 ./local-dir [remote-dir]" >&2
  exit 2
fi

LOCAL_DIR="$1"
if [[ ! -d "$LOCAL_DIR" ]]; then
  echo "Local directory does not exist: $LOCAL_DIR" >&2
  exit 1
fi

KALI_HOST="${KALI_HOST:-kali}"
KALI_USER="${KALI_USER:-kali}"
KALI_PORT="${KALI_PORT:-22}"
KALI_USE_TAILSCALE_SSH="${KALI_USE_TAILSCALE_SSH:-1}"
KEY="${STRIX_KALI_KEY:-$HOME/.ssh/strix_kali_ed25519}"
REMOTE_ROOT="${KALI_REMOTE_ROOT:-~/strix-arena-workspaces}"

NAME="$(basename "$(realpath "$LOCAL_DIR")" | tr -c 'A-Za-z0-9._-' '_')"
REMOTE_DIR="${2:-$REMOTE_ROOT/$NAME}"
REMOTE_DIR_Q="$(python3 -c 'import shlex,sys; print(shlex.quote(sys.argv[1]))' "$REMOTE_DIR")"
REMOTE="${KALI_USER}@${KALI_HOST}"

run_remote() {
  if [[ "$KALI_USE_TAILSCALE_SSH" == "1" ]]; then
    tailscale ssh "$REMOTE" "$@"
  else
    ssh \
      -i "$KEY" \
      -o IdentitiesOnly=yes \
      -o StrictHostKeyChecking=accept-new \
      -o ServerAliveInterval=30 \
      -o ServerAliveCountMax=3 \
      -o "ProxyCommand=tailscale nc %h %p" \
      -p "$KALI_PORT" \
      "$REMOTE" "$@"
  fi
}

run_remote "mkdir -p $REMOTE_DIR_Q"

tar \
  --exclude='.git' \
  --exclude='.venv' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='build' \
  --exclude='target' \
  --exclude='coverage' \
  -C "$LOCAL_DIR" -cf - . \
| run_remote "tar -C $REMOTE_DIR_Q -xf -"

echo "Synced $LOCAL_DIR -> ${REMOTE}:$REMOTE_DIR"
