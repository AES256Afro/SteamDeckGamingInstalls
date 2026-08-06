# SteamOS and Arch guide

## SteamOS principles

SteamOS has an immutable base system. This project does not run `steamos-readonly
disable`, add an AUR helper, or install game launchers with `pacman`. Flatpak and
per-user Steam compatibility tools survive normal system updates more reliably.

Recommended flow:

```bash
./install.sh --dry-run all
./install.sh all
```

Use Desktop Mode for installation. Return to Gaming Mode only after the scripts
finish and Steam has been restarted.

## Arch-family desktops

On regular Arch, EndeavourOS, or Manjaro, the prerequisite script can install
missing tools and Flatpak with `pacman`. Existing native Steam is preferred. If
Steam is absent, the guided workflow offers the Flathub build instead of editing
`/etc/pacman.conf` to enable multilib automatically.

That choice avoids making a system-wide repository decision on the user's
behalf. Advanced Arch users can install native Steam and UMU from official Arch
repositories before running this project.

## microSD cards and removable drives

Mount the drive in Desktop Mode before launching Lutris. Pass the mounted
directory explicitly:

```bash
./install.sh wow --library /run/media/deck/CARD-NAME/Games
```

The script checks the mounted filesystem and grants the Lutris Flatpak access to
the selected directory. Unmounting or renaming the card later breaks the saved
prefix path until it is mounted at the same location again.

## Steam restart

Adding GE-Proton or XLM does not change a running Steam client's list of tools.
Use one of these paths:

- Steam Deck: **Steam > Power > Switch to Gaming Mode**.
- Desktop Mode: **Steam > Exit**, wait for it to close, and start Steam again.

Closing only the Steam window is not always a full exit.

