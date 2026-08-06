#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

library_path="$HOME/Games"
launch_after=1
allow_unsupported_fs=0

usage() {
  cat <<'EOF'
Usage: scripts/install-wow.sh [options]

Options:
  --library PATH                 Parent directory for the Battle.net prefix
  --no-launch                    Install Lutris but do not start Battle.net setup
  --allow-unsupported-filesystem Continue even if the target is on NTFS
  -h, --help                     Show this help

This uses the maintained Lutris Battle.net installer. World of Warcraft is
selected and downloaded inside Battle.net after the Lutris installer finishes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library)
      [[ $# -ge 2 ]] || sdgi_die "--library requires a path."
      library_path="$2"
      shift
      ;;
    --no-launch)
      launch_after=0
      ;;
    --allow-unsupported-filesystem)
      allow_unsupported_fs=1
      ;;
    -h|--help)
      usage
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
sdgi_ensure_flatpak_app net.lutris.Lutris "Lutris"

if sdgi_is_dry_run; then
  resolved_library="$library_path"
else
  mkdir -p "$library_path"
  resolved_library="$(cd "$library_path" && pwd -P)"
fi

fs_type="$(sdgi_filesystem_type "${resolved_library:-$library_path}")"
if [[ -n "$fs_type" ]]; then
  sdgi_info "Game library filesystem: $fs_type"
fi
if [[ -d "$resolved_library" ]]; then
  available_gib="$(sdgi_available_gib "$resolved_library")"
  if [[ -n "$available_gib" ]]; then
    sdgi_info "Space currently available at the game library: $available_gib GiB"
  fi
fi
if sdgi_is_ntfs "$fs_type"; then
  if [[ "$allow_unsupported_fs" -ne 1 ]]; then
    sdgi_die "Lutris documents that Battle.net does not work correctly on NTFS. Choose an ext4 or Btrfs location, or pass --allow-unsupported-filesystem at your own risk."
  fi
  sdgi_warn "Continuing with an NTFS Battle.net prefix by explicit request. This is unsupported by Lutris."
fi

sdgi_grant_flatpak_path net.lutris.Lutris "$resolved_library"

cat <<EOF

Lutris will guide the Windows launcher installation.

Use this destination when it asks where to install:
  $resolved_library/Battle.net

Important installer sequence:
  1. Let Lutris create its separate Battle.net prefix and download the installer.
  2. When the first Battle.net login window appears during installation, do not
     sign in yet. Close that window so the Lutris installer can finish.
  3. After Lutris reports success, launch Battle.net from the Lutris library.
  4. Sign in, select World of Warcraft, choose Retail or Classic, and install it.
  5. In Lutris, open Battle.net > Configure > Runner options. If available,
     select "GE-Proton (Latest)" to use Lutris's UMU integration.

Do not put the Battle.net prefix on NTFS. For a microSD card formatted by the
Steam Deck, choose a directory under /run/media/deck/ and pass it with --library.
EOF

if [[ "$launch_after" -eq 1 ]] && sdgi_confirm "Start the maintained Lutris Battle.net installer now?" yes; then
  sdgi_step "Launching Lutris. Keep this terminal open for the checklist above."
  sdgi_launch_detached flatpak run net.lutris.Lutris lutris:battlenet-standard
else
  sdgi_info "Start it later with: flatpak run net.lutris.Lutris lutris:battlenet-standard"
fi

sdgi_ok "Lutris is ready. Battle.net and WoW finish through the graphical installer."
