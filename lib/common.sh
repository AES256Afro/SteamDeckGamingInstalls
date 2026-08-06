#!/usr/bin/env bash

# Shared helpers for the Steam Deck Gaming Installs scripts.
# This file is sourced by the entry points in scripts/.

if [[ -n "${SDGI_COMMON_LOADED:-}" ]]; then
  return 0
fi
SDGI_COMMON_LOADED=1

SDGI_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/steam-deck-gaming-installs"
SDGI_PLATFORM=""
SDGI_OS_ID=""
SDGI_OS_LIKE=""
SDGI_OS_NAME=""

sdgi_color_enabled() {
  [[ -t 1 && -z "${NO_COLOR:-}" ]]
}

sdgi_color() {
  local code="$1"
  shift
  if sdgi_color_enabled; then
    printf '\033[%sm%s\033[0m\n' "$code" "$*"
  else
    printf '%s\n' "$*"
  fi
}

sdgi_info() {
  sdgi_color "1;34" "[INFO] $*"
}

sdgi_step() {
  sdgi_color "1;36" "[STEP] $*"
}

sdgi_ok() {
  sdgi_color "1;32" "[ OK ] $*"
}

sdgi_warn() {
  sdgi_color "1;33" "[WARN] $*" >&2
}

sdgi_error() {
  sdgi_color "1;31" "[FAIL] $*" >&2
}

sdgi_die() {
  sdgi_error "$*"
  exit 1
}

sdgi_is_dry_run() {
  [[ "${SDGI_DRY_RUN:-0}" == "1" ]]
}

sdgi_quote_command() {
  printf '  '
  printf '%q ' "$@"
  printf '\n'
}

sdgi_run() {
  if sdgi_is_dry_run; then
    sdgi_info "Dry run, would execute:"
    sdgi_quote_command "$@"
    return 0
  fi
  "$@"
}

sdgi_confirm() {
  local prompt="$1"
  local default_answer="${2:-no}"
  local hint answer

  if [[ "${SDGI_ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi

  if [[ "$default_answer" == "yes" ]]; then
    hint="[Y/n]"
  else
    hint="[y/N]"
  fi

  if [[ ! -t 0 ]]; then
    [[ "$default_answer" == "yes" ]]
    return
  fi

  read -r -p "$prompt $hint " answer
  if [[ -z "$answer" ]]; then
    [[ "$default_answer" == "yes" ]]
    return
  fi
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

sdgi_require_regular_user() {
  if [[ "$(id -u)" -eq 0 ]]; then
    sdgi_die "Run this installer as your normal desktop user, not with sudo. It will request sudo only for an OS package when needed."
  fi
}

sdgi_detect_platform() {
  local os_release_file="${SDGI_OS_RELEASE_FILE:-/etc/os-release}"
  local id="" id_like="" pretty_name=""

  [[ "$(uname -s)" == "Linux" || -n "${SDGI_TESTING:-}" ]] || \
    sdgi_die "This installer supports Linux only."
  [[ -r "$os_release_file" ]] || sdgi_die "Cannot read $os_release_file."

  # shellcheck disable=SC1090
  . "$os_release_file"
  id="${ID:-unknown}"
  id_like="${ID_LIKE:-}"
  pretty_name="${PRETTY_NAME:-$id}"

  SDGI_OS_ID="$(printf '%s' "$id" | tr '[:upper:]' '[:lower:]')"
  SDGI_OS_LIKE=" $(printf '%s' "$id_like" | tr '[:upper:]' '[:lower:]') "
  SDGI_OS_NAME="$pretty_name"

  case "$SDGI_OS_ID" in
    steamos)
      SDGI_PLATFORM="steamos"
      ;;
    ubuntu|debian|linuxmint|pop|neon)
      SDGI_PLATFORM="debian"
      ;;
    arch|endeavouros|manjaro)
      SDGI_PLATFORM="arch"
      ;;
    *)
      if [[ "$SDGI_OS_LIKE" == *" debian "* || "$SDGI_OS_LIKE" == *" ubuntu "* ]]; then
        SDGI_PLATFORM="debian"
      elif [[ "$SDGI_OS_LIKE" == *" arch "* ]]; then
        SDGI_PLATFORM="arch"
      else
        sdgi_die "Unsupported distribution: $SDGI_OS_NAME. Supported families are SteamOS/Arch and Ubuntu/Debian."
      fi
      ;;
  esac
}

