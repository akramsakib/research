#!/usr/bin/env bash
set -euo pipefail

# Starts tailscaled in userspace-networking mode for this Arena environment.
# Arena's default route is link-local, so we add a harmless /32 address to make
# Tailscale's network monitor consider IPv4 available. The default route source
# remains the original 169.254 address.

if ! command -v tailscaled >/dev/null 2>&1 || ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale/tailscaled is not installed. Run ./setup-kali-link.sh first." >&2
  exit 1
fi

sudo ip addr add 10.254.254.254/32 dev eth0 2>/dev/null || true
if ip -4 route show default | grep -q 'via 169\.254\.0\.22'; then
  sudo ip route replace default via 169.254.0.22 dev eth0 src 169.254.0.21 2>/dev/null || true
fi

sudo systemctl stop tailscaled >/dev/null 2>&1 || true
sudo pkill -x tailscaled >/dev/null 2>&1 || true
sudo rm -f /run/tailscale/tailscaled.sock

exec sudo tailscaled \
  --tun=userspace-networking \
  --state=/var/lib/tailscale/tailscaled.state \
  --socket=/run/tailscale/tailscaled.sock \
  --socks5-server=localhost:1055
