# Steam Deck Gaming Installs

Guided Linux setup for:

- World of Warcraft through Lutris and Battle.net
- Final Fantasy XIV through XIVLauncher
- The latest verified GE-Proton release for Steam

The scripts support SteamOS and Arch-family distributions, plus Ubuntu and
Debian-family distributions on x86_64. They use user-level Flatpaks where that
keeps the setup consistent and avoids changing SteamOS's read-only base system.

This is a community compatibility setup. Blizzard and Square Enix do not list
Linux in the official PC requirements for these games. Upstream launcher or game
updates can occasionally require a workaround.

## Steam Deck quick start

1. Press the **Steam** button.
2. Choose **Power > Switch to Desktop**.
3. Open **Konsole** from the application menu.
4. Run:

   ```bash
   git clone https://github.com/AES256Afro/SteamDeckGamingInstalls.git
   cd SteamDeckGamingInstalls
   ./install.sh
   ```

5. Choose **Set up everything** and follow the prompts on screen.

Nothing should be run with `sudo`. The installer asks for your password only if
Ubuntu, Debian, or Arch needs a small prerequisite package. SteamOS normally
needs no system package changes.

## Direct commands

```bash
# Preview every planned action
./install.sh --dry-run all

# Prepare all components
./install.sh all

# Run only one workflow
./install.sh proton
./install.sh wow
./install.sh ffxiv

# Put the Battle.net prefix on a Steam Deck-formatted microSD card
./install.sh wow --library /run/media/deck/YOUR-CARD/Games

# Check the current setup without changing it
./install.sh doctor

# Update installed components without deleting prefixes or game data
./install.sh update
```

## What each workflow does

### GE-Proton

The Proton script asks GitHub for the current
[GE-Proton release](https://github.com/GloriousEggroll/proton-ge-custom/releases/latest)
at runtime. It downloads the x86_64 archive, verifies GitHub's asset digest,
verifies the publisher's SHA-512 checksum, checks the archive paths, and then
installs the release into Steam's `compatibilitytools.d` directory.

Steam itself manages Valve Proton stable and Proton Experimental. GE-Proton is
a separate community compatibility tool. Start with Steam's game-specific
default, and select GE-Proton only when it solves a game-specific problem or a
maintained guide calls for it.

### World of Warcraft

The WoW script installs Lutris from Flathub and starts Lutris's maintained
Battle.net installer. You finish the graphical Battle.net setup, sign in, and
select the WoW edition you want. Lutris keeps Battle.net in its own prefix.

Read [the World of Warcraft guide](docs/WORLD-OF-WARCRAFT.md) before choosing a
microSD card or other external drive.

### Final Fantasy XIV

On Steam Deck, the FFXIV script installs XLM as a Steam compatibility tool. This
is the current method recommended by the XIVLauncher project for Steam Deck and
Big Picture systems. Desktop Linux users with a non-Steam FFXIV license can
choose the XIVLauncher Flatpak instead.

Read [the Final Fantasy XIV guide](docs/FINAL-FANTASY-XIV.md) for the exact Steam
properties and license notes.

## Safety and support features

- `--dry-run` previews mutations.
- Logs are stored under
  `~/.local/state/steam-deck-gaming-installs/`.
- GitHub release executables and archives must have a publisher digest.
- GE-Proton is also checked against its published SHA-512 file.
- Archive paths are checked before extraction.
- The installer refuses to run as root.
- SteamOS's read-only partition is not unlocked.
- Battle.net prefixes on NTFS are rejected by default because Lutris documents
  that configuration as broken.
- Existing game data and Wine prefixes are never removed by the update script.
- Older GE-Proton directories are kept so games pinned to an older release do
  not break. Remove an unused release later through ProtonUp-Qt or after checking
  every game's Compatibility selection.

## Guides

- [World of Warcraft](docs/WORLD-OF-WARCRAFT.md)
- [Final Fantasy XIV](docs/FINAL-FANTASY-XIV.md)
- [Ubuntu and Debian](docs/UBUNTU-DEBIAN.md)
- [SteamOS and Arch](docs/STEAMOS-ARCH.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Research and upstream choices](docs/RESEARCH.md)
- [Security model](SECURITY.md)

## Developer checks

```bash
./tests/run.sh
```

CI also runs ShellCheck on every shell file.

## Scope

The automated checks prove that launchers and compatibility tools are installed
in the expected locations. They cannot prove that account login, a full game
download, or rendered gameplay works on a particular machine. Those final steps
remain visible and interactive so credentials never pass through these scripts.