sdgi_require_x86_64() {
  local machine
  machine="${SDGI_TEST_ARCH:-$(uname -m)}"
  case "$machine" in
    x86_64|amd64)
      return 0
      ;;
    *)
      sdgi_die "Unsupported CPU architecture: $machine. These game clients and XLM are installed for x86_64 systems."
      ;;
  esac
}

sdgi_initialize() {
  sdgi_require_regular_user
  sdgi_detect_platform
  sdgi_require_x86_64
  sdgi_info "Detected $SDGI_OS_NAME ($SDGI_PLATFORM family, x86_64)."
}

sdgi_start_log() {
  local action="${1:-install}"
  local log_file

  [[ "${SDGI_NO_LOG:-0}" != "1" ]] || return 0
  mkdir -p "$SDGI_STATE_DIR"
  log_file="$SDGI_STATE_DIR/${action}-$(date +%Y%m%d-%H%M%S).log"
  exec > >(tee -a "$log_file") 2>&1
  sdgi_info "Log: $log_file"
}

sdgi_missing_commands() {
  local command_name
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 || printf '%s\n' "$command_name"
  done
}

sdgi_ensure_base_tools() {
  local -a required=(curl python3 tar sha256sum sha512sum)
  local -a missing=()
  local command_name

  while IFS= read -r command_name; do
    [[ -n "$command_name" ]] && missing+=("$command_name")
  done < <(sdgi_missing_commands "${required[@]}")

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  sdgi_warn "Missing required commands: ${missing[*]}"
  case "$SDGI_PLATFORM" in
    debian)
      sdgi_step "Installing base download and verification tools."
      sdgi_run sudo apt-get update
      sdgi_run sudo apt-get install -y curl ca-certificates python3 tar coreutils
      ;;
    arch)
      sdgi_step "Installing base download and verification tools."
      sdgi_run sudo pacman -S --needed --noconfirm curl ca-certificates python tar coreutils
      ;;
    steamos)
      sdgi_die "SteamOS is missing a base command (${missing[*]}). Update or repair SteamOS first. This project does not unlock the read-only system partition."
      ;;
  esac
  if sdgi_is_dry_run; then
    export SDGI_MISSING_BASE_TOOLS=1
  fi
}

sdgi_ensure_flatpak() {
  if command -v flatpak >/dev/null 2>&1; then
    return 0
  fi

  case "$SDGI_PLATFORM" in
    debian)
      sdgi_step "Installing Flatpak from the distribution package manager."
      sdgi_run sudo apt-get update
      sdgi_run sudo apt-get install -y flatpak ca-certificates
      ;;
    arch)
      sdgi_step "Installing Flatpak from the distribution package manager."
      sdgi_run sudo pacman -S --needed --noconfirm flatpak ca-certificates
      ;;
    steamos)
      sdgi_die "Flatpak should be included with SteamOS, but it was not found. Update or repair SteamOS before continuing."
      ;;
  esac
}

sdgi_ensure_flathub() {
  if flatpak remotes --user --columns=name 2>/dev/null | grep -Fxq flathub; then
    return 0
  fi
  sdgi_step "Adding Flathub for this user."
  sdgi_run flatpak remote-add --user --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
}

sdgi_flatpak_app_installed() {
  local app_id="$1"
  flatpak info --user "$app_id" >/dev/null 2>&1 || flatpak info "$app_id" >/dev/null 2>&1
}

