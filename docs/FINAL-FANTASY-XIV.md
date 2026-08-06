# Final Fantasy XIV and XIVLauncher guide

## Choose the correct method

Use the XLM Steam compatibility tool when any of these are true:

- You are on Steam Deck or another device centered on Steam Gaming Mode.
- You own FFXIV on Steam.
- You want the Steam overlay and controller flow through Big Picture.

Use the XIVLauncher Flatpak when all of these are true:

- You are on a regular desktop Linux session.
- Your FFXIV Windows license is not a Steam license.
- You do not need the launcher to behave as a Steam compatibility tool.

The automatic choice uses XLM on Steam Deck. On desktop Linux it asks when both
paths are reasonable.

## Steam Deck and XLM

Connect power and use a stable network before downloading the full game.

Run in Desktop Mode:

```bash
./install.sh ffxiv --method steam
```

The script:

1. Detects native or Flatpak Steam.
2. Resolves the latest XLM release from `Blooym/xlm`.
3. Verifies GitHub's SHA-256 asset digest.
4. Installs XLM into the correct `compatibilitytools.d` directory.
5. Enables XLM's fallback secret provider on Steam Deck and Flatpak Steam, as
   the upstream installer does.

Then fully restart Steam and finish these exact steps:

1. Open **FINAL FANTASY XIV Online** in your library.
2. If you do not own the Steam edition, use the **FINAL FANTASY XIV Online Free
   Trial** library entry described by the XIVLauncher guide.
3. Open the gear menu and choose **Properties**.
4. Make sure **Launch Options** is empty.
5. Open **Compatibility**.
6. Enable **Force the use of a specific Steam Play compatibility tool**.
7. Choose **XLCore [XLM]**.
8. Close Properties and press **Play**.
9. XLM downloads and starts XIVLauncher.Core.
10. Sign in directly in XIVLauncher and select or download the game files.

Do not select GE-Proton for the FFXIV Steam entry when using XLM. XLM itself is
the selected compatibility tool and manages XIVLauncher.Core.

## Desktop Flatpak

Run:

```bash
./install.sh ffxiv --method flatpak
```

This installs `dev.goats.xivlauncher` from Flathub. The launcher opens in the
desktop session and handles the game data location.

If you put game files on an external Linux-formatted drive, use Flatseal or a
targeted command such as the following to grant the launcher access to only that
directory:

```bash
flatpak override --user --filesystem=/path/to/FFXIV dev.goats.xivlauncher
```

## License and account notes

- A Steam FFXIV license and a Windows FFXIV license are different purchase
  channels. Installing a launcher does not convert one to the other.
- Use the Steam or Free Trial library entry specified by the current
  XIVLauncher guide for the XLM method.
- The Square Enix account, service account, region, and expansion entitlements
  must already be valid.
- XIVLauncher plugins are third-party software. Add them only from sources you
  trust and troubleshoot the base game with plugins disabled first.

## Storage

Square Enix's published PC requirements listed 140 GB for FFXIV when this guide
was researched in August 2026. Requirements change over time, so check the
current official system requirements and leave extra space for patching.

## Updating

Run:

```bash
./install.sh update
```

XIVLauncher.Core updates itself through its launcher path. The project updater
refreshes the installed XLM compatibility tool when it detects XLM, or updates
the XIVLauncher Flatpak when that method is installed.
