#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

with_steam=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-steam)
      with_steam=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/prerequisites.sh [--with-steam]

Installs only the small OS-level tools required by this project, then enables
Flathub for the current user. On SteamOS it does not unlock or modify the
read-only system partition.
EOF
      exit 0
      ;;
    *)
      sdgi_die "Unknown option: $1"
      ;;
  esac
  shift
done

sdgi_initialize
sdgi_ensure_base_tools
sdgi_ensure_flatpak
sdgi_ensure_flathub

if [[ "$with_steam" -eq 1 ]]; then
  sdgi_ensure_steam
  steam_mode="$(sdgi_detect_steam_mode)"
  sdgi_ok "Steam mode: $steam_mode"
fi

sdgi_ok "Prerequisites are ready."
