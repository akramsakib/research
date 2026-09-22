#!/usr/bin/env bash
set -euo pipefail

# Remove this Arena node from the tailnet and stop Tailscale.
# Also prints the SSH public key path so you can remove it from Kali authorized_keys.

if command -v tailscale >/dev/null 2>&1; then
  sudo tailscale logout || true
  sudo systemctl stop tailscaled >/dev/null 2>&1 || true
fi

KEY="${STRIX_KALI_KEY:-$HOME/.ssh/strix_kali_ed25519}"
cat <<MSG
Tailscale logout requested.

If you added this public key to Kali, remove it when finished:
  $KEY.pub

To delete the local key from this workspace:
  rm -f '$KEY' '$KEY.pub'
MSG
