#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Steam Deck Gaming Installs

Usage:
  ./install.sh [options] [command] [command options]

Commands:
  menu           Show the guided menu (default)
  all            Prepare Steam, GE-Proton, XIVLauncher, and Lutris/Battle.net
  prerequisites  Install the cross-distro prerequisites
  proton         Install the latest verified GE-Proton release
  ffxiv          Install XIVLauncher using the recommended method
  wow            Install Lutris and start its maintained Battle.net installer
  update         Update installed components without touching game data
  doctor         Run read-only system checks
  help           Show this help

Global options:
  -n, --dry-run  Show planned changes without installing them
  -y, --yes      Accept safe default prompts
  -h, --help     Show this help

Examples:
  ./install.sh
  ./install.sh all
  ./install.sh --dry-run all
  ./install.sh wow --library /run/media/deck/Games
  ./install.sh ffxiv --method steam
EOF
}

run_script() {
  local name="$1"
  shift
  "$ROOT_DIR/scripts/$name" "$@"
}

run_all() {
  sdgi_step "1 of 5: Preparing the operating system and Steam."
  run_script prerequisites.sh --with-steam

  sdgi_step "2 of 5: Installing the latest verified GE-Proton release."
  run_script install-ge-proton.sh

  sdgi_step "3 of 5: Installing XIVLauncher."
  run_script install-ffxiv.sh

  sdgi_step "4 of 5: Installing the World of Warcraft launcher path."
  run_script install-wow.sh

  sdgi_step "5 of 5: Checking the resulting setup."
  run_script doctor.sh
}

show_menu() {
  local choice
  cat <<'EOF'

What would you like to do?

  1) Set up everything
  2) Install or update GE-Proton
  3) Set up World of Warcraft
  4) Set up Final Fantasy XIV with XIVLauncher
  5) Update installed components
  6) Check my setup
  7) Install prerequisites only
  8) Exit
EOF

  read -r -p "Choose 1-8: " choice
  case "$choice" in
    1) run_all ;;
    2) run_script install-ge-proton.sh ;;
    3) run_script install-wow.sh ;;
    4) run_script install-ffxiv.sh ;;
    5) run_script update.sh ;;
    6) run_script doctor.sh ;;
    7) run_script prerequisites.sh ;;
    8) sdgi_info "No changes made." ;;
    *) sdgi_die "Please choose a number from 1 through 8." ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      export SDGI_DRY_RUN=1
      shift
      ;;
    -y|--yes)
      export SDGI_ASSUME_YES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      break
      ;;
    *)
      break
      ;;
  esac
done

command_name="${1:-menu}"
[[ $# -eq 0 ]] || shift

sdgi_start_log "$command_name"

case "$command_name" in
  menu)
    show_menu
    ;;
  all)
    run_all "$@"
    ;;
  prerequisites)
    run_script prerequisites.sh "$@"
    ;;
  proton)
    run_script install-ge-proton.sh "$@"
    ;;
  ffxiv)
    run_script install-ffxiv.sh "$@"
    ;;
  wow)
    run_script install-wow.sh "$@"
    ;;
  update)
    run_script update.sh "$@"
    ;;
  doctor)
    run_script doctor.sh "$@"
    ;;
  help)
    usage
    ;;
  *)
    usage >&2
    sdgi_die "Unknown command: $command_name"
    ;;
esac

