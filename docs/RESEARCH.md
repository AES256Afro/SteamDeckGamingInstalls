# Research and upstream choices

Research snapshot: August 6, 2026. Release versions are intentionally not
hardcoded in the installer. Each run resolves the current upstream release.

## Projects used directly

### XIVLauncher, XIVLauncher.Core, and XLM

The [official XIVLauncher Linux guide](https://goatcorp.github.io/faq/steamdeck)
routes Steam Deck, Big Picture, and Steam-owned FFXIV users to XLM as a Steam
compatibility tool. It routes desktop Linux users without a Steam license to the
Flatpak or a system package.

[XLM](https://github.com/Blooym/xlm) provides different upstream installer paths
for Steam Deck, native Steam, and Flatpak Steam. This project incorporates those
paths and launch arguments, but downloads the release asset to a temporary file
and verifies GitHub's published asset digest before executing it. That is safer
and more auditable than piping a changing URL directly to a shell.

### GE-Proton

[GE-Proton](https://github.com/GloriousEggroll/proton-ge-custom) documents the
native and Flatpak `compatibilitytools.d` locations and publishes a SHA-512 file
beside each x86_64 archive. This project verifies both the GitHub asset digest
and that publisher checksum before extracting the archive.

GE-Proton also documents that Lutris uses UMU when `GE-Proton (Latest)` is
selected. The guide preserves that exact UI path instead of pretending the
Steam compatibility-tool copy automatically controls Lutris.

### Lutris Battle.net installer

[Lutris's Battle.net page](https://lutris.net/games/battlenet/) publishes the
current `battlenet-standard` installer. Its script downloads Battle.net from
Blizzard, creates a dedicated 64-bit prefix, disables problematic launcher
acceleration features, and instructs the user to close the first login window
before finishing.

This project invokes the published installer through Lutris's documented
`lutris:battlenet-standard` protocol. It does not copy a snapshot of the YAML,
so Lutris can deliver maintained installer changes.

### UMU Launcher

[UMU Launcher](https://github.com/Open-Wine-Components/umu-launcher) runs Proton
outside Steam with the Steam Linux Runtime and a shared game-fix database. Its
documentation supports `GE-Proton` as an auto-updating Proton path. Lutris is
used as the UMU integration layer here because it supplies the UI, prefix
tracking, Battle.net installer, and Flatpak distribution needed across both
supported distro families.

## Projects evaluated and incorporated conceptually

### NonSteamLaunchers

[NonSteamLaunchers](https://github.com/moraroy/NonSteamLaunchers-On-Steam-Deck)
offers broad launcher installation, Steam shortcut scanning, artwork, save
backup integration, UMU, GE-Proton, SD-card handling, logs, and dry-run controls.

Useful ideas incorporated here:

- explicit dry-run mode;
- persistent install logs;
- microSD path support and Flatpak permissions;
- UMU and GE-Proton awareness;
- guarded behavior around destructive actions;
- Steam Gaming Mode handoff instructions.

This project does not install NonSteamLaunchers itself because only Battle.net
is in scope. It also avoids a persistent game scanner, automatic binary Steam
VDF edits, bundled artwork services, and a shared prefix for unrelated launchers.
The smaller Lutris path is easier to diagnose and works on both distro families.

### ProtonUp-Qt

[ProtonUp-Qt](https://github.com/DavidoTek/ProtonUp-Qt) remains a good graphical
manager for compatibility tools. Its model informed Steam-installation
detection. It is not required because the command-line GE-Proton installer can
verify upstream checksums and can be rerun noninteractively.

## Valve Proton distinction

[Valve Proton](https://github.com/ValveSoftware/Proton) is shipped and updated by
Steam. Proton stable is QA-tested, Proton Experimental carries public test fixes,
and Bleeding Edge is automated and untested. This project does not replace
Steam's copies or automatically opt a user into Bleeding Edge.

The menu item called GE-Proton installs the latest community GE release. The
guides explicitly recommend using Steam's default first.

## Filesystems and official support boundary

[Lutris Battle.net troubleshooting](https://github.com/lutris/docs/blob/master/Battle.Net.md)
says Battle.net does not work correctly when installed on NTFS and requires
working Vulkan-capable drivers. The installer therefore refuses an NTFS prefix
unless the user passes an explicit override.

Square Enix's [FFXIV system requirements](https://na.finalfantasyxiv.com/system_requirements/)
list Windows and macOS, not Linux. Blizzard's published WoW requirements also
target Windows and macOS. This project provides a community compatibility path,
not vendor support or a promise that future patches will work immediately.

