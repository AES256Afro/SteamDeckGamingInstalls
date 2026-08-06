#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

library_path=""
warning_count=0

usage() {
  cat <<'EOF'
Usage: scripts/doctor.sh [--library PATH]

Runs read-only checks for the OS, Flatpak, Steam, compatibility tools, launchers,
Vulkan visibility, and an optional game-library filesystem.
EOF
}

check_ok() {
  sdgi_ok "$*"
}

check_warn() {
  sdgi_warn "$*"
  warning_count=$((warning_count + 1))
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library)
      [[ $# -ge 2 ]] || sdgi_die "--library requires a path."
      library_path="$2"
      shift
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

for required_command in curl python3 tar sha256sum sha512sum; do
  if command -v "$required_command" >/dev/null 2>&1; then
    check_ok "Found $required_command."
  else
    check_warn "Missing $required_command. Run ./install.sh prerequisites."
  fi
done

if command -v flatpak >/dev/null 2>&1; then
  check_ok "Flatpak is installed."
  if flatpak remotes --columns=name 2>/dev/null | grep -Fxq flathub; then
    check_ok "Flathub is configured."
  else
    check_warn "Flathub is not configured. Run ./install.sh prerequisites."
  fi
else
  check_warn "Flatpak is not installed. Run ./install.sh prerequisites."
fi

steam_mode="$(sdgi_detect_steam_mode)"
if [[ "$steam_mode" == "none" ]]; then
  check_warn "Steam was not detected."
else
  check_ok "Detected $steam_mode Steam."
  compat_dir="$(sdgi_steam_compat_dir "$steam_mode")"
  if [[ -d "$compat_dir" ]]; then
    check_ok "Compatibility tool directory exists: $compat_dir"

    shopt -s nullglob
    ge_tools=("$compat_dir"/GE-Proton*)
    shopt -u nullglob
    if [[ "${#ge_tools[@]}" -gt 0 ]]; then
      ge_names=()
      for ge_tool in "${ge_tools[@]}"; do
        [[ -d "$ge_tool" ]] && ge_names+=("$(basename "$ge_tool")")
      done
      if [[ "${#ge_names[@]}" -gt 0 ]]; then
        check_ok "GE-Proton installed: ${ge_names[*]}"
      else
        check_warn "No GE-Proton release was found. Run ./install.sh proton."
      fi
    else
      check_warn "No GE-Proton release was found. Run ./install.sh proton."
    fi

    xlm_found=0
    while IFS= read -r manifest; do
      if grep -Fq 'XLCore' "$manifest" 2>/dev/null; then
        xlm_found=1
        break
      fi
    done < <(find "$compat_dir" -maxdepth 3 -type f -name compatibilitytool.vdf 2>/dev/null)
    if [[ "$xlm_found" -eq 1 ]]; then
      check_ok "XLM / XLCore Steam compatibility tool is installed."
    else
      check_warn "XLM / XLCore was not found. Run ./install.sh ffxiv --method steam."
    fi
  else
    check_warn "Steam compatibility tool directory does not exist yet: $compat_dir"
  fi
fi

if command -v flatpak >/dev/null 2>&1 && sdgi_flatpak_app_installed net.lutris.Lutris; then
  check_ok "Lutris is installed."
else
  check_warn "Lutris is not installed. Run ./install.sh wow."
fi

if command -v flatpak >/dev/null 2>&1 && sdgi_flatpak_app_installed dev.goats.xivlauncher; then
  check_ok "XIVLauncher Flatpak is installed."
else
  sdgi_info "XIVLauncher Flatpak is not installed. This is expected when using XLM."
fi

if command -v vulkaninfo >/dev/null 2>&1; then
  if vulkaninfo --summary >/dev/null 2>&1; then
    check_ok "Vulkan responds to vulkaninfo."
  else
    check_warn "vulkaninfo is installed, but Vulkan initialization failed. Check your GPU driver and 32-bit Vulkan packages."
  fi
elif [[ -d /usr/share/vulkan/icd.d ]] && find /usr/share/vulkan/icd.d -type f -name '*.json' -print -quit | grep -q .; then
  check_ok "A Vulkan ICD is present. Install vulkan-tools if you want a functional test."
else
  check_warn "Could not confirm a Vulkan driver. Proton games require working Vulkan support."
fi

if [[ -n "$library_path" ]]; then
  if [[ -d "$library_path" ]]; then
    fs_type="$(sdgi_filesystem_type "$library_path")"
    if sdgi_is_ntfs "$fs_type"; then
      check_warn "Library $library_path is on $fs_type. Lutris does not support a Battle.net prefix on NTFS."
    else
      check_ok "Library filesystem: ${fs_type:-unknown} ($library_path)"
    fi
    df -h "$library_path" | tail -n 1
  else
    check_warn "Library path does not exist: $library_path"
  fi
fi

printf '\n'
if [[ "$warning_count" -eq 0 ]]; then
  sdgi_ok "All automated checks passed."
else
  sdgi_warn "$warning_count check(s) need attention."
fi
sdgi_info "These checks verify setup state only. They do not prove that either game completes login or renders correctly."

