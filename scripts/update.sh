#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

skip_xlm=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-xlm)
      skip_xlm=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/update.sh [--skip-xlm]

Updates installed project Flatpaks, installs the latest GE-Proton release, and
refreshes XLM when it is already present. Game data and Wine prefixes are not
deleted or migrated.
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

if command -v flatpak >/dev/null 2>&1; then
  user_apps=()
  system_apps=()
  for app_id in com.valvesoftware.Steam net.lutris.Lutris dev.goats.xivlauncher; do
    if flatpak info --user "$app_id" >/dev/null 2>&1; then
      user_apps+=("$app_id")
    elif flatpak info --system "$app_id" >/dev/null 2>&1; then
      system_apps+=("$app_id")
    fi
  done
  if [[ "${#user_apps[@]}" -gt 0 ]]; then
    sdgi_step "Updating user-installed gaming Flatpaks."
    sdgi_run flatpak update --user -y "${user_apps[@]}"
  fi
  if [[ "${#system_apps[@]}" -gt 0 ]]; then
    sdgi_warn "System-installed Flatpaks are managed by the system administrator and were not changed: ${system_apps[*]}"
  fi
fi

steam_mode="$(sdgi_detect_steam_mode)"
if [[ "$steam_mode" != "none" ]]; then
  "$ROOT_DIR/scripts/install-ge-proton.sh" --steam-mode "$steam_mode"

  if [[ "$skip_xlm" -eq 0 ]]; then
    compat_dir="$(sdgi_steam_compat_dir "$steam_mode")"
    xlm_found=0
    if [[ -d "$compat_dir" ]]; then
      while IFS= read -r manifest; do
        if grep -Fq 'XLCore' "$manifest" 2>/dev/null; then
          xlm_found=1
          break
        fi
      done < <(find "$compat_dir" -maxdepth 3 -type f -name compatibilitytool.vdf 2>/dev/null)
    fi
    if [[ "$xlm_found" -eq 1 ]]; then
      sdgi_step "Refreshing the installed XLM compatibility tool."
      "$ROOT_DIR/scripts/install-ffxiv.sh" --method steam --steam-mode "$steam_mode" --no-launch
    else
      sdgi_info "XLM is not installed, so its refresh was skipped."
    fi
  fi
else
  sdgi_warn "Steam was not detected, so GE-Proton and XLM updates were skipped."
fi

sdgi_ok "Update pass complete."
sdgi_show_steam_restart_note