sdgi_ensure_flatpak_app() {
  local app_id="$1"
  local label="$2"
  if sdgi_flatpak_app_installed "$app_id"; then
    sdgi_ok "$label is already installed."
    return 0
  fi
  sdgi_step "Installing $label from Flathub."
  sdgi_run flatpak install --user -y flathub "$app_id"
}

sdgi_detect_steam_mode() {
  if [[ -n "${SDGI_STEAM_MODE:-}" ]]; then
    case "$SDGI_STEAM_MODE" in
      native|flatpak|none)
        printf '%s\n' "$SDGI_STEAM_MODE"
        return 0
        ;;
      *)
        sdgi_die "SDGI_STEAM_MODE must be native, flatpak, or none."
        ;;
    esac
  fi

  if [[ "$SDGI_PLATFORM" == "steamos" ]]; then
    printf 'native\n'
  elif command -v steam >/dev/null 2>&1 || [[ -d "$HOME/.steam/root" || -d "$HOME/.local/share/Steam" ]]; then
    printf 'native\n'
  elif command -v flatpak >/dev/null 2>&1 && sdgi_flatpak_app_installed com.valvesoftware.Steam; then
    printf 'flatpak\n'
  else
    printf 'none\n'
  fi
}

sdgi_steam_compat_dir() {
  local mode="${1:-$(sdgi_detect_steam_mode)}"
  case "$mode" in
    native)
      printf '%s\n' "$HOME/.steam/root/compatibilitytools.d"
      ;;
    flatpak)
      printf '%s\n' "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d"
      ;;
    *)
      return 1
      ;;
  esac
}

sdgi_ensure_steam() {
  local mode
  mode="$(sdgi_detect_steam_mode)"
  if [[ "$mode" != "none" ]]; then
    sdgi_ok "Detected $mode Steam."
    return 0
  fi

  sdgi_warn "Steam was not detected."
  if ! sdgi_confirm "Install Steam from Flathub now?" yes; then
    sdgi_die "Steam is required for the compatibility-tool installation. Install Steam, launch it once, then rerun this command."
  fi
  sdgi_ensure_flatpak
  sdgi_ensure_flathub
  sdgi_ensure_flatpak_app com.valvesoftware.Steam "Steam"
  export SDGI_STEAM_MODE=flatpak
}

sdgi_download() {
  local url="$1"
  local output="$2"
  local -a curl_args=(
    --fail --location --show-error --silent
    --retry 3 --retry-all-errors --connect-timeout 15
    --proto '=https' --tlsv1.2
  )

  if [[ -n "${GITHUB_TOKEN:-}" && "$url" == https://api.github.com/* ]]; then
    curl_args+=(--header "Authorization: Bearer $GITHUB_TOKEN")
  fi
  curl "${curl_args[@]}" --output "$output" "$url"
}

sdgi_fetch_latest_release_json() {
  local repository="$1"
  local output="$2"
  sdgi_download "https://api.github.com/repos/$repository/releases/latest" "$output"
}

sdgi_release_tag_from_json() {
  local json_file="$1"
  python3 - "$json_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
tag = data.get("tag_name")
if not tag:
    raise SystemExit("Latest release response did not contain tag_name")
print(tag)
PY
}

sdgi_release_asset_from_json() {
  local json_file="$1"
  local asset_pattern="$2"
  python3 - "$json_file" "$asset_pattern" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
pattern = re.compile(sys.argv[2])
matches = [asset for asset in data.get("assets", []) if pattern.fullmatch(asset.get("name", ""))]
if len(matches) != 1:
    names = ", ".join(asset.get("name", "") for asset in data.get("assets", []))
    raise SystemExit(f"Expected one release asset matching {pattern.pattern!r}, found {len(matches)}. Assets: {names}")
asset = matches[0]
print("\t".join((
    asset["name"],
    asset["browser_download_url"],
    asset.get("digest") or "-",
)))
PY
}

sdgi_verify_digest() {
  local file="$1"
  local digest="$2"
  local algorithm expected actual

  [[ "$digest" != "-" && -n "$digest" ]] || \
    sdgi_die "The publisher did not provide a digest for $(basename "$file"). Refusing an unverified executable download."

  algorithm="${digest%%:*}"
  expected="${digest#*:}"
  case "$algorithm" in
    sha256)
      actual="$(sha256sum "$file" | awk '{print $1}')"
      ;;
    sha512)
      actual="$(sha512sum "$file" | awk '{print $1}')"
      ;;
    *)
      sdgi_die "Unsupported digest algorithm: $algorithm"
      ;;
  esac

  [[ "$actual" == "$expected" ]] || sdgi_die "Digest verification failed for $(basename "$file")."
  sdgi_ok "Verified $(basename "$file") with $algorithm."
}

