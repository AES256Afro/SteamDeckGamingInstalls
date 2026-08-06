#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

method="auto"
steam_mode="auto"
launch_after=1

usage() {
  cat <<'EOF'
Usage: scripts/install-ffxiv.sh [options]

Options:
  --method auto|steam|flatpak  Choose XLM Steam tool or XIVLauncher Flatpak
  --steam-mode auto|native|flatpak
  --no-launch                 Do not launch the Flatpak after installation
  -h, --help                  Show this help

The Steam method installs XLM, the XIVLauncher method recommended by the
XIVLauncher project for Steam Deck, Big Picture, and Steam-owned FFXIV.
The Flatpak method is intended for desktop Linux with a non-Steam license.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --method)
      [[ $# -ge 2 ]] || sdgi_die "--method requires a value."
      method="$2"
      shift
      ;;
    --steam-mode)
      [[ $# -ge 2 ]] || sdgi_die "--steam-mode requires a value."
      steam_mode="$2"
      shift
      ;;
    --no-launch)
      launch_after=0
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

case "$method" in auto|steam|flatpak) ;; *) sdgi_die "Invalid --method: $method" ;; esac
case "$steam_mode" in auto|native|flatpak) ;; *) sdgi_die "Invalid --steam-mode: $steam_mode" ;; esac

sdgi_initialize
sdgi_ensure_base_tools

if [[ "${SDGI_MISSING_BASE_TOOLS:-0}" == "1" ]]; then
  sdgi_info "Dry run: after installing the missing tools, the script would resolve and verify the current XIVLauncher component."
  exit 0
fi

if [[ "$method" == "auto" ]]; then
  if [[ "$SDGI_PLATFORM" == "steamos" ]]; then
    method="steam"
  elif [[ "$(sdgi_detect_steam_mode)" == "none" ]]; then
    method="flatpak"
  elif [[ "${SDGI_ASSUME_YES:-0}" == "1" || ! -t 0 ]]; then
    method="steam"
  else
    cat <<'EOF'

Choose the XIVLauncher installation style:

  1) XLM Steam compatibility tool
     Recommended for Steam Deck, Big Picture, and Steam-owned FFXIV.

  2) XIVLauncher Flatpak
     Recommended for desktop Linux when your FFXIV license is not on Steam.
EOF
    read -r -p "Choose 1 or 2 [1]: " method_choice
    case "${method_choice:-1}" in
      1) method="steam" ;;
      2) method="flatpak" ;;
      *) sdgi_die "Please choose 1 or 2." ;;
    esac
  fi
fi

if [[ "$method" == "flatpak" ]]; then
  sdgi_ensure_flatpak
  sdgi_ensure_flathub
  sdgi_ensure_flatpak_app dev.goats.xivlauncher "XIVLauncher"
  sdgi_ok "XIVLauncher Flatpak is installed."
  if [[ "$launch_after" -eq 1 ]] && sdgi_confirm "Launch XIVLauncher now?" yes; then
    sdgi_launch_detached flatpak run dev.goats.xivlauncher
  fi
  cat <<'EOF'

Next steps:
  1. Sign in with the Square Enix account that owns your license.
  2. Let XIVLauncher download or locate the FFXIV game files.
  3. On Steam Deck, the XLM method is preferred for Gaming Mode integration.
EOF
  exit 0
fi

if [[ "$steam_mode" == "auto" ]]; then
  sdgi_ensure_steam
  steam_mode="$(sdgi_detect_steam_mode)"
elif [[ "$steam_mode" == "flatpak" ]]; then
  sdgi_ensure_flatpak
  sdgi_ensure_flathub
  sdgi_ensure_flatpak_app com.valvesoftware.Steam "Steam"
fi

compat_dir="$(sdgi_steam_compat_dir "$steam_mode")"
work_dir="$(mktemp -d)"
trap 'rm -rf -- "$work_dir"' EXIT
release_json="$work_dir/release.json"

sdgi_step "Checking the latest XLM release."
sdgi_fetch_latest_release_json Blooym/xlm "$release_json"
release_tag="$(sdgi_release_tag_from_json "$release_json")"
IFS=$'\t' read -r asset_name asset_url asset_digest < <(
  sdgi_release_asset_from_json "$release_json" 'xlm-x86_64-unknown-linux-gnu'
)

sdgi_info "Latest XLM release: $release_tag"
sdgi_info "Steam mode: $steam_mode"
sdgi_info "Compatibility tool directory: $compat_dir"
if sdgi_is_dry_run; then
  sdgi_info "Dry run, would download, verify, and install XLM."
  exit 0
fi

binary_path="$work_dir/$asset_name"
sdgi_download "$asset_url" "$binary_path"
sdgi_verify_digest "$binary_path" "$asset_digest"
chmod 0755 "$binary_path"
mkdir -p "$compat_dir"

extra_args="--run-as-steam-compat-tool=true"
if [[ "$SDGI_PLATFORM" == "steamos" || "$steam_mode" == "flatpak" ]]; then
  extra_args="$extra_args --use-fallback-secret-provider"
fi

sdgi_step "Installing XLM as a Steam compatibility tool."
"$binary_path" install-steam-tool \
  --xlm-updater-disable \
  --extra-launch-args="$extra_args" \
  --steam-compat-path "$compat_dir/"

sdgi_ok "Installed XLM $release_tag."
sdgi_show_steam_restart_note
cat <<'EOF'

Finish in Steam:
  1. Open FINAL FANTASY XIV Online, or FINAL FANTASY XIV Online Free Trial.
  2. Open Properties > Compatibility.
  3. Enable "Force the use of a specific Steam Play compatibility tool."
  4. Select "XLCore [XLM]".
  5. Make sure the Launch Options box is empty, then press Play.
  6. XIVLauncher will install or update itself and guide you through game setup.

Your Steam and Square Enix license types still need to match the account rules
shown by XIVLauncher. This script does not change licenses or account regions.
EOF
