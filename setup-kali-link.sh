#!/usr/bin/env bash
set -euo pipefail

# Prepare this Arena workspace to reach a user-owned Kali host over Tailscale + SSH.
# Secrets are read from environment variables and are not written to disk.
#
# Optional env vars:
#   TAILSCALE_AUTHKEY  one-time/ephemeral Tailscale auth key, used only for `tailscale up`
#   TAILSCALE_HOSTNAME hostname to register for this Arena node
#   KALI_HOST          Kali Tailscale hostname or 100.x.y.z address
#   KALI_USER          dedicated Kali SSH username
#   KALI_PORT          SSH port, default 22
#   STRIX_KALI_KEY     SSH private key path, default ~/.ssh/strix_kali_ed25519

KEY="${STRIX_KALI_KEY:-$HOME/.ssh/strix_kali_ed25519}"
PUB="$KEY.pub"
KALI_PORT="${KALI_PORT:-22}"
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-arena-strix-$(hostname | tr -cd '[:alnum:]-' | cut -c1-32)}"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

start_tailscaled() {
  need tailscale
  if tailscale status >/dev/null 2>&1; then
    return 0
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl start tailscaled >/dev/null 2>&1 || true
  fi

  if ! tailscale status >/dev/null 2>&1; then
    # Fallback for environments where systemd does not start services.
    if ! pgrep -x tailscaled >/dev/null 2>&1; then
      sudo tailscaled --state=/var/lib/tailscale/tailscaled.state >/tmp/tailscaled.log 2>&1 &
      sleep 2
    fi
  fi
}

ensure_key() {
  mkdir -p "$(dirname "$KEY")"
  chmod 700 "$(dirname "$KEY")"
  if [[ ! -f "$KEY" ]]; then
    ssh-keygen -t ed25519 -N '' -f "$KEY" -C "arena-strix-kali-$(date -u +%Y%m%dT%H%M%SZ)" >/dev/null
  fi
  chmod 600 "$KEY"
  chmod 644 "$PUB"
}

join_tailnet_if_needed() {
  local status
  status="$(tailscale status 2>&1 || true)"
  if grep -qi 'Logged out' <<<"$status"; then
    if [[ -z "${TAILSCALE_AUTHKEY:-}" ]]; then
      cat <<MSG
Tailscale is installed and running, but this Arena node is not logged in.
Set a one-time/ephemeral Tailscale auth key and rerun, for example:

  export TAILSCALE_AUTHKEY='YOUR_TAILSCALE_AUTH_KEY'
  ./setup-kali-link.sh

The key is passed directly to tailscale and is not saved by this script.
MSG
      return 0
    fi

    sudo tailscale up \
      --auth-key="$TAILSCALE_AUTHKEY" \
      --hostname="$TAILSCALE_HOSTNAME" \
      --accept-routes=false \
      --accept-dns=true >/dev/null
  fi
}

test_ssh_if_configured() {
  if [[ -z "${KALI_HOST:-}" || -z "${KALI_USER:-}" ]]; then
    cat <<MSG

SSH key is ready. Add this public key to the dedicated Kali account's authorized_keys:

$(cat "$PUB")

Then set the target and test:

  export KALI_HOST='kali-tailnet-host-or-100.x.y.z'
  export KALI_USER='strix'
  export KALI_PORT='22'   # optional
  ./setup-kali-link.sh
MSG
    return 0
  fi

  need ssh
  echo "Testing SSH connection to ${KALI_USER}@${KALI_HOST}:${KALI_PORT} ..."
  ssh \
    -i "$KEY" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=12 \
    -p "$KALI_PORT" \
    "${KALI_USER}@${KALI_HOST}" \
    "printf 'connected as '; whoami; printf 'host: '; hostname; uname -a; printf 'tools: '; command -v bash python3 curl ssh 2>/dev/null | tr '\n' ' '; printf '\n'"
}

main() {
  start_tailscaled
  join_tailnet_if_needed
  ensure_key

  echo "Tailscale status:"
  tailscale status 2>&1 | sed -n '1,12p' || true

  test_ssh_if_configured
}

main "$@"
