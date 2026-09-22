#!/usr/bin/env bash
set -euo pipefail

# Run a command on the user-owned Kali host over Tailscale.
# Defaults match the Kali node discovered in this tailnet.
# Optional env vars:
#   KALI_HOST=kali
#   KALI_USER=kali
#   KALI_PORT=22
#   KALI_USE_TAILSCALE_SSH=1  # default; uses Tailscale SSH/ACL auth
#   STRIX_KALI_KEY=~/.ssh/strix_kali_ed25519  # only used for normal OpenSSH mode

KALI_HOST="${KALI_HOST:-kali}"
KALI_USER="${KALI_USER:-kali}"
KALI_PORT="${KALI_PORT:-22}"
KALI_USE_TAILSCALE_SSH="${KALI_USE_TAILSCALE_SSH:-1}"
KEY="${STRIX_KALI_KEY:-$HOME/.ssh/strix_kali_ed25519}"

if [[ "$KALI_USE_TAILSCALE_SSH" == "1" ]]; then
  if [[ $# -eq 0 ]]; then
    exec tailscale ssh "${KALI_USER}@${KALI_HOST}"
  fi
  exec tailscale ssh "${KALI_USER}@${KALI_HOST}" "$@"
fi

# Normal OpenSSH mode. Proxy through tailscale nc so it also works when this
# Arena environment uses Tailscale userspace networking and has no kernel TUN route.
SSH_OPTS=(
  -i "$KEY"
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=accept-new
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
  -o "ProxyCommand=tailscale nc %h %p"
  -p "$KALI_PORT"
)

if [[ ! -f "$KEY" ]]; then
  echo "SSH key not found: $KEY" >&2
  echo "Run ./setup-kali-link.sh first, or set KALI_USE_TAILSCALE_SSH=1." >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  exec ssh "${SSH_OPTS[@]}" "${KALI_USER}@${KALI_HOST}"
fi

exec ssh "${SSH_OPTS[@]}" "${KALI_USER}@${KALI_HOST}" "$@"
