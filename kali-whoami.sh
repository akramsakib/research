#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck disable=SC1091
source ./kali.env 2>/dev/null || true
./kali-ssh.sh 'printf "connected user="; whoami; printf " host="; hostname; printf " cwd="; pwd; printf "\n"; uname -a'