sdgi_safe_tar_root() {
  local archive="$1"
  python3 - "$archive" <<'PY'
import posixpath
import sys
import tarfile


def fail(message):
    raise SystemExit(message)


roots = set()
with tarfile.open(sys.argv[1], mode="r:gz") as archive:
    for member in archive:
        name = member.name
        normalized = posixpath.normpath(name)
        if name.startswith("/") or normalized == ".." or normalized.startswith("../"):
            fail(f"Archive contains an unsafe path: {name}")
        if normalized in ("", "."):
            continue

        root = normalized.split("/", 1)[0]
        roots.add(root)

        if member.isdev() or member.isfifo():
            fail(f"Archive contains an unsupported special file: {name}")

        if member.issym() or member.islnk():
            target = member.linkname
            if target.startswith("/"):
                fail(f"Archive link has an absolute target: {name} -> {target}")
            if member.issym():
                resolved = posixpath.normpath(posixpath.join(posixpath.dirname(normalized), target))
            else:
                resolved = posixpath.normpath(target)
            if resolved == ".." or resolved.startswith("../") or resolved.split("/", 1)[0] != root:
                fail(f"Archive link escapes its top-level directory: {name} -> {target}")

if len(roots) != 1:
    if roots:
        fail("Archive contains more than one top-level path.")
    fail("Archive is empty.")
print(next(iter(roots)))
PY
}

sdgi_filesystem_type() {
  local path="$1"
  if command -v findmnt >/dev/null 2>&1; then
    findmnt -n -o FSTYPE --target "$path" 2>/dev/null || true
  else
    stat -f -c '%T' "$path" 2>/dev/null || true
  fi
}

sdgi_available_gib() {
  local path="$1"
  df -Pk "$path" 2>/dev/null | awk 'NR == 2 { printf "%.1f", $4 / 1048576 }'
}

sdgi_is_ntfs() {
  local fs_type
  fs_type="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$fs_type" == "ntfs" || "$fs_type" == "ntfs3" || "$fs_type" == "fuseblk" ]]
}

sdgi_grant_flatpak_path() {
  local app_id="$1"
  local path="$2"
  case "$path" in
    "$HOME"|"$HOME"/*)
      return 0
      ;;
  esac
  sdgi_step "Granting $app_id access to $path."
  sdgi_run flatpak override --user --filesystem="$path" "$app_id"
}

sdgi_launch_detached() {
  if sdgi_is_dry_run; then
    sdgi_info "Dry run, would launch:"
    sdgi_quote_command "$@"
    return 0
  fi
  "$@" >/dev/null 2>&1 &
  disown || true
}

sdgi_show_steam_restart_note() {
  sdgi_warn "Steam must be fully restarted before it will show a newly installed compatibility tool."
  sdgi_info "Steam Deck: Steam button > Power > Switch to Gaming Mode, or restart Steam from Desktop Mode."
  sdgi_info "Desktop Linux: Steam menu > Exit, then start Steam again."
}
