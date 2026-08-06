#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

requested_mode="auto"

usage() {
  cat <<'EOF'
Usage: scripts/install-ge-proton.sh [--steam-mode auto|native|flatpak]

Resolves the current GloriousEggroll/proton-ge-custom release at runtime,
verifies both GitHub's asset digest and the publisher's SHA-512 checksum, and
installs it into Steam's per-user compatibilitytools.d directory.

Valve Proton stable and Proton Experimental remain managed by Steam itself.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --steam-mode)
      [[ $# -ge 2 ]] || sdgi_die "--steam-mode requires a value."
      requested_mode="$2"
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

case "$requested_mode" in
  auto|native|flatpak) ;;
  *) sdgi_die "--steam-mode must be auto, native, or flatpak." ;;
esac

sdgi_initialize
sdgi_ensure_base_tools

if [[ "$requested_mode" == "auto" ]]; then
  sdgi_ensure_steam
  steam_mode="$(sdgi_detect_steam_mode)"
else
  steam_mode="$requested_mode"
  if [[ "$steam_mode" == "flatpak" ]]; then
    sdgi_ensure_flatpak
    sdgi_ensure_flathub
    sdgi_ensure_flatpak_app com.valvesoftware.Steam "Steam"
  fi
fi

compat_dir="$(sdgi_steam_compat_dir "$steam_mode")"
if [[ "${SDGI_MISSING_BASE_TOOLS:-0}" == "1" ]]; then
  sdgi_info "Dry run: after installing the missing tools, the script would resolve, verify, and install the current GE-Proton release in $compat_dir."
  exit 0
fi
work_dir="$(mktemp -d)"
staging_dir=""
cleanup() {
  [[ -z "$staging_dir" || ! -d "$staging_dir" ]] || rm -rf -- "$staging_dir"
  rm -rf -- "$work_dir"
}
trap cleanup EXIT

release_json="$work_dir/release.json"
sdgi_step "Checking the latest official GE-Proton release."
sdgi_fetch_latest_release_json GloriousEggroll/proton-ge-custom "$release_json"
release_tag="$(sdgi_release_tag_from_json "$release_json")"

[[ "$release_tag" =~ ^GE-Proton[0-9A-Za-z._-]+$ ]] || \
  sdgi_die "Unexpected GE-Proton release tag: $release_tag"

escaped_tag="${release_tag//./\\.}"
IFS=$'\t' read -r archive_name archive_url archive_digest < <(
  sdgi_release_asset_from_json "$release_json" "${escaped_tag}\\.tar\\.gz"
)
IFS=$'\t' read -r checksum_name checksum_url checksum_digest < <(
  sdgi_release_asset_from_json "$release_json" "${escaped_tag}\\.sha512sum"
)

destination="$compat_dir/$release_tag"
if [[ -d "$destination" ]]; then
  sdgi_ok "$release_tag is already installed in $compat_dir."
  sdgi_show_steam_restart_note
  exit 0
fi

sdgi_info "Latest release: $release_tag"
sdgi_info "Install target: $destination"
if sdgi_is_dry_run; then
  sdgi_info "Dry run, would download, verify, and install $release_tag."
  exit 0
fi

archive_path="$work_dir/$archive_name"
checksum_path="$work_dir/$checksum_name"

sdgi_step "Downloading $archive_name. This is a large file and may take a while."
sdgi_download "$archive_url" "$archive_path"
sdgi_download "$checksum_url" "$checksum_path"
sdgi_verify_digest "$archive_path" "$archive_digest"
sdgi_verify_digest "$checksum_path" "$checksum_digest"

sdgi_step "Checking the publisher's SHA-512 checksum."
(
  cd "$work_dir"
  sha512sum -c "$checksum_name"
)
sdgi_ok "Publisher checksum passed."

archive_root="$(sdgi_safe_tar_root "$archive_path")"
[[ "$archive_root" == "$release_tag" ]] || \
  sdgi_die "Archive root '$archive_root' did not match release '$release_tag'."

mkdir -p "$compat_dir"
staging_dir="$(mktemp -d "$compat_dir/.sdgi-ge.XXXXXX")"
sdgi_step "Extracting $release_tag."
tar -xzf "$archive_path" -C "$staging_dir"
[[ -f "$staging_dir/$release_tag/compatibilitytool.vdf" ]] || \
  sdgi_die "The extracted release does not contain compatibilitytool.vdf."
mv "$staging_dir/$release_tag" "$destination"
rmdir "$staging_dir"
staging_dir=""

sdgi_ok "Installed $release_tag."
sdgi_show_steam_restart_note
sdgi_info "Use Steam's game-specific default first. Select $release_tag only when a game or guide needs GE-Proton."
