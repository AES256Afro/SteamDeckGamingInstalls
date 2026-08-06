#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass_count=0

pass() {
  printf 'ok %d - %s\n' "$((pass_count + 1))" "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'not ok %d - %s\n' "$((pass_count + 1))" "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  [[ "$expected" == "$actual" ]] || fail "$label: expected '$expected', got '$actual'"
  pass "$label"
}

printf 'TAP version 13\n'

while IFS= read -r shell_file; do
  bash -n "$shell_file" || fail "bash syntax: $shell_file"
done < <(find "$ROOT_DIR" -type f -name '*.sh' -not -path '*/.git/*' | sort)
pass "all shell files pass bash -n"

if LC_ALL=C grep -r $'\xE2\x80\x94' \
  --exclude-dir=.git --exclude-dir=.github "$ROOT_DIR" >/dev/null 2>&1; then
  fail "repository must not contain Unicode U+2014"
fi
pass "repository does not contain Unicode U+2014"

platform_result="$(
  export SDGI_TESTING=1
  export SDGI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/os-release.ubuntu"
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_detect_platform
  printf '%s' "$SDGI_PLATFORM"
)"
assert_eq "debian" "$platform_result" "Ubuntu maps to Debian family"

platform_result="$(
  export SDGI_TESTING=1
  export SDGI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/os-release.steamos"
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_detect_platform
  printf '%s' "$SDGI_PLATFORM"
)"
assert_eq "steamos" "$platform_result" "SteamOS is detected directly"

platform_result="$(
  export SDGI_TESTING=1
  export SDGI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/os-release.archlike"
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_detect_platform
  printf '%s' "$SDGI_PLATFORM"
)"
assert_eq "arch" "$platform_result" "Arch derivative maps to Arch family"

compat_result="$(
  export HOME=/tmp/sdgi-test-home
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_steam_compat_dir native
)"
assert_eq "/tmp/sdgi-test-home/.steam/root/compatibilitytools.d" "$compat_result" "native Steam compatibility path"

compat_result="$(
  export HOME=/tmp/sdgi-test-home
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_steam_compat_dir flatpak
)"
assert_eq "/tmp/sdgi-test-home/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d" "$compat_result" "Flatpak Steam compatibility path"

tag_result="$(
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_release_tag_from_json "$ROOT_DIR/tests/fixtures/release.json"
)"
assert_eq "GE-Proton99-1" "$tag_result" "release tag parser"

asset_result="$(
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_release_asset_from_json "$ROOT_DIR/tests/fixtures/release.json" 'GE-Proton99-1\.tar\.gz'
)"
assert_eq $'GE-Proton99-1.tar.gz\thttps://example.invalid/GE-Proton99-1.tar.gz\tsha256:abc123' "$asset_result" "release asset parser"

dry_run_result="$(
  export SDGI_DRY_RUN=1
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_run false
  printf 'survived'
)"
[[ "$dry_run_result" == *survived ]] || fail "dry-run suppresses command execution"
pass "dry-run suppresses command execution"

ntfs_result="$(
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  if sdgi_is_ntfs ntfs3; then printf yes; else printf no; fi
)"
assert_eq "yes" "$ntfs_result" "NTFS detector recognizes ntfs3"

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/input/GE-Proton99-1"
touch "$tmp_dir/input/GE-Proton99-1/compatibilitytool.vdf"
COPYFILE_DISABLE=1 tar -czf "$tmp_dir/safe.tar.gz" -C "$tmp_dir/input" GE-Proton99-1
tar_root="$(
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_safe_tar_root "$tmp_dir/safe.tar.gz"
)"
assert_eq "GE-Proton99-1" "$tar_root" "safe archive root parser"

mkdir -p "$tmp_dir/unsafe/GE-Proton99-1/nested"
ln -s ../../../outside "$tmp_dir/unsafe/GE-Proton99-1/nested/escape"
COPYFILE_DISABLE=1 tar -czf "$tmp_dir/unsafe.tar.gz" -C "$tmp_dir/unsafe" GE-Proton99-1
if (
  # shellcheck source=lib/common.sh
  . "$ROOT_DIR/lib/common.sh"
  sdgi_safe_tar_root "$tmp_dir/unsafe.tar.gz"
) >/dev/null 2>&1; then
  fail "unsafe archive links are rejected"
fi
pass "unsafe archive links are rejected"

printf '1..%d\n' "$pass_count"
